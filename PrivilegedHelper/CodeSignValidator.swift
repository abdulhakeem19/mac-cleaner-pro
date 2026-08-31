import Foundation
import Security

/// Validates that an incoming XPC connection comes from a process whose code
/// signature satisfies our pinned requirement. SMAuthorizedClients in Info.plist
/// is the primary gate enforced by launchd; this is defense in depth.
enum CodeSignValidator {

    /// Apple-form requirement string for the main app. Update with the real Team ID
    /// once code-signing is wired with a Developer ID certificate.
    private static let appRequirementString =
        "anchor apple generic " +
        "and identifier \"com.maccleanerpro\" " +
        "and certificate leaf[subject.OU] = \"REPLACE_TEAM_ID\""

    static func connectionMatchesAppRequirement(_ connection: NSXPCConnection) -> Bool {
        // Build the SecRequirement from the string.
        var requirement: SecRequirement?
        let compileStatus = SecRequirementCreateWithString(appRequirementString as CFString,
                                                           [], &requirement)
        guard compileStatus == errSecSuccess, let requirement else { return false }

        // Get the audit token of the peer process and validate it.
        let auditToken = connection.auditToken
        let tokenData = withUnsafeBytes(of: auditToken) { Data($0) }

        let attributes: [String: Any] = [
            kSecGuestAttributeAudit as String: tokenData
        ]

        var code: SecCode?
        let copyStatus = SecCodeCopyGuestWithAttributes(nil, attributes as CFDictionary, [], &code)
        guard copyStatus == errSecSuccess, let code else { return false }

        let validateStatus = SecCodeCheckValidity(code, [], requirement)
        return validateStatus == errSecSuccess
    }
}

private extension NSXPCConnection {
    /// `auditToken` is private API surface but stable since macOS 10.7.
    /// Read it via KVC to avoid deprecation warnings on the public symbol.
    var auditToken: audit_token_t {
        let selector = NSSelectorFromString("auditToken")
        if responds(to: selector) {
            let value = (self as AnyObject).value(forKey: "auditToken") as? NSValue
            var token = audit_token_t()
            value?.getValue(&token, size: MemoryLayout<audit_token_t>.size)
            return token
        }
        return audit_token_t()
    }
}
