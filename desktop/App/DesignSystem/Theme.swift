import SwiftUI

/// Design tokens for Mac Cleaner Pro — kept in sync with the marketing site's
/// CSS custom properties so screenshots from the app slot into the website
/// without color drift.
///
/// Brand colors (accent, gradient) are identical in both modes.
/// Surface / border / text colors swap between light and dark via
/// `Color(light:dark:)` so they remain WCAG-AA-readable in both palettes.
enum Theme {

    // MARK: - Brand (mode-invariant)

    static let accent     = Color(hex: 0x7C5CFF)
    static let accent2    = Color(hex: 0x0A84FF)

    static let brandGradient = LinearGradient(
        colors: [
            Color(hex: 0x0A84FF),
            Color(hex: 0x7C5CFF),
            Color(hex: 0xB47BFF),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Status (mode-invariant)

    static let ok   = Color(hex: 0x30D158)
    static let warn = Color(hex: 0xFFB340)
    static let bad  = Color(hex: 0xFF453A)

    // MARK: - Adaptive surfaces / borders

    static let accentSoft = Color(
        light: Color(hex: 0x7C5CFF, alpha: 0.12),
        dark:  Color(hex: 0x7C5CFF, alpha: 0.18)
    )

    static let accentRing = Color(
        light: Color(hex: 0x7C5CFF, alpha: 0.30),
        dark:  Color(hex: 0x7C5CFF, alpha: 0.40)
    )

    /// Subtle hairline used on glass cards.
    static let border = Color(
        light: Color.black.opacity(0.10),
        dark:  Color.white.opacity(0.10)
    )

    /// Slightly stronger hairline used for selected / focused states.
    static let borderStrong = Color(
        light: Color.black.opacity(0.18),
        dark:  Color.white.opacity(0.18)
    )

    /// Hover background tint used on rows and list items.
    static let hoverFill = Color(
        light: Color.black.opacity(0.04),
        dark:  Color.white.opacity(0.04)
    )

    // MARK: - Radii

    static let rSm: CGFloat = 8
    static let rMd: CGFloat = 12
    static let rLg: CGFloat = 16
    static let rXl: CGFloat = 22
}

extension Color {
    /// 0xRRGGBB convenience init.
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >>  8) & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
