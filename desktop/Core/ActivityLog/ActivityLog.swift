import Foundation

/// One audit-trail entry surfaced in the Activity Log UI.
public struct ActivityEntry: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let timestamp: Date
    public let kind: Kind
    public let source: Source
    public let bytes: UInt64
    public let itemCount: Int
    public let tokenID: UUID?
    public let note: String?

    public enum Kind: String, Codable, Sendable { case clean, undo, empty, freed }
    public enum Source: String, Codable, Sendable {
        case smartScan, largeFiles, uninstaller, manual, system, memoryManager
    }

    public init(id: UUID = UUID(),
                timestamp: Date = Date(),
                kind: Kind,
                source: Source,
                bytes: UInt64,
                itemCount: Int,
                tokenID: UUID? = nil,
                note: String? = nil) {
        self.id = id; self.timestamp = timestamp; self.kind = kind
        self.source = source; self.bytes = bytes; self.itemCount = itemCount
        self.tokenID = tokenID; self.note = note
    }
}

/// Append-only persistent log of clean / undo / empty actions.
///
/// MVP uses a JSON file at `~/Library/Application Support/MacCleanerPro/activity.json`
/// — a few hundred entries per power user, well within JSON's comfort zone. The
/// plan's GRDB backing can swap in later by re-implementing this actor with the
/// same surface; views and call sites won't need to change.
public actor ActivityLog {

    public static let shared = ActivityLog()

    private var entries: [ActivityEntry] = []
    private var loaded = false

    private let fileURL: URL

    public init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let support = URL(fileURLWithPath: NSHomeDirectory())
                .appendingPathComponent("Library/Application Support/MacCleanerPro")
            self.fileURL = support.appendingPathComponent("activity.json")
        }
    }

    public func append(_ entry: ActivityEntry) async {
        await ensureLoaded()
        entries.append(entry)
        // Cap the on-disk log at 1000 entries — newest wins.
        if entries.count > 1000 {
            entries.removeFirst(entries.count - 1000)
        }
        persist()
    }

    public func all() async -> [ActivityEntry] {
        await ensureLoaded()
        return entries.sorted { $0.timestamp > $1.timestamp }
    }

    public func clear() async {
        entries.removeAll()
        loaded = true
        persist()
    }

    // MARK: - Persistence

    private func ensureLoaded() async {
        if loaded { return }
        loaded = true
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([ActivityEntry].self, from: data) {
            entries = decoded
        }
    }

    private func persist() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(entries)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Logging the log's own error to stderr is the right move — we can't
            // recursively log to ourselves and a missing audit entry is
            // recoverable, so we don't propagate.
            NSLog("[ActivityLog] persist failed: \(error)")
        }
    }
}
