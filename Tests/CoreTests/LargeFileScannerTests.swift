import XCTest
@testable import Core

final class LargeFileScannerTests: XCTestCase {

    private var tmp: URL!
    private let fm = FileManager.default

    override func setUpWithError() throws {
        tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("LargeFiles-\(UUID().uuidString)")
        try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws { try? fm.removeItem(at: tmp) }

    @discardableResult
    private func write(_ name: String, mb: Int, mtime: Date? = nil) throws -> URL {
        let url = tmp.appendingPathComponent(name)
        try fm.createDirectory(at: url.deletingLastPathComponent(),
                               withIntermediateDirectories: true)
        try Data(repeating: 0xAB, count: mb * 1024 * 1024).write(to: url)
        if let mtime {
            try fm.setAttributes([.modificationDate: mtime], ofItemAtPath: url.path)
        }
        return url
    }

    func testFiltersByMinSize() async throws {
        _ = try write("small.bin", mb: 1)
        let big = try write("big.bin", mb: 5)

        let scanner = LargeFileScanner()
        let results = await scanner.scan(.init(root: tmp, minSize: 4 * 1024 * 1024))

        XCTAssertEqual(results.map(\.url.lastPathComponent), [big.lastPathComponent])
    }

    func testSortedBySizeDescending() async throws {
        _ = try write("a.bin", mb: 5)
        _ = try write("b.bin", mb: 8)
        _ = try write("c.bin", mb: 6)

        let scanner = LargeFileScanner()
        let results = await scanner.scan(.init(root: tmp, minSize: 1))
        XCTAssertEqual(results.map(\.url.lastPathComponent), ["b.bin", "c.bin", "a.bin"])
    }

    func testOlderThanFilter() async throws {
        let old = try write("old.bin", mb: 2,
                            mtime: Date(timeIntervalSinceNow: -200 * 86_400))
        _ = try write("new.bin", mb: 2)

        let scanner = LargeFileScanner()
        let results = await scanner.scan(.init(
            root: tmp,
            minSize: 1,
            olderThanDays: 90
        ))
        XCTAssertEqual(results.map(\.url.lastPathComponent), [old.lastPathComponent])
    }

    func testRecursesIntoSubdirs() async throws {
        _ = try write("nested/deep/d.bin", mb: 3)
        let scanner = LargeFileScanner()
        let results = await scanner.scan(.init(root: tmp, minSize: 1))
        XCTAssertEqual(results.count, 1)
    }
}
