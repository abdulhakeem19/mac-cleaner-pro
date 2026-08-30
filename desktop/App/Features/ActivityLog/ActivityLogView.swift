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
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                summaryCard
                if model.entries.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(model.entries) { e in
                            EntryRow(entry: e)
                        }
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { model.reload() }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            SectionHeader(
                eyebrow: "Audit trail",
                title: "Activity Log",
                subtitle: "Every clean, undo, and empty — yours to review."
            )
            Spacer()
            Button {
                model.reload()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(SoftButtonStyle())
            Button("Clear") { model.clearAll() }
                .buttonStyle(SoftButtonStyle())
                .disabled(model.entries.isEmpty)
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.brandGradient)
                    .frame(width: 56, height: 56)
                    .shadow(color: Theme.accentRing, radius: 14, y: 6)
                Image(systemName: "internaldrive")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Lifetime reclaimed")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                AnimatedByteCount(
                    value: Double(model.totalReclaimed),
                    font: .system(size: 30, weight: .semibold).monospacedDigit()
                )
                .animation(.easeInOut(duration: 0.5), value: model.totalReclaimed)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(model.entries.count) entries")
                    .font(.system(size: 13, weight: .medium))
                Text("All on your Mac, nothing uploaded.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .glassCard(padded: false)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.accentSoft)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Theme.accentRing, lineWidth: 1)
                        )
                        .frame(width: 52, height: 52)
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nothing logged yet")
                        .font(.system(size: 16, weight: .semibold))
                        .tracking(-0.2)
                    Text("Every clean, undo, and empty will appear here — fully on-device.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Three example rows, dimmed
            VStack(spacing: 8) {
                EmptyExampleRow(icon: "sparkles",            color: Theme.accent, label: "Cleaned 12 items · Smart Scan",       weight: "—")
                EmptyExampleRow(icon: "arrow.uturn.backward", color: Theme.ok,     label: "Restored 3 items · Smart Scan",       weight: "—")
                EmptyExampleRow(icon: "xmark.bin",           color: Theme.bad,    label: "Permanently removed 2 items · Manual",weight: "—")
            }
            .opacity(0.45)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(22)
        .glassCard(padded: false)
    }
}

private struct EntryRow: View {
    let entry: ActivityEntry
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.14))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(headline)
                    .font(.system(size: 13, weight: .medium))
                Text(entry.timestamp.formatted(date: .abbreviated, time: .standard))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Text(byteString(entry.bytes))
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundStyle(entry.kind == .undo ? .secondary : .primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
    }
    private var icon: String {
        switch entry.kind {
        case .clean: return "sparkles"
        case .undo:  return "arrow.uturn.backward"
        case .empty: return "xmark.bin"
        case .freed: return "memorychip"
        }
    }
    private var color: Color {
        switch entry.kind {
        case .clean: return Theme.accent
        case .undo:  return Theme.ok
        case .empty: return Theme.bad
        case .freed: return Theme.accent2
        }
    }
    private var headline: String {
        let verb: String
        switch entry.kind {
        case .clean: verb = "Cleaned"
        case .undo:  verb = "Restored"
        case .empty: verb = "Permanently removed"
        case .freed:
            let where_ = sourceLabel(entry.source)
            if entry.itemCount > 0 {
                return "Freed memory · quit \(entry.itemCount) app\(entry.itemCount == 1 ? "" : "s") · \(where_)"
            }
            return "Freed memory · \(where_)"
        }
        let where_ = sourceLabel(entry.source)
        return "\(verb) \(entry.itemCount) item\(entry.itemCount == 1 ? "" : "s") · \(where_)"
    }
    private func sourceLabel(_ s: ActivityEntry.Source) -> String {
        switch s {
        case .smartScan:        return "Smart Scan"
        case .largeFiles:       return "Large Files"
        case .duplicateFinder:  return "Duplicates"
        case .uninstaller:      return "Uninstaller"
        case .manual:           return "Manual"
        case .system:           return "System"
        case .memoryManager:    return "Memory"
        case .developerJunk:    return "Developer Junk"
        }
    }
}

/// Faint preview row shown on the empty state so users immediately understand
/// what the log will look like once they start cleaning.
private struct EmptyExampleRow: View {
    let icon: String
    let color: Color
    let label: String
    let weight: String
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.14))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.system(size: 12))
            Spacer()
            Text(weight)
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Theme.border.opacity(0.6), lineWidth: 1)
        )
    }
}

private func byteString(_ bytes: UInt64) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
}
