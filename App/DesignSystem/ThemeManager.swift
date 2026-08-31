import SwiftUI
import AppKit

/// User's preferred appearance. Default is `.light` to match the website.
enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var systemImage: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    /// SwiftUI `ColorScheme?` to feed `.preferredColorScheme(_:)`. `nil` when
    /// the user wants the OS-level setting to win.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

/// Single source of truth for the app's appearance. Persisted via `@AppStorage`
/// so the choice survives relaunch.
@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var appearance: Appearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: "MacCleanerPro.appearance")
        }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "MacCleanerPro.appearance")
        // Default LIGHT — matches the marketing site's default.
        self.appearance = raw.flatMap(Appearance.init(rawValue:)) ?? .light
    }

    func toggle() {
        switch appearance {
        case .light:  appearance = .dark
        case .dark:   appearance = .light
        case .system: appearance = (NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua)
            ? .light : .dark
        }
    }
}
