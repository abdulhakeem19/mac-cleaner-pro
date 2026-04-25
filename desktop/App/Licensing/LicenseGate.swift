import SwiftUI
import Core

/// Single source of truth for the UI's view of the license state.
///
/// Each feature view observes this and disables destructive actions when the
/// trial has expired and no Pro key is present. The state is refreshed on
/// appear and after Settings updates the key.
@MainActor
final class LicenseGate: ObservableObject {
    static let shared = LicenseGate()

    @Published private(set) var state: LicenseManager.State = .trial(daysRemaining: 14)

    init() { Task { await refresh() } }

    func refresh() async {
        let s = await LicenseManager.shared.currentState()
        await MainActor.run { self.state = s }
    }

    /// `true` when destructive actions should be allowed.
    var canCleanNow: Bool {
        switch state {
        case .pro, .trial: return true
        case .expired:     return false
        }
    }

    var lockReason: String {
        switch state {
        case .expired:
            return "Trial expired — enter a license in Settings → License to continue cleaning."
        default: return ""
        }
    }
}
