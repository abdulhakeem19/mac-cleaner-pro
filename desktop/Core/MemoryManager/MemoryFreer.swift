import Foundation
import Darwin

/// Orchestrates RAM-reclamation actions in $0-mode (no privileged helper).
///
/// Two strategies, used together by `quickFree`:
///
/// 1. **Soft purge** — allocate-and-release pressure trick. We `malloc` a
///    bounded amount of RAM in 64 MB chunks, touch one byte per page so the
///    kernel actually faults the pages in, then `free()`. This forces the
///    kernel to evict purgeable / cached / inactive pages and compress
///    anonymous pages it would otherwise keep resident.
///
/// 2. **Process termination** — `SIGTERM` (then optional `SIGKILL`) for a list
///    of PIDs the user explicitly selected. Always user-confirmed at the UI
///    layer; this actor doesn't decide who to kill.
///
/// **Swap-aware safety:** when swap is already heavily in use (the regime that
/// causes user-visible hangs), allocating more anonymous pages would push real
/// working-set memory further into swap and make things worse. In that state
/// we *skip* soft-purge and tell the caller the only honest action is to quit
/// memory-hog processes. This is the difference between a marketing-mode
/// cleaner that always claims to "free" memory and one that does no harm.
///
/// The real `/usr/sbin/purge` binary requires root and is intentionally
/// deferred to the paid-signing release, when the privileged helper gains a
/// `runPurge` XPC method.
public actor MemoryFreer {

    public static let shared = MemoryFreer()

    /// Hard ceiling on the soft-purge allocation.
    public static let maxSoftPurgeBytes: UInt64 = 2 * 1024 * 1024 * 1024  // 2 GB

    /// If swap usage is at or above this fraction of total RAM, soft-purge is
    /// skipped — adding more anonymous pages in that regime worsens thrash.
    public static let swapSkipThreshold: Double = 0.25  // 25% of RAM

    /// If `available` (free + cached + inactive headroom) drops below this
    /// fraction of total RAM, we also skip — the kernel has nothing slack to
    /// give us anyway.
    public static let availableFloor: Double = 0.05  // 5% of RAM

    public init() {}

    // MARK: - Public actions

    /// Runs the soft-purge strategy and returns honest before/after deltas.
    /// On memory-tight + heavy-swap systems, returns a result with
    /// `skippedReason` set rather than allocating more pages.
    public func quickFree() async -> FreeResult {
        let start = Date()
        let before = MemoryStatsReader.snapshot()

        if let reason = swapSkipReason(stats: before) {
            return FreeResult(
                strategy: "soft-purge (skipped)",
                beforeStats: before,
                afterStats: before,
                processesTerminated: 0,
                elapsed: Date().timeIntervalSince(start),
                skippedReason: reason
            )
        }

        let target = softPurgeTarget(stats: before)
        await runSoftPurge(targetBytes: target)

        // Let the kernel finish bookkeeping before measuring.
        try? await Task.sleep(nanoseconds: 600_000_000)
        let after = MemoryStatsReader.snapshot()

        return FreeResult(
            strategy: "soft-purge",
            beforeStats: before,
            afterStats: after,
            processesTerminated: 0,
            elapsed: Date().timeIntervalSince(start)
        )
    }

    /// Sends `SIGTERM` (or `SIGKILL` if `force`) to each pid. Returns the count
    /// successfully signaled.
    public func terminate(pids: [pid_t], force: Bool = false) -> Int {
        let signal: Int32 = force ? SIGKILL : SIGTERM
        var ok = 0
        for pid in pids where pid > 0 {
            if kill(pid, signal) == 0 { ok += 1 }
        }
        return ok
    }

    /// Quit selected processes, then conditionally run soft-purge to reclaim
    /// what those processes left behind. Soft-purge is skipped under the same
    /// swap/available rules as `quickFree`.
    public func quitAndFree(pids: [pid_t], force: Bool = false) async -> FreeResult {
        let start = Date()
        let before = MemoryStatsReader.snapshot()
        let killed = terminate(pids: pids, force: force)

        // Give terminated processes a beat to release their memory.
        try? await Task.sleep(nanoseconds: 800_000_000)

        let basis = MemoryStatsReader.snapshot()
        var skipped: String?
        if let reason = swapSkipReason(stats: basis) {
            skipped = reason
        } else {
            await runSoftPurge(targetBytes: softPurgeTarget(stats: basis))
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        let after = MemoryStatsReader.snapshot()
        let label = force ? "force-quit" : "quit"
        let strategy = skipped == nil ? "\(label) + soft-purge" : "\(label) only"

        return FreeResult(
            strategy: strategy,
            beforeStats: before,
            afterStats: after,
            processesTerminated: killed,
            elapsed: Date().timeIntervalSince(start),
            skippedReason: skipped
        )
    }

    // MARK: - Strategy helpers (internal but exposed for tests)

    /// Returns a non-nil reason string when soft-purge should be skipped.
    internal func swapSkipReason(stats: MemoryStats) -> String? {
        guard stats.totalBytes > 0 else { return "no memory stats" }
        let swapFrac = Double(stats.swapUsedBytes) / Double(stats.totalBytes)
        if swapFrac >= Self.swapSkipThreshold {
            return "swap is \(Int(swapFrac * 100))% of RAM — quitting apps will help, allocating more memory will not"
        }
        let basis = stats.freeBytes &+ stats.purgeableBytes &+ stats.inactiveBytes
        let basisFrac = Double(basis) / Double(stats.totalBytes)
        if basisFrac < Self.availableFloor {
            return "system already memory-tight — quit a memory-hungry app instead"
        }
        return nil
    }

    /// Bytes to allocate for the soft-purge pressure trick. Bounded by the
    /// hard ceiling and by half of "discardable" memory (free + purgeable +
    /// inactive) so we never push working set into swap.
    internal func softPurgeTarget(stats: MemoryStats) -> UInt64 {
        let basis = stats.freeBytes &+ stats.purgeableBytes &+ stats.inactiveBytes
        return min(Self.maxSoftPurgeBytes, basis / 2)
    }

    // MARK: - Soft purge implementation

    private func runSoftPurge(targetBytes: UInt64) async {
        let chunkSize = 64 * 1024 * 1024  // 64 MB
        let totalChunks = Int(min(targetBytes / UInt64(chunkSize), 64))
        guard totalChunks > 0 else { return }

        let pageSize = Int(getpagesize())
        var pointers: [UnsafeMutableRawPointer] = []
        pointers.reserveCapacity(totalChunks)

        for i in 0..<totalChunks {
            guard let p = malloc(chunkSize) else { break }
            // Touch one byte per page so the kernel actually maps the pages.
            // Without this, malloc just hands us virtual addresses and the
            // pressure trick does nothing.
            var off = 0
            while off < chunkSize {
                p.advanced(by: off).assumingMemoryBound(to: UInt8.self).pointee = 0xAA
                off += pageSize
            }
            pointers.append(p)
            if i % 4 == 3 { await Task.yield() }
        }

        for p in pointers { free(p) }
    }
}
