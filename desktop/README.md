# Mac Cleaner Pro

A native, honest macOS cleaner — written in Swift/SwiftUI, no telemetry, no
cloud uploads, no subscription. Free and open source (MIT).

Built and maintained by a single indie developer. This repo is the desktop
app; see [Support this project](#support-this-project) if you'd like to help
keep it alive.

## What it does

- **Smart Scan** — parallel Swift `TaskGroup` scan across caches, logs,
  Xcode DerivedData, browser caches, and a System Data breakdown, driven by
  a signed, updateable [rule pack](RulePacks/v1.json).
- **Large & Old Files** — user-picked root, size/age filters, Quick Look
  preview.
- **Space Lens** — treemap + sunburst disk usage visualizer.
- **Memory Manager** — live RAM gauge, top-consumer list, Quick Free.
- **App Uninstaller** — finds leftover files across 12+ user-space and
  6+ system-space categories.
- **Trash-first + Undo** — every deletion stages at
  `~/.Trash/MacCleanerPro/<UUID>/` for 30 days; nothing is ever deleted
  outright.
- **Tamper-evident Activity Log** — every cleanup action is recorded.

Some features (system-cache cleanup, malware scanner, Space Lens
system-level scans) need a privileged helper, which itself needs an Apple
Developer Program membership — see [Ship status](#ship-status) below.

## Download

Prebuilt, signed releases: **[maccleanerpro.com](https://maccleanerpro.com)**
or this repo's [Releases](../../releases) page.

Or build it yourself — see below.

## Building from source

Requires Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`).

```sh
xcodegen generate     # regenerates MacCleanerPro.xcodeproj from project.yml
open MacCleanerPro.xcodeproj
```

Or from the command line:

```sh
xcodebuild -project MacCleanerPro.xcodeproj -scheme MacCleanerPro test   # run the test suite
./tools/build-release.sh                                                # archive + DMG → out/
```

`*.xcodeproj/` is gitignored on purpose — it's generated from `project.yml`,
never edited by hand. Any change to targets, sources, entitlements, or build
phases goes through `project.yml`.

## Architecture

Three-target build, all defined in `project.yml`:

1. **`Core` framework** (`Core/` + `Shared/`) — pure Swift, no UI. Every
   domain module lives here: `Scanner`, `RulesEngine`, `LargeFiles`,
   `Uninstaller`, `DeletionService`, `ActivityLog`, `Licensing`,
   `HelperBridge`, `Onboarding`, `Privacy`. All unit tests target this
   framework (`Tests/CoreTests/`).
2. **`MacCleanerPro` app** (`App/`) — the SwiftUI shell. Hardened Runtime,
   not sandboxed (needs Full Disk Access).
3. **`PrivilegedHelper` tool** (`PrivilegedHelper/` +
   `Shared/HelperProtocol.swift`) — a root daemon registered via
   `SMAppService.daemon`, XPC-only.

See `docs/rule-pack-signing.md` for how the rule pack is signed/verified, and
`docs/SHIP_READINESS.md` for the full feature/readiness matrix.

## Ship status ($0-mode)

This app currently ships **ad-hoc signed, not notarized** — it doesn't yet
have a paid Apple Developer Program membership ($99/yr), so:

- First launch needs a one-time right-click → Open (see `docs/INSTALL.md`).
- The privileged helper (system-level cleanup) isn't wired up yet — it
  requires a Developer ID-signed binary.
- It's not on the Mac App Store yet.

Getting to a notarized, App Store-ready build is exactly what
[donations](#support-this-project) go toward.

## Contributing

Contributions are very welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) for
dev setup, code style, and what's especially useful to work on as a single
maintainer.

## Support this project

Mac Cleaner Pro is free, with no ads, telemetry, or nagware. If it's useful
to you, donations directly fund:

- The **Apple Developer Program** ($99/yr) needed for notarization and an
  eventual Mac App Store listing.
- **Server/hosting costs** for the licensing and download backend.
- Time spent on maintenance, bug fixes, and new rule packs.

- GitHub Sponsors: [github.com/sponsors/vunexolabs](https://github.com/sponsors/vunexolabs)
- Open Collective: [opencollective.com/mac-cleaner-pro](https://opencollective.com/mac-cleaner-pro)
- Ko-fi: [ko-fi.com/vunexolabs](https://ko-fi.com/vunexolabs)

*(Links go live once the accounts are set up — see the maintainer if any of
these 404.)*

## Security

Found a vulnerability? Please read [SECURITY.md](SECURITY.md) rather than
opening a public issue.

## License

MIT — see [LICENSE](LICENSE). The "Mac Cleaner Pro" name and branding are
not covered by the code license — see [NOTICE.md](NOTICE.md).
