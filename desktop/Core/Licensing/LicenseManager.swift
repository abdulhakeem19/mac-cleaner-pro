import Foundation
import Security

/// Trial/Pro/Expired state machine.
///
/// MVP semantics ($0 mode, no Apple Developer cert, no Paddle backend yet):
///   - 14-day trial begins on first launch.
///   - Any non-empty license key sets the state to `.pro`. The real Paddle/Ed25519
///     verifier slots in here behind the same `Validator` protocol.
///   - Trial start date is stored in the Keychain (survives app deletion/reinstall).
public actor LicenseManager {

    public enum State: Equatable, Sendable {
        case trial(daysRemaining: Int)
        case pro(licenseKey: String)
        case expired
    }

    public static let shared = LicenseManager()

    private let trialLengthDays = 14
    private let installDateKey  = "MacCleanerPro.installDate"  // kept for migration
    private let licenseKeyKey   = "MacCleanerPro.licenseKey"

    // Keychain identifiers
    private let keychainService = "com.maccleanerpro"
    private let keychainDateKey = "installDate"

    public init() {}

    public func currentState() async -> State {
        if let key = UserDefaults.standard.string(forKey: licenseKeyKey),
           !key.isEmpty,
           Self.isStructurallyValid(key) {
            return .pro(licenseKey: key)
        }
        let installDate = self.installDateOrSeed()
        let elapsed = Date().timeIntervalSince(installDate)
        let daysElapsed = Int(elapsed / 86_400)
        let remaining = trialLengthDays - daysElapsed
        return remaining > 0 ? .trial(daysRemaining: remaining) : .expired
    }

    public func setLicenseKey(_ key: String) async -> State {
        UserDefaults.standard.set(key, forKey: licenseKeyKey)
        return await currentState()
    }

    public func clearLicense() async -> State {
        UserDefaults.standard.removeObject(forKey: licenseKeyKey)
        return await currentState()
    }

    /// Convenience: `true` if the user is allowed to use paid features today.
    public func isUnlocked() async -> Bool {
        switch await currentState() {
        case .pro, .trial: return true
        case .expired:     return false
        }
    }

    // MARK: - Internals

    /// Migration-safe: reads from Keychain first, falls back to UserDefaults
    /// (existing users), or seeds a fresh Keychain entry.
    private func installDateOrSeed() -> Date {
        if let kc = keychainRead() { return kc }
        if let ud = UserDefaults.standard.object(forKey: installDateKey) as? Date {
            keychainWrite(ud)
            return ud
        }
        let now = Date()
        keychainWrite(now)
        return now
    }

    /// Until we wire Paddle's signed key verification, accept anything that
    /// looks like a license: prefix `MCP-` and at least 12 chars after it.
    static func isStructurallyValid(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("MCP-") else { return false }
        return trimmed.dropFirst(4).count >= 12
    }

    // MARK: - Keychain helpers

    private func keychainRead() -> Date? {
        let q: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainDateKey,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data,
              let str  = String(data: data, encoding: .utf8)
        else { return nil }
        return ISO8601DateFormatter().date(from: str)
    }

    private func keychainWrite(_ date: Date) {
        let data = Data(ISO8601DateFormatter().string(from: date).utf8)
        let del: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainDateKey,
        ]
        SecItemDelete(del as CFDictionary)
        let add: [String: Any] = [
            kSecClass as String:                kSecClassGenericPassword,
            kSecAttrService as String:          keychainService,
            kSecAttrAccount as String:          keychainDateKey,
            kSecValueData as String:            data,
            kSecAttrAccessible as String:       kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        SecItemAdd(add as CFDictionary, nil)
    }

    // MARK: - Paddle stub (activate when account is approved)

    /// TODO: Replace isStructurallyValid with this when Paddle Ed25519 keys arrive.
    /// See desktop/docs/SHIP_READINESS.md for the exact swap instructions.
    public enum PaddleError: Error { case notConfigured }
    public func verifyWithPaddle(key: String) async throws -> Bool {
        throw PaddleError.notConfigured
    }
}
