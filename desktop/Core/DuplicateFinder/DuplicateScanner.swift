import Foundation
import CryptoKit

/// One file inside a duplicate group.
public struct DuplicateFile: Identifiable, Sendable, Hashable {
    public var id: URL { url }
    public let url: URL
    public let size: UInt64
    public let modifiedAt: Date?

    public init(url: URL, size: UInt64, modifiedAt: Date?) {
        self.url = url; self.size = size; self.modifiedAt = modifiedAt
    }
}

/// A set of files with byte-for-byte identical content.
/// `files` is sorted newest-first: `files[0]` is the suggested keeper.
public struct DuplicateGroup: Identifiable, Sendable {
    public let id: String               // SHA-256 hex digest
    public let files: [DuplicateFile]   // count >= 2, newest first

    public var fileSize: UInt64 { files.first?.size ?? 0 }
    public var wastedBytes: UInt64 { fileSize * UInt64(files.count - 1) }

    public init(id: String, files: [DuplicateFile]) {
        self.id = id; self.files = files
    }
}

/// Finds duplicate files using a two-pass strategy:
///   1. Walk the tree and group file paths by allocated size (fast — metadata only).
///   2. SHA-256 hash only files that share a size with at least one other file.
///
/// This avoids hashing unique-size files, which are the vast majority of any
/// real directory tree. Streaming hashing (64 KB chunks) keeps peak memory flat
/// regardless of file size.
public actor DuplicateScanner {
    public private(set) var filesExamined: Int = 0
    public private(set) var filesHashed: Int = 0

    public init() {}

    /// Directory names pruned during the walk. These hold machine-generated or
    /// system-managed files that aren't the user's own duplicated documents, and
    /// they make up the bulk of a naive home-folder scan.
    static let prunedDirectoryNames: Set<String> = [
        "Library",          // caches, app support, containers — huge and irrelevant
        "node_modules", ".git", ".svn", ".hg",
        "Pods", ".gradle", ".cocoapods", "DerivedData",
        ".Trash", ".cache", "Caches",
    ]

    public func scan(root: URL, minSize: UInt64 = 1_048_576) async -> [DuplicateGroup] {
        filesExamined = 0
        filesHashed = 0

        // ── Pass 1: group file paths by size ─────────────────────────────────
        var bySize: [UInt64: [(url: URL, modifiedAt: Date?, allocSize: UInt64)]] = [:]

        let keys: [URLResourceKey] = [
            .isRegularFileKey, .isSymbolicLinkKey, .isDirectoryKey,
            .fileSizeKey,               // logical content size — used for minSize filter + grouping
            .totalFileAllocatedSizeKey, // disk allocation — stored in DuplicateFile.size for display
            .contentModificationDateKey,
        ]

        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        // Stream the tree one entry at a time instead of `enumerator.allObjects`,
        // which blocks until the *entire* tree is materialized and ignores
        // cancellation for its whole duration. Streaming lets us check
        // `Task.isCancelled` between entries (so Cancel is responsive) and prune
        // heavy, never-relevant subtrees before descending into them.
        let keySet = Set(keys)
        while let url = enumerator.nextObject() as? URL {
            if Task.isCancelled { return [] }
            filesExamined &+= 1
            if filesExamined & 0x3FF == 0 { await Task.yield() }

            guard let vals = try? url.resourceValues(forKeys: keySet) else { continue }

            // Prune noise directories (caches, VCS, dependency trees, app
            // support) — they hold machine-generated files, not the user's
            // duplicated documents, and dominate a home-folder walk.
            if vals.isDirectory == true {
                if Self.prunedDirectoryNames.contains(url.lastPathComponent) {
                    enumerator.skipDescendants()
                }
                continue
            }

            guard vals.isRegularFile == true, vals.isSymbolicLink != true else { continue }
            let logicalSize = UInt64(vals.fileSize ?? 0)
            guard logicalSize >= minSize else { continue }
            let allocSize = UInt64(vals.totalFileAllocatedSize ?? Int(logicalSize))

            bySize[logicalSize, default: []].append((url, vals.contentModificationDate, allocSize))
        }

        // ── Pass 2: hash size-matched candidates ─────────────────────────────
        var byHash: [String: [DuplicateFile]] = [:]

        for (_, candidates) in bySize {
            if Task.isCancelled { return [] }
            guard candidates.count >= 2 else { continue }

            for (url, modifiedAt, allocSize) in candidates {
                if Task.isCancelled { return [] }
                guard let digest = try? hashFile(url) else { continue }
                filesHashed &+= 1
                await Task.yield()
                byHash[digest, default: []].append(
                    DuplicateFile(url: url, size: allocSize, modifiedAt: modifiedAt)
                )
            }
        }

        // ── Build result: groups with 2+ files, sorted by wasted bytes desc ──
        return byHash
            .map { hash, files -> DuplicateGroup in
                let sorted = files.sorted {
                    ($0.modifiedAt ?? .distantPast) > ($1.modifiedAt ?? .distantPast)
                }
                return DuplicateGroup(id: hash, files: sorted)
            }
            .filter { $0.files.count >= 2 }
            .sorted { $0.wastedBytes > $1.wastedBytes }
    }

    // MARK: - Private

    private func hashFile(_ url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        let chunkSize = 65_536
        while true {
            let chunk = handle.readData(ofLength: chunkSize)
            if chunk.isEmpty { break }
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
