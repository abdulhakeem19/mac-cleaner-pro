import XCTest
@testable import Core

final class DuplicateScannerTests: XCTestCase {

    private var tmpDir: URL!

    override func setUp() async throws {
        tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DupScanTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    // MARK: - Helpers

    @discardableResult
    private func write(_ name: String, content: Data, in dir: URL? = nil) throws -> URL {
        let parent = dir ?? tmpDir!
        let url = parent.appendingPathComponent(name)
        try content.write(to: url)
        return url
    }

    private func makeContent(size: Int, byte: UInt8 = 0xAB) -> Data {
        Data(repeating: byte, count: size)
    }

    // MARK: - Tests

    func testFindsExactDuplicates() async throws {
        let payload = makeContent(size: 2_048)
        try write("a.bin", content: payload)
        try write("b.bin", content: payload)
        try write("c.bin", content: payload)

        let groups = await DuplicateScanner().scan(root: tmpDir, minSize: 1_024)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].files.count, 3)
        XCTAssertEqual(groups[0].wastedBytes, UInt64(groups[0].fileSize) * 2)
    }

    func testIgnoresUniqueFiles() async throws {
        try write("a.bin", content: makeContent(size: 2_048, byte: 0x11))
        try write("b.bin", content: makeContent(size: 2_048, byte: 0x22))

        let groups = await DuplicateScanner().scan(root: tmpDir, minSize: 1_024)
        XCTAssertTrue(groups.isEmpty)
    }

    func testMinSizeFilterExcludesSmallFiles() async throws {
        let smallPayload = makeContent(size: 512)
        try write("a.bin", content: smallPayload)
        try write("b.bin", content: smallPayload)

        // minSize = 1 KB — these 512-byte files should be excluded
        let groups = await DuplicateScanner().scan(root: tmpDir, minSize: 1_024)
        XCTAssertTrue(groups.isEmpty)
    }

    func testMinSizeFilterIncludesLargeFiles() async throws {
        let payload = makeContent(size: 2_048)
        try write("a.bin", content: payload)
        try write("b.bin", content: payload)

        let groups = await DuplicateScanner().scan(root: tmpDir, minSize: 1_024)
        XCTAssertFalse(groups.isEmpty)
    }

    func testSameNameDifferentContentNotGrouped() async throws {
        // Same size, different content → different SHA-256 → not duplicates
        let sub1 = tmpDir.appendingPathComponent("sub1", isDirectory: true)
        let sub2 = tmpDir.appendingPathComponent("sub2", isDirectory: true)
        try FileManager.default.createDirectory(at: sub1, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: sub2, withIntermediateDirectories: true)

        try write("report.pdf", content: makeContent(size: 2_048, byte: 0xAA), in: sub1)
        try write("report.pdf", content: makeContent(size: 2_048, byte: 0xBB), in: sub2)

        let groups = await DuplicateScanner().scan(root: tmpDir, minSize: 1_024)
        XCTAssertTrue(groups.isEmpty)
    }

    func testSortedByWastedBytesDescending() async throws {
        let small = makeContent(size: 2_048)
        let large = makeContent(size: 4_096)

        // Group A: 2 copies of 2 KB = 2 KB wasted
        try write("small1.bin", content: small)
        try write("small2.bin", content: small)

        // Group B: 3 copies of 4 KB = 8 KB wasted — should come first
        try write("large1.bin", content: large)
        try write("large2.bin", content: large)
        try write("large3.bin", content: large)

        let groups = await DuplicateScanner().scan(root: tmpDir, minSize: 1_024)
        XCTAssertEqual(groups.count, 2)
        XCTAssertGreaterThan(groups[0].wastedBytes, groups[1].wastedBytes)
    }

    func testNewestFileIsFirstInGroup() async throws {
        let payload = makeContent(size: 2_048)
        let old = tmpDir.appendingPathComponent("old.bin")
        let new = tmpDir.appendingPathComponent("new.bin")
        try payload.write(to: old)
        try payload.write(to: new)

        // Stamp old.bin with a past modification date
        let pastDate = Date(timeIntervalSinceNow: -86_400 * 30)
        try FileManager.default.setAttributes(
            [.modificationDate: pastDate], ofItemAtPath: old.path
        )

        let groups = await DuplicateScanner().scan(root: tmpDir, minSize: 1_024)
        XCTAssertEqual(groups.count, 1)
        // files[0] should be the newer file
        XCTAssertEqual(groups[0].files[0].url.lastPathComponent, "new.bin")
    }

    func testRecursiveScan() async throws {
        let sub = tmpDir.appendingPathComponent("deep/nested", isDirectory: true)
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)

        let payload = makeContent(size: 2_048)
        try write("root.bin", content: payload)
        try write("nested.bin", content: payload, in: sub)

        let groups = await DuplicateScanner().scan(root: tmpDir, minSize: 1_024)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].files.count, 2)
    }

    func testCancellationReturnsEmpty() async throws {
        let payload = makeContent(size: 2_048)
        try write("a.bin", content: payload)
        try write("b.bin", content: payload)

        let scanner = DuplicateScanner()
        let task = Task { await scanner.scan(root: tmpDir, minSize: 1_024) }
        task.cancel()
        let result = await task.value
        // Cancelled scan returns empty (or partial) — must not crash
        XCTAssertTrue(result.isEmpty)
    }
}
