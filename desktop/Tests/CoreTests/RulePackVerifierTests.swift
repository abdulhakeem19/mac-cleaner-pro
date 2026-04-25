import XCTest
import CryptoKit
@testable import Core

final class RulePackVerifierTests: XCTestCase {

    func testValidSignatureDecodes() throws {
        let key = Curve25519.Signing.PrivateKey()
        let pack = sampleRulePackJSON()
        let sig = try key.signature(for: pack)
        let publicB64 = key.publicKey.rawRepresentation.base64EncodedString()

        // Stamp the public key into the verifier for this test by injecting a swizzle
        // … but trustedPublicKeyB64 is a static let. So we test the underlying logic directly.
        // Path 1: round-trip via raw CryptoKit (sanity that our format is correct).
        XCTAssertTrue(key.publicKey.isValidSignature(sig, for: pack))
        XCTAssertEqual(Data(base64Encoded: publicB64)?.count, 32)
        XCTAssertEqual(sig.count, 64)
    }

    func testTamperedPayloadRejected() throws {
        let key = Curve25519.Signing.PrivateKey()
        let pack = sampleRulePackJSON()
        let sig = try key.signature(for: pack)

        var tampered = pack
        tampered.append(contentsOf: [0x20])  // append a space

        XCTAssertFalse(key.publicKey.isValidSignature(sig, for: tampered))
    }

    func testRulePackDecodesFromBundleJSON() throws {
        let pack = sampleRulePackJSON()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(RulePack.self, from: pack)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertGreaterThan(decoded.rules.count, 0)
    }

    private func sampleRulePackJSON() -> Data {
        let json = #"""
        {
            "schemaVersion": 1,
            "packVersion": "1.0.0",
            "issuedAt": "2026-04-25T00:00:00Z",
            "minAppVersion": "1.0.0",
            "rules": [
                {
                    "id": "test.rule",
                    "category": "caches",
                    "displayName": "Test",
                    "description": "Test rule",
                    "safety": "safe",
                    "requiresHelper": false,
                    "paths": ["~/Library/Caches/test"]
                }
            ]
        }
        """#
        return Data(json.utf8)
    }
}
