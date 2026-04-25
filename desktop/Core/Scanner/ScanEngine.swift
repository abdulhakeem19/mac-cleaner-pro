import Foundation

/// One scanned filesystem entry under a rule.
public struct ScanItem: Sendable, Hashable {
    public let url: URL
    public let size: UInt64
    public let modifiedAt: Date?
    public init(url: URL, size: UInt64, modifiedAt: Date?) {
        self.url = url; self.size = size; self.modifiedAt = modifiedAt
    }
}

/// Aggregated result for a single rule.
public struct RuleScanResult: Sendable, Identifiable {
    public let ruleID: String
    public let displayName: String
    public let category: RulePack.Category
    public let safety: RulePack.Safety
    public let requiresHelper: Bool
    public let items: [ScanItem]
    public let totalSize: UInt64
    public let error: String?

    public var id: String { ruleID }

    public init(ruleID: String,
                displayName: String,
                category: RulePack.Category,
                safety: RulePack.Safety,
                requiresHelper: Bool,
                items: [ScanItem],
                totalSize: UInt64,
                error: String? = nil) {
        self.ruleID = ruleID
        self.displayName = displayName
        self.category = category
        self.safety = safety
        self.requiresHelper = requiresHelper
        self.items = items
        self.totalSize = totalSize
        self.error = error
    }
}

/// Executes rules from a `RulePack` in parallel.
///
/// Helper-required rules currently produce a deferred result with a zero size and
/// a `requiresHelper` flag the UI can act on; size summation through the helper's
/// `sizesForSystemPaths` is wired in once SMAppService approval is in hand.
public actor ScanEngine {

    private let resolver = PathResolver()

    public init() {}

    public func scan(pack: RulePack) async -> [RuleScanResult] {
        await withTaskGroup(of: RuleScanResult.self, returning: [RuleScanResult].self) { group in
            for rule in pack.rules {
                group.addTask { [resolver] in
                    await Self.scanOne(rule: rule, resolver: resolver)
                }
            }
            var out: [RuleScanResult] = []
            for await result in group { out.append(result) }
            // Sort by reclaimable size descending so the UI shows wins first.
            out.sort { $0.totalSize > $1.totalSize }
            return out
        }
    }

    private static func scanOne(rule: RulePack.Rule, resolver: PathResolver) async -> RuleScanResult {
        if rule.requiresHelper {
            return RuleScanResult(
                ruleID: rule.id,
                displayName: rule.displayName,
                category: rule.category,
                safety: rule.safety,
                requiresHelper: true,
                items: [],
                totalSize: 0
            )
        }

        let roots = resolver.resolve(patterns: rule.paths, excludes: rule.excludes ?? [])
        let cutoff = rule.olderThanDays.map { Date(timeIntervalSinceNow: -Double($0) * 86_400) }

        var items: [ScanItem] = []
        var total: UInt64 = 0

        for root in roots {
            if Task.isCancelled { break }
            let (size, mtime) = sizeAndModified(of: root)
            if let cutoff, let mtime, mtime > cutoff { continue }
            items.append(ScanItem(url: root, size: size, modifiedAt: mtime))
            total &+= size
        }

        return RuleScanResult(
            ruleID: rule.id,
            displayName: rule.displayName,
            category: rule.category,
            safety: rule.safety,
            requiresHelper: false,
            items: items.sorted { $0.size > $1.size },
            totalSize: total
        )
    }

    /// Total file-allocated size + most-recent mtime of `url`. Recurses into
    /// directories using `FileManager.enumerator`. Hidden files are skipped to
    /// match user expectations and avoid touching state like `.DS_Store`.
    private static func sizeAndModified(of url: URL) -> (UInt64, Date?) {
        let keys: [URLResourceKey] = [
            .totalFileAllocatedSizeKey, .isDirectoryKey, .contentModificationDateKey
        ]
        let values = (try? url.resourceValues(forKeys: Set(keys)))
        guard let values else { return (0, nil) }

        if values.isDirectory == true {
            var total: UInt64 = 0
            var newest = values.contentModificationDate
            if let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles]
            ) {
                for case let child as URL in enumerator {
                    if Task.isCancelled { break }
                    let r = try? child.resourceValues(forKeys: Set(keys))
                    if let s = r?.totalFileAllocatedSize { total &+= UInt64(s) }
                    if let m = r?.contentModificationDate {
                        if newest.map({ m > $0 }) ?? true { newest = m }
                    }
                }
            }
            return (total, newest)
        } else {
            return (UInt64(values.totalFileAllocatedSize ?? 0), values.contentModificationDate)
        }
    }
}
