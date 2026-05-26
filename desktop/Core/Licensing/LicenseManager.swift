import Foundation
import Security

/// Trial/Pro/Expired state machine.
///
/// License key is stored in the macOS Keychain via SecureLicenseStorage.
/// Background revalidation runs every 24 h when the app is live; a 7-day
/// grace period allows offline use between revalidations.
public actor LicenseManager {

    public enum State: Equatable, Sendable {
        case trial(daysRemaining: Int)
        case pro(licenseKey: String)
        case expired
    }

    public static let shared = LicenseManager()

    private let trialLengthDays = 14

    // Legacy keys — read-once for migration, then removed
    private let legacyInstallDateKey = "MacCleanerPro.installDate"
    private let legacyLicenseKeyKey  = "MacCleanerPro.licenseKey"

    // Keychain identifiers for trial start date (separate from license storage)
    private let keychainService = "com.maccleanerpro"
    private let keychainDateKey = "installDate"

    public init() {}

    // MARK: - State

    public func currentState() async -> State {
        if let licenseData = await SecureLicenseStorage.shared.retrieveLicense() {
            let result = LicenseValidator.validate(licenseData.licenseKey)
            if case .valid = result {
                return .pro(licenseKey: licenseData.licenseKey)
            }
            // Corrupted / tampered entry — purge it
            await SecureLicenseStorage.shared.clearLicense()
        }
        return trialState()
    }

    // MARK: - Revalidation

    /// Re-checks the license with the server if 24 h have elapsed.
    /// On network failure, honours the 7-day grace period; beyond that it
    /// clears the stored license so the app reverts to expired state.
    public func revalidateIfNeeded() async {
        guard let licenseData = await SecureLicenseStorage.shared.retrieveLicense() else { return }
        guard await SecureLicenseStorage.shared.needsRevalidation() else { return }

        let deviceId   = DeviceIdentifier.getDeviceID()
        let deviceName = DeviceIdentifier.getDeviceName()

        do {
            let api = ActivationAPI()
            let response = try await api.activateLicense(
                licenseData.licenseKey,
                deviceId: deviceId,
                deviceName: deviceName
            )

            if response.valid {
                await SecureLicenseStorage.shared.updateValidationTimestamp()
                await SecureLicenseStorage.shared.setOfflineMode(false)
            } else {
                // Revoked or refunded — remove immediately
                await SecureLicenseStorage.shared.clearLicense()
            }
        } catch {
            // Network unreachable — check grace period
            let inGrace = await SecureLicenseStorage.shared.isInGracePeriod()
            await SecureLicenseStorage.shared.setOfflineMode(true)
            if !inGrace {
                await SecureLicenseStorage.shared.clearLicense()
            }
        }
    }

    // MARK: - Migration

    /// One-time migration: moves a license key previously stored in
    /// UserDefaults into the Keychain so it benefits from secure storage.
    public func migrateFromUserDefaults() async {
        guard await SecureLicenseStorage.shared.retrieveLicense() == nil else { return }

        let legacyKeys = [legacyLicenseKeyKey, "MacCleanerPro.licenseKey.fallback"]
        for udKey in legacyKeys {
            guard let oldKey = UserDefaults.standard.string(forKey: udKey), !oldKey.isEmpty else { continue }
            let result = LicenseValidator.validate(oldKey)
            if case .valid(let payload) = result {
                let deviceId = DeviceIdentifier.getDeviceID()
                try? await SecureLicenseStorage.shared.storeLicense(
                    oldKey, deviceId: deviceId, payload: payload, activations: nil
                )
            }
            UserDefaults.standard.removeObject(forKey: udKey)
            return
        }
    }

    // MARK: - Activation / Deactivation

    /// Validates the key locally (Ed25519) and stores it in the Keychain.
    /// Pass `activationInfo` when a server activation response is available.
    public func setLicenseKey(
        _ key: String,
        activationInfo: ActivationAPI.ActivationInfo? = nil
    ) async -> State {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)

        let result = LicenseValidator.validate(trimmed)
        guard case .valid(let payload) = result else {
            return await currentState()
        }

        let deviceId = DeviceIdentifier.getDeviceID()
        try? await SecureLicenseStorage.shared.storeLicense(
            trimmed, deviceId: deviceId, payload: payload, activations: activationInfo
        )
        return await currentState()
    }

    public func clearLicense() async -> State {
        await SecureLicenseStorage.shared.clearLicense()
        return await currentState()
    }

    public func isUnlocked() async -> Bool {
        switch await currentState() {
        case .pro, .trial: return true
        case .expired:     return false
        }
    }

    public func getLicensePayload() async -> LicensePayload? {
        guard let licenseData = await SecureLicenseStorage.shared.retrieveLicense() else { return nil }
        let result = LicenseValidator.validate(licenseData.licenseKey)
        if case .valid(let payload) = result { return payload }
        return nil
    }

    // MARK: - Structural check (used for quick UI feedback)

    public static func isStructurallyValid(_ key: String) -> Bool {
        LicenseValidator.validate(key) != .invalid(.invalidFormat)
    }

    // MARK: - Trial helpers

    private func trialState() -> State {
        let installDate = installDateOrSeed()
        let daysElapsed = Int(Date().timeIntervalSince(installDate) / 86_400)
        let remaining   = trialLengthDays - daysElapsed
        return remaining > 0 ? .trial(daysRemaining: remaining) : .expired
    }

    /// Migration-safe: reads from Keychain first, falls back to UserDefaults
    /// (existing users), or seeds a fresh Keychain entry.
    private func installDateOrSeed() -> Date {
        if let kc = keychainRead() { return kc }
        if let ud = UserDefaults.standard.object(forKey: legacyInstallDateKey) as? Date {
            keychainWrite(ud)
            return ud
        }
        let now = Date()
        keychainWrite(now)
        return now
    }

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

    public enum PaddleError: Error { case notConfigured }
    public func verifyWithPaddle(key: String) async throws -> Bool {
        throw PaddleError.notConfigured
    }
}
