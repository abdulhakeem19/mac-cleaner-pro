import Foundation

/// One installed application surfaced by `AppDiscovery`.
public struct AppRecord: Identifiable, Sendable, Hashable {
    public var id: URL { bundleURL }
    public let bundleURL: URL
    public let bundleID: String
    public let name: String
    public let version: String?
    public let size: UInt64

    public init(bundleURL: URL, bundleID: String, name: String,
                version: String?, size: UInt64) {
        self.bundleURL = bundleURL
        self.bundleID = bundleID
        self.name = name
        self.version = version
        self.size = size
    }
}

/// Where on disk a leftover lives, used for grouping in the UI and to decide
/// whether the privileged helper is required to delete it.
public enum LeftoverCategory: String, Sendable, CaseIterable, Codable {
    case applicationSupport
    case preferences
    case caches
    case containers
    case groupContainers
    case launchAgents
    case savedState
    case logs
    case httpStorages
    case webKit
    case cookies
    case applicationScripts

    // System-scope (require helper)
    case systemApplicationSupport
    case systemPreferences
    case systemCaches
    case systemLaunchAgents
    case systemLaunchDaemons
    case privilegedHelperTools

    public var requiresHelper: Bool {
        switch self {
        case .systemApplicationSupport, .systemPreferences, .systemCaches,
             .systemLaunchAgents, .systemLaunchDaemons, .privilegedHelperTools:
            return true
        default:
            return false
        }
    }

    public var displayName: String {
        switch self {
        case .applicationSupport:        return "Application Support"
        case .preferences:               return "Preferences"
        case .caches:                    return "Caches"
        case .containers:                return "Containers"
        case .groupContainers:           return "Group Containers"
        case .launchAgents:              return "Launch Agents"
        case .savedState:                return "Saved Application State"
        case .logs:                      return "Logs"
        case .httpStorages:              return "HTTP Storages"
        case .webKit:                    return "WebKit"
        case .cookies:                   return "Cookies"
        case .applicationScripts:        return "Application Scripts"
        case .systemApplicationSupport:  return "System Application Support"
        case .systemPreferences:         return "System Preferences"
        case .systemCaches:              return "System Caches"
        case .systemLaunchAgents:        return "System LaunchAgents"
        case .systemLaunchDaemons:       return "System LaunchDaemons"
        case .privilegedHelperTools:     return "Privileged Helper Tools"
        }
    }
}

public struct Leftover: Identifiable, Sendable, Hashable {
    public var id: URL { url }
    public let url: URL
    public let size: UInt64
    public let category: LeftoverCategory
    public init(url: URL, size: UInt64, category: LeftoverCategory) {
        self.url = url; self.size = size; self.category = category
    }
    public var requiresHelper: Bool { category.requiresHelper }
}
