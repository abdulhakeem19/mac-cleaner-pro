import SwiftUI

// MARK: - Glass card

private struct GlassCard: ViewModifier {
    var radius: CGFloat = Theme.rLg
    var padded: Bool = true
    func body(content: Content) -> some View {
        content
            .padding(padded ? 16 : 0)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.border, lineWidth: 1)
            )
    }
}

extension View {
    /// Applies the glass-card treatment used everywhere in the app.
    func glassCard(radius: CGFloat = Theme.rLg, padded: Bool = true) -> some View {
        modifier(GlassCard(radius: radius, padded: padded))
    }
}

// MARK: - Eyebrow (uppercase tracking + dot)

struct Eyebrow: View {
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            PulsingDot(size: 5)
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule().strokeBorder(Theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?

    init(eyebrow: String? = nil, title: String, subtitle: String? = nil) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let eyebrow {
                Eyebrow(text: eyebrow)
            }
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .tracking(-0.4)
            if let subtitle {
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Gradient (primary) button

struct GradientButtonStyle: ButtonStyle {
    var disabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(disabled
                          ? AnyShapeStyle(Color.gray.opacity(0.3))
                          : AnyShapeStyle(Theme.brandGradient))
            )
            .overlay(
                Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: disabled ? .clear : Theme.accentRing,
                    radius: configuration.isPressed ? 6 : 12,
                    y: configuration.isPressed ? 2 : 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75),
                       value: configuration.isPressed)
            .opacity(disabled ? 0.6 : 1.0)
    }
}

// MARK: - Soft (secondary) button

struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(.ultraThinMaterial)
            )
            .overlay(
                Capsule().strokeBorder(Theme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75),
                       value: configuration.isPressed)
    }
}

// MARK: - Safety / status chips

struct StatusChip: View {
    enum Kind { case safe, review, destructive, helper, info }
    let kind: Kind
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.14)))
            .overlay(Capsule().strokeBorder(color.opacity(0.34), lineWidth: 1))
    }

    private var color: Color {
        switch kind {
        case .safe:        return Theme.ok
        case .review:      return Theme.warn
        case .destructive: return Theme.bad
        case .helper:      return Theme.warn
        case .info:        return Theme.accent
        }
    }
}

// MARK: - Logo mark

struct LogoMark: View {
    var size: CGFloat = 22
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(Theme.brandGradient)
                .shadow(color: Theme.accentRing, radius: size * 0.4, y: size * 0.2)
            // Stylised sparkle / sweep cuts (mirrors the website mark)
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.55, weight: .bold))
                .foregroundStyle(.white)
                .opacity(0.95)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Gradient text

extension View {
    /// Apply the brand gradient as the foreground style (text only — equivalent
    /// to the marketing site's `.gradient-text` class).
    func brandGradientText() -> some View {
        self.foregroundStyle(Theme.brandGradient)
    }
}

// MARK: - Pulsing dot

/// Subtle breathing dot used in eyebrows and live indicators. Stays at base
/// opacity for users with reduced motion (system-respected).
struct PulsingDot: View {
    var color: Color = Theme.accent
    var size: CGFloat = 6
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: color.opacity(pulse ? 0.7 : 0.3), radius: pulse ? 6 : 3)
            .scaleEffect(pulse ? 1.15 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}
