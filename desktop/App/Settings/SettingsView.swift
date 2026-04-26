import SwiftUI
import AppKit
import Core

@MainActor
final class SettingsModel: ObservableObject {
    @Published var licenseKey: String = ""
    @Published var licenseState: LicenseManager.State = .trial(daysRemaining: 14)
    @AppStorage("MacCleanerPro.telemetryEnabled") var telemetryEnabled = false
    @AppStorage("MacCleanerPro.crashReportsEnabled") var crashReportsEnabled = false
    @AppStorage("MacCleanerPro.autoUpdateEnabled") var autoUpdateEnabled = true

    init() { refresh() }

    func refresh() {
        Task {
            let state = await LicenseManager.shared.currentState()
            await MainActor.run {
                self.licenseState = state
                if case .pro(let key) = state { self.licenseKey = key }
            }
        }
    }

    func applyLicenseKey() {
        let key = licenseKey
        Task {
            let state = await LicenseManager.shared.setLicenseKey(key)
            await MainActor.run { self.licenseState = state }
        }
    }

    func clearLicense() {
        Task {
            let state = await LicenseManager.shared.clearLicense()
            await MainActor.run { self.licenseState = state; self.licenseKey = "" }
        }
    }

    func resetOnboarding() {
        OnboardingState.reset()
    }

    func revealActivityLog() {
        let url = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/MacCleanerPro")
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

// MARK: - Settings view

struct SettingsView: View {
    @StateObject private var model = SettingsModel()
    @EnvironmentObject private var theme: ThemeManager

    private var isTrialOrExpired: Bool {
        switch model.licenseState {
        case .trial, .expired: return true
        case .pro: return false
        }
    }

    @ViewBuilder private var buyLicenseButton: some View {
        Button {
            if let url = URL(string: "https://maccleanerpro.com/pricing/") {
                NSWorkspace.shared.open(url)
            }
        } label: {
            Label("Buy License", systemImage: "arrow.up.right")
                .font(.system(size: 12, weight: .semibold))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SectionHeader(
                    eyebrow: "Preferences",
                    title: "Settings",
                    subtitle: "Personalize how Mac Cleaner Pro looks, behaves, and reports."
                )

                appearanceCard
                licenseCard
                privacyCard
                advancedCard
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Cards

    private var appearanceCard: some View {
        SettingsCard(icon: "paintbrush.pointed.fill",
                     title: "Appearance",
                     subtitle: "Pick a theme. Default is light, matching the website.") {
            HStack(spacing: 8) {
                ForEach(Appearance.allCases) { mode in
                    AppearanceTile(
                        mode: mode,
                        isSelected: theme.appearance == mode,
                        action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                theme.appearance = mode
                            }
                        }
                    )
                }
            }
        }
    }

    private var licenseCard: some View {
        SettingsCard(icon: "key.fill",
                     title: "License",
                     subtitle: "Pay-once. No subscription.") {
            VStack(alignment: .leading, spacing: 14) {
                LicenseStateBadge(state: model.licenseState)

                VStack(alignment: .leading, spacing: 6) {
                    Text("License key")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.0)
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                    TextField("MCP-XXXXXXXXXXXX", text: $model.licenseKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Theme.border, lineWidth: 1)
                        )
                }

                HStack(spacing: 8) {
                    Button("Apply") { model.applyLicenseKey() }
                        .buttonStyle(GradientButtonStyle(disabled: model.licenseKey.isEmpty))
                        .disabled(model.licenseKey.isEmpty)
                    Button("Clear") { model.clearLicense() }
                        .buttonStyle(SoftButtonStyle())
                    Spacer()
                    Group {
                        if isTrialOrExpired {
                            buyLicenseButton.buttonStyle(GradientButtonStyle())
                        } else {
                            buyLicenseButton.buttonStyle(SoftButtonStyle())
                        }
                    }
                }

                Text("Payments processed by Paddle.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var privacyCard: some View {
        SettingsCard(icon: "lock.shield.fill",
                     title: "Privacy",
                     subtitle: "Both are off by default. Nothing leaves your Mac.") {
            VStack(spacing: 0) {
                ToggleRow(
                    label: "Send anonymous usage data",
                    sub: "No file paths, contents, or identifiers.",
                    isOn: $model.telemetryEnabled
                )
                Divider().padding(.vertical, 4).opacity(0.3)
                ToggleRow(
                    label: "Send crash reports",
                    sub: "Helps us fix the rough edges.",
                    isOn: $model.crashReportsEnabled
                )
                Divider().padding(.vertical, 4).opacity(0.3)
                ToggleRow(
                    label: "Check for updates automatically",
                    sub: "Daily check, version + macOS version only.",
                    isOn: $model.autoUpdateEnabled
                )
            }
        }
    }

    private var advancedCard: some View {
        SettingsCard(icon: "wrench.and.screwdriver.fill",
                     title: "Advanced",
                     subtitle: "Power-user controls.") {
            VStack(spacing: 12) {
                AdvancedActionRow(
                    icon: "folder",
                    title: "Reveal Activity Log folder",
                    subtitle: "~/Library/Application Support/MacCleanerPro",
                    action: { model.revealActivityLog() }
                )
                AdvancedActionRow(
                    icon: "sparkles",
                    title: "Show onboarding on next launch",
                    subtitle: "Re-runs the welcome wizard next time you open the app.",
                    action: { model.resetOnboarding() }
                )
            }
        }
    }
}

// MARK: - Reusable bits

private struct SettingsCard<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.accentSoft)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.brandGradient)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            content
        }
        .padding(20)
        .glassCard(padded: false)
    }
}

