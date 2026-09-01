import XCTest
import Security
@testable import Core

final class LicenseManagerTests: XCTestCase {

    // Real signed test fixture (signed with the embedded Ed25519 test keypair)
    let validProKey = "MCP-dGVzdEBleGFtcGxlLmNvbXxwcm98MjAyNi0wNS0yNVQwNzoyNjowNS4zMDZafDE.y93pv9j0tCifKODbQfGcHlo1wVwl6gJvF0pZq06U1gV7pVVigtWW2LeTqYHCiCYgUbKX_Wo-dHx3F-Z0Q5SKDw"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "MacCleanerPro.licenseKey")
        // Clear license storage Keychain entry so tests start with a clean slate
        let licenseQ: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: "com.maccleanerpro.license",
        ]
        SecItemDelete(licenseQ as CFDictionary)
    }

    func testFreshInstallIsFree() async {
        let mgr = LicenseManager()
        // Defend against any license left in the login Keychain by the real app
        // (the test bundle can read the same generic-password items).
        _ = await mgr.clearLicense()
        let state = await mgr.currentState()
        XCTAssertEqual(state, .free)
    }

    func testValidSignedKeyUnlocksPro() async {
        let mgr = LicenseManager()
        let state = await mgr.setLicenseKey(validProKey)
        if case .pro = state {} else { XCTFail("expected pro, got \(state)") }
    }

    func testInvalidKeyRemainsFree() async {
        let mgr = LicenseManager()
        let state = await mgr.setLicenseKey("not-a-key")
        XCTAssertEqual(state, .free)
    }

    // MARK: - Revalidation revocation policy

    func testAuthoritativeRevocationIsDetected() {
        XCTAssertTrue(LicenseManager.isAuthoritativeRevocation("License revoked"))
        XCTAssertTrue(LicenseManager.isAuthoritativeRevocation("Order refunded"))
        XCTAssertTrue(LicenseManager.isAuthoritativeRevocation("payment chargeback received"))
        XCTAssertTrue(LicenseManager.isAuthoritativeRevocation("License disabled by admin"))
    }

    func testUnknownOrTransientErrorsAreNotRevocations() {
        // These must NOT clear a cryptographically valid (e.g. self-issued/dev) license.
        XCTAssertFalse(LicenseManager.isAuthoritativeRevocation(nil))
        XCTAssertFalse(LicenseManager.isAuthoritativeRevocation(""))
        XCTAssertFalse(LicenseManager.isAuthoritativeRevocation("License not found"))
        XCTAssertFalse(LicenseManager.isAuthoritativeRevocation("Internal server error"))
        XCTAssertFalse(LicenseManager.isAuthoritativeRevocation("limit reached"))
    }

    func testIsUnlockedWhenFree() async {
        let mgr = LicenseManager()
        let unlocked = await mgr.isUnlocked()
        XCTAssertTrue(unlocked)
    }
}
