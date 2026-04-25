import SwiftUI
import Core

@MainActor
final class SmartScanModel: ObservableObject {
    @Published var results: [RuleScanResult] = []
    @Published var selected: Set<String> = []     // ruleIDs the user has checked
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var loadError: String?
    @Published var totalReclaimable: UInt64 = 0
    @Published var lastScannedAt: Date?
    @Published var lastUndoToken: UndoToken?
    @Published var actionMessage: String?

    private let engine = ScanEngine()
    private let deletion = DeletionService.shared
    private var scanTask: Task<Void, Never>?

    func scan() {
        scanTask?.cancel()
        guard let pack = loadBundledPack() else { return }
        isScanning = true
        results = []
        // Clear any lingering "Permanently removed …" / "Restored …" line from
        // the previous action so the post-scan UI starts clean.
        if lastUndoToken == nil { actionMessage = nil }
        scanTask = Task { [engine] in
            let scanned = await engine.scan(pack: pack)
            await MainActor.run {
                self.results = scanned
                // Default-check rules tagged `.safe`.
                self.selected = Set(scanned.filter { $0.safety == .safe }.map(\.ruleID))
                self.recomputeTotal()
                self.lastScannedAt = Date()
                self.isScanning = false
            }
        }
    }

    func cancel() {
        scanTask?.cancel()
        isScanning = false
    }

    /// Move every URL from currently-selected, non-helper, non-empty rules to
    /// the staging trash. Surfaces an undo token until the user dismisses it
    /// or a new clean replaces it.
    func cleanSelected() {
        let urls = results
            .filter { selected.contains($0.ruleID) && !$0.requiresHelper && !$0.items.isEmpty }
            .flatMap { $0.items.map(\.url) }
        guard !urls.isEmpty else { return }
        isCleaning = true
        actionMessage = nil
        Task { [deletion] in
            do {
                let result = try await deletion.trashWithFailures(urls: urls, source: .smartScan)
                let token = result.token
                let skipped = result.failures.count
                await MainActor.run {
                    self.lastUndoToken = token
                    var msg = "Moved \(formattedSize(token.totalBytes))"
                    if skipped > 0 {
                        msg += " — \(skipped) item\(skipped == 1 ? "" : "s") skipped (permission denied)"
                    }
                    self.actionMessage = msg
                    self.isCleaning = false
                }
                // Rescan so the cleaned rows zero out.
                self.scan()
            } catch {
                await MainActor.run {
                    self.actionMessage = "Clean failed: \(error)"
                    self.isCleaning = false
                }
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
                    self.actionMessage = "Restored \(formattedSize(token.totalBytes))"
                }
                self.scan()
            } catch {
                await MainActor.run {
                    self.actionMessage = "Undo failed: \(error)"
                }
            }
        }
    }

    func dismissUndo() {
        guard let token = lastUndoToken else { return }
        Task { [deletion] in
            try? await deletion.empty(token)
            await MainActor.run {
                self.lastUndoToken = nil
                self.actionMessage = "Permanently removed \(formattedSize(token.totalBytes))"
            }
        }
    }

    func toggle(ruleID: String) {
        if selected.contains(ruleID) { selected.remove(ruleID) } else { selected.insert(ruleID) }
        recomputeTotal()
    }

    private func recomputeTotal() {
        totalReclaimable = results
            .filter { selected.contains($0.ruleID) }
            .reduce(UInt64(0)) { $0 &+ $1.totalSize }
    }

    private func loadBundledPack() -> RulePack? {
        do {
            return try RulePackLoader.loadBundled()
        } catch RulePackLoader.LoadError.bundledResourceMissing {
            loadError = "Bundled rule pack missing"
            return nil
        } catch {
            loadError = "Decode failed: \(error)"
            return nil
        }
    }
}

