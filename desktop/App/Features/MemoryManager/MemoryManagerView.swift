import SwiftUI
import AppKit
import Core

// MARK: - View Model

@MainActor
final class MemoryManagerModel: ObservableObject {

    // Live system stats
    @Published var stats: MemoryStats = MemoryStatsReader.snapshot()
    @Published var pressure: MemoryPressureLevel = .normal
    @Published var processes: [ProcessMemoryEntry] = []
    @Published var totalProcessCount: Int = 0
    @Published var selectedPIDs: Set<pid_t> = []

    // Action state
    @Published var isFreeing = false
    @Published var lastResult: FreeResult?
    @Published var actionMessage: String?

    // Settings
    @AppStorage("MCP-MemoryManager-AutoMode") var autoMode = false

    private var statsTimer: Task<Void, Never>?
    private var processTimer: Task<Void, Never>?
    private var pressureMonitor: PressureMonitor?
    private var lastAutoFire: Date = .distantPast

    // App-foreground tracking — pause refresh when window is backgrounded.
    @Published var isForeground = true

    func start() {
        attachPressureMonitor()
        startTimers()
    }

    func stop() {
        statsTimer?.cancel(); statsTimer = nil
        processTimer?.cancel(); processTimer = nil
        pressureMonitor?.stop(); pressureMonitor = nil
    }

    func setForeground(_ on: Bool) {
        guard isForeground != on else { return }
        isForeground = on
        if on { startTimers() } else {
            statsTimer?.cancel(); statsTimer = nil
            processTimer?.cancel(); processTimer = nil
        }
    }

    // MARK: Timers

