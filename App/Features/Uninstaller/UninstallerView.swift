import SwiftUI
import AppKit
import Core

@MainActor
final class UninstallerModel: ObservableObject {
    @Published var apps: [AppRecord] = []
    @Published var selectedApp: AppRecord?
    @Published var leftovers: [Leftover] = []
    @Published var checkedLeftovers: Set<URL> = []
    @Published var includeBundle = true
    @Published var isLoadingApps = false
    @Published var isLoadingLeftovers = false
    @Published var actionMessage: String?
    @Published var lastUndoToken: UndoToken?

    private let discovery = AppDiscovery()
    private let finder = LeftoverFinder()
    private let deletion = DeletionService.shared

    func loadApps() {
        isLoadingApps = true
        Task { [discovery] in
            let list = await discovery.listInstalledApps()
            await MainActor.run {
                self.apps = list
                self.isLoadingApps = false
            }
        }
    }

    func select(_ app: AppRecord?) {
        selectedApp = app
        leftovers = []
        checkedLeftovers = []
        guard let app else { return }
        isLoadingLeftovers = true
        Task { [finder] in
            let found = await finder.leftovers(forBundleID: app.bundleID, appName: app.name)
            await MainActor.run {
                self.leftovers = found.sorted { $0.size > $1.size }
                // Default-check user-space leftovers (helper-required ones stay off in $0 mode).
                self.checkedLeftovers = Set(found
                    .filter { !$0.requiresHelper }
                    .map(\.url))
                self.isLoadingLeftovers = false
            }
        }
    }

    func toggle(leftover: Leftover) {
        if leftover.requiresHelper { return }   // gated until Developer ID is in place
        if checkedLeftovers.contains(leftover.url) {
            checkedLeftovers.remove(leftover.url)
        } else {
            checkedLeftovers.insert(leftover.url)
        }
    }

    var totalSelectedBytes: UInt64 {
        var total: UInt64 = 0
        if includeBundle, let app = selectedApp { total &+= app.size }
        for l in leftovers where checkedLeftovers.contains(l.url) {
            total &+= l.size
        }
        return total
    }

    func uninstall() {
        guard let app = selectedApp else { return }
        var urls: [URL] = []
        if includeBundle { urls.append(app.bundleURL) }
        urls.append(contentsOf: leftovers
            .filter { checkedLeftovers.contains($0.url) && !$0.requiresHelper }
            .map(\.url))
        guard !urls.isEmpty else { return }

        Task { [deletion] in
            do {
                let result = try await deletion.trashWithFailures(urls: urls, source: .uninstaller)
                await MainActor.run {
                    self.lastUndoToken = result.token
                    var msg = "Uninstalled \(app.name) — moved \(byteString(result.token.totalBytes))"
                    if !result.failures.isEmpty {
                        msg += " (\(result.failures.count) skipped)"
                    }
                    self.actionMessage = msg
                }
                self.loadApps()
                await MainActor.run { self.selectedApp = nil; self.leftovers = [] }
            } catch {
                await MainActor.run { self.actionMessage = "Uninstall failed: \(error)" }
            }
        }
    }

    func undoLast() {
        guard let token = lastUndoToken else { return }
        Task { [deletion] in
            do {
                try await deletion.undo(token)
                await MainActor.run {
                    self.lastUndoToken = nil
                    self.actionMessage = "Restored \(byteString(token.totalBytes))"
                }
                self.loadApps()
            } catch {
                await MainActor.run { self.actionMessage = "Undo failed: \(error)" }
            }
        }
    }

    func dismissUndo() {
        guard let token = lastUndoToken else { return }
        Task { [deletion] in
            try? await deletion.empty(token)
            await MainActor.run {
                self.lastUndoToken = nil
                self.actionMessage = nil
            }
        }
    }
}

struct UninstallerView: View {
    @StateObject private var model = UninstallerModel()
    @StateObject private var gate = LicenseGate.shared

    var body: some View {
        HSplitView {
            appList
                .frame(minWidth: 280, idealWidth: 320)
            detail
                .frame(minWidth: 380)
        }
        .onAppear { if model.apps.isEmpty { model.loadApps() } }
    }

