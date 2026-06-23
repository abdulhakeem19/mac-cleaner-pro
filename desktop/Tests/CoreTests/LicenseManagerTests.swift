import XCTest
import Security
@testable import Core

final class LicenseManagerTests: XCTestCase {

    // Real signed test fixture (signed with the embedded Ed25519 test keypair)
    let validProKey = "MCP-dGVzdEBleGFtcGxlLmNvbXxwcm98MjAyNi0wNS0yNVQwNzoyNjowNS4zMDZafDE.y93pv9j0tCifKODbQfGcHlo1wVwl6gJvF0pZq06U1gV7pVVigtWW2LeTqYHCiCYgUbKX_Wo-dHx3F-Z0Q5SKDw"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "MacCleanerPro.installDate")
        UserDefaults.standard.removeObject(forKey: "MacCleanerPro.licenseKey")
        // Clear trial date Keychain entry
        let trialQ: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: "com.maccleanerpro",
        ]
        SecItemDelete(trialQ as CFDictionary)
        // Clear license storage Keychain entry so tests start with a clean slate
        let licenseQ: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: "com.maccleanerpro.license",
        ]
        SecItemDelete(licenseQ as CFDictionary)
    }

    func testFreshInstallStartsTrial() async {
        let mgr = LicenseManager()
        // Defend against any license left in the login Keychain by the real app
        // (the test bundle can read the same generic-password items).
        _ = await mgr.clearLicense()
        let state = await mgr.currentState()
        if case .trial(let days) = state {
            XCTAssertEqual(days, 14)
        } else {
            XCTFail("expected trial, got \(state)")
        }
    }

    func testValidSignedKeyUnlocksPro() async {
        let mgr = LicenseManager()
        let state = await mgr.setLicenseKey(validProKey)
        if case .pro = state {} else { XCTFail("expected pro, got \(state)") }
    }

    func testInvalidKeyRemainsTrial() async {
        let mgr = LicenseManager()
        let state = await mgr.setLicenseKey("not-a-key")
        if case .trial = state {} else { XCTFail("expected trial, got \(state)") }
    }

    func testExpiredAfterTrialWindow() async {
        // Clear any stored license directly (does NOT seed an install date the
        // way currentState()/clearLicense() would).
        await SecureLicenseStorage.shared.clearLicense()
        deleteTrialDateKeychain()
        // Stamp install date 30 days ago — with no Keychain trial date present,
        // installDateOrSeed() falls back to this UserDefaults value.
        UserDefaults.standard.set(Date(timeIntervalSinceNow: -30 * 86_400),
                                  forKey: "MacCleanerPro.installDate")
        let mgr = LicenseManager()
        let state = await mgr.currentState()
        XCTAssertEqual(state, .expired)
    }

    private func deleteTrialDateKeychain() {
        let q: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: "com.maccleanerpro",
        ]
        SecItemDelete(q as CFDictionary)
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

    func testIsUnlockedDuringTrial() async {
        let mgr = LicenseManager()
        let unlocked = await mgr.isUnlocked()
        XCTAssertTrue(unlocked)
    }
}
