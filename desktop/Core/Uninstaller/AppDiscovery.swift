import Foundation

/// Walks `/Applications` and `~/Applications` for `.app` bundles, reads each
/// bundle's `Info.plist`, and returns one `AppRecord` per app sorted by size.
///
/// System apps (firmlinked from `/System/Applications`) are excluded — we only
/// surface user-installed apps the user can actually uninstall.
public actor AppDiscovery {

    public init() {}

    public func listInstalledApps() async -> [AppRecord] {
        let roots = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: NSHomeDirectory() + "/Applications"),
        ]
        var seen = Set<String>()
        var out: [AppRecord] = []

        for root in roots {
            for bundleURL in scanDirectoryForApps(root) {
                let key = bundleURL.standardizedFileURL.path
                if !seen.insert(key).inserted { continue }
                if Task.isCancelled { return out.sorted { $0.size > $1.size } }
                if let record = readBundle(at: bundleURL) {
                    out.append(record)
                }
            }
        }
        return out.sorted { $0.size > $1.size }
    }

    /// Looks for `.app` bundles directly inside `dir` (one level deep). We don't
    /// recurse — `/Applications/Utilities/Foo.app` is intentionally surfaced via
    /// the Utilities entry as a folder, not as an app — because Apple's pattern
    /// for user-installed apps doesn't nest below the first level.
    private func scanDirectoryForApps(_ dir: URL) -> [URL] {
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else {
            return []
        }
        return names.compactMap { name -> URL? in
            guard name.hasSuffix(".app") else { return nil }
            return dir.appendingPathComponent(name)
        }
    }

    private func readBundle(at url: URL) -> AppRecord? {
        let infoPlistURL = url.appendingPathComponent("Contents/Info.plist")
        guard let data = try? Data(contentsOf: infoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(
                from: data, options: [], format: nil) as? [String: Any]
        else { return nil }

        guard let bundleID = plist["CFBundleIdentifier"] as? String else { return nil }
        // Skip Apple-signed system frameworks that occasionally appear in /Applications.
        if bundleID.hasPrefix("com.apple.") { return nil }

        let name = (plist["CFBundleDisplayName"] as? String)
            ?? (plist["CFBundleName"] as? String)
            ?? url.deletingPathExtension().lastPathComponent
        let version = plist["CFBundleShortVersionString"] as? String
            ?? plist["CFBundleVersion"] as? String
        let size = (try? Self.bundleSize(at: url)) ?? 0

        return AppRecord(bundleURL: url, bundleID: bundleID,
                         name: name, version: version, size: size)
    }

    static func bundleSize(at url: URL) throws -> UInt64 {
        let keys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey]
        var total: UInt64 = 0
        if let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        ) {
            for case let child as URL in enumerator {
                if let s = try? child.resourceValues(forKeys: keys).totalFileAllocatedSize {
                    total &+= UInt64(s)
                }
            }
        }
        return total
    }
}
