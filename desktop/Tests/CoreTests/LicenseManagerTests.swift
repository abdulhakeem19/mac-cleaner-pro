import XCTest
import Security
@testable import Core

final class LicenseManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "MacCleanerPro.installDate")
        UserDefaults.standard.removeObject(forKey: "MacCleanerPro.licenseKey")
        // Clear Keychain so each test starts with a fresh trial state
        let q: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: "com.maccleanerpro",
        ]
        SecItemDelete(q as CFDictionary)
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

    func testStructurallyValidKeyUnlocksPro() async {
        let mgr = LicenseManager()
        let state = await mgr.setLicenseKey("MCP-ABCDEFGHIJKL")
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
