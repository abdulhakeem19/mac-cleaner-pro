import SwiftUI
import Core

/// Single source of truth for the UI's view of the license state.
///
/// On launch: migrates any UserDefaults key to Keychain, then does a
/// background server revalidation if 24 h have elapsed.
/// After that: re-checks every hour so grace-period expiry is reflected
/// without requiring an app restart.
@MainActor
final class LicenseGate: ObservableObject {
    static let shared = LicenseGate()

    @Published private(set) var state: LicenseManager.State = .trial(daysRemaining: 14)
    /// Non-nil while the Pro license is validated but the device is offline.
    /// Value is the number of grace period days remaining before the license locks.
    @Published private(set) var gracePeriodDaysLeft: Int? = nil

    private var revalidationTask: Task<Void, Never>?

    init() {
        Task {
            await LicenseManager.shared.migrateFromUserDefaults()
            await LicenseManager.shared.revalidateIfNeeded()
            await refresh()
            schedulePeriodicRevalidation()
        }
    }

    func refresh() async {
        let s = await LicenseManager.shared.currentState()
        let graceDays: Int?
        if case .pro = s {
            graceDays = await SecureLicenseStorage.shared.gracePeriodDaysRemaining()
        } else {
            graceDays = nil
        }
        state = s
        gracePeriodDaysLeft = graceDays
    }

    private func schedulePeriodicRevalidation() {
        revalidationTask?.cancel()
        revalidationTask = Task { [weak self] in
            while !Task.isCancelled {
                // Wake every hour; needsRevalidation() gates the actual network call
                try? await Task.sleep(for: .seconds(3_600))
                guard !Task.isCancelled else { break }
                await LicenseManager.shared.revalidateIfNeeded()
                await self?.refresh()
            }
        }
    }

    /// Mac Cleaner Pro is free and open source — nothing gates destructive
    /// actions. `state`/`gracePeriodDaysLeft` are kept for the optional
    /// legacy "Pro" badge shown to pre-open-source purchasers in Settings.
    var canCleanNow: Bool { true }

    var lockReason: String { "" }
}