    private func startTimers() {
        statsTimer?.cancel()
        processTimer?.cancel()

        statsTimer = Task { [weak self] in
            // 1Hz system stats refresh — cheap.
            while !Task.isCancelled {
                await MainActor.run {
                    self?.stats = MemoryStatsReader.snapshot()
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }

        processTimer = Task { [weak self] in
            // 2s process list refresh — matches Activity Monitor cadence.
            // Initial fetch happens immediately.
            while !Task.isCancelled {
                let snapshot = await ProcessInspector.shared.snapshot()
                await MainActor.run {
                    guard let self else { return }
                    self.processes = snapshot.entries
                    self.totalProcessCount = snapshot.totalCount
                    // Drop selections for PIDs that no longer exist.
                    let live = Set(snapshot.entries.map(\.id))
                    self.selectedPIDs.formIntersection(live)
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    // MARK: Pressure

    private func attachPressureMonitor() {
        pressureMonitor?.stop()
        let monitor = PressureMonitor { [weak self] level in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.pressure = level
                self.maybeAutoFire(level: level)
            }
        }
        monitor.start()
        pressureMonitor = monitor
    }

    private func maybeAutoFire(level: MemoryPressureLevel) {
        guard autoMode, level == .critical else { return }
        guard Date().timeIntervalSince(lastAutoFire) > 120 else { return }
        lastAutoFire = Date()
        Task { await self.runQuickFree(auto: true) }
    }

    // MARK: Actions

    func runQuickFree(auto: Bool = false) async {
        guard !isFreeing else { return }
        isFreeing = true
        actionMessage = auto ? "Auto: pressure critical — running Quick Free" : "Reclaiming memory…"
        let result = await MemoryFreer.shared.quickFree()
        await onFreeFinished(result, label: auto ? "Auto Quick Free" : "Quick Free")
    }

    func quitSelected(force: Bool = false) async {
        guard !isFreeing else { return }
        let pids = Array(selectedPIDs)
        guard !pids.isEmpty else { return }
        isFreeing = true
        actionMessage = "Quitting \(pids.count) app\(pids.count == 1 ? "" : "s") and reclaiming…"
        let result = await MemoryFreer.shared.quitAndFree(pids: pids, force: force)
        selectedPIDs.removeAll()
        await onFreeFinished(result, label: force ? "Force Quit + Free" : "Quit + Free")
    }

    private func onFreeFinished(_ result: FreeResult, label: String) async {
        let entry = ActivityEntry(
            kind: .freed,
            source: .memoryManager,
            bytes: result.reclaimedBytes,
            itemCount: result.processesTerminated,
            note: "\(label) · \(result.strategy)"
        )
        await ActivityLog.shared.append(entry)
        self.lastResult = result
        self.isFreeing = false
        self.stats = MemoryStatsReader.snapshot()
        self.actionMessage = format(result: result, label: label)
    }

    private func format(result: FreeResult, label: String) -> String {
        if let reason = result.skippedReason {
            return "\(label) skipped: \(reason)"
        }
        let f = ByteCountFormatter()
        f.countStyle = .memory
        f.allowedUnits = [.useGB, .useMB]
        var parts: [String] = []
        if result.processesTerminated > 0 {
            parts.append("\(result.processesTerminated) app\(result.processesTerminated == 1 ? "" : "s") quit")
        }
        if result.reclaimedBytes > 0 {
            parts.append("\(f.string(fromByteCount: Int64(result.reclaimedBytes))) cache reclaimed")
        }
        if result.compressedDelta < 0 {
            let bytes = UInt64(-result.compressedDelta)
            parts.append("compressor −\(f.string(fromByteCount: Int64(bytes)))")
        }
        if result.swapDelta < 0 {
            let bytes = UInt64(-result.swapDelta)
            parts.append("swap −\(f.string(fromByteCount: Int64(bytes)))")
        }
        if parts.isEmpty {
            return "\(label): no measurable change — system was already lean"
        }
        return "\(label): " + parts.joined(separator: " · ")
    }
}

// MARK: - Main view

struct MemoryManagerView: View {
    @StateObject private var model = MemoryManagerModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                gaugeCard
                actionsCard
                processesCard
            }
            .padding(28)
            .frame(maxWidth: 1100, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
        .onChange(of: scenePhase) { phase in
            model.setForeground(phase == .active)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            SectionHeader(
                eyebrow: "MEMORY",
                title: "Free up RAM",
                subtitle: "Live system memory, top consumers, one-click reclaim — based on the same kernel APIs Activity Monitor uses."
            )
            Spacer()
            PressureBadge(level: model.pressure)
        }
    }

    // MARK: Gauge

    private var gaugeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Memory Usage")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(usedTotalText)
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            MemoryStackedBar(stats: model.stats)
                .frame(height: 22)

            HStack(spacing: 18) {
                LegendDot(color: Theme.accent2, label: "App", value: bytes(model.stats.appBytes))
                LegendDot(color: Theme.bad,     label: "Wired", value: bytes(model.stats.wiredBytes))
                LegendDot(color: Theme.warn,    label: "Compressed", value: bytes(model.stats.compressedBytes))
                LegendDot(color: Theme.ok,      label: "Cached", value: bytes(model.stats.cachedBytes))
                LegendDot(color: .secondary,    label: "Free", value: bytes(model.stats.freeBytes))
                Spacer()
            }
            .font(.system(size: 11, weight: .medium))

            if model.stats.swapTotalBytes > 0 || model.stats.swapUsedBytes > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text("Swap: \(bytes(model.stats.swapUsedBytes)) used")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .glassCard()
    }

    private var usedTotalText: String {
        "\(bytes(model.stats.usedBytes)) of \(bytes(model.stats.totalBytes)) used"
    }

    // MARK: Actions

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Button {
                    Task { await model.runQuickFree() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.sparkles")
                        Text("Quick Free")
                    }
                }
                .buttonStyle(GradientButtonStyle(disabled: model.isFreeing))
                .disabled(model.isFreeing)

                Button {
                    Task { await model.quitSelected(force: false) }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle")
                        Text("Quit Selected (\(model.selectedPIDs.count))")
                    }
                }
                .buttonStyle(SoftButtonStyle())
                .disabled(model.isFreeing || model.selectedPIDs.isEmpty)

                Spacer()

                Toggle(isOn: $model.autoMode) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.badge.automatic")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Auto-free on critical pressure")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
            }

            if let msg = model.actionMessage {
                HStack(spacing: 8) {
                    if model.isFreeing {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.ok)
                    }
                    Text(msg)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity)
            }
        }
        .glassCard()
        .animation(.easeOut(duration: 0.2), value: model.actionMessage)
    }

    // MARK: Processes

    private var processesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top memory consumers")
                    .font(.system(size: 14, weight: .semibold))
                Text("(updates every 2s)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(processCountLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // Header row
            HStack(spacing: 0) {
                Text("").frame(width: 28)
                Text("Process").frame(maxWidth: .infinity, alignment: .leading)
                Text("Memory").frame(width: 110, alignment: .trailing)
                Text("% RAM").frame(width: 70, alignment: .trailing)
                Text("").frame(width: 60)
            }
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .padding(.bottom, 4)

            Divider().opacity(0.3)

            LazyVStack(spacing: 0) {
                ForEach(model.processes.prefix(50)) { entry in
                    ProcessRow(
                        entry: entry,
                        totalRAM: model.stats.totalBytes,
                        selected: model.selectedPIDs.contains(entry.id),
                        onToggle: {
                            if model.selectedPIDs.contains(entry.id) {
                                model.selectedPIDs.remove(entry.id)
                            } else if entry.isOwnedByCurrentUser {
                                model.selectedPIDs.insert(entry.id)
                            }
                        }
                    )
                    Divider().opacity(0.15)
                }
            }
        }
        .glassCard()
    }

    private var processCountLabel: String {
        let shown = min(model.processes.count, 50)
        let total = max(model.totalProcessCount, model.processes.count)
        if total > shown {
            return "Top \(shown) of \(total)"
        }
        return "\(total) process\(total == 1 ? "" : "es")"
    }

    // MARK: helpers

    private func bytes(_ value: UInt64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .memory
        f.allowedUnits = [.useGB, .useMB]
        return f.string(fromByteCount: Int64(value))
    }
}

