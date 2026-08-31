import Foundation
import IOKit

/// Device identifier generator for machine activation tracking.
///
/// Generates a stable, unique identifier for the current Mac that:
/// - Persists across app reinstalls
/// - Survives OS updates
/// - Is consistent for the same hardware
/// - Cannot be easily spoofed
public struct DeviceIdentifier {

    /// Get a stable device identifier for this Mac
    public static func getDeviceID() -> String {
        // Try to get the hardware UUID from IOKit
        if let hardwareUUID = getHardwareUUID() {
            return hardwareUUID
        }

        // Fallback: Use a combination of hardware serial and model
        if let fallbackID = getFallbackIdentifier() {
            return fallbackID
        }

        // Last resort: Generate and store a UUID in Keychain
        return getOrCreateKeychainID()
    }

    /// Get device name for display purposes
    public static func getDeviceName() -> String {
        return Host.current().localizedName ?? "Unknown Mac"
    }

    // MARK: - Private Methods

    /// Get the hardware UUID from IORegistry
    private static func getHardwareUUID() -> String? {
        let platformExpert = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )

        guard platformExpert != 0 else {
            return nil
        }

        defer {
            IOObjectRelease(platformExpert)
        }

        guard let serialNumberAsCFString = IORegistryEntryCreateCFProperty(
            platformExpert,
            kIOPlatformUUIDKey as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? String else {
            return nil
        }

        return serialNumberAsCFString
    }

    /// Get a fallback identifier based on hardware serial
    private static func getFallbackIdentifier() -> String? {
        let platformExpert = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )

        guard platformExpert != 0 else {
            return nil
        }

        defer {
            IOObjectRelease(platformExpert)
        }

        guard let serialNumber = IORegistryEntryCreateCFProperty(
            platformExpert,
            kIOPlatformSerialNumberKey as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? String else {
            return nil
        }

        // Combine with model identifier for uniqueness
        let model = getModelIdentifier()
        return "fallback-\(serialNumber)-\(model)"
    }

    /// Get the Mac model identifier
    private static func getModelIdentifier() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }

    /// Get or create a device ID stored in Keychain (last resort)
    private static func getOrCreateKeychainID() -> String {
        let service = "com.maccleanerpro.deviceid"
        let account = "device"

        // Try to read existing
        if let existing = keychainRead(service: service, account: account) {
            return existing
        }

        // Generate new
        let newID = "generated-\(UUID().uuidString)"
        keychainWrite(service: service, account: account, value: newID)
        return newID
    }

    private static func keychainRead(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    private static func keychainWrite(service: String, account: String, value: String) {
        let data = Data(value.utf8)

        // Delete existing first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }
}
