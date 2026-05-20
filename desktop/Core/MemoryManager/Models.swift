import Foundation

public enum MemoryPressureLevel: Int, Sendable, Codable, Comparable {
    case normal = 0, warning = 1, critical = 2
    public static func < (lhs: MemoryPressureLevel, rhs: MemoryPressureLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    public var label: String {
        switch self {
        case .normal:   return "Normal"
        case .warning:  return "Warning"
        case .critical: return "Critical"
        }
    }
}

/// A single sampling of system-wide memory state, modeled after Activity Monitor.
/// All values are bytes unless noted.
public struct MemoryStats: Sendable, Equatable {
    public let totalBytes: UInt64
    public let activeBytes: UInt64
    public let inactiveBytes: UInt64
    public let wiredBytes: UInt64
    public let compressedBytes: UInt64
    public let speculativeBytes: UInt64
    public let purgeableBytes: UInt64
    public let freeBytes: UInt64
    /// File-backed pages (caches that can be discarded without paging).
    public let externalBytes: UInt64
    /// App / anonymous pages (must be compressed or paged out to reclaim).
    public let internalBytes: UInt64
    public let swapUsedBytes: UInt64
    public let swapTotalBytes: UInt64
    public let pageSize: UInt64
    public let timestamp: Date

    public init(totalBytes: UInt64, activeBytes: UInt64, inactiveBytes: UInt64,
                wiredBytes: UInt64, compressedBytes: UInt64, speculativeBytes: UInt64,
                purgeableBytes: UInt64, freeBytes: UInt64, externalBytes: UInt64,
                internalBytes: UInt64, swapUsedBytes: UInt64, swapTotalBytes: UInt64,
                pageSize: UInt64, timestamp: Date = Date()) {
        self.totalBytes = totalBytes
        self.activeBytes = activeBytes
        self.inactiveBytes = inactiveBytes
        self.wiredBytes = wiredBytes
        self.compressedBytes = compressedBytes
        self.speculativeBytes = speculativeBytes
        self.purgeableBytes = purgeableBytes
        self.freeBytes = freeBytes
        self.externalBytes = externalBytes
        self.internalBytes = internalBytes
        self.swapUsedBytes = swapUsedBytes
        self.swapTotalBytes = swapTotalBytes
        self.pageSize = pageSize
        self.timestamp = timestamp
    }

    /// "App memory" as Activity Monitor displays it — anonymous (internal) pages.
    public var appBytes: UInt64 { internalBytes }

    /// File caches that the kernel can drop under pressure without paging out.
    public var cachedBytes: UInt64 { externalBytes &+ purgeableBytes }

    /// Total memory the system reports as "used" — matches Activity Monitor's
    /// Memory Pressure denominator (App + Wired + Compressed).
    public var usedBytes: UInt64 { appBytes &+ wiredBytes &+ compressedBytes }

    public var availableBytes: UInt64 {
        totalBytes > usedBytes ? totalBytes &- usedBytes : 0
    }

    public var usedFraction: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }
}

/// Per-process memory snapshot. Bundle/icon enrichment is done in the UI layer.
public struct ProcessMemoryEntry: Sendable, Identifiable, Hashable {
    public let id: pid_t
    public let name: String
    public let executablePath: String
    public let residentBytes: UInt64
    public let virtualBytes: UInt64
    public let isOwnedByCurrentUser: Bool

    public var pid: pid_t { id }

    public init(id: pid_t, name: String, executablePath: String,
                residentBytes: UInt64, virtualBytes: UInt64,
                isOwnedByCurrentUser: Bool) {
        self.id = id
        self.name = name
        self.executablePath = executablePath
        self.residentBytes = residentBytes
        self.virtualBytes = virtualBytes
        self.isOwnedByCurrentUser = isOwnedByCurrentUser
    }
}

/// Outcome of a free / reclaim action, with honest before/after deltas.
///
/// Carries the full `MemoryStats` snapshots so callers can report any specific
/// delta they care about. The `reclaimedBytes` headline number measures the
/// pages the kernel actually discarded under our pressure (cached + inactive
/// shrinking), which is what soft-purge targets — *not* the change in
/// `availableBytes`, which only moves when wired/compressed/app-anonymous pages
/// shrink, none of which soft-purge can do without root.
public struct FreeResult: Sendable {
    public let strategy: String
    public let beforeStats: MemoryStats
    public let afterStats: MemoryStats
    public let processesTerminated: Int
    public let elapsed: TimeInterval
    /// Set when MemoryFreer chose to skip soft-purge because allocating more
    /// pages would worsen swap thrash on a memory-tight system.
    public let skippedReason: String?

    public init(strategy: String,
                beforeStats: MemoryStats,
                afterStats: MemoryStats,
                processesTerminated: Int,
                elapsed: TimeInterval,
                skippedReason: String? = nil) {
        self.strategy = strategy
        self.beforeStats = beforeStats
        self.afterStats = afterStats
        self.processesTerminated = processesTerminated
        self.elapsed = elapsed
        self.skippedReason = skippedReason
    }

    /// Honest measure of what the kernel discarded under our pressure:
    /// the drop in (cached + inactive). Saturating subtract.
    public var reclaimedBytes: UInt64 {
        let b = beforeStats.cachedBytes &+ beforeStats.inactiveBytes
        let a = afterStats.cachedBytes &+ afterStats.inactiveBytes
        return b > a ? b &- a : 0
    }

    /// Negative = compressor shrunk (good — pages were decompressed or freed).
    public var compressedDelta: Int64 {
        Int64(afterStats.compressedBytes) - Int64(beforeStats.compressedBytes)
    }

    /// Negative = swap usage went down (good).
    public var swapDelta: Int64 {
        Int64(afterStats.swapUsedBytes) - Int64(beforeStats.swapUsedBytes)
    }

    /// Negative = pressure on the system eased.
    public var usedDelta: Int64 {
        Int64(afterStats.usedBytes) - Int64(beforeStats.usedBytes)
    }
}
