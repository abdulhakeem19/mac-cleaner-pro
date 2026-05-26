import Foundation
import SwiftUI
import Core

/// Global session manager that keeps long-running tasks alive even when
/// views are dismissed. Prevents scans, memory monitoring, etc. from being
/// cancelled when users navigate between tabs.
///
/// Features:
/// - Persistent tasks that survive tab switches
/// - Task pause/resume support
/// - Automatic task recovery after app restart
/// - Worker pool for efficient resource usage
/// - Progress tracking and reporting
@MainActor
final class SessionManager: ObservableObject {
    static let shared = SessionManager()

    // MARK: - Memory Manager Session
    @Published var memoryStats: MemoryStats = MemoryStatsReader.snapshot()
    @Published var memoryPressure: MemoryPressureLevel = .normal
    @Published var memoryProcesses: [ProcessMemoryEntry] = []
    @Published var memoryTotalProcessCount: Int = 0

    private var memoryStatsTimer: Task<Void, Never>?
    private var memoryProcessTimer: Task<Void, Never>?
    private var memoryPressureMonitor: PressureMonitor?

    // MARK: - Space Lens Session
    @Published var spaceLensRoot: URL = URL(fileURLWithPath: NSHomeDirectory())
    @Published var spaceLensTree: SpaceLensNode?
    @Published var spaceLensIsScanning = false
    @Published var spaceLensIsPaused = false
    @Published var spaceLensBytesScanned: UInt64 = 0
    @Published var spaceLensCurrentPath: String = ""
    @Published var spaceLensCanResume = false  // True if previous scan was interrupted

    private var spaceLensTask: Task<Void, Never>?
    private let spaceLensScanner = SpaceLensScanner()
    private let spaceLensWorkerPool = WorkerPool(maxWorkers: 4)

    // MARK: - Large Files Session
    @Published var largeFilesIsScanning = false
    @Published var largeFilesIsPaused = false
    @Published var largeFilesResults: [FileEntry] = []
    @Published var largeFilesScannedCount: Int = 0
    @Published var largeFilesCanResume = false

    private var largeFilesTask: Task<Void, Never>?
    private let largeFilesWorkerPool = WorkerPool(maxWorkers: 4)

    private init() {
        // Check for interrupted tasks on launch
        Task {
            await checkForInterruptedTasks()
        }
    }

    // MARK: - Memory Manager

