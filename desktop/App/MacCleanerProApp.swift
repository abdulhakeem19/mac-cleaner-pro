import SwiftUI
import AppKit
import Core

@main
struct MacCleanerProApp: App {
    @State private var showOnboarding = !OnboardingState.hasCompleted
    @StateObject private var theme = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 980, minHeight: 640)
                .environmentObject(theme)
                .preferredColorScheme(theme.appearance.colorScheme)
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView { showOnboarding = false }
                        .environmentObject(theme)
                        .preferredColorScheme(theme.appearance.colorScheme)
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .help) {
                Button("Mac Cleaner Pro Help") {
                    if let url = URL(string: "https://maccleanerpro.com/help") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            CommandGroup(after: .appInfo) {
                Divider()
                Button("Buy License…") {
                    if let url = URL(string: "https://maccleanerpro.com/buy") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            // Theme submenu under View, so Cmd+, → System Settings still works
            // and people who like keyboard nav can flip themes from the menu bar.
            CommandGroup(after: .toolbar) {
                Menu("Theme") {
                    ForEach(Appearance.allCases) { mode in
                        Button {
                            theme.appearance = mode
                        } label: {
                            HStack {
                                Image(systemName: mode.systemImage)
                                Text(mode.label)
                                if theme.appearance == mode {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
        }

        Settings {
            SettingsView()
                .environmentObject(theme)
                .preferredColorScheme(theme.appearance.colorScheme)
        }
    }
}
