import Foundation
import Security

/// Pro/Free state machine.
///
/// Mac Cleaner Pro is free and open source — every feature is unlocked
/// regardless of license state. `.pro` is kept only to recognize legacy
/// license keys from pre-open-source purchases (shown as "Supporter" in
/// Settings); everyone else is `.free`, with no trial or expiry.
///
/// License key is stored in the macOS Keychain via SecureLicenseStorage.
/// Background revalidation runs every 24 h when the app is live; a 7-day
/// grace period allows offline use between revalidations.
public actor LicenseManager {

    public enum State: Equatable, Sendable {
        case free
        case pro(licenseKey: String)
    }

    public static let shared = LicenseManager()

    // Legacy key — read-once for migration, then removed
    private let legacyLicenseKeyKey = "MacCleanerPro.licenseKey"

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
        return .free
    }

    // MARK: - Revalidation

    /// Re-checks the license with the server if 24 h have elapsed.
    ///
    /// The Ed25519 signature is the cryptographic root of trust and is verified
    /// fully offline (see ``LicenseValidator``), so a stored license is only ever
    /// *removed* here when the server **authoritatively revokes** it (refund,
    /// chargeback, manual disable). We deliberately never clear a
    /// cryptographically valid license just because the server is unreachable,
    /// returns an error, or doesn't recognize the key — that would punish paying
    /// customers who are offline and silently wipe self-issued / developer keys.
    /// In those "couldn't confirm" cases we only flip the offline-mode flag (used
    /// for non-blocking UI messaging) and keep the license.
    public func revalidateIfNeeded() async {
        guard let licenseData = await SecureLicenseStorage.shared.retrieveLicense() else { return }
        guard await SecureLicenseStorage.shared.needsRevalidation() else { return }

        let deviceId   = DeviceIdentifier.getDeviceID()
        let deviceName = DeviceIdentifier.getDeviceName()

        do {
            let api = ActivationAPI()
            let response = try await api.revalidate(
                licenseData.licenseKey,
                deviceId: deviceId,
                deviceName: deviceName
            )

            if response.valid {
                await SecureLicenseStorage.shared.updateValidationTimestamp()
                await SecureLicenseStorage.shared.setOfflineMode(false)
            } else if Self.isAuthoritativeRevocation(response.error) {
                // Server explicitly says this license was revoked/refunded.
                await SecureLicenseStorage.shared.clearLicense()
            } else {
                // Server couldn't confirm the key (unknown to the backend, or a
                // transient/environment mismatch). Keep the locally valid license.
                await SecureLicenseStorage.shared.setOfflineMode(true)
            }
        } catch {
            // Network / HTTP failure — stay offline-tolerant, never revoke.
            await SecureLicenseStorage.shared.setOfflineMode(true)
        }
    }

    /// Whether a server `valid:false` response is an *authoritative* revocation
    /// (refund / chargeback / manual disable) as opposed to "the backend doesn't
    /// know this key". Only authoritative revocations clear a stored license.
    static func isAuthoritativeRevocation(_ error: String?) -> Bool {
        guard let error = error?.lowercased() else { return false }
        let revocationSignals = ["revoked", "refunded", "refund", "chargeback", "disabled", "deactivated"]
        return revocationSignals.contains { error.contains($0) }
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
        return true
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

    // MARK: - Paddle stub (activate when account is approved)

    public enum PaddleError: Error { case notConfigured }
    public func verifyWithPaddle(key: String) async throws -> Bool {
        throw PaddleError.notConfigured
    }
}
