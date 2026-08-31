import SwiftUI
import AppKit

extension Color {
    /// Build a `Color` that resolves to one value in light mode and another in
    /// dark mode. Wraps `NSColor(name:dynamicProvider:)` so it picks up the
    /// effective appearance from the surrounding view (including the
    /// `.preferredColorScheme(_:)` override we apply at the root).
    init(light: Color, dark: Color) {
        self.init(
            nsColor: NSColor(name: nil) { appearance in
                let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                return NSColor(isDark ? dark : light)
            }
        )
    }
}
