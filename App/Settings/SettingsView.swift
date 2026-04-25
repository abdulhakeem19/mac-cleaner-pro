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

struct SettingsView: View {
    @StateObject private var model = SettingsModel()

    var body: some View {
        TabView {
            generalTab.tabItem { Label("General", systemImage: "gear") }
            licenseTab.tabItem { Label("License", systemImage: "key") }
            privacyTab.tabItem { Label("Privacy", systemImage: "hand.raised") }
            advancedTab.tabItem { Label("Advanced", systemImage: "wrench.and.screwdriver") }
        }
        .frame(width: 520, height: 360)
    }

    private var generalTab: some View {
        Form {
            Section("Updates") {
                Toggle("Check for updates automatically", isOn: $model.autoUpdateEnabled)
                Text("Auto-updates ship with the paid Apple Developer build. In this build, check the website manually.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(20)
    }

    private var licenseTab: some View {
        Form {
            Section("Status") {
                LicenseStateBadge(state: model.licenseState)
            }
            Section("License key") {
                TextField("MCP-XXXXXXXXXXXX", text: $model.licenseKey)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Apply") { model.applyLicenseKey() }
                        .disabled(model.licenseKey.isEmpty)
                    Button("Clear") { model.clearLicense() }
                    Spacer()
                }
                Text("Buy a license at maccleanerpro.app — payment is processed by Paddle.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(20)
    }

    private var privacyTab: some View {
        Form {
            Section("Telemetry") {
                Toggle("Send anonymous usage data", isOn: $model.telemetryEnabled)
                Toggle("Send crash reports", isOn: $model.crashReportsEnabled)
                Text("Both are off by default. No file paths, contents, or identifiers are ever sent.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(20)
    }

    private var advancedTab: some View {
        Form {
            Section("Activity Log") {
                Button("Reveal Activity Log Folder…") { model.revealActivityLog() }
            }
            Section("Onboarding") {
                Button("Show Onboarding Again on Next Launch") { model.resetOnboarding() }
            }
        }
        .padding(20)
    }
}

private struct LicenseStateBadge: View {
    let state: LicenseManager.State
    var body: some View {
        switch state {
        case .trial(let days):
            Label("Trial — \(days) day\(days == 1 ? "" : "s") left",
                  systemImage: "hourglass")
                .foregroundStyle(.orange)
        case .pro(let key):
            Label("Pro — \(redact(key))", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
        case .expired:
            Label("Trial expired — enter a license to continue cleaning",
                  systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }
    private func redact(_ key: String) -> String {
        guard key.count > 8 else { return key }
        return String(key.prefix(4)) + "…" + String(key.suffix(4))
    }
}
