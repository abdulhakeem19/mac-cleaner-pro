import Foundation
import Darwin
import Darwin.Mach

/// Reads the live VM statistics via `host_statistics64` + `sysctlbyname`.
/// Same data source Activity Monitor uses, no shell-out.
public enum MemoryStatsReader {

    /// Returns a snapshot of the current memory state. Cheap (~microseconds);
    /// safe to call from the UI thread, but prefer the View Model's timer loop
    /// to avoid wasted churn.
    public static func snapshot() -> MemoryStats {
        let pageSize = UInt64(vm_kernel_page_size)
        let total = readTotalRAM()
        let (swapUsed, swapTotal) = readSwapUsage()
        let vm = readVMStats()

        return MemoryStats(
            totalBytes:        total,
            activeBytes:       vm.active &* pageSize,
            inactiveBytes:     vm.inactive &* pageSize,
            wiredBytes:        vm.wired &* pageSize,
            compressedBytes:   vm.compressed &* pageSize,
            speculativeBytes:  vm.speculative &* pageSize,
            purgeableBytes:    vm.purgeable &* pageSize,
            freeBytes:         vm.free &* pageSize,
            externalBytes:     vm.external &* pageSize,
            internalBytes:     vm.`internal` &* pageSize,
            swapUsedBytes:     swapUsed,
            swapTotalBytes:    swapTotal,
            pageSize:          pageSize
        )
    }

    // MARK: - sysctl

    private static func readTotalRAM() -> UInt64 {
        var value: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        if sysctlbyname("hw.memsize", &value, &size, nil, 0) != 0 {
            return 0
        }
        return value
    }

    private static func readSwapUsage() -> (used: UInt64, total: UInt64) {
        var swap = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        if sysctlbyname("vm.swapusage", &swap, &size, nil, 0) != 0 {
            return (0, 0)
        }
        return (swap.xsu_used, swap.xsu_total)
    }

    // MARK: - mach VM stats

    private struct VMRaw {
        var free: UInt64 = 0
        var active: UInt64 = 0
        var inactive: UInt64 = 0
        var wired: UInt64 = 0
        var compressed: UInt64 = 0
        var speculative: UInt64 = 0
        var purgeable: UInt64 = 0
        var external: UInt64 = 0
        var `internal`: UInt64 = 0
    }

    private static func readVMStats() -> VMRaw {
        var info = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )
        let host = mach_host_self()
        let kr = withUnsafeMutablePointer(to: &info) { ptr -> kern_return_t in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return VMRaw() }

        var raw = VMRaw()
        raw.free        = UInt64(info.free_count)
        raw.active      = UInt64(info.active_count)
        raw.inactive    = UInt64(info.inactive_count)
        raw.wired       = UInt64(info.wire_count)
        // `compressor_page_count` is the number of *compressed* pages currently
        // sitting in the compressor — already counted in pageSize for byte math.
        raw.compressed  = UInt64(info.compressor_page_count)
        raw.speculative = UInt64(info.speculative_count)
        raw.purgeable   = UInt64(info.purgeable_count)
        raw.external    = UInt64(info.external_page_count)
        raw.internal    = UInt64(info.internal_page_count)
        return raw
    }
}
