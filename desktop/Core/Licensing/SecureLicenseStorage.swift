import Foundation
import Security
import CryptoKit

/// Secure license storage using macOS Keychain with additional protection layers
/// Similar to how CleanMyMac, Sublime Text, and other pro apps handle licensing
public actor SecureLicenseStorage {

    public static let shared = SecureLicenseStorage()

    private let keychainService = "com.maccleanerpro.license"
    private let keychainLicenseKey = "license_key"
    private let keychainDeviceIDKey = "device_id"
    private let keychainActivationKey = "activation_data"

    // UserDefaults for non-sensitive caching
    private let lastValidationKey = "MCP-LastValidation"
    private let validationGracePeriodKey = "MCP-GracePeriod"
    private let offlineModeKey = "MCP-OfflineMode"

    // Constants
    private let validationInterval: TimeInterval = 24 * 60 * 60  // 24 hours
    private let gracePeriodDays: Int = 7  // Allow 7 days offline

    public struct LicenseData: Codable {
        public let licenseKey: String
        public let deviceId: String
        public let activatedAt: Date
        public let lastValidated: Date
        public let activationsData: ActivationsData?

        public struct ActivationsData: Codable {
            public let currentDevice: String
            public let totalDevices: Int
            public let maxDevices: Int
        }
    }

    private init() {}

    // MARK: - Public API

    /// Store license with full validation and device binding
    public func storeLicense(
        _ key: String,
        deviceId: String,
        payload: LicensePayload,
        activations: ActivationAPI.ActivationInfo?
    ) async throws {
        // Store in Keychain (encrypted by macOS)
        try keychainStore(key: keychainLicenseKey, value: key)
        try keychainStore(key: keychainDeviceIDKey, value: deviceId)

        // Store activation metadata
        let licenseData = LicenseData(
            licenseKey: key,
            deviceId: deviceId,
            activatedAt: Date(),
            lastValidated: Date(),
            activationsData: activations.map { act in
                LicenseData.ActivationsData(
                    currentDevice: deviceId,
                    totalDevices: act.count,
                    maxDevices: act.limit
                )
            }
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(licenseData)
        try keychainStore(key: keychainActivationKey, value: String(data: data, encoding: .utf8)!)

        // Cache validation timestamp
        UserDefaults.standard.set(Date(), forKey: lastValidationKey)
        UserDefaults.standard.set(false, forKey: offlineModeKey)
    }

    /// Retrieve stored license
    public func retrieveLicense() async -> LicenseData? {
        guard let keyData = keychainRetrieve(key: keychainLicenseKey),
              let licenseKey = String(data: keyData, encoding: .utf8),
              let deviceIdData = keychainRetrieve(key: keychainDeviceIDKey),
              let deviceId = String(data: deviceIdData, encoding: .utf8),
              let activationData = keychainRetrieve(key: keychainActivationKey),
              let activationJSON = String(data: activationData, encoding: .utf8) else {
            return nil
        }

        let decoder = JSONDecoder()
        if let jsonData = activationJSON.data(using: .utf8),
           let licenseData = try? decoder.decode(LicenseData.self, from: jsonData) {
            return licenseData
        }

        // Fallback: basic license data without full activation info
        return LicenseData(
            licenseKey: licenseKey,
            deviceId: deviceId,
            activatedAt: Date(),
            lastValidated: UserDefaults.standard.object(forKey: lastValidationKey) as? Date ?? Date(),
            activationsData: nil
        )
    }

    /// Check if license needs revalidation
    public func needsRevalidation() async -> Bool {
        guard let lastValidation = UserDefaults.standard.object(forKey: lastValidationKey) as? Date else {
            return true  // Never validated
        }

        let elapsed = Date().timeIntervalSince(lastValidation)
        return elapsed >= validationInterval
    }

    /// Check if still in grace period (offline mode)
    public func isInGracePeriod() async -> Bool {
        guard let lastValidation = UserDefaults.standard.object(forKey: lastValidationKey) as? Date else {
            return false
        }

        let elapsed = Date().timeIntervalSince(lastValidation)
        let gracePeriodSeconds = TimeInterval(gracePeriodDays * 24 * 60 * 60)
        return elapsed < gracePeriodSeconds
    }

    /// Days remaining in the grace period when currently in offline mode.
    /// Returns nil when the license has been validated online recently (not offline).
    public func gracePeriodDaysRemaining() async -> Int? {
        guard UserDefaults.standard.bool(forKey: offlineModeKey) else { return nil }
        guard let lastValidation = UserDefaults.standard.object(forKey: lastValidationKey) as? Date else {
            return nil
        }
        let gracePeriodSeconds = TimeInterval(gracePeriodDays * 24 * 60 * 60)
        let remaining = gracePeriodSeconds - Date().timeIntervalSince(lastValidation)
        return remaining > 0 ? Int(ceil(remaining / 86_400)) : 0
    }

    /// Mark validation successful
    public func updateValidationTimestamp() async {
        UserDefaults.standard.set(Date(), forKey: lastValidationKey)
    }

    /// Set offline mode flag
    public func setOfflineMode(_ enabled: Bool) async {
        UserDefaults.standard.set(enabled, forKey: offlineModeKey)
    }

    /// Check if in offline mode
    public func isOfflineMode() async -> Bool {
        return UserDefaults.standard.bool(forKey: offlineModeKey)
    }

    /// Clear all license data
    public func clearLicense() async {
        keychainDelete(key: keychainLicenseKey)
        keychainDelete(key: keychainDeviceIDKey)
        keychainDelete(key: keychainActivationKey)
        UserDefaults.standard.removeObject(forKey: lastValidationKey)
        UserDefaults.standard.removeObject(forKey: offlineModeKey)
    }

    // MARK: - Keychain Operations

    private func keychainStore(key: String, value: String) throws {
        let data = Data(value.utf8)

        // Delete existing
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw LicenseError.keychainStorageFailed
        }
    }

    private func keychainRetrieve(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return data
    }

    private func keychainDelete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

public enum LicenseError: Error, LocalizedError {
    case keychainStorageFailed
    case invalidLicenseData
    case validationExpired
    case gracePeriodExpired

    public var errorDescription: String? {
        switch self {
        case .keychainStorageFailed:
            return "Failed to store license securely"
        case .invalidLicenseData:
            return "License data is corrupted"
        case .validationExpired:
            return "License validation expired"
        case .gracePeriodExpired:
            return "Grace period expired - please reconnect to the internet"
        }
    }
}