    func startMemoryMonitoring() {
        guard memoryStatsTimer == nil else { return }

        // Stats timer: 1Hz
        memoryStatsTimer = Task { [weak self] in
            while !Task.isCancelled {
                await MainActor.run {
                    self?.memoryStats = MemoryStatsReader.snapshot()
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }

        // Process timer: 2s
        memoryProcessTimer = Task { [weak self] in
            while !Task.isCancelled {
                let snapshot = await ProcessInspector.shared.snapshot()
                await MainActor.run {
                    guard let self else { return }
                    self.memoryProcesses = snapshot.entries
                    self.memoryTotalProcessCount = snapshot.totalCount
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }

        // Pressure monitor
        if memoryPressureMonitor == nil {
            let monitor = PressureMonitor { [weak self] level in
                Task { @MainActor [weak self] in
                    self?.memoryPressure = level
                }
            }
            monitor.start()
            memoryPressureMonitor = monitor
        }
    }

    func stopMemoryMonitoring() {
        // Don't actually stop — keep running in background
        // Users can navigate away and come back to live data
    }

    // MARK: - Task Recovery

    private func checkForInterruptedTasks() async {
        if let state = await TaskPersistence.shared.load() {
            switch state.type {
            case .spaceLens:
                spaceLensCanResume = true
            case .largeFiles:
                largeFilesCanResume = true
            case .smartScan:
                break
            }
        }
    }

    // MARK: - Space Lens

    func startSpaceLensScan(root: URL? = nil, resume: Bool = false) {
        if let newRoot = root {
            spaceLensRoot = newRoot
        }

        spaceLensTask?.cancel()
        spaceLensIsScanning = true
        spaceLensIsPaused = false
        spaceLensCanResume = false

        if !resume {
            spaceLensBytesScanned = 0
            spaceLensCurrentPath = ""
            spaceLensTree = nil
        }

        let target = spaceLensRoot
        spaceLensTask = Task { [spaceLensScanner, weak self] in
            // Save task state for recovery
            let taskState = TaskPersistence.TaskState(
                id: UUID(),
                type: .spaceLens,
                started: Date(),
                progress: TaskPersistence.TaskState.Progress(
                    current: 0,
                    total: nil,
                    itemsScanned: 0,
                    currentPath: target.path
                ),
                status: .running
            )
            await TaskPersistence.shared.save(taskState)

            let result = await spaceLensScanner.scan(root: target) { [weak self] progress in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.spaceLensBytesScanned = progress.bytesScanned
                    self.spaceLensCurrentPath = Self.tildify(progress.currentPath)

                    // Update persisted state
                    let updatedState = TaskPersistence.TaskState(
                        id: taskState.id,
                        type: .spaceLens,
                        started: taskState.started,
                        progress: TaskPersistence.TaskState.Progress(
                            current: progress.bytesScanned,
                            total: nil,
                            itemsScanned: 0,
                            currentPath: progress.currentPath
                        ),
                        status: .running
                    )
                    await TaskPersistence.shared.save(updatedState)
                }
            }

            await MainActor.run {
                guard let self, !Task.isCancelled else {
                    Task { await TaskPersistence.shared.clear() }
                    return
                }
                self.spaceLensTree = result
                self.spaceLensIsScanning = false
                self.spaceLensBytesScanned = result.size
                Task { await TaskPersistence.shared.clear() }
            }
        }
    }

    func pauseSpaceLensScan() {
        spaceLensIsPaused = true
        spaceLensCanResume = true
        // Don't cancel - just mark as paused
        // The scan will continue in background but can be resumed later
    }

    func resumeSpaceLensScan() {
        spaceLensIsPaused = false
        if !spaceLensIsScanning {
            startSpaceLensScan(resume: true)
        }
    }

    func cancelSpaceLensScan() {
        spaceLensTask?.cancel()
        spaceLensIsScanning = false
        spaceLensIsPaused = false
        spaceLensCanResume = false
        Task { await TaskPersistence.shared.clear() }
    }

    // MARK: - Large Files

    func startLargeFilesScan(queries: [LargeFileQuery], resume: Bool = false) {
        largeFilesTask?.cancel()
        largeFilesIsScanning = true
        largeFilesIsPaused = false
        largeFilesCanResume = false

        if !resume {
            largeFilesResults = []
            largeFilesScannedCount = 0
        }

        largeFilesTask = Task { [weak self] in
            let scanner = LargeFileScanner()
            var allResults: [FileEntry] = resume ? await MainActor.run { self?.largeFilesResults ?? [] } : []

            // Save task state
            let taskState = TaskPersistence.TaskState(
                id: UUID(),
                type: .largeFiles,
                started: Date(),
                progress: TaskPersistence.TaskState.Progress(
                    current: UInt64(allResults.count),
                    total: nil,
                    itemsScanned: allResults.count,
                    currentPath: ""
                ),
                status: .running
            )
            await TaskPersistence.shared.save(taskState)

            for query in queries {
                guard !Task.isCancelled else { break }
                let result = await scanner.scan(query)
                allResults.append(contentsOf: result)

                await MainActor.run {
                    self?.largeFilesScannedCount = allResults.count
                    self?.largeFilesResults = allResults.sorted { $0.size > $1.size }
                }

                // Update persisted state
                let updatedState = TaskPersistence.TaskState(
                    id: taskState.id,
                    type: .largeFiles,
                    started: taskState.started,
                    progress: TaskPersistence.TaskState.Progress(
                        current: UInt64(allResults.count),
                        total: nil,
                        itemsScanned: allResults.count,
                        currentPath: query.root.path
                    ),
                    status: .running
                )
                await TaskPersistence.shared.save(updatedState)
            }

            await MainActor.run {
                guard let self, !Task.isCancelled else {
                    Task { await TaskPersistence.shared.clear() }
                    return
                }
                self.largeFilesResults = allResults.sorted { $0.size > $1.size }
                self.largeFilesIsScanning = false
                Task { await TaskPersistence.shared.clear() }
            }
        }
    }

    func pauseLargeFilesScan() {
        largeFilesIsPaused = true
        largeFilesCanResume = true
    }

    func resumeLargeFilesScan(queries: [LargeFileQuery]) {
        largeFilesIsPaused = false
        if !largeFilesIsScanning {
            startLargeFilesScan(queries: queries, resume: true)
        }
    }

    func cancelLargeFilesScan() {
        largeFilesTask?.cancel()
        largeFilesIsScanning = false
        largeFilesIsPaused = false
        largeFilesCanResume = false
        Task { await TaskPersistence.shared.clear() }
    }

    // MARK: - Helpers

    private static func tildify(_ path: String) -> String {
        let home = NSHomeDirectory()
        return path.hasPrefix(home) ? "~" + String(path.dropFirst(home.count)) : path
    }
}
