import XCTest
import Darwin
@testable import Core

final class MemoryManagerTests: XCTestCase {

    // MARK: - MemoryStatsReader

    func testSnapshotReturnsPlausibleValues() {
        let s = MemoryStatsReader.snapshot()

        // hw.memsize should be at least 1 GB on any machine running tests.
        XCTAssertGreaterThan(s.totalBytes, 1_000_000_000)
        XCTAssertGreaterThan(s.pageSize, 0)
        XCTAssertEqual(s.pageSize % 4096, 0)

        // Used should be a sane fraction of total.
        XCTAssertLessThan(s.usedBytes, s.totalBytes)
        XCTAssertGreaterThan(s.usedFraction, 0)
        XCTAssertLessThanOrEqual(s.usedFraction, 1.0)

        // Sum of major buckets should not wildly exceed total (some overlap is
        // expected across active/inactive/cached so we only enforce a generous
        // upper bound).
        let bucketSum = s.appBytes &+ s.wiredBytes &+ s.compressedBytes &+ s.cachedBytes &+ s.freeBytes
        XCTAssertLessThan(bucketSum, s.totalBytes &* 2)
    }

    func testAvailableBytesNeverUnderflows() {
        // Synthesize an inverted state to exercise the saturating subtract.
        let s = MemoryStats(
            totalBytes: 1_000, activeBytes: 0, inactiveBytes: 0,
            wiredBytes: 800, compressedBytes: 400, speculativeBytes: 0,
            purgeableBytes: 0, freeBytes: 0, externalBytes: 0,
            internalBytes: 200, swapUsedBytes: 0, swapTotalBytes: 0,
            pageSize: 4096
        )
        XCTAssertEqual(s.availableBytes, 0)
    }

    // MARK: - ProcessInspector

    func testSnapshotIncludesCurrentProcess() async {
        let snap = await ProcessInspector.shared.snapshot(excludeCritical: false)
        let myPID = getpid()
        XCTAssertTrue(snap.entries.contains { $0.id == myPID },
                      "Expected own pid \(myPID) in snapshot")
        if let me = snap.entries.first(where: { $0.id == myPID }) {
            XCTAssertGreaterThan(me.residentBytes, 0)
            XCTAssertTrue(me.isOwnedByCurrentUser)
        }
        XCTAssertGreaterThanOrEqual(snap.totalCount, snap.entries.count)
    }

    func testSnapshotSortedByRSSDescending() async {
        let snap = await ProcessInspector.shared.snapshot()
        let rssValues = snap.entries.map(\.residentBytes)
        XCTAssertEqual(rssValues, rssValues.sorted(by: >))
    }

    func testSnapshotExcludesCriticalNamesByDefault() async {
        let snap = await ProcessInspector.shared.snapshot()
        for name in ProcessInspector.criticalNames {
            XCTAssertFalse(
                snap.entries.contains { $0.name == name },
                "Critical process \(name) should be filtered out"
            )
        }
    }

    func testSnapshotLimitClampsButReportsTotal() async {
        let limited = await ProcessInspector.shared.snapshot(limit: 5)
        XCTAssertLessThanOrEqual(limited.entries.count, 5)
        // On any real system there are far more than 5 user-visible processes.
        XCTAssertGreaterThan(limited.totalCount, limited.entries.count)
    }

    // MARK: - MemoryFreer

    func testQuickFreeReturnsResultWithBeforeAfter() async {
        let result = await MemoryFreer.shared.quickFree()
        XCTAssertEqual(result.processesTerminated, 0)
        XCTAssertGreaterThan(result.elapsed, 0)
        XCTAssertFalse(result.strategy.isEmpty)
        XCTAssertGreaterThan(result.beforeStats.totalBytes, 0)
        XCTAssertGreaterThan(result.afterStats.totalBytes, 0)
    }

    func testTerminateReturnsZeroForInvalidPIDs() async {
        let n = await MemoryFreer.shared.terminate(pids: [-1, -2], force: false)
        XCTAssertEqual(n, 0)
    }

    // MARK: - Emergency mode (swap-aware strategy selection)

    func testEmergencyModeTriggersOnHeavySwap() async {
        // 8 GB total, 4 GB swap used → 50% > 25% threshold → emergency.
        let s = MemoryStats(
            totalBytes: 8_000_000_000, activeBytes: 0, inactiveBytes: 100_000_000,
            wiredBytes: 0, compressedBytes: 0, speculativeBytes: 0,
            purgeableBytes: 0, freeBytes: 100_000_000, externalBytes: 0,
            internalBytes: 0, swapUsedBytes: 4_000_000_000, swapTotalBytes: 4_000_000_000,
            pageSize: 16384
        )
        let isEmergency = await MemoryFreer.shared.isEmergencyMode(stats: s)
        XCTAssertTrue(isEmergency, "Expected emergency mode when swap exceeds threshold")
    }

    func testEmergencyModeClearOnHealthySystem() async {
        // 16 GB total, 0 swap → well below threshold → standard mode.
        let s = MemoryStats(
            totalBytes: 16_000_000_000, activeBytes: 0, inactiveBytes: 2_000_000_000,
            wiredBytes: 0, compressedBytes: 0, speculativeBytes: 0,
            purgeableBytes: 0, freeBytes: 2_000_000_000, externalBytes: 0,
            internalBytes: 0, swapUsedBytes: 0, swapTotalBytes: 0,
            pageSize: 16384
        )
        let isEmergency = await MemoryFreer.shared.isEmergencyMode(stats: s)
        XCTAssertFalse(isEmergency, "Expected standard mode on a healthy system")
    }

    func testNormalPurgeTargetCappedByCeiling() async {
        // 64 GB machine with 60 GB reclaimable — ceiling must clamp to maxNormalPurgeBytes.
        let s = MemoryStats(
            totalBytes: 64_000_000_000, activeBytes: 0,
            inactiveBytes: 30_000_000_000, wiredBytes: 0, compressedBytes: 0,
            speculativeBytes: 0, purgeableBytes: 0, freeBytes: 30_000_000_000,
            externalBytes: 0, internalBytes: 0, swapUsedBytes: 0,
            swapTotalBytes: 0, pageSize: 16384
        )
        let target = await MemoryFreer.shared.normalPurgeTarget(stats: s)
        XCTAssertLessThanOrEqual(target, MemoryFreer.maxNormalPurgeBytes)
    }
}
