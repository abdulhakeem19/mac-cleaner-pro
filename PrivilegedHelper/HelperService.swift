import Foundation

/// Implements the XPC-exposed verbs. Every path is validated against an allowlist
/// before any filesystem mutation. The allowlist is the contract that lets us
/// safely run as root: even a buggy or compromised app process cannot trick the
/// helper into touching arbitrary paths.
final class HelperService: NSObject, HelperProtocol {

    private static let allowedPrefixes: [String] = [
        "/Library/Caches/",
        "/Library/Logs/",
        "/private/var/folders/",         // user-scoped temp/cache only via app sandbox containers
        "/Library/Application Support/CrashReporter/"
    ]

    func version(reply: @escaping (String) -> Void) {
        reply(HelperVersion.string)
    }

    func trashSystemPaths(_ paths: [String], reply: @escaping (UInt64, Error?) -> Void) {
        do {
            var reclaimed: UInt64 = 0
            for raw in paths {
                let path = (raw as NSString).standardizingPath
                guard Self.isAllowed(path) else {
                    throw HelperError.pathNotAllowlisted
                }
                let url = URL(fileURLWithPath: path)
                guard FileManager.default.fileExists(atPath: path) else {
                    throw HelperError.pathNotFound
                }
                let size = (try? url.directorySize()) ?? 0
                var trashedURL: NSURL?
                try FileManager.default.trashItem(at: url, resultingItemURL: &trashedURL)
                reclaimed &+= size
            }
            reply(reclaimed, nil)
        } catch {
            reply(0, error)
        }
    }

    func sizesForSystemPaths(_ paths: [String], reply: @escaping ([String: UInt64], Error?) -> Void) {
        var out: [String: UInt64] = [:]
        for raw in paths {
            let path = (raw as NSString).standardizingPath
            guard Self.isAllowed(path) else { continue }
            let url = URL(fileURLWithPath: path)
            out[path] = (try? url.directorySize()) ?? 0
        }
        reply(out, nil)
    }

    private static func isAllowed(_ path: String) -> Bool {
        // Disallow path traversal artifacts before prefix checking.
        guard !path.contains("/.."), !path.contains("/./"), path.hasPrefix("/") else {
            return false
        }
        return allowedPrefixes.contains(where: { path.hasPrefix($0) })
    }
}

enum HelperVersion {
    static let string = "1.0.0"
}

private extension URL {
    func directorySize() throws -> UInt64 {
        let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .isDirectoryKey]
        let values = try resourceValues(forKeys: Set(keys))
        if values.isDirectory == true {
            var total: UInt64 = 0
            if let enumerator = FileManager.default.enumerator(at: self,
                                                               includingPropertiesForKeys: keys,
                                                               options: [.skipsHiddenFiles]) {
                for case let url as URL in enumerator {
                    if let size = try? url.resourceValues(forKeys: Set(keys)).totalFileAllocatedSize {
                        total &+= UInt64(size)
                    }
                }
            }
            return total
        } else {
            return UInt64(values.totalFileAllocatedSize ?? 0)
        }
    }
}
