import SwiftUI
import AppKit
import Core

@main
struct MacCleanerProApp: App {
    @State private var showOnboarding = !OnboardingState.hasCompleted

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView { showOnboarding = false }
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .help) {
                Button("Mac Cleaner Pro Help") {
                    if let url = URL(string: "https://maccleanerpro.app/help") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            CommandGroup(after: .appInfo) {
                Divider()
                Button("Buy License…") {
                    if let url = URL(string: "https://maccleanerpro.app/buy") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }

        Settings {
            SettingsView()
        }
    }
}
