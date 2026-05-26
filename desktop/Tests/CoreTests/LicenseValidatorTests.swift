import XCTest
import Security
@testable import Core

final class LicenseValidatorTests: XCTestCase {

    // Valid test license keys generated with the same keypair
    let validProKey = "MCP-dGVzdEBleGFtcGxlLmNvbXxwcm98MjAyNi0wNS0yNVQwNzoyNjowNS4zMDZafDE.y93pv9j0tCifKODbQfGcHlo1wVwl6gJvF0pZq06U1gV7pVVigtWW2LeTqYHCiCYgUbKX_Wo-dHx3F-Z0Q5SKDw"
    let validFamilyKey = "MCP-ZmFtaWx5QGV4YW1wbGUuY29tfGZhbWlseXwyMDI2LTA1LTI1VDA3OjI2OjA1LjMxMlp8NQ.9h9xAGu7afO802yVFUyoPbvQwV69i1Z-POujrqm7djqaDZKDdEs8AuajuubdL8q5qQ3k098NVb2hsqLzr3NwAw"

    override func setUp() {
        super.setUp()
        // Clear license Keychain so shared LicenseManager state doesn't bleed between tests
        let q: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: "com.maccleanerpro.license",
        ]
        SecItemDelete(q as CFDictionary)
    }

    // MARK: - Valid License Tests

    func testValidProLicense() {
        let result = LicenseValidator.validate(validProKey)

        guard case .valid(let payload) = result else {
            XCTFail("Expected valid license, got \(result)")
            return
        }

        XCTAssertEqual(payload.email, "test@example.com")
        XCTAssertEqual(payload.plan, .pro)
        XCTAssertEqual(payload.machineLimit, 1)
    }

    func testValidFamilyLicense() {
        let result = LicenseValidator.validate(validFamilyKey)

        guard case .valid(let payload) = result else {
            XCTFail("Expected valid license, got \(result)")
            return
        }

        XCTAssertEqual(payload.email, "family@example.com")
        XCTAssertEqual(payload.plan, .family)
        XCTAssertEqual(payload.machineLimit, 5)
    }

    // MARK: - Invalid Format Tests

    func testInvalidFormat_NoPrefix() {
        let key = "dGVzdEBleGFtcGxlLmNvbXxwcm98MjAyNi0wNS0yNVQwNzoyNjowNS4zMDZafDE.y93pv9j0tCifKODbQfGcHlo1wVwl6gJvF0pZq06U1gV7pVVigtWW2LeTqYHCiCYgUbKX_Wo-dHx3F-Z0Q5SKDw"
        let result = LicenseValidator.validate(key)

        XCTAssertEqual(result, .invalid(.invalidFormat))
    }

    func testInvalidFormat_NoDot() {
        let key = "MCP-dGVzdEBleGFtcGxlLmNvbXxwcm98MjAyNi0wNS0yNVQwNzoyNjowNS4zMDZafDE"
        let result = LicenseValidator.validate(key)

        XCTAssertEqual(result, .invalid(.invalidFormat))
    }

    func testInvalidFormat_Empty() {
        let result = LicenseValidator.validate("")
        XCTAssertEqual(result, .invalid(.invalidFormat))
    }

    func testInvalidFormat_OnlyPrefix() {
        let result = LicenseValidator.validate("MCP-")
        XCTAssertEqual(result, .invalid(.invalidFormat))
    }

    // MARK: - Invalid Signature Tests

    func testInvalidSignature_Tampered() {
        // Tamper with the last few characters of the signature
        let tamperedKey = validProKey.dropLast(5) + "AAAAA"
        let result = LicenseValidator.validate(String(tamperedKey))

        XCTAssertEqual(result, .invalid(.invalidSignature))
    }

    func testInvalidSignature_WrongKey() {
        // A key signed with a different private key
        let wrongKey = "MCP-dGVzdEBleGFtcGxlLmNvbXxwcm98MjAyNi0wNS0yNVQwNzoyNjowNS4zMDZafDE.AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        let result = LicenseValidator.validate(wrongKey)

        XCTAssertEqual(result, .invalid(.invalidSignature))
    }

    // MARK: - Invalid Payload Tests

    func testInvalidPayload_MalformedData() {
        // Valid signature format but garbage payload ("abcdefgh" is not email|plan|date|limit)
        let key = "MCP-YWJjZGVmZ2g.y93pv9j0tCifKODbQfGcHlo1wVwl6gJvF0pZq06U1gV7pVVigtWW2LeTqYHCiCYgUbKX_Wo-dHx3F-Z0Q5SKDw"
        let result = LicenseValidator.validate(key)

        // Payload parsing fails before signature check — correct to return invalidPayload
        XCTAssertEqual(result, .invalid(.invalidPayload))
    }

    // MARK: - Structural Validation

    func testIsStructurallyValid_ValidKey() {
        XCTAssertTrue(LicenseManager.isStructurallyValid(validProKey))
        XCTAssertTrue(LicenseManager.isStructurallyValid(validFamilyKey))
    }

    func testIsStructurallyValid_InvalidFormat() {
        XCTAssertFalse(LicenseManager.isStructurallyValid(""))
        XCTAssertFalse(LicenseManager.isStructurallyValid("MCP-"))
        XCTAssertFalse(LicenseManager.isStructurallyValid("INVALID-KEY"))
        XCTAssertFalse(LicenseManager.isStructurallyValid("no-prefix"))
    }

    // MARK: - Integration Tests

    func testLicenseManagerIntegration() async {
        let manager = LicenseManager.shared

        // Set valid key
        let newState = await manager.setLicenseKey(validProKey)
        guard case .pro(let storedKey) = newState else {
            XCTFail("Expected pro state after setting valid key")
            return
        }
        XCTAssertEqual(storedKey, validProKey)

        // Verify payload extraction
        let payload = await manager.getLicensePayload()
        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?.email, "test@example.com")
        XCTAssertEqual(payload?.plan, .pro)

        // Clear license
        let clearedState = await manager.clearLicense()
        XCTAssertNotEqual(clearedState, .pro(licenseKey: validProKey))
    }

    func testLicenseManager_RejectsInvalidKey() async {
        let manager = LicenseManager.shared

        // Try to set invalid key
        let invalidKey = "MCP-INVALID-KEY"
        _ = await manager.setLicenseKey(invalidKey)

        // Should not be stored
        let payload = await manager.getLicensePayload()
        XCTAssertNil(payload)
    }

    // MARK: - Edge Cases

    func testWhitespace_Trimmed() {
        let keyWithSpaces = "  \(validProKey)  "
        let result = LicenseValidator.validate(keyWithSpaces.trimmingCharacters(in: .whitespacesAndNewlines))

        guard case .valid = result else {
            XCTFail("Expected valid license after trimming")
            return
        }
    }

    func testPayloadParsing_AllFields() {
        let result = LicenseValidator.validate(validProKey)

        guard case .valid(let payload) = result else {
            XCTFail("Expected valid license")
            return
        }

        // Verify all fields are parsed correctly
        XCTAssertFalse(payload.email.isEmpty)
        XCTAssertTrue(payload.email.contains("@"))
        XCTAssertGreaterThan(payload.machineLimit, 0)
        XCTAssertLessThanOrEqual(payload.machineLimit, 5)
        XCTAssertNotNil(payload.purchaseDate)
    }
}
