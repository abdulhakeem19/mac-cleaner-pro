import Foundation

/// Finds developer build/cache artifacts by *folder name at any depth* under a
/// set of code roots — the thing a glob-based rule pack can't do efficiently.
///
/// Why this beats `find ~ -name node_modules | xargs du`:
///   - **One pruned pass.** When a directory matches a detector we size it and
///     immediately `skipDescendants()` — we never recurse *into* a matched
///     `node_modules`, so a repo with nested workspaces is walked once, not once
///     per match.
///   - **In-process safety.** Sibling-manifest confirmation (`package.json` next
///     to `node_modules`) happens during the same walk, so each item's safety
///     reflects live filesystem state rather than a static assumption.
///   - **Cancellable + streamed.** Cooperative cancellation and throttled
///     progress feed the live UI; deletion routes through `DeletionService`
///     (trash + undo), never `rm -rf`.
///
/// Hidden directories are deliberately **not** skipped — half the artifacts we
/// care about are dotfolders (`.next`, `.gradle`, `.dart_tool`). VCS internals
/// (`.git`/`.hg`/`.svn`) and system trees are pruned explicitly instead.
public actor DeveloperScanner {

    public init() {}

    /// Home-relative directories commonly used to hold code. Only those that
    /// exist are returned; callers can also pass their own roots.
    public static func defaultRoots() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let candidates = [
            "Documents", "Desktop", "Developer", "Projects", "Project",
            "workspace", "Workspace", "code", "Code", "dev", "development",
            "src", "repos", "git", "GitHub",
        ]
        var seen = Set<String>()
        var roots: [URL] = []
        for name in candidates {
            let url = home.appendingPathComponent(name)
            let key = url.standardizedFileURL.path
            guard seen.insert(key).inserted, Self.isDirectory(url) else { continue }
            roots.append(url)
        }
        return roots
    }

    /// Scan `roots` (defaulting to ``defaultRoots()``) for known artifacts,
    /// sorted by size descending.
    public func scan(
        roots: [URL]? = nil,
        onProgress: (@Sendable (DeveloperScanProgress) -> Void)? = nil
    ) async -> [DeveloperArtifact] {
        let scanRoots = roots ?? Self.defaultRoots()
        var found: [DeveloperArtifact] = []
        var scanned = 0
        var reclaimable: UInt64 = 0

        for root in scanRoots {
            if Task.isCancelled { break }
            let result = await scanRoot(
                root,
                priorScanned: scanned,
                priorReclaimable: reclaimable,
                onProgress: onProgress
            )
            found.append(contentsOf: result.artifacts)
            scanned += result.scannedDirectories
            reclaimable &+= result.reclaimableBytes
        }

        onProgress?(DeveloperScanProgress(
            scannedDirectories: scanned,
            foundCount: found.count,
            reclaimableBytes: reclaimable,
            currentPath: ""))
        return found.sorted { $0.size > $1.size }
    }

    // MARK: - Walk

    private struct RootResult {
        var artifacts: [DeveloperArtifact] = []
        var scannedDirectories = 0
        var reclaimableBytes: UInt64 = 0
    }

    /// Walks one root, returning everything it found. `prior*` are the running
    /// totals from earlier roots, used only to make the streamed progress
    /// figures continuous across roots.
    private func scanRoot(
        _ root: URL,
        priorScanned: Int,
        priorReclaimable: UInt64,
        onProgress: (@Sendable (DeveloperScanProgress) -> Void)?
    ) async -> RootResult {
        var result = RootResult()
        let keys: [URLResourceKey] = [
            .isDirectoryKey, .isSymbolicLinkKey, .contentModificationDateKey,
        ]
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: keys,
            options: [.skipsPackageDescendants]   // treat .app/.framework as opaque
        ) else { return result }

        var batch = 0
        var lastEmit = Date.distantPast
        for case let url as URL in enumerator {
            if Task.isCancelled { return result }
            batch &+= 1
            if batch & 0x3FF == 0 { await Task.yield() }

            let values = try? url.resourceValues(forKeys: Set(keys))
            guard values?.isDirectory == true else { continue }
            if values?.isSymbolicLink == true { enumerator.skipDescendants(); continue }

            let name = url.lastPathComponent

            // Never walk into version-control internals or system trees.
            if Self.isPrunedDirectory(name) || Self.isBlocked(url) {
                enumerator.skipDescendants()
                continue
            }

            result.scannedDirectories &+= 1
            emitThrottled(
                scanned: priorScanned + result.scannedDirectories,
                found: result.artifacts.count,
                reclaimable: priorReclaimable &+ result.reclaimableBytes,
                path: url.path, lastEmit: &lastEmit, onProgress: onProgress)

            guard let detector = DeveloperDetectors.match(folderName: name) else { continue }

            // Match: size it, confirm the toolchain, record it, and prune.
            let size = (try? LargeFileScanner.directorySize(url)) ?? 0
            let parent = url.deletingLastPathComponent()
            let confirmed = detector.confirms(in: parent)
            let safety: RulePack.Safety = confirmed ? detector.safety : .reviewRecommended
            let reason = confirmed
                ? detector.reason
                : detector.reason + " (couldn't confirm the build tool nearby — review before removing.)"

            result.artifacts.append(DeveloperArtifact(
                url: url,
                kind: detector.folderName,
                displayName: detector.displayName,
                projectName: parent.lastPathComponent,
                size: size,
                safety: safety,
                reason: reason,
                restoreCommand: detector.restoreCommand,
                confirmed: confirmed,
                modifiedAt: values?.contentModificationDate))
            result.reclaimableBytes &+= size

            enumerator.skipDescendants()
        }
        return result
    }

    // MARK: - Pruning helpers

    private func emitThrottled(
        scanned: Int, found: Int, reclaimable: UInt64, path: String,
        lastEmit: inout Date,
        onProgress: (@Sendable (DeveloperScanProgress) -> Void)?
    ) {
        guard let onProgress else { return }
        let now = Date()
        guard now.timeIntervalSince(lastEmit) >= 0.10 else { return }
        lastEmit = now
        onProgress(DeveloperScanProgress(
            scannedDirectories: scanned, foundCount: found,
            reclaimableBytes: reclaimable, currentPath: path))
    }

    /// Directory names we should never descend into (and never match).
    private static func isPrunedDirectory(_ name: String) -> Bool {
        name == ".git" || name == ".hg" || name == ".svn" || name == ".Trash"
    }

    /// System / app-bundle prefixes that should never appear in a developer
    /// scan even if a user points a root at them. We intentionally do *not*
    /// block `/private` — on macOS that's where `/var`, `/tmp`, and per-user
    /// temp dirs resolve, none of which are system trees worth excluding.
    private static let blockedPrefixes: [String] = [
        "/System/", "/Library/", "/Applications/",
    ]

    private static func isBlocked(_ url: URL) -> Bool {
        let path = url.path
        // A user's own ~/Library should also be off-limits for this scanner.
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home + "/Library/") { return true }
        return blockedPrefixes.contains { path.hasPrefix($0) }
    }

    private static func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }
}
