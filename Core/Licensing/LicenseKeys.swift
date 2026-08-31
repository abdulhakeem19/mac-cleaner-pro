import Foundation

/// Ed25519 public key for license verification.
///
/// This public key corresponds to the private key used to sign license keys
/// on the server. It's embedded in the app binary and used to verify signatures offline.
///
/// **Security:** This is intentionally public - it cannot be used to forge licenses.
/// Only the private key (kept secret on the server) can sign valid licenses.
public enum LicenseKeys {
    /// Ed25519 public key in PEM format.
    /// Generated with the corresponding private key on the server.
    public static let publicKey = """
    -----BEGIN PUBLIC KEY-----
    MCowBQYDK2VwAyEAKnIyzginaZwN7MOyjuFZmVSo22t+Gep1+45wvY7xqlM=
    -----END PUBLIC KEY-----
    """
}
