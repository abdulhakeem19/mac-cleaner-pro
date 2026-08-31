import Foundation

/// XPC contract between the main app and the privileged helper.
///
/// The helper exposes a deliberately tiny verb set. Every parameter is validated
/// inside the helper against an allowlist — never trust the app to send sane paths.
///
/// All methods use a reply block (NSXPCConnection requirement); higher-level
/// `HelperBridge` code wraps these in async/await.
@objc public protocol HelperProtocol {

    /// Returns the helper's semantic version string.
    func version(reply: @escaping (String) -> Void)

    /// Move a list of system-owned files/directories to the user's Trash, running as root.
    /// The helper enforces an allowlist of acceptable path prefixes; anything else is rejected.
    /// Reply: total bytes reclaimed, plus an optional error if any path failed.
    func trashSystemPaths(_ paths: [String], reply: @escaping (UInt64, Error?) -> Void)

    /// Compute on-disk sizes for a list of system-owned paths the helper is allowed to read.
    func sizesForSystemPaths(_ paths: [String], reply: @escaping ([String: UInt64], Error?) -> Void)
}

public enum HelperError: Int, Error {
    case pathNotAllowlisted = 1001
    case pathNotFound        = 1002
    case ioFailure           = 1003
    case clientNotAuthorized = 1004
    case connectionInvalid   = 1005
}

/// Mach service name used by both the helper's NSXPCListener and the app's NSXPCConnection.
public let helperMachServiceName = "com.maccleanerpro.helper"

/// Bundle identifier of the privileged helper executable, used to construct the
/// `SMAppService.daemon(plistName:)` lookup. Must match Launchd.plist `Label`.
public let helperBundleIdentifier = "com.maccleanerpro.helper"

/// Filename of the launchd plist embedded in the app's `Contents/Library/LaunchDaemons/`,
/// referenced by `SMAppService.daemon(plistName:)`.
public let helperLaunchdPlistName = "com.maccleanerpro.helper.plist"
