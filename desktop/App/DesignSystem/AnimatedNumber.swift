import SwiftUI

/// Tweens a Double to its target value when it changes — used for the
/// "Reclaimable: 6.36 GB" counter so the number rolls in instead of popping.
struct AnimatedByteCount: View, Animatable {
    var value: Double
    var font: Font = .system(size: 22, weight: .semibold).monospacedDigit()
    var color: Color = .primary

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        let bytes = max(0, Int64(value))
        Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .monospacedDigit()
    }
}
