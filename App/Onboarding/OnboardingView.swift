import SwiftUI
import Core

private enum OnboardingStep: Int, CaseIterable {
    case welcome, fullDiskAccess, finish
}

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var step: OnboardingStep = .welcome
    @State private var fdaGranted: Bool = FullDiskAccess.isGranted()

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            footer
                .padding(20)
        }
        .frame(width: 640, height: 460)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:        welcome
        case .fullDiskAccess: fullDiskAccess
        case .finish:         finish
        }
    }

    private var welcome: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Welcome to Mac Cleaner Pro").font(.largeTitle.bold())
            Text("Reclaim disk space safely. Every action is reversible — files go to a staged trash you can restore from.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 460)
            Spacer()
        }
        .padding(40)
    }

    private var fullDiskAccess: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: fdaGranted ? "checkmark.shield.fill" : "lock.shield")
                    .foregroundStyle(fdaGranted ? .green : .orange)
                    .font(.title2)
                Text("Full Disk Access").font(.title2.bold())
                Spacer()
            }

            Text("To find caches, logs, and app leftovers across your account, Mac Cleaner Pro needs Full Disk Access. Without it, scans miss most of what's reclaimable.")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("How to grant:").font(.headline)
                Text("1. Click **Open System Settings** below.")
                Text("2. Toggle **Mac Cleaner Pro** on under Privacy & Security → Full Disk Access.")
                Text("3. Return here and click **Re-check**.")
            }
            .font(.callout)

            HStack {
                Button("Open System Settings…") { FullDiskAccess.openSystemSettings() }
                    .buttonStyle(.borderedProminent)
                Button("Re-check") { fdaGranted = FullDiskAccess.isGranted() }
                Spacer()
                if fdaGranted {
                    Label("Granted", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Text("Not granted yet").foregroundStyle(.orange)
                }
            }
            Spacer()
        }
        .padding(40)
    }

    private var finish: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64)).foregroundStyle(.green)
            Text("You're all set").font(.largeTitle.bold())
            Text("Run **Smart Scan** to see what's reclaimable. The privileged helper for system-level cleanup is disabled in this build — system caches will appear with a 'Requires helper' badge.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 480)
            Spacer()
        }
        .padding(40)
    }

    private var footer: some View {
        HStack {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { s in
                Circle()
                    .fill(s == step ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
            Spacer()
            if step != .welcome {
                Button("Back") {
                    if let prev = OnboardingStep(rawValue: step.rawValue - 1) { step = prev }
                }
            }
            if step == .finish {
                Button("Get Started") {
                    OnboardingState.hasCompleted = true
                    onFinish()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            } else {
                Button("Continue") {
                    if let next = OnboardingStep(rawValue: step.rawValue + 1) { step = next }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
    }
}
