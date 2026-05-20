import Foundation
import Darwin

/// Lists user-space processes with per-PID memory usage, using libproc
/// (`proc_listpids`, `proc_pidinfo`, `proc_pidpath`). Doesn't require any
/// special entitlement for processes the user already owns.
public actor ProcessInspector {

    public static let shared = ProcessInspector()

    /// System processes we never offer to terminate. Kept conservative —
    /// the goal is to avoid catastrophic UX, not to implement a kernel allowlist.
    public static let criticalNames: Set<String> = [
        "kernel_task", "launchd", "WindowServer", "loginwindow",
        "logd", "configd", "powerd", "coreaudiod", "mds", "mds_stores",
        "cfprefsd", "hidd", "opendirectoryd", "syslogd", "UserEventAgent",
        "Dock", "Finder", "SystemUIServer", "ControlCenter", "Spotlight",
        "MacCleanerPro", "com.maccleanerpro.helper",
    ]

    public init() {}

    public struct Snapshot: Sendable {
        public let entries: [ProcessMemoryEntry]
        /// Total visible processes after critical-name filter, *before* `limit`.
        public let totalCount: Int
        public init(entries: [ProcessMemoryEntry], totalCount: Int) {
            self.entries = entries
            self.totalCount = totalCount
        }
    }

    /// Returns processes sorted by RSS (descending), capped at `limit`.
    /// `excludeCritical=true` filters the names listed above.
    public func snapshot(limit: Int = 200,
                         excludeCritical: Bool = true) -> Snapshot {
        let pids = listAllPIDs()
        guard !pids.isEmpty else { return Snapshot(entries: [], totalCount: 0) }

        let uid = getuid()
        var entries: [ProcessMemoryEntry] = []
        entries.reserveCapacity(pids.count)

        for pid in pids where pid > 0 {
            guard let entry = inspect(pid: pid, currentUID: uid) else { continue }
            if excludeCritical && Self.criticalNames.contains(entry.name) { continue }
            entries.append(entry)
        }

        entries.sort { $0.residentBytes > $1.residentBytes }
        let total = entries.count
        if entries.count > limit { entries = Array(entries.prefix(limit)) }
        return Snapshot(entries: entries, totalCount: total)
    }

    // MARK: - libproc

    private func listAllPIDs() -> [pid_t] {
        // Two-pass: ask for required size, then fetch.
        let neededBytes = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard neededBytes > 0 else { return [] }
        let cap = Int(neededBytes) / MemoryLayout<pid_t>.size + 32
        var pids = [pid_t](repeating: 0, count: cap)
        let actualBytes = proc_listpids(UInt32(PROC_ALL_PIDS), 0,
                                        &pids,
                                        Int32(cap * MemoryLayout<pid_t>.size))
        guard actualBytes > 0 else { return [] }
        let count = Int(actualBytes) / MemoryLayout<pid_t>.size
        return Array(pids.prefix(count))
    }

    private func inspect(pid: pid_t, currentUID: uid_t) -> ProcessMemoryEntry? {
        // Task info: RSS + virtual size.
        var task = proc_taskinfo()
        let taskSize = Int32(MemoryLayout<proc_taskinfo>.size)
        let r = withUnsafeMutablePointer(to: &task) { ptr -> Int32 in
            proc_pidinfo(pid, PROC_PIDTASKINFO, 0, ptr, taskSize)
        }
        guard r == taskSize else { return nil }

        // Short BSD info: ownership uid + comm name.
        var bsd = proc_bsdshortinfo()
        let bsdSize = Int32(MemoryLayout<proc_bsdshortinfo>.size)
        let br = withUnsafeMutablePointer(to: &bsd) { ptr -> Int32 in
            proc_pidinfo(pid, PROC_PIDT_SHORTBSDINFO, 0, ptr, bsdSize)
        }
        let ownedByUser: Bool
        var name: String
        if br == bsdSize {
            ownedByUser = (bsd.pbsi_uid == currentUID)
            name = withUnsafePointer(to: bsd.pbsi_comm) {
                $0.withMemoryRebound(to: CChar.self, capacity: MemoryLayout.size(ofValue: bsd.pbsi_comm)) {
                    String(cString: $0)
                }
            }
        } else {
            ownedByUser = false
            name = ""
        }

        // Executable path (full). 4096 == PROC_PIDPATHINFO_MAXSIZE
        // (4 * MAXPATHLEN) per <sys/proc_info.h>; not exposed to Swift.
        var pathBuf = [CChar](repeating: 0, count: 4096)
        let pr = proc_pidpath(pid, &pathBuf, UInt32(pathBuf.count))
        let path = pr > 0 ? String(cString: pathBuf) : ""

        // Prefer the bundle/executable display name from path's last component
        // when comm is truncated (BSD comm is 16 chars).
        if !path.isEmpty {
            let last = (path as NSString).lastPathComponent
            if !last.isEmpty { name = last }
        }
        if name.isEmpty { name = "pid \(pid)" }

        return ProcessMemoryEntry(
            id: pid,
            name: name,
            executablePath: path,
            residentBytes: task.pti_resident_size,
            virtualBytes: task.pti_virtual_size,
            isOwnedByCurrentUser: ownedByUser
        )
    }
}
