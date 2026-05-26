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
        // Stamp install date 30 days ago.
        UserDefaults.standard.set(Date(timeIntervalSinceNow: -30 * 86_400),
                                  forKey: "MacCleanerPro.installDate")
        let mgr = LicenseManager()
        let state = await mgr.currentState()
        XCTAssertEqual(state, .expired)
    }

    func testIsUnlockedDuringTrial() async {
        let mgr = LicenseManager()
        let unlocked = await mgr.isUnlocked()
        XCTAssertTrue(unlocked)
    }
}
