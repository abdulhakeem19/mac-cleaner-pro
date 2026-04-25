import SwiftUI
import Core

struct ContentView: View {
    @State private var bundledPackStatus: String = "Loading…"

    var body: some View {
        NavigationSplitView {
            List {
                Label("Smart Scan", systemImage: "sparkles")
                Label("Large & Old Files", systemImage: "doc.text.magnifyingglass")
                Label("App Uninstaller", systemImage: "trash.square")
                Label("Activity Log", systemImage: "clock.arrow.circlepath")
            }
            .listStyle(.sidebar)
            .navigationTitle("Mac Cleaner Pro")
        } detail: {
            VStack(alignment: .leading, spacing: 16) {
                Text("Welcome to Mac Cleaner Pro")
                    .font(.largeTitle).bold()
                Text("Bundled rule pack: \(bundledPackStatus)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .task { await loadBundledPack() }
    }

    private func loadBundledPack() async {
        guard let url = Bundle.main.url(forResource: "v1", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            bundledPackStatus = "missing"
            return
        }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let pack = try decoder.decode(RulePack.self, from: data)
            bundledPackStatus = "v\(pack.packVersion) — \(pack.rules.count) rules"
        } catch {
            bundledPackStatus = "decode failed: \(error)"
        }
    }
}

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Privacy") {
                Toggle("Send anonymous usage data", isOn: .constant(false))
                Toggle("Send crash reports", isOn: .constant(false))
            }
            Section("Updates") {
                Toggle("Check for updates automatically", isOn: .constant(true))
            }
        }
        .padding(24)
        .frame(width: 480, height: 280)
    }
}

#Preview {
    ContentView()
        .frame(width: 1000, height: 700)
}
