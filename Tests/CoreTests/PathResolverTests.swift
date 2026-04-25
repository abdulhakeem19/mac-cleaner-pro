import XCTest
@testable import Core

final class PathResolverTests: XCTestCase {

    private var tmp: URL!
    private let fm = FileManager.default

    override func setUpWithError() throws {
        tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("PathResolverTests-\(UUID().uuidString)")
        try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? fm.removeItem(at: tmp)
    }

    private func touch(_ relative: String) throws -> URL {
        let url = tmp.appendingPathComponent(relative)
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data().write(to: url)
        return url
    }

    private func mkdir(_ relative: String) throws -> URL {
        let url = tmp.appendingPathComponent(relative)
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func testLiteralPath() throws {
        let f = try touch("a.txt")
        let resolver = PathResolver()
        let resolved = resolver.resolve(patterns: [f.path])
        XCTAssertEqual(resolved.map(\.path), [f.path])
    }

    func testStarMatchesDirectChildren() throws {
        _ = try touch("dir/a.txt")
        _ = try touch("dir/b.txt")
        _ = try touch("dir/.hidden")
        let resolver = PathResolver()
        let resolved = resolver.resolve(patterns: ["\(tmp.path)/dir/*"])
        let names = Set(resolved.map { $0.lastPathComponent })
        XCTAssertEqual(names, ["a.txt", "b.txt"])
    }

    func testDoubleStarRecursive() throws {
        _ = try touch("d1/x.log")
        _ = try touch("d1/d2/y.log")
        _ = try touch("d1/d2/d3/z.log")
        let resolver = PathResolver()
        let resolved = resolver.resolve(patterns: ["\(tmp.path)/d1/**/*"])
        let names = Set(resolved.map { $0.lastPathComponent })
        XCTAssertTrue(names.isSuperset(of: ["x.log", "y.log", "z.log"]))
    }

    func testExcludesPrefixDropsMatches() throws {
        _ = try mkdir("apps/Keep")
        let drop = try mkdir("apps/Drop")
        _ = try touch("apps/Drop/inner.txt")
        let resolver = PathResolver()
        let resolved = resolver.resolve(
            patterns: ["\(tmp.path)/apps/*"],
            excludes: [drop.path]
        )
        XCTAssertEqual(resolved.map { $0.lastPathComponent }, ["Keep"])
    }

    func testTildeExpansionMatchesHome() {
        // Just verify the helper expands; we don't depend on user-specific files.
        let expanded = PathResolver.expandTilde("~/somewhere")
        XCTAssertEqual(expanded, NSHomeDirectory() + "/somewhere")
    }
}
