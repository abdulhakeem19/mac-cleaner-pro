import Foundation
import ServiceManagement
import Core

/// Owns the lifecycle of the privileged helper daemon via `SMAppService`.
///
/// Apple replaced `SMJobBless` with `SMAppService` in macOS 13. The flow:
/// 1. The helper's launchd plist is embedded in the app bundle at
///    `Contents/Library/LaunchDaemons/com.maccleanerpro.helper.plist`.
/// 2. `register()` asks the user (via the System Settings → Login Items pane) to
///    approve installing the daemon.
/// 3. Once approved, launchd loads the plist and the helper executable.
/// 4. On user request, `unregister()` removes the daemon.
///
/// The first registration attempt prompts the user; subsequent calls are no-ops
/// if already enabled. If the user has the daemon disabled in System Settings we
/// surface that state via `requiresApproval` so the UI can deep-link to settings.
@MainActor
final class HelperManager: ObservableObject {

    enum Status: Equatable {
        case notRegistered
        case requiresApproval
        case enabled
        case error(String)
    }

    @Published private(set) var status: Status = .notRegistered

    private let service: SMAppService = .daemon(plistName: helperLaunchdPlistName)

    init() { refresh() }

    func refresh() {
        status = Self.translate(service.status)
    }

    /// Trigger first-time registration. The user is prompted by the system; this
    /// returns immediately and the actual approval is asynchronous. Re-check
    /// `status` after the user returns to the app.
    func register() async {
        do {
            try service.register()
            refresh()
        } catch let error as NSError {
            // kSMErrorAlreadyRegistered is benign — treat as success and refresh.
            if error.domain == "SMAppServiceErrorDomain" && error.code == 1 {
                refresh()
            } else {
                status = .error("\(error.domain) \(error.code): \(error.localizedDescription)")
            }
        }
    }

    func unregister() async {
        do {
            try await service.unregister()
            // Drop any stale XPC handle that pointed at the now-departed helper.
            await HelperBridge.shared.invalidate()
            refresh()
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    /// Deep-link to the Login Items pane so the user can approve the daemon.
    func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    private static func translate(_ status: SMAppService.Status) -> Status {
        switch status {
        case .notRegistered:    return .notRegistered
        case .enabled:          return .enabled
        case .requiresApproval: return .requiresApproval
        case .notFound:         return .error("Helper plist not found in app bundle")
        @unknown default:       return .error("Unknown SMAppService status")
        }
    }
}