private struct AppearanceTile: View {
    let mode: Appearance
    let isSelected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(preview)
                        .frame(height: 64)
                    Image(systemName: mode.systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? AnyShapeStyle(Theme.brandGradient)
                                                    : AnyShapeStyle(Color.secondary))
                }
                Text(mode.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Theme.accentSoft
                                     : (hovering ? Theme.hoverFill : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? Theme.accentRing : Theme.border,
                                  lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
    }

    private var preview: AnyShapeStyle {
        switch mode {
        case .light: return AnyShapeStyle(LinearGradient(
            colors: [Color(hex: 0xFFFFFF), Color(hex: 0xF1F3F9)],
            startPoint: .top, endPoint: .bottom))
        case .dark: return AnyShapeStyle(LinearGradient(
            colors: [Color(hex: 0x0E1016), Color(hex: 0x1A1E28)],
            startPoint: .top, endPoint: .bottom))
        case .system: return AnyShapeStyle(LinearGradient(
            colors: [Color(hex: 0xFFFFFF), Color(hex: 0x1A1E28)],
            startPoint: .leading, endPoint: .trailing))
        }
    }
}

private struct ToggleRow: View {
    let label: String
    let sub: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 13, weight: .medium))
                Text(sub).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.accent)
        }
        .padding(.vertical, 4)
    }
}

private struct AdvancedActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 13, weight: .medium))
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: Theme.rMd, style: .continuous)
                    .fill(hovering ? Theme.hoverFill : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

private struct LicenseStateBadge: View {
    let state: LicenseManager.State
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(badgeColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: badgeIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(badgeColor)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(badgeText)
                    .font(.system(size: 13, weight: .semibold))
                Text(badgeSub)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(badgeColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(badgeColor.opacity(0.30), lineWidth: 1)
        )
    }

    private var badgeColor: Color {
        switch state {
        case .trial: return Theme.warn
        case .pro: return Theme.ok
        case .expired: return Theme.bad
        }
    }
    private var badgeIcon: String {
        switch state {
        case .trial: return "hourglass"
        case .pro: return "checkmark.seal.fill"
        case .expired: return "exclamationmark.triangle.fill"
        }
    }
    private var badgeText: String {
        switch state {
        case .trial(let days): return "Trial — \(days) day\(days == 1 ? "" : "s") left"
        case .pro: return "Pro license"
        case .expired: return "Trial expired"
        }
    }
    private var badgeSub: String {
        switch state {
        case .trial: return "Full access while you decide."
        case .pro(let key): return redact(key)
        case .expired: return "Enter a license to continue cleaning."
        }
    }
    private func redact(_ key: String) -> String {
        guard key.count > 8 else { return key }
        return String(key.prefix(4)) + "…" + String(key.suffix(4))
    }
}
