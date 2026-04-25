import SwiftUI
import AppKit
import Quartz
import Core

@MainActor
final class LargeFilesModel: ObservableObject {
    @Published var root: URL = URL(fileURLWithPath: NSHomeDirectory())
    @Published var minSizeMB: Double = 100
    @Published var olderThanDays: Int = 0       // 0 = no age filter
    @Published var entries: [FileEntry] = []
    @Published var selection: Set<URL> = []
    @Published var isScanning = false
    @Published var actionMessage: String?
    @Published var lastUndoToken: UndoToken?

    private let scanner = LargeFileScanner()
    private let deletion = DeletionService.shared
    private var task: Task<Void, Never>?

    func pickRoot() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = root
        if panel.runModal() == .OK, let url = panel.url { root = url }
    }

    func scan() {
        task?.cancel()
        isScanning = true
        // Don't wipe the message while an Undo banner is still active.
        if lastUndoToken == nil { actionMessage = nil }
        let q = LargeFileQuery(
            root: root,
            minSize: UInt64(minSizeMB * 1024 * 1024),
            olderThanDays: olderThanDays > 0 ? olderThanDays : nil
        )
        task = Task { [scanner] in
            let result = await scanner.scan(q)
            await MainActor.run {
                self.entries = result
                self.selection.removeAll()
                self.isScanning = false
            }
        }
    }

    func cancel() {
        task?.cancel()
        isScanning = false
    }

    func quickLookSelection() {
        guard !selection.isEmpty else { return }
        let urls = entries.filter { selection.contains($0.url) }.map(\.url)
        QuickLookCoordinator.shared.show(urls: urls)
    }

    func trashSelection() {
        let urls = entries.filter { selection.contains($0.url) }.map(\.url)
        guard !urls.isEmpty else { return }
        Task { [deletion] in
            do {
                let result = try await deletion.trashWithFailures(urls: urls, source: .largeFiles)
                await MainActor.run {
                    self.lastUndoToken = result.token
                    var msg = "Moved \(byteString(result.token.totalBytes))"
                    if !result.failures.isEmpty {
                        msg += " — \(result.failures.count) skipped (permission denied)"
                    }
                    self.actionMessage = msg
                }
                self.scan()
            } catch {
                await MainActor.run { self.actionMessage = "Trash failed: \(error)" }
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
                self.scan()
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

    var totalSelectedBytes: UInt64 {
        entries.filter { selection.contains($0.url) }
               .reduce(UInt64(0)) { $0 &+ $1.size }
    }
}

struct LargeFilesView: View {
    @StateObject private var model = LargeFilesModel()
    @StateObject private var gate = LicenseGate.shared
    @State private var sortOrder: [KeyPathComparator<FileEntry>] = [
        .init(\.size, order: .reverse)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            controls
            Divider()
            table
            if model.lastUndoToken != nil { undoBanner }
            footer
        }
        .padding(20)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "folder").foregroundStyle(.secondary)
                Text(model.root.path).font(.body.monospaced()).lineLimit(1).truncationMode(.middle)
                Spacer()
                Button("Choose Folder…") { model.pickRoot() }
            }
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Text("Min size:")
                    Slider(value: $model.minSizeMB, in: 10...2000, step: 10)
                        .frame(width: 180)
                    Text("\(Int(model.minSizeMB)) MB").font(.callout.monospacedDigit())
                        .frame(width: 64, alignment: .trailing)
                }
                HStack(spacing: 6) {
                    Text("Older than:")
                    Picker("", selection: $model.olderThanDays) {
                        Text("Any").tag(0)
                        Text("30 days").tag(30)
                        Text("180 days").tag(180)
                        Text("1 year").tag(365)
                    }
                    .labelsHidden().frame(width: 110)
                }
                Spacer()
                if model.isScanning {
                    Button("Cancel") { model.cancel() }
                } else {
                    Button("Scan") { model.scan() }.buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var table: some View {
        Table(sortedEntries, selection: $model.selection, sortOrder: $sortOrder) {
            TableColumn("Name") { entry in
                HStack {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: entry.url.path))
                        .resizable().frame(width: 16, height: 16)
                    Text(entry.url.lastPathComponent).lineLimit(1)
                }
            }
            .width(min: 200, ideal: 280)

            TableColumn("Size", value: \.size) { entry in
                Text(byteString(entry.size)).font(.body.monospacedDigit())
            }
            .width(80)

            TableColumn("Modified", value: \.modifiedSortKey) { entry in
                Text(entry.modifiedAt.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "—")
                    .font(.callout)
            }
            .width(110)

            TableColumn("Type") { entry in
                Text(entry.fileExtension.isEmpty ? "folder" : entry.fileExtension)
                    .font(.callout).foregroundStyle(.secondary)
            }
            .width(80)

            TableColumn("Path") { entry in
                Text(entry.url.deletingLastPathComponent().path)
                    .font(.caption.monospaced()).foregroundStyle(.secondary)
                    .lineLimit(1).truncationMode(.middle)
            }
        }
        .frame(maxHeight: .infinity)
        .overlay {
            if model.isScanning && model.entries.isEmpty {
                ProgressView("Scanning…")
            } else if !model.isScanning && model.entries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle).foregroundStyle(.secondary)
                    Text("No matches").bold()
                    Text("Pick a folder and scan.").foregroundStyle(.secondary)
                }
            }
        }
    }

    private var sortedEntries: [FileEntry] {
        model.entries.sorted(using: sortOrder)
    }

    private var footer: some View {
        HStack {
            Text("\(model.entries.count) files · selected: ")
                .foregroundStyle(.secondary)
            Text(byteString(model.totalSelectedBytes))
                .font(.body.monospacedDigit().bold())
            Spacer()
            Button("Quick Look") { model.quickLookSelection() }
                .disabled(model.selection.isEmpty)
            Button("Move to Trash") { model.trashSelection() }
                .buttonStyle(.borderedProminent)
                .disabled(model.selection.isEmpty || !gate.canCleanNow)
        }
        .task { await gate.refresh() }
    }

    private var undoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.uturn.backward.circle").foregroundStyle(.green)
            Text(model.actionMessage ?? "Files staged in trash").font(.callout)
            Spacer()
            Button("Undo") { model.undoLast() }
            Button("Dismiss") { model.dismissUndo() }.buttonStyle(.bordered)
        }
        .padding(10)
        .background(.green.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
    }
}

private extension FileEntry {
    /// `Date?` doesn't conform to `Comparable`. Map missing dates to distant past
    /// so they sort to the bottom under the default ascending order.
    var modifiedSortKey: Date { modifiedAt ?? .distantPast }
}

private func byteString(_ bytes: UInt64) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
}

// MARK: - Quick Look

/// Bridges the AppKit `QLPreviewPanel` singleton — the only Quick Look API that
/// can present an inline panel on macOS — to a Swifty array-of-URLs datasource.
@MainActor
final class QuickLookCoordinator: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    static let shared = QuickLookCoordinator()
    private var urls: [URL] = []

    func show(urls: [URL]) {
        self.urls = urls
        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.delegate = self
        panel.makeKeyAndOrderFront(nil)
        panel.reloadData()
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int { urls.count }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        urls[index] as NSURL
    }
}
