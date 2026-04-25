import Foundation

/// XPC contract between the main app and the privileged helper.
///
/// The helper exposes a deliberately tiny verb set. Every parameter is validated
/// inside the helper against an allowlist — never trust the app to send sane paths.
///
/// All methods use a reply block (NSXPCConnection requirement); modeled here as
/// completion handlers. Higher-level Swift code in HelperBridge wraps these in
/// async/await.
@objc protocol HelperProtocol {

    /// Returns the helper's semantic version string.
    func version(reply: @escaping (String) -> Void)

    /// Move a list of system-owned files/directories to the user's Trash via fts(3) under root.
    /// The helper enforces an allowlist of acceptable path prefixes; anything else is rejected.
    func trashSystemPaths(_ paths: [String], reply: @escaping (UInt64, Error?) -> Void)

    /// Enumerate sizes for a list of system-owned paths the helper is allowed to read.
    func sizesForSystemPaths(_ paths: [String], reply: @escaping ([String: UInt64], Error?) -> Void)
}

enum HelperError: Int, Error {
    case pathNotAllowlisted = 1001
    case pathNotFound       = 1002
    case ioFailure          = 1003
    case clientNotAuthorized = 1004
}

/// Mach service name used by both the helper's NSXPCListener and the app's NSXPCConnection.
let helperMachServiceName = "com.privachat.maccleanerpro.helper"