    private var appList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Installed Apps").font(.headline)
                Spacer()
                Button {
                    model.loadApps()
                } label: { Image(systemName: "arrow.clockwise") }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            Divider()
            if model.isLoadingApps && model.apps.isEmpty {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(model.apps, selection: Binding(
                    get: { model.selectedApp?.id },
                    set: { newID in
                        model.select(model.apps.first(where: { $0.id == newID }))
                    }
                )) { app in
                    AppRow(app: app).tag(app.id)
                }
                .listStyle(.inset)
            }
        }
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let app = model.selectedApp {
                detailHeader(app: app)
                Divider()
                if model.isLoadingLeftovers {
                    ProgressView("Finding leftovers…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    leftoversList
                }
                if model.lastUndoToken != nil { undoBanner }
                footer(app: app)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "trash.square")
                        .font(.largeTitle).foregroundStyle(.secondary)
                    Text("Select an app to uninstall").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(20)
    }

    private func detailHeader(app: AppRecord) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: app.bundleURL.path))
                .resizable().frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name).font(.title3.bold())
                Text(app.bundleID).font(.caption.monospaced()).foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    if let v = app.version {
                        Text("v\(v)").font(.caption).foregroundStyle(.secondary)
                    }
                    Text(byteString(app.size)).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private var leftoversList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Toggle("Include the application bundle itself",
                       isOn: $model.includeBundle)
                    .padding(.bottom, 8)

                if model.leftovers.isEmpty {
                    Text("No leftovers found.").foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }

                ForEach(grouped(), id: \.0) { category, items in
                    Section {
                        ForEach(items) { leftover in
                            LeftoverRow(
                                leftover: leftover,
                                isChecked: model.checkedLeftovers.contains(leftover.url),
                                onToggle: { model.toggle(leftover: leftover) }
                            )
                        }
                    } header: {
                        HStack(spacing: 6) {
                            Text(category.displayName).font(.subheadline.weight(.semibold))
                            if category.requiresHelper {
                                Text("Requires helper")
                                    .font(.caption2)
                                    .padding(.horizontal, 6).padding(.vertical, 1)
                                    .background(.orange.opacity(0.18), in: Capsule())
                                    .foregroundStyle(.orange)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private func grouped() -> [(LeftoverCategory, [Leftover])] {
        let dict = Dictionary(grouping: model.leftovers, by: \.category)
        return LeftoverCategory.allCases
            .compactMap { c in dict[c].map { (c, $0) } }
    }

    private func footer(app: AppRecord) -> some View {
        HStack {
            Text("Will reclaim: ").foregroundStyle(.secondary)
            Text(byteString(model.totalSelectedBytes))
                .font(.body.monospacedDigit().bold())
            Spacer()
            Button("Uninstall \(app.name)") { model.uninstall() }
                .buttonStyle(.borderedProminent)
                .disabled(model.totalSelectedBytes == 0 || !gate.canCleanNow)
        }
    }

    private var undoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.uturn.backward.circle").foregroundStyle(.green)
            Text(model.actionMessage ?? "Uninstalled — staged in trash").font(.callout)
            Spacer()
            Button("Undo") { model.undoLast() }
            Button("Dismiss") { model.dismissUndo() }.buttonStyle(.bordered)
        }
        .padding(10)
        .background(.green.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct AppRow: View {
    let app: AppRecord
    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: app.bundleURL.path))
                .resizable().frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(app.name).lineLimit(1)
                Text(byteString(app.size))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

private struct LeftoverRow: View {
    let leftover: Leftover
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Toggle("", isOn: Binding(get: { isChecked }, set: { _ in onToggle() }))
                .labelsHidden()
                .disabled(leftover.requiresHelper)
            VStack(alignment: .leading, spacing: 1) {
                Text(leftover.url.lastPathComponent).font(.body).lineLimit(1)
                Text(leftover.url.deletingLastPathComponent().path)
                    .font(.caption.monospaced()).foregroundStyle(.secondary)
                    .lineLimit(1).truncationMode(.middle)
            }
            Spacer()
            Text(byteString(leftover.size))
                .font(.callout.monospacedDigit())
                .foregroundStyle(leftover.requiresHelper ? .secondary : .primary)
        }
        .padding(.vertical, 2)
    }
}

private func byteString(_ bytes: UInt64) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
}
