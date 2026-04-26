# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repo layout

This is a monorepo with two independent roots and one design-handoff bundle:

- `desktop/` — native macOS app (Swift / SwiftUI / SMAppService). Source of truth for the Xcode project is `desktop/project.yml` (XcodeGen). **`*.xcodeproj/` is gitignored — regenerate it from the YAML.**
- `web/` — Next.js 15 App Router landing page (statically exported, Tailwind v4, Framer Motion).
- `maccleanerpro/` — HTML/CSS/JS design prototypes from Claude Design. Read `maccleanerpro/README.md` before treating any file in here as production code.

## Common commands

### Desktop (run from `desktop/`)

```sh
xcodegen generate                                                          # regenerate .xcodeproj from project.yml — required after pulling
xcodebuild -project MacCleanerPro.xcodeproj -scheme MacCleanerPro test     # full test suite (CoreTests bundle)
xcodebuild -project MacCleanerPro.xcodeproj -scheme MacCleanerPro \
  test -only-testing:CoreTests/ScanEngineTests/testFoo                     # single test
./tools/build-release.sh                                                   # archive + ad-hoc re-sign + DMG → desktop/out/
./tools/sign-rules.sh RulePacks/v1.json                                    # produces RulePacks/v1.json.sig (Ed25519, base64)
./tools/verify-rules.sh RulePacks/v1.json                                  # mirrors the runtime verifier
```

XcodeGen is required (`brew install xcodegen`). Any change to targets, sources, entitlements, or build phases must go through `project.yml`, not the generated project.

### Web (run from `web/`)

```sh
npm install
npm run dev      # localhost:3000
npm run build    # static export → web/out/
npm run lint
```

## Desktop architecture

Three-target build, all defined in `project.yml`:

1. **`Core` framework** (`desktop/Core/` + `desktop/Shared/`) — pure Swift, no UI. Houses every domain module: `Scanner`, `RulesEngine`, `LargeFiles`, `Uninstaller`, `DeletionService`, `ActivityLog`, `Licensing`, `HelperBridge`, `Onboarding`, `Privacy`. **All unit tests target this framework** (`Tests/CoreTests/`). Keep business logic here so it stays testable without a host app.
2. **`MacCleanerPro` app** (`desktop/App/`) — SwiftUI shell. Hardened Runtime, **NOT sandboxed** (it needs Full Disk Access). Bundles `RulePacks/v1.json` as a resource and embeds the helper.
3. **`PrivilegedHelper` tool** (`desktop/PrivilegedHelper/` + `desktop/Shared/HelperProtocol.swift`) — root daemon registered via `SMAppService.daemon`, XPC-only. The XPC contract is `Shared/HelperProtocol.swift`, deliberately shared between app and helper targets.

Two post-build scripts (in `project.yml`) are load-bearing — don't strip them:

- **Relocate helper to `Contents/MacOS/`.** XcodeGen's `embed: true` puts tool dependencies in `Contents/Resources/`, but `SMAppService` requires the helper at `Contents/MacOS/<bundle-id>` so launchd treats it as a Mach-O executable.
- **Embed launchd plist at `Contents/Library/LaunchDaemons/`.** `SMAppService.daemon(plistName:)` looks here. The plist is also `__launchd_plist`-sectcreated into the helper binary, but `SMAppService` needs the file form.

`tools/build-release.sh` re-signs the **whole bundle in one `codesign --force --deep --sign -` pass**. This is required: separate ad-hoc signing operations produce different synthetic team identifiers, and dyld on Apple Silicon refuses to load frameworks whose team identifier differs from the loader's. Don't replace this with per-target signing.

### $0-mode vs paid-mode

The repo currently ships in **$0-mode** (ad-hoc signed, not notarized, no privileged helper at runtime). Switching to a paid Apple Developer membership requires three coordinated changes; see the header comment in `tools/build-release.sh` and `desktop/docs/SHIP_READINESS.md` for the exact steps. The literal token `REPLACE_TEAM_ID` appears in `project.yml`, `PrivilegedHelper/Info.plist`, and `PrivilegedHelper/CodeSignValidator.swift` and must be substituted together.

### Rule packs

`RulePacks/v1.json` is the bundled cleanup rule set, signed with Ed25519. Sign with `tools/sign-rules.sh` (uses `RULEPACK_PRIVATE_KEY` env var in CI, or `keys/rulepack_private.pem` locally — `keys/*` is gitignored except for the public key). The Swift verifier in `Core/RulesEngine` does the real check at runtime; the verify script mirrors it. See `desktop/docs/rule-pack-signing.md`.

### Runtime data locations

- Trash staging: `~/.Trash/MacCleanerPro/<UUID>/` (30-day retention; tokens persist so Undo survives relaunch)
- Activity log: `~/Library/Application Support/MacCleanerPro/activity.json`
- License state: `UserDefaults` (key shape `MCP-XXXXXXXXXXXX`; validator is currently `isStructurallyValid` — Paddle Ed25519 verification is the post-launch swap)

## Web architecture

Next.js 15 App Router, **static export** (`next build` → `web/out/`), so no server-side runtime. All marketing copy is centralized as a typed module in `web/content/site.ts` — change copy there, not in components. Pricing is dual-currency (USD + INR) with locale auto-detect. Animations honor `prefers-reduced-motion` via the helpers in `web/lib/motion.ts`.