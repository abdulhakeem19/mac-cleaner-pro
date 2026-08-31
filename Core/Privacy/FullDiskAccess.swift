import Foundation
import AppKit

/// Detection + deep-link for Full Disk Access.
///
/// macOS doesn't expose a direct API to query FDA. The reliable trick is to
/// attempt to enumerate one of the protected paths — `~/Library/Mail` is the
/// canonical probe used by every cleaner. If the read returns a non-empty list
/// (or a permission denial), we know the answer; if it returns an empty list
/// from a directory that should always exist, FDA is not granted.
public enum FullDiskAccess {

    /// Best-effort probe. Returns `true` if the protected probe path is readable.
    /// Note: this can return `false` even on a fresh install if Mail has never
    /// been launched — callers should treat `false` as "assume not granted, ask
    /// the user to grant" and let the user re-check after returning.
    public static func isGranted() -> Bool {
        let mail = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Mail")
        if let names = try? FileManager.default.contentsOfDirectory(atPath: mail.path),
           !names.isEmpty {
            return true
        }
        // Fallback probe: Safari's history is also FDA-gated and almost always
        // exists on a real user account.
        let safari = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Safari/Bookmarks.plist")
        return FileManager.default.isReadableFile(atPath: safari.path)
    }

    /// Open System Settings → Privacy & Security → Full Disk Access.
    public static func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }
}
