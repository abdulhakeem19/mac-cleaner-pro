import Foundation

/// Efficient worker pool for parallel file operations
/// Prevents resource exhaustion by limiting concurrent operations
public actor WorkerPool {

    private let maxWorkers: Int
    private var activeWorkers = 0
    private var pendingWork: [() async -> Void] = []

    public init(maxWorkers: Int = 4) {
        // Optimal for file I/O: CPU count for compute, but limit for I/O
        self.maxWorkers = min(maxWorkers, ProcessInfo.processInfo.activeProcessorCount)
    }

    /// Submit work to the pool. Returns immediately.
    /// Work is executed when a worker becomes available.
    public func submit(_ work: @escaping () async -> Void) async {
        if activeWorkers < maxWorkers {
            activeWorkers += 1
            Task {
                await work()
                await self.workerFinished()
            }
        } else {
            pendingWork.append(work)
        }
    }

    private func workerFinished() {
        activeWorkers -= 1

        // Start next pending work if any
        if !pendingWork.isEmpty {
            let work = pendingWork.removeFirst()
            activeWorkers += 1
            Task {
                await work()
                await self.workerFinished()
            }
        }
    }

    /// Wait for all work to complete
    public func drain() async {
        while activeWorkers > 0 || !pendingWork.isEmpty {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }

    /// Cancel all pending work (active work continues)
    public func cancelPending() {
        pendingWork.removeAll()
    }
}
