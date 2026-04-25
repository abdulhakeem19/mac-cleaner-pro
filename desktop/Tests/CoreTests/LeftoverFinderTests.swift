import XCTest
@testable import Core

final class LeftoverFinderTests: XCTestCase {

    private var tmp: URL!
    private var home: URL!
    private var system: URL!
    private let fm = FileManager.default

    override func setUpWithError() throws {
        tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("LeftoverFinder-\(UUID().uuidString)")
        home = tmp.appendingPathComponent("home/Library")
        system = tmp.appendingPathComponent("system/Library")
        try fm.createDirectory(at: home, withIntermediateDirectories: true)
        try fm.createDirectory(at: system, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws { try? fm.removeItem(at: tmp) }

    @discardableResult
    private func mkdir(_ relative: String, under base: URL) throws -> URL {
        let url = base.appendingPathComponent(relative)
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @discardableResult
    private func touch(_ relative: String, under base: URL) throws -> URL {
        let url = base.appendingPathComponent(relative)
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data().write(to: url)
        return url
    }

    func testFindsContainerByExactBundleID() async throws {
        let bundleID = "com.example.MyApp"
        let container = try mkdir("Containers/\(bundleID)", under: home)
        try touch("Containers/\(bundleID)/Data/Documents/note.txt", under: home)

        let finder = LeftoverFinder(homeLibrary: home, systemLibrary: system)
        let results = await finder.leftovers(forBundleID: bundleID, appName: "MyApp")

        XCTAssertTrue(results.contains { $0.url.path == container.path })
    }

    func testFindsPreferencePlistByBundleIDPrefix() async throws {
        let bundleID = "com.example.MyApp"
        let plist = try touch("Preferences/\(bundleID).plist", under: home)

        let finder = LeftoverFinder(homeLibrary: home, systemLibrary: system)
        let results = await finder.leftovers(forBundleID: bundleID, appName: "MyApp")

        XCTAssertTrue(results.contains { $0.url.path == plist.path && $0.category == .preferences })
    }

    func testFindsApplicationSupportByAppName() async throws {
        let appSupport = try mkdir("Application Support/MyApp", under: home)

        let finder = LeftoverFinder(homeLibrary: home, systemLibrary: system)
        let results = await finder.leftovers(forBundleID: "com.example.MyApp", appName: "MyApp")

        XCTAssertTrue(results.contains { $0.url.path == appSupport.path })
    }

    func testFindsGroupContainerByContainsMatch() async throws {
        let bundleID = "com.example.MyApp"
        let group = try mkdir("Group Containers/ABC123XYZ.com.example.MyApp", under: home)

        let finder = LeftoverFinder(homeLibrary: home, systemLibrary: system)
        let results = await finder.leftovers(forBundleID: bundleID, appName: "MyApp")

        XCTAssertTrue(results.contains { $0.url.path == group.path && $0.category == .groupContainers })
    }

    func testFlagsSystemLeftoversAsRequiringHelper() async throws {
        let bundleID = "com.example.MyApp"
        let daemon = try touch("LaunchDaemons/\(bundleID).helper.plist", under: system)

        let finder = LeftoverFinder(homeLibrary: home, systemLibrary: system)
        let results = await finder.leftovers(forBundleID: bundleID, appName: "MyApp")

        guard let hit = results.first(where: { $0.url.path == daemon.path }) else {
            XCTFail("expected system leftover"); return
        }
        XCTAssertEqual(hit.category, .systemLaunchDaemons)
        XCTAssertTrue(hit.requiresHelper)
    }

    func testIgnoresUnrelatedFiles() async throws {
        try touch("Application Support/SomeOtherApp/data.bin", under: home)
        try touch("Caches/com.unrelated.App", under: home)

        let finder = LeftoverFinder(homeLibrary: home, systemLibrary: system)
        let results = await finder.leftovers(forBundleID: "com.example.MyApp", appName: "MyApp")

        XCTAssertTrue(results.isEmpty)
    }
}
