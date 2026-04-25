import XCTest
@testable import Core

final class ActivityLogTests: XCTestCase {

    private var tmpFile: URL!

    override func setUpWithError() throws {
        tmpFile = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ActivityLog-\(UUID().uuidString).json")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpFile)
    }

    func testAppendAndReadback() async {
        let log = ActivityLog(fileURL: tmpFile)
        await log.append(.init(kind: .clean, source: .smartScan, bytes: 1024, itemCount: 3))
        await log.append(.init(kind: .undo, source: .smartScan, bytes: 1024, itemCount: 3))
        let all = await log.all()
        XCTAssertEqual(all.count, 2)
        // Newest first.
        XCTAssertEqual(all.first?.kind, .undo)
    }

    func testPersistenceAcrossInstances() async {
        let a = ActivityLog(fileURL: tmpFile)
        await a.append(.init(kind: .clean, source: .uninstaller, bytes: 999, itemCount: 1))

        let b = ActivityLog(fileURL: tmpFile)
        let all = await b.all()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.bytes, 999)
        XCTAssertEqual(all.first?.source, .uninstaller)
    }

    func testClearEmptiesLog() async {
        let log = ActivityLog(fileURL: tmpFile)
        await log.append(.init(kind: .clean, source: .smartScan, bytes: 1, itemCount: 1))
        await log.clear()
        let all = await log.all()
        XCTAssertTrue(all.isEmpty)
    }
}
