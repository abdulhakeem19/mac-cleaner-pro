import Foundation

/// One file the Large & Old Files scanner returned.
public struct FileEntry: Identifiable, Sendable, Hashable {
    public var id: URL { url }
    public let url: URL
    public let size: UInt64
    public let modifiedAt: Date?
    public let accessedAt: Date?
    public init(url: URL, size: UInt64, modifiedAt: Date?, accessedAt: Date?) {
        self.url = url; self.size = size
        self.modifiedAt = modifiedAt; self.accessedAt = accessedAt
    }
    public var fileExtension: String { url.pathExtension.lowercased() }
}

public struct LargeFileQuery: Sendable, Equatable {
    public var root: URL
    public var minSize: UInt64
    public var olderThanDays: Int?
    public init(root: URL, minSize: UInt64, olderThanDays: Int? = nil) {
        self.root = root; self.minSize = minSize; self.olderThanDays = olderThanDays
    }
}

/// Walks a user-selected directory tree producing a list of files larger than a
/// threshold, optionally older than N days. Built for responsiveness, not raw
/// throughput — it cooperatively yields between batches and honors cancellation.
///
/// Skips:
///   - Hidden files (`.skipsHiddenFiles`)
///   - Bundle internals (`.skipsPackageDescendants`) — the `.app` itself is sized whole
///   - Symlinks (avoid double-counting)
///   - APFS snapshot mounts and synthetic firmlinked system paths via path heuristics
public actor LargeFileScanner {

    public init() {}

    /// Run a query and return matches sorted by size descending.
    public func scan(_ query: LargeFileQuery) async -> [FileEntry] {
        let cutoff = query.olderThanDays.map { Date(timeIntervalSinceNow: -Double($0) * 86_400) }
        let keys: [URLResourceKey] = [
            .totalFileAllocatedSizeKey,
            .isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey, .isPackageKey,
            .contentModificationDateKey, .contentAccessDateKey,
        ]

        guard let enumerator = FileManager.default.enumerator(
            at: query.root,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        var out: [FileEntry] = []
        var batch = 0
        for case let url as URL in enumerator {
            if Task.isCancelled { return out.sorted { $0.size > $1.size } }
            batch &+= 1
            if batch & 0x3FF == 0 { await Task.yield() }

            if Self.shouldSkip(url) { continue }

            guard let values = try? url.resourceValues(forKeys: Set(keys)) else { continue }
            if values.isSymbolicLink == true { continue }

            // Treat .app/.bundle/.framework as a single unit.
            if values.isPackage == true {
                let size = (try? Self.directorySize(url)) ?? 0
                guard size >= query.minSize else { continue }
                let mtime = values.contentModificationDate
                if let cutoff, let mtime, mtime > cutoff { continue }
                out.append(FileEntry(url: url, size: size,
                                     modifiedAt: mtime,
                                     accessedAt: values.contentAccessDate))
                enumerator.skipDescendants()
                continue
            }

            guard values.isRegularFile == true else { continue }
            let size = UInt64(values.totalFileAllocatedSize ?? 0)
            guard size >= query.minSize else { continue }
            let mtime = values.contentModificationDate
            if let cutoff, let mtime, mtime > cutoff { continue }
            out.append(FileEntry(url: url, size: size,
                                 modifiedAt: mtime,
                                 accessedAt: values.contentAccessDate))
        }
        return out.sorted { $0.size > $1.size }
    }

    // MARK: - Helpers

    /// Path-prefix exclusions for noise we never want to surface.
    private static let blockedPrefixes: [String] = [
        "/System/",
        "/Volumes/com.apple.TimeMachine.localsnapshots",
        "/.MobileBackups",
        "/private/var/db",
    ]

    private static func shouldSkip(_ url: URL) -> Bool {
        let path = url.path
        return blockedPrefixes.contains { path.hasPrefix($0) }
    }

    static func directorySize(_ url: URL) throws -> UInt64 {
        let keys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey]
        var total: UInt64 = 0
        if let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        ) {
            for case let child as URL in enumerator {
                if let s = try? child.resourceValues(forKeys: keys).totalFileAllocatedSize {
                    total &+= UInt64(s)
                }
            }
        }
        return total
    }
}