struct SmartScanView: View {
    @StateObject private var model = SmartScanModel()
    @StateObject private var gate = LicenseGate.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            if let err = model.loadError {
                Text(err).foregroundStyle(.red)
            }
            if model.isScanning && model.results.isEmpty {
                ProgressView("Scanning…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if model.results.isEmpty {
                emptyState
            } else {
                resultsList
            }
            Spacer(minLength: 0)
            if model.lastUndoToken != nil { undoBanner }
            if let msg = model.actionMessage, model.lastUndoToken == nil {
                Text(msg).font(.caption).foregroundStyle(.secondary)
            }
            footer
        }
        .padding(20)
        .onAppear {
            if model.results.isEmpty && !model.isScanning { model.scan() }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Smart Scan").font(.title2).bold()
                if let last = model.lastScannedAt {
                    Text("Last scanned \(last.formatted(date: .omitted, time: .standard))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if model.isScanning {
                Button("Cancel") { model.cancel() }
            } else {
                Button("Rescan") { model.scan() }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(.secondary)
            Text("Click Rescan to find junk").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultsList: some View {
        List {
            ForEach(groupedByCategory(), id: \.0) { category, rules in
                Section(category.displayName) {
                    ForEach(rules) { result in
                        RuleRow(
                            result: result,
                            isSelected: model.selected.contains(result.ruleID),
                            onToggle: { model.toggle(ruleID: result.ruleID) }
                        )
                    }
                }
            }
        }
        .listStyle(.inset)
    }

    private var footer: some View {
        HStack {
            Text("Reclaimable: ")
                .foregroundStyle(.secondary)
            Text(formattedSize(model.totalReclaimable))
                .font(.title3.monospacedDigit().bold())
            Spacer()
            if !gate.canCleanNow {
                Text(gate.lockReason).font(.caption).foregroundStyle(.red)
            }
            Button(model.isCleaning ? "Cleaning…" : "Clean Selected") {
                model.cleanSelected()
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.totalReclaimable == 0 || model.isCleaning || !gate.canCleanNow)
        }
        .task { await gate.refresh() }
    }

    private var undoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.uturn.backward.circle")
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(model.actionMessage ?? "Files staged in trash")
                    .font(.callout)
                Text("Undo to restore, or dismiss to permanently delete.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Undo") { model.undoLast() }
            Button("Dismiss") { model.dismissUndo() }
                .buttonStyle(.bordered)
        }
        .padding(10)
        .background(.green.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
    }

    private func groupedByCategory() -> [(RulePack.Category, [RuleScanResult])] {
        let grouped = Dictionary(grouping: model.results, by: \.category)
        return RulePack.Category.allOrdered
            .compactMap { cat in grouped[cat].map { (cat, $0) } }
    }
}

private struct RuleRow: View {
    let result: RuleScanResult
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Toggle("", isOn: Binding(get: { isSelected }, set: { _ in onToggle() }))
                .labelsHidden()
                .disabled(result.requiresHelper || result.totalSize == 0)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(result.displayName).font(.body)
                    SafetyBadge(safety: result.safety)
                    if result.requiresHelper {
                        Text("Requires helper")
                            .font(.caption2).foregroundStyle(.orange)
                    }
                }
                if let err = result.error {
                    Text(err).font(.caption).foregroundStyle(.red)
                } else if result.requiresHelper {
                    Text("Approve the privileged helper to scan this category")
                        .font(.caption).foregroundStyle(.secondary)
                } else if result.items.isEmpty {
                    Text("Nothing to clean").font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("\(result.items.count) item\(result.items.count == 1 ? "" : "s")")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(formattedSize(result.totalSize))
                .font(.body.monospacedDigit())
                .foregroundStyle(result.totalSize == 0 ? .secondary : .primary)
        }
        .padding(.vertical, 2)
    }
}

private struct SafetyBadge: View {
    let safety: RulePack.Safety
    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6).padding(.vertical, 1)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }
    private var label: String {
        switch safety {
        case .safe: return "Safe"
        case .reviewRecommended: return "Review"
        case .destructive: return "Destructive"
        }
    }
    private var color: Color {
        switch safety {
        case .safe: return .green
        case .reviewRecommended: return .orange
        case .destructive: return .red
        }
    }
}

private func formattedSize(_ bytes: UInt64) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
}

extension RulePack.Category {
    static var allOrdered: [RulePack.Category] {
        [.caches, .logs, .developer, .browser, .mail, .trash, .uninstaller, .other]
    }
    var displayName: String {
        switch self {
        case .caches: return "Caches"
        case .logs: return "Logs"
        case .developer: return "Developer"
        case .browser: return "Browsers"
        case .mail: return "Mail"
        case .trash: return "Trash"
        case .uninstaller: return "Uninstaller"
        case .other: return "Other"
        }
    }
}
