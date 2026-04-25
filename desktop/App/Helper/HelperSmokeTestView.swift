import SwiftUI
import Core

/// End-to-end smoke test for the privileged helper.
///
/// Flow:
/// 1. Show current `SMAppService` status; offer Register / Unregister / Open Settings.
/// 2. Plant a 1 MiB file at `/Library/Caches/MacCleanerProSmoke/<uuid>.bin` (writing this
///    path itself requires root, so the planting goes through the helper's trash verb in
///    reverse — see note below).
/// 3. Round-trip `version()`, `sizesForSystemPaths()`, then `trashSystemPaths()`.
/// 4. Show reclaimed bytes and confirm the file is gone.
///
/// Note on planting: `/Library/Caches/` requires root to write to, but a real cleaner
/// cleans paths the system itself created. For the smoke test we use a path that
/// the running user *can* create — `/Library/Caches/MacCleanerProSmoke/` — by writing
/// via `sudo`-less means: `/Library/Caches` is world-writable on most Macs (`drwxrwxr-t`).
/// If creation fails we surface that as a precondition error instead of failing the test.
struct HelperSmokeTestView: View {

    @StateObject private var manager = HelperManager()
    @State private var log: [String] = []
    @State private var isRunning = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Helper status:").bold()
                Text(statusLabel).foregroundStyle(statusColor)
                Spacer()
                Button("Refresh") { manager.refresh() }
            }

            HStack(spacing: 8) {
                Button("Register") { Task { await manager.register() } }
                    .disabled(manager.status == .enabled)
                Button("Unregister") { Task { await manager.unregister() } }
                    .disabled(manager.status == .notRegistered)
                Button("Open Login Items") { manager.openLoginItemsSettings() }
                Spacer()
                Button(isRunning ? "Running…" : "Run Smoke Test") {
                    Task { await runSmokeTest() }
                }
                .disabled(isRunning || manager.status != .enabled)
                .buttonStyle(.borderedProminent)
            }

            GroupBox("Output") {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(log.enumerated()), id: \.offset) { _, line in
                            Text(line).font(.system(.caption, design: .monospaced))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                }
                .frame(minHeight: 200)
            }
        }
        .padding(20)
    }

    private var statusLabel: String {
        switch manager.status {
        case .notRegistered:    return "Not registered"
        case .requiresApproval: return "Requires approval — open Login Items"
        case .enabled:          return "Enabled"
        case .error(let msg):   return "Error: \(msg)"
        }
    }

    private var statusColor: Color {
        switch manager.status {
        case .enabled:           return .green
        case .requiresApproval:  return .orange
        case .error:             return .red
        case .notRegistered:     return .secondary
        }
    }

    @MainActor
    private func runSmokeTest() async {
        isRunning = true
        defer { isRunning = false }
        log.removeAll()

        let bridge = HelperBridge.shared
        let dir = "/Library/Caches/MacCleanerProSmoke"
        let path = "\(dir)/\(UUID().uuidString).bin"

        do {
            append("→ helper.version()")
            let v = try await bridge.version()
            append("✓ helper version = \(v)")

            append("→ planting 1 MiB at \(path)")
            try plantFile(at: path, dirPath: dir, megabytes: 1)
            append("✓ planted")

            append("→ helper.sizesForSystemPaths([planted])")
            let sizes = try await bridge.sizesForSystemPaths([path])
            append("✓ size = \(sizes[path] ?? 0) bytes")

            append("→ helper.trashSystemPaths([planted])")
            let reclaimed = try await bridge.trashSystemPaths([path])
            append("✓ reclaimed \(reclaimed) bytes")

            let stillThere = FileManager.default.fileExists(atPath: path)
            append(stillThere ? "✗ file still exists — FAIL" : "✓ file gone — PASS")
        } catch {
            append("✗ \(error)")
        }
    }

    private func plantFile(at path: String, dirPath: String, megabytes: Int) throws {
        try FileManager.default.createDirectory(atPath: dirPath,
                                                withIntermediateDirectories: true)
        let bytes = Data(count: megabytes * 1024 * 1024)
        guard FileManager.default.createFile(atPath: path, contents: bytes) else {
            throw NSError(domain: "Smoke", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Could not create \(path) — /Library/Caches may not be writable by your user. Run the test against a path that the helper allowlists and you can create."
            ])
        }
    }

    private func append(_ s: String) { log.append(s) }
}
