import SwiftUI
import Core

@MainActor
final class ActivityLogModel: ObservableObject {
    @Published var entries: [ActivityEntry] = []
    @Published var totalReclaimed: UInt64 = 0

    func reload() {
        Task {
            let all = await ActivityLog.shared.all()
            await MainActor.run {
                self.entries = all
                self.totalReclaimed = all
                    .filter { $0.kind == .clean }
                    .reduce(UInt64(0)) { $0 &+ $1.bytes }
            }
        }
    }

    func clearAll() {
        Task {
            await ActivityLog.shared.clear()
            await MainActor.run { self.entries = []; self.totalReclaimed = 0 }
        }
    }
}

struct ActivityLogView: View {
    @StateObject private var model = ActivityLogModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Activity Log").font(.title2.bold())
                    Text("Lifetime reclaimed: \(byteString(model.totalReclaimed))")
                        .font(.callout).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Refresh") { model.reload() }
                Button("Clear") { model.clearAll() }
                    .disabled(model.entries.isEmpty)
            }
            Divider()
            if model.entries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle).foregroundStyle(.secondary)
                    Text("No activity yet").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(model.entries) { e in
                    EntryRow(entry: e)
                }
                .listStyle(.inset)
            }
        }
        .padding(20)
        .onAppear { model.reload() }
    }
}

private struct EntryRow: View {
    let entry: ActivityEntry
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(headline).font(.body)
                Text(entry.timestamp.formatted(date: .abbreviated, time: .standard))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(byteString(entry.bytes))
                .font(.callout.monospacedDigit())
                .foregroundStyle(entry.kind == .undo ? .secondary : .primary)
        }
        .padding(.vertical, 2)
    }
    private var icon: String {
        switch entry.kind {
        case .clean: return "trash"
        case .undo:  return "arrow.uturn.backward"
        case .empty: return "xmark.bin"
        }
    }
    private var color: Color {
        switch entry.kind {
        case .clean: return .blue
        case .undo:  return .green
        case .empty: return .red
        }
    }
    private var headline: String {
        let verb: String
        switch entry.kind {
        case .clean: verb = "Cleaned"
        case .undo:  verb = "Restored"
        case .empty: verb = "Permanently removed"
        }
        let where_ = sourceLabel(entry.source)
        return "\(verb) \(entry.itemCount) item\(entry.itemCount == 1 ? "" : "s") · \(where_)"
    }
    private func sourceLabel(_ s: ActivityEntry.Source) -> String {
        switch s {
        case .smartScan:   return "Smart Scan"
        case .largeFiles:  return "Large Files"
        case .uninstaller: return "Uninstaller"
        case .manual:      return "Manual"
        case .system:      return "System"
        }
    }
}

private func byteString(_ bytes: UInt64) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
}
