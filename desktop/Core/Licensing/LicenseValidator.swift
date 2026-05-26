import Foundation
import CryptoKit

/// License validation result
public enum LicenseValidationResult: Equatable {
    case valid(LicensePayload)
    case invalid(LicenseValidationError)
}

/// License validation errors
public enum LicenseValidationError: Error, Equatable, LocalizedError {
    case invalidFormat
    case invalidSignature
    case invalidPayload
    case expiredLicense
    case invalidPlan

    public var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid license key format"
        case .invalidSignature:
            return "License signature verification failed"
        case .invalidPayload:
            return "License payload is corrupted"
        case .expiredLicense:
            return "License has expired"
        case .invalidPlan:
            return "Invalid license plan"
        }
    }
}

/// Parsed license payload
public struct LicensePayload: Equatable, Codable {
    public let email: String
    public let plan: LicensePlan
    public let purchaseDate: Date
    public let machineLimit: Int

    public enum LicensePlan: String, Codable {
        case pro
        case family

        public var displayName: String {
            switch self {
            case .pro: return "Pro"
            case .family: return "Family"
            }
        }

        public var machineLimit: Int {
            switch self {
            case .pro: return 1
            case .family: return 5
            }
        }
    }
}

/// Ed25519-based license validator
public struct LicenseValidator {

    // MARK: - Public Methods

    /// Validate a license key and return the payload if valid
    public static func validate(_ licenseKey: String) -> LicenseValidationResult {
        // Step 1: Check structural format
        guard licenseKey.hasPrefix("MCP-") else {
            return .invalid(.invalidFormat)
        }

        let keyBody = String(licenseKey.dropFirst(4))
        let parts = keyBody.components(separatedBy: ".")
        guard parts.count == 2 else {
            return .invalid(.invalidFormat)
        }

        let payloadBase64 = parts[0]
        let signatureBase64 = parts[1]

        // Step 2: Decode payload
        guard let payloadData = base64urlDecode(payloadBase64) else {
            return .invalid(.invalidFormat)
        }

        guard let payloadString = String(data: payloadData, encoding: .utf8) else {
            return .invalid(.invalidPayload)
        }

        // Step 3: Parse payload
        guard let payload = parsePayload(payloadString) else {
            return .invalid(.invalidPayload)
        }

        // Step 4: Verify signature
        guard let signatureData = base64urlDecode(signatureBase64) else {
            return .invalid(.invalidFormat)
        }

        guard verifySignature(
            payload: payloadData,
            signature: signatureData,
            publicKey: LicenseKeys.publicKey
        ) else {
            return .invalid(.invalidSignature)
        }

        // All checks passed
        return .valid(payload)
    }

    // MARK: - Private Methods

    /// Base64url decode (URL-safe base64 without padding)
    private static func base64urlDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        return Data(base64Encoded: base64)
    }

    /// Parse payload string into structured data
    /// Format: email|plan|purchaseDate|machineLimit
    private static func parsePayload(_ payloadString: String) -> LicensePayload? {
        let components = payloadString.components(separatedBy: "|")
        guard components.count == 4 else { return nil }

        let email = components[0]
        guard !email.isEmpty else { return nil }

        guard let plan = LicensePayload.LicensePlan(rawValue: components[1]) else {
            return nil
        }

        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let purchaseDate = iso8601Formatter.date(from: components[2]) else {
            return nil
        }

        guard let machineLimit = Int(components[3]), machineLimit > 0 else {
            return nil
        }

        return LicensePayload(
            email: email,
            plan: plan,
            purchaseDate: purchaseDate,
            machineLimit: machineLimit
        )
    }

    /// Verify Ed25519 signature using CryptoKit
    private static func verifySignature(
        payload: Data,
        signature: Data,
        publicKey: String
    ) -> Bool {
        do {
            // Parse PEM public key
            let pemLines = publicKey
                .components(separatedBy: .newlines)
                .filter { !$0.contains("PUBLIC KEY") && !$0.isEmpty }
                .joined()

            guard let keyData = Data(base64Encoded: pemLines) else {
                return false
            }

            // Extract the raw 32-byte Ed25519 public key from the DER-encoded structure
            // DER format: 30 2a 30 05 06 03 2b 65 70 03 21 00 [32 bytes of actual key]
            // We need to skip the first 12 bytes of DER overhead
            guard keyData.count == 44 else { // 12 bytes overhead + 32 bytes key
                return false
            }

            let rawKeyData = keyData.suffix(32)

            // Create Curve25519 public key
            let curve25519Key = try Curve25519.Signing.PublicKey(rawRepresentation: rawKeyData)

            // Verify signature
            return curve25519Key.isValidSignature(signature, for: payload)
        } catch {
            return false
        }
    }
}
