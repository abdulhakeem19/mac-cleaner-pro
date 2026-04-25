import Foundation

/// Trial/Pro/Expired state machine.
///
/// MVP semantics ($0 mode, no Apple Developer cert, no Paddle backend yet):
///   - 14-day trial begins on first launch.
///   - Any non-empty license key sets the state to `.pro`. The real Paddle/Ed25519
///     verifier slots in here behind the same `Validator` protocol.
///   - State is purely a local UserDefaults flag — anti-piracy is out of scope
///     until v1.1; the goal is to support a paid build path that exists.
public actor LicenseManager {

    public enum State: Equatable, Sendable {
        case trial(daysRemaining: Int)
        case pro(licenseKey: String)
        case expired
    }

    public static let shared = LicenseManager()

    private let trialLengthDays = 14
    private let installDateKey  = "MacCleanerPro.installDate"
    private let licenseKeyKey   = "MacCleanerPro.licenseKey"

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

    private func installDateOrSeed() -> Date {
        if let stored = UserDefaults.standard.object(forKey: installDateKey) as? Date {
            return stored
        }
        let now = Date()
        UserDefaults.standard.set(now, forKey: installDateKey)
        return now
    }

    /// Until we wire Paddle's signed key verification, accept anything that
    /// looks like a license: prefix `MCP-` and at least 12 chars after it.
    /// The shape mirrors what Paddle issues, so real keys will pass through.
    static func isStructurallyValid(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("MCP-") else { return false }
        return trimmed.dropFirst(4).count >= 12
    }
}
