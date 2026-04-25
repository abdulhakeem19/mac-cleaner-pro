import Foundation

/// Loads `RulePack` instances from two distinct sources with different trust models:
///
///   - **Bundled** packs ship inside the app bundle, authenticated by code-signing
///     (or, in $0-mode, ad-hoc signing — the bytes can't be tampered with after
///     build without breaking the app's own signature). No Ed25519 check needed.
///
///   - **Remote** packs fetched from a CDN are untrusted by default and MUST be
///     verified against `RulePackVerifier.trustedPublicKeyB64` before use.
///
/// Keeping the two paths distinct prevents a future refactor from accidentally
/// applying bundled-grade trust to a CDN payload.
public enum RulePackLoader {

    public enum LoadError: Error, Sendable {
        case bundledResourceMissing
        case decodeFailed(Error)
    }

    /// Decode the rule pack shipped in the app bundle. Skips signature checking
    /// because in-bundle bytes are authenticated by the app's own code signature.
    public static func loadBundled(named name: String = "v1",
                                   in bundle: Bundle = .main) throws -> RulePack {
        guard let url = bundle.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            throw LoadError.bundledResourceMissing
        }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(RulePack.self, from: data)
        } catch {
            throw LoadError.decodeFailed(error)
        }
    }

    /// Decode and signature-verify a CDN-fetched pack. Failures here MUST cause
    /// the caller to fall back to the bundled pack — never silently load an
    /// unverified payload.
    public static func loadRemote(packData: Data,
                                  signatureB64: String,
                                  currentAppVersion: String) throws -> RulePack {
        try RulePackVerifier().verify(packData: packData,
                                      signatureB64: signatureB64,
                                      currentAppVersion: currentAppVersion)
    }
}
