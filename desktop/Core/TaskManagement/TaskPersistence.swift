import Foundation

/// Persists task state so scans can resume after app quit/restart
public actor TaskPersistence {

    public static let shared = TaskPersistence()

    private let fileURL: URL

    public struct TaskState: Codable, Sendable {
        public let id: UUID
        public let type: TaskType
        public let started: Date
        public let progress: Progress
        public let status: Status

        public init(id: UUID, type: TaskType, started: Date, progress: Progress, status: Status) {
            self.id = id
            self.type = type
            self.started = started
            self.progress = progress
            self.status = status
        }

        public enum TaskType: String, Codable, Sendable {
            case spaceLens
            case largeFiles
            case smartScan
        }

        public enum Status: String, Codable, Sendable {
            case running
            case paused
            case completed
            case cancelled
        }

        public struct Progress: Codable, Sendable {
            public let current: UInt64
            public let total: UInt64?
            public let itemsScanned: Int
            public let currentPath: String

            public init(current: UInt64, total: UInt64?, itemsScanned: Int, currentPath: String) {
                self.current = current
                self.total = total
                self.itemsScanned = itemsScanned
                self.currentPath = currentPath
            }
        }
    }

    private init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("MacCleanerPro")

        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        fileURL = appSupport.appendingPathComponent("task_state.json")
    }

    // MARK: - Public API

    public func save(_ state: TaskState) async {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save task state: \(error)")
        }
    }

    public func load() async -> TaskState? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(TaskState.self, from: data)
        } catch {
            print("Failed to load task state: \(error)")
            return nil
        }
    }

    public func clear() async {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
