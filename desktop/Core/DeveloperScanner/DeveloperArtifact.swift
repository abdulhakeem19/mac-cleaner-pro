import Foundation

/// One developer build/cache artifact found by ``DeveloperScanner``.
///
/// Unlike a generic large file, every artifact carries the *why* (`reason`) and
/// the *how to get it back* (`restoreCommand`) — the two pieces of context that
/// turn "a folder you're scared to delete" into "a folder you delete without
/// thinking". `safety` is derived from live filesystem state at scan time, not a
/// static list: if the creating toolchain can't be confirmed present, the item
/// is downgraded to `.reviewRecommended` regardless of the detector's default.
public struct DeveloperArtifact: Identifiable, Sendable, Hashable {
    public var id: URL { url }

    /// The artifact directory itself (e.g. `~/workspace/foo/node_modules`).
    public let url: URL
    /// Stable detector identifier, used for grouping/iconography (e.g. `node_modules`).
    public let kind: String
    /// Human label for the artifact type (e.g. "JS dependencies").
    public let displayName: String
    /// Name of the project the artifact belongs to — the parent directory's name.
    public let projectName: String
    /// Allocated size on disk, in bytes.
    public let size: UInt64
    /// Effective safety tier after sibling/toolchain confirmation.
    public let safety: RulePack.Safety
    /// One sentence the UI shows: *why* this is safe to remove.
    public let reason: String
    /// The exact command that regenerates it (e.g. `npm install`).
    public let restoreCommand: String
    /// Whether the creating toolchain was confirmed present (sibling manifest found).
    public let confirmed: Bool
    public let modifiedAt: Date?

    public init(url: URL,
                kind: String,
                displayName: String,
                projectName: String,
                size: UInt64,
                safety: RulePack.Safety,
                reason: String,
                restoreCommand: String,
                confirmed: Bool,
                modifiedAt: Date?) {
        self.url = url
        self.kind = kind
        self.displayName = displayName
        self.projectName = projectName
        self.size = size
        self.safety = safety
        self.reason = reason
        self.restoreCommand = restoreCommand
        self.confirmed = confirmed
        self.modifiedAt = modifiedAt
    }
}

/// Throttled progress emitted while a developer scan runs, so the UI can render a
/// live counter + the path currently being walked.
public struct DeveloperScanProgress: Sendable {
    public let scannedDirectories: Int
    public let foundCount: Int
    public let reclaimableBytes: UInt64
    public let currentPath: String

    public init(scannedDirectories: Int, foundCount: Int,
                reclaimableBytes: UInt64, currentPath: String) {
        self.scannedDirectories = scannedDirectories
        self.foundCount = foundCount
        self.reclaimableBytes = reclaimableBytes
        self.currentPath = currentPath
    }
}