// MARK: - Stacked bar

private struct MemoryStackedBar: View {
    let stats: MemoryStats

    var body: some View {
        GeometryReader { geo in
            let total = max(1, Double(stats.totalBytes))
            let segments: [(Double, Color)] = [
                (Double(stats.appBytes)        / total, Theme.accent2),
                (Double(stats.wiredBytes)      / total, Theme.bad),
                (Double(stats.compressedBytes) / total, Theme.warn),
                (Double(stats.cachedBytes)     / total, Theme.ok),
            ]
            HStack(spacing: 1) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                    Rectangle()
                        .fill(seg.1)
                        .frame(width: max(0, geo.size.width * seg.0))
                }
                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(maxWidth: .infinity)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Theme.border, lineWidth: 1)
            )
            .animation(.easeOut(duration: 0.4), value: stats.usedBytes)
        }
    }
}

private struct LegendDot: View {
    let color: Color
    let label: String
    let value: String
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).foregroundStyle(.secondary)
            Text(value).foregroundStyle(.primary).monospacedDigit()
        }
    }
}

// MARK: - Pressure badge

private struct PressureBadge: View {
    let level: MemoryPressureLevel

    var body: some View {
        let kind: StatusChip.Kind = {
            switch level {
            case .normal:   return .safe
            case .warning:  return .review
            case .critical: return .destructive
            }
        }()
        return HStack(spacing: 6) {
            Text("Pressure")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            StatusChip(kind: kind, text: level.label)
        }
    }
}

// MARK: - Process row

private struct ProcessRow: View {
    let entry: ProcessMemoryEntry
    let totalRAM: UInt64
    let selected: Bool
    let onToggle: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                if entry.isOwnedByCurrentUser {
                    Toggle(isOn: Binding(get: { selected }, set: { _ in onToggle() })) { EmptyView() }
                        .toggleStyle(.checkbox)
                } else {
                    Image(systemName: "lock")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .help("System-owned process — cannot quit from here.")
                }
            }
            .frame(width: 28)

            HStack(spacing: 8) {
                AppIconView(path: entry.executablePath)
                    .frame(width: 18, height: 18)
                Text(entry.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(formatBytes(entry.residentBytes))
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
                .frame(width: 110, alignment: .trailing)

            Text(percentText)
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)

            Text("PID \(entry.pid)")
                .font(.system(size: 10).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(hovering ? Theme.hoverFill : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture(count: 1) {
            if entry.isOwnedByCurrentUser { onToggle() }
        }
    }

    private func formatBytes(_ value: UInt64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .memory
        f.allowedUnits = [.useGB, .useMB]
        return f.string(fromByteCount: Int64(value))
    }

    private var percentText: String {
        guard totalRAM > 0 else { return "—" }
        let pct = Double(entry.residentBytes) / Double(totalRAM) * 100.0
        if pct < 0.1 { return "<0.1%" }
        return String(format: "%.1f%%", pct)
    }
}

private struct AppIconView: View {
    let path: String
    var body: some View {
        if let icon = Self.icon(for: path) {
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
        } else {
            Image(systemName: "app.dashed")
                .foregroundStyle(.secondary)
        }
    }

    private static func icon(for path: String) -> NSImage? {
        guard !path.isEmpty else { return nil }
        // Helper executables nest like:
        //   /Applications/Brave.app/Contents/Frameworks/
        //     Brave Helper.app/Contents/MacOS/Brave Helper
        // The *innermost* .app is a helper bundle with a generic icon — what
        // users actually recognize is the *outermost* .app ancestor. Walk up
        // collecting every .app component, then pick the topmost one.
        let components = (path as NSString).pathComponents
        var lastAppIndex: Int?
        for (i, c) in components.enumerated() where c.hasSuffix(".app") {
            // First .app encountered while walking from root is the outermost.
            if lastAppIndex == nil { lastAppIndex = i }
        }
        if let idx = lastAppIndex {
            let appPath = NSString.path(withComponents: Array(components.prefix(idx + 1)))
            return NSWorkspace.shared.icon(forFile: appPath)
        }
        return NSWorkspace.shared.icon(forFile: path)
    }
}
