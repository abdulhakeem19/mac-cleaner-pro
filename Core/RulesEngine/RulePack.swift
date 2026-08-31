import Foundation

// Wire format for a versioned rule pack. Mirrors RulePacks/v1.json.
// Decoded from the bytes that were signed — never re-encode before verification.

public struct RulePack: Codable, Sendable {
    public let schemaVersion: Int
    public let packVersion: String         // semver
    public let issuedAt: Date
    public let minAppVersion: String
    public let rules: [Rule]

    public struct Rule: Codable, Sendable {
        public let id: String
        public let category: Category
        public let displayName: String
        public let description: String
        public let safety: Safety
        public let requiresHelper: Bool
        public let paths: [String]
        public let excludes: [String]?
        public let olderThanDays: Int?
        /// Optional one-liner telling the user how the data comes back (e.g.
        /// "Re-downloaded on the next `npm install`"). Decoded as nil when absent.
        public let restoreHint: String?

        // Explicit init (with a defaulted `restoreHint`) so existing call sites
        // that predate the field — including tests — keep compiling unchanged.
        public init(id: String, category: Category, displayName: String,
                    description: String, safety: Safety, requiresHelper: Bool,
                    paths: [String], excludes: [String]? = nil,
                    olderThanDays: Int? = nil, restoreHint: String? = nil) {
            self.id = id; self.category = category; self.displayName = displayName
            self.description = description; self.safety = safety
            self.requiresHelper = requiresHelper; self.paths = paths
            self.excludes = excludes; self.olderThanDays = olderThanDays
            self.restoreHint = restoreHint
        }
    }

    public enum Category: String, Codable, Sendable {
        case caches, logs, developer, browser, mail, trash, uninstaller, other
    }

    public enum Safety: String, Codable, Sendable {
        case safe                  // default-checked
        case reviewRecommended     // unchecked, user reviews
        case destructive           // unchecked, requires explicit confirmation
    }
}
