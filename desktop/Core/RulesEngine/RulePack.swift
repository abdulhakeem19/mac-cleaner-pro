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
