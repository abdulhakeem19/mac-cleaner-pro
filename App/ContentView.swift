import SwiftUI
import Core

private enum SidebarItem: Hashable {
    case smartScan, largeFiles, uninstaller, activityLog
    #if DEBUG
    case helperSmokeTest
    #endif
}

struct ContentView: View {
    @State private var selection: SidebarItem? = .smartScan

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("Smart Scan", systemImage: "sparkles").tag(SidebarItem.smartScan)
                Label("Large & Old Files", systemImage: "doc.text.magnifyingglass").tag(SidebarItem.largeFiles)
                Label("App Uninstaller", systemImage: "trash.square").tag(SidebarItem.uninstaller)
                Label("Activity Log", systemImage: "clock.arrow.circlepath").tag(SidebarItem.activityLog)
                #if DEBUG
                Section("Developer") {
                    Label("Helper Smoke Test", systemImage: "stethoscope").tag(SidebarItem.helperSmokeTest)
                }
                #endif
            }
            .listStyle(.sidebar)
            .navigationTitle("Mac Cleaner Pro")
        } detail: {
            switch selection ?? .smartScan {
            case .smartScan:    SmartScanView()
            case .largeFiles:   LargeFilesView()
            case .uninstaller:  UninstallerView()
            case .activityLog:  ActivityLogView()
            #if DEBUG
            case .helperSmokeTest: HelperSmokeTestView()
            #endif
            }
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 1000, height: 700)
}
