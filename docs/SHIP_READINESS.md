# Ship Readiness — v1.0 ($0-mode)

Status as of end of Week 8. This document maps every feature to its state and explicitly calls out which capabilities require an Apple Developer Program membership ($99/yr) to unlock.

## ✅ Working in $0-mode

| Feature | Notes |
|---|---|
| Onboarding wizard | 3-step: Welcome → Full Disk Access → Done. Re-shown on next launch via Settings → Advanced. |
| Full Disk Access detection | Probe via `~/Library/Mail` + `~/Library/Safari/Bookmarks.plist`. Deep-link to System Settings. |
| Smart Scan (user-space rules) | Bundled rule pack v1 with 10+ rules. Helper-required rules display "Requires helper" badge. |
| Large & Old Files | User-picked root, size + age filters, sortable Table, Quick Look preview, Move to Trash. |
| App Uninstaller | Discovers `/Applications` + `~/Applications`. 12 user-space + 6 system-space leftover categories. |
| Trash + Undo | All deletions stage at `~/.Trash/MacCleanerPro/<UUID>/`. Tokens persist to disk; Undo survives relaunch. |
| Activity Log | JSON-backed at `~/Library/Application Support/MacCleanerPro/activity.json`. Auto-logged from `DeletionService`. |
| License manager | Trial (14 days) → Pro / Expired state machine. UserDefaults-backed. Accepts `MCP-XXXXXXXXXXXX` keys. |
| License gate | Clean / Move-to-Trash / Uninstall buttons disable when trial expires. |
| Settings | Tabbed: General / License / Privacy / Advanced. Onboarding reset. |
| About + Help menu | Standard macOS About box + Help / Buy License menu items. |
| DMG packaging | `tools/build-release.sh` produces a drag-to-Applications DMG, ad-hoc signed. |

## 🔒 Blocked until Apple Developer Program ($99/yr)

| Feature | What unblocks it |
|---|---|
| Privileged helper (system caches, system uninstaller leftovers) | `SMAppService.daemon` registration requires a Team-ID-bearing code signature. |
| Notarization | `xcrun notarytool` needs an active Developer Program membership. |
| Gatekeeper-clean first launch | Notarization stapling. Until then, users do right-click → Open once. |
| Sparkle auto-updates | Works *technically* without paid cert, but EdDSA + signed binaries is the only sane path. |
| Mac App Store | Separate sandboxed target, requires App Store Connect. |
| Setapp listing | Requires Developer Program membership. |

To upgrade: in `project.yml` set `DEVELOPMENT_TEAM` and `CODE_SIGN_IDENTITY: "Developer ID Application: <Name> (TEAMID)"`, replace `REPLACE_TEAM_ID` in `PrivilegedHelper/Info.plist` and `PrivilegedHelper/CodeSignValidator.swift`, then re-run `tools/build-release.sh`. Notarization is a single `xcrun notarytool submit` call per the script's header comment.

## 📋 Pre-launch checklist

- [ ] Update `project.yml` `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` for the release.
- [ ] Tag a release in git (`git tag v1.0.0 && git push --tags`).
- [ ] Run `./tools/build-release.sh`.
- [ ] Test the DMG on a clean Mac (or fresh user account): drag to Applications, right-click → Open, complete onboarding, run Smart Scan, run Large Files, run Uninstaller, verify Undo round-trips.
- [ ] Upload `out/MacCleanerPro-1.0.0.dmg` to your distribution channel.
- [ ] Publish `docs/INSTALL.md` content on the marketing site.
- [ ] Wire Paddle: replace `LicenseManager.isStructurallyValid` with real Ed25519 verification once you have keys from Paddle.

## 🛣️ Recommended post-launch sequence

1. **First $99 of revenue → buy Apple Developer Program.** Re-cut a notarized DMG; existing users update by re-downloading.
2. **Wire real Paddle license verification.** The shape of the keys (`MCP-...`) already matches what Paddle issues; just swap the validator.
3. **Sign + ship the privileged helper.** With Team ID in place, system-level cleanup features turn on.
4. **Wire Sparkle** for auto-updates so users don't have to manually download.
