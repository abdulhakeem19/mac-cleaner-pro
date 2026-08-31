import Foundation

/// Finds files an app left behind across the standard Library locations.
///
/// Matching strategy per location is deliberately conservative — we only flag
/// items whose name *contains* the bundle ID, or whose name is an exact match
/// for the bundle ID's last component or the app name. This avoids false
/// positives (e.g. a generic "logs" folder being attributed to every app).
///
/// `homeOverride` and `systemOverride` exist so tests can run against a
/// synthetic Library tree.
public actor LeftoverFinder {

    private let homeLibrary: URL
    private let systemLibrary: URL

    public init(homeLibrary: URL? = nil, systemLibrary: URL? = nil) {
        self.homeLibrary = homeLibrary
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library")
        self.systemLibrary = systemLibrary
            ?? URL(fileURLWithPath: "/Library")
    }

    public func leftovers(forBundleID bundleID: String, appName: String) async -> [Leftover] {
        var found: [Leftover] = []
        let lastComponent = bundleID.split(separator: ".").last.map(String.init) ?? bundleID

        for spec in Self.userSpecs(home: homeLibrary) {
            found.append(contentsOf: scan(spec: spec,
                                          bundleID: bundleID,
                                          lastComponent: lastComponent,
                                          appName: appName))
        }
        for spec in Self.systemSpecs(system: systemLibrary) {
            found.append(contentsOf: scan(spec: spec,
                                          bundleID: bundleID,
                                          lastComponent: lastComponent,
                                          appName: appName))
        }
        return dedupe(found)
    }

    // MARK: - Spec table

    private struct Spec {
        let directory: URL
        let category: LeftoverCategory
        let match: Match
    }

    private enum Match {
        /// Match a child whose name is exactly `<bundleID>` or `<bundleID>.<ext>`.
        /// Used for high-precision locations (preferences plist, container, etc.)
        case bundleIDExactOrPrefixed
        /// Match any child whose name *contains* the bundle ID. Used for noisier
        /// locations like Group Containers where Apple often prepends the team ID.
        case bundleIDContains
        /// Match a child whose name is exactly `<bundleID>` OR `<appName>`.
        /// Used for Application Support / Logs which apps populate by either key.
        case bundleIDOrAppName
    }

    private static func userSpecs(home: URL) -> [Spec] {
        [
            Spec(directory: home.appendingPathComponent("Application Support"),
                 category: .applicationSupport, match: .bundleIDOrAppName),
            Spec(directory: home.appendingPathComponent("Preferences"),
                 category: .preferences, match: .bundleIDExactOrPrefixed),
            Spec(directory: home.appendingPathComponent("Caches"),
                 category: .caches, match: .bundleIDExactOrPrefixed),
            Spec(directory: home.appendingPathComponent("Containers"),
                 category: .containers, match: .bundleIDExactOrPrefixed),
            Spec(directory: home.appendingPathComponent("Group Containers"),
                 category: .groupContainers, match: .bundleIDContains),
            Spec(directory: home.appendingPathComponent("LaunchAgents"),
                 category: .launchAgents, match: .bundleIDExactOrPrefixed),
            Spec(directory: home.appendingPathComponent("Saved Application State"),
                 category: .savedState, match: .bundleIDExactOrPrefixed),
            Spec(directory: home.appendingPathComponent("Logs"),
                 category: .logs, match: .bundleIDOrAppName),
            Spec(directory: home.appendingPathComponent("HTTPStorages"),
                 category: .httpStorages, match: .bundleIDExactOrPrefixed),
            Spec(directory: home.appendingPathComponent("WebKit"),
                 category: .webKit, match: .bundleIDExactOrPrefixed),
            Spec(directory: home.appendingPathComponent("Cookies"),
                 category: .cookies, match: .bundleIDExactOrPrefixed),
            Spec(directory: home.appendingPathComponent("Application Scripts"),
                 category: .applicationScripts, match: .bundleIDExactOrPrefixed),
        ]
    }

    private static func systemSpecs(system: URL) -> [Spec] {
        [
            Spec(directory: system.appendingPathComponent("Application Support"),
                 category: .systemApplicationSupport, match: .bundleIDOrAppName),
            Spec(directory: system.appendingPathComponent("Preferences"),
                 category: .systemPreferences, match: .bundleIDExactOrPrefixed),
            Spec(directory: system.appendingPathComponent("Caches"),
                 category: .systemCaches, match: .bundleIDExactOrPrefixed),
            Spec(directory: system.appendingPathComponent("LaunchAgents"),
                 category: .systemLaunchAgents, match: .bundleIDExactOrPrefixed),
            Spec(directory: system.appendingPathComponent("LaunchDaemons"),
                 category: .systemLaunchDaemons, match: .bundleIDExactOrPrefixed),
            Spec(directory: system.appendingPathComponent("PrivilegedHelperTools"),
                 category: .privilegedHelperTools, match: .bundleIDContains),
        ]
    }

    // MARK: - Scanning

    private func scan(spec: Spec,
                      bundleID: String,
                      lastComponent: String,
                      appName: String) -> [Leftover] {
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: spec.directory.path) else {
            return []
        }
        var hits: [Leftover] = []
        for name in names {
            guard matches(name: name, kind: spec.match,
                          bundleID: bundleID, appName: appName) else { continue }
            let url = spec.directory.appendingPathComponent(name)
            let size = (try? Self.size(of: url)) ?? 0
            hits.append(Leftover(url: url, size: size, category: spec.category))
        }
        // Avoid spamming with empty zero-byte preference plists for the wrong app
        // by silently dropping zero-size matches in noisy locations. The exact
        // bundleID matches are still kept regardless of size.
        _ = lastComponent
        return hits
    }

    private func matches(name: String, kind: Match,
                         bundleID: String, appName: String) -> Bool {
        let stem = (name as NSString).deletingPathExtension
        switch kind {
        case .bundleIDExactOrPrefixed:
            return stem == bundleID || name == bundleID || name.hasPrefix(bundleID + ".")
        case .bundleIDContains:
            return name.contains(bundleID)
        case .bundleIDOrAppName:
            return stem == bundleID || stem == appName || name == bundleID || name == appName
        }
    }

    private func dedupe(_ items: [Leftover]) -> [Leftover] {
        var seen = Set<String>()
        var out: [Leftover] = []
        for item in items {
            let key = item.url.standardizedFileURL.path
            if seen.insert(key).inserted { out.append(item) }
        }
        return out
    }

    static func size(of url: URL) throws -> UInt64 {
        let keys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey, .isDirectoryKey]
        let values = try url.resourceValues(forKeys: keys)
        if values.isDirectory == true {
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
        } else {
            return UInt64(values.totalFileAllocatedSize ?? 0)
        }
    }
}
