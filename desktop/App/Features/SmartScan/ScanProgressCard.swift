import SwiftUI

// MARK: - Animated scanning card

/// Full-width card shown while SmartScan is running.
/// Progress values are simulated for display — real per-rule streaming
/// would require an AsyncStream API on ScanEngine (future work).
struct ScanProgressCard: View {
    @State private var arcProgress: Double = 0       // 0 → 1, drives arc fill
    @State private var displayPct: Double = 0        // 0 → 92, shown as Int in pill
    @State private var simulatedBytes: Double = 0
    @State private var activeRule: Int = 0

    private let rules: [(name: String, path: String)] = [
        ("Scanning user caches",    "~/Library/Caches/*"),
        ("Hashing Xcode artifacts", "~/Library/Developer/Xcode/DerivedData"),
        ("Browser caches",          "Chrome · Firefox · Safari"),
        ("User logs",               "~/Library/Logs/**"),
        ("App leftovers",           "~/Library/Application Support"),
        ("System caches",           "/Library/Caches/*"),
    ]

    private let stageBytes: [Double] = [
        3.0e9, 6.3e9, 6.42e9, 6.44e9, 7.1e9, 9.4e9,
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            headerRow
            arcMeter
            ruleList
        }
        .padding(24)
        .glassCard(padded: false)
        .task { await runAnimation() }
    }

    // MARK: Header

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("LIVE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Theme.accent)
                Text("Smart Scan in progress")
                    .font(.system(size: 16, weight: .semibold))
            }
            Spacer()
            HStack(spacing: 6) {
                PulsingDot(size: 7)
                Text("\(Int(displayPct))%")
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Theme.accentSoft)
            .clipShape(Capsule())
        }
    }

    // MARK: Arc meter

    private var arcMeter: some View {
        HStack {
            Spacer()
            ZStack {
                // Background track: 270° arc starting at ~8 o'clock
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Theme.accent.opacity(0.10),
                            style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(135))

                // Filled arc — grows with arcProgress
                Circle()
                    .trim(from: 0, to: max(0.001, 0.75 * arcProgress))
                    .stroke(
                        LinearGradient(
                            colors: [Theme.accent, Color(red: 0.04, green: 0.52, blue: 1.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))

                // Center label
                VStack(spacing: 3) {
                    AnimatedByteCount(
                        value: simulatedBytes,
                        font: .system(size: 30, weight: .bold).monospacedDigit()
                    )
                    .animation(.easeOut(duration: 1.2), value: simulatedBytes)
                    Text("SCANNED")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.8)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 190, height: 190)
            Spacer()
        }
    }

    // MARK: Rule list

    private var ruleList: some View {
        VStack(spacing: 0) {
            ForEach(Array(rules.enumerated()), id: \.offset) { i, rule in
                ScanRuleRow(
                    name: rule.name,
                    path: rule.path,
                    rowState: rowState(for: i),
                    bytes: i < activeRule ? stageBytes[min(i, stageBytes.count - 1)] : 0
                )
                if i < rules.count - 1 {
                    Divider()
                        .opacity(0.35)
                        .padding(.leading, 56)
                }
            }
        }
        .background(.ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: Theme.rLg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.rLg, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
    }

    // MARK: Animation

    private enum ScanPhase { case pending, active, done }

    private func rowState(for i: Int) -> ScanRuleRow.Phase {
        if i < activeRule { return .done }
        if i == activeRule { return .active }
        return .pending
    }

    private func runAnimation() async {
        let totalDuration: Double = 12.0
        let ruleInterval = totalDuration / Double(rules.count)  // 2 s per rule

        // Single smooth linear climb — never restarts, no flicker
        withAnimation(.linear(duration: totalDuration - 1.0)) {
            arcProgress    = 0.95
            displayPct     = 95
        }
        // Byte counter: one linear sweep from 0 to the final stage total
        withAnimation(.linear(duration: totalDuration - 0.8)) {
            simulatedBytes = stageBytes.last ?? 0
        }

        // Advance rule highlight every 2 s
        for i in 0 ..< rules.count {
            withAnimation(.easeOut(duration: 0.35)) { activeRule = i }
            try? await Task.sleep(for: .seconds(ruleInterval))
        }

        // Final completion burst: fill arc to 100 % and flash the pill
        withAnimation(.easeOut(duration: 0.9)) {
            arcProgress = 1.0
            displayPct  = 100
        }
        try? await Task.sleep(for: .seconds(0.45))
    }
}

// MARK: - Per-rule row

struct ScanRuleRow: View {
    enum Phase { case pending, active, done }

    let name: String
    let path: String
    let rowState: Phase
    let bytes: Double

    var body: some View {
        HStack(spacing: 14) {
            // State indicator
            ZStack {
                Circle()
                    .fill(dotBackground)
                    .frame(width: 32, height: 32)
                if rowState == .active {
                    PulsingDot(color: Theme.accent, size: 10)
                } else {
                    Circle()
                        .fill(rowState == .done
                              ? Theme.accent.opacity(0.45)
                              : Color.secondary.opacity(0.18))
                        .frame(width: 10, height: 10)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 13,
                                  weight: rowState == .active ? .semibold : .regular))
                    .foregroundStyle(rowState == .pending ? Color.secondary : Color.primary)
                Text(path)
                    .font(.system(size: 11).monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Group {
                if rowState == .done && bytes > 0 {
                    Text(ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file))
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                } else {
                    Text("—")
                        .font(.system(size: 13).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(rowState == .active ? Theme.accentSoft : Color.clear)
        .animation(.easeOut(duration: 0.22), value: rowState == .active)
    }

    private var dotBackground: Color {
        rowState == .pending ? Color.secondary.opacity(0.08) : Theme.accentSoft
    }
}
