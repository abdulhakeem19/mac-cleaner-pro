# Installing Mac Cleaner Pro

Mac Cleaner Pro v1.0 ships **without notarization** while we bootstrap. macOS Gatekeeper will warn you on first launch. This is a **one-time** workaround — every subsequent launch opens normally.

## Step 1 — Drag to Applications

1. Open the downloaded `MacCleanerPro-1.0.0.dmg`.
2. Drag **Mac Cleaner Pro** onto the **Applications** folder shortcut.
3. Eject the DMG.

## Step 2 — First launch (the Gatekeeper bypass)

If you double-click the app, macOS will say:

> "Mac Cleaner Pro" cannot be opened because Apple cannot check it for malicious software.

Don't worry — that just means we haven't paid Apple's $99/yr developer fee yet. Bypass it once:

1. Open the **Applications** folder in Finder.
2. **Right-click** (or Control-click) **Mac Cleaner Pro**.
3. Choose **Open** from the context menu.
4. Click **Open** in the confirmation dialog.

After this once, double-clicking will always work.

> **Why is this needed?** Apple requires every distributed app to be signed by a paid Developer ID and notarized through their service. Until Mac Cleaner Pro reaches that revenue milestone, we ship ad-hoc signed builds that work identically — Gatekeeper just adds a one-time prompt.

## Step 3 — Grant Full Disk Access

The first-run wizard will guide you through this. You'll need to:

1. Open **System Settings → Privacy & Security → Full Disk Access**.
2. Toggle **Mac Cleaner Pro** on.

Without Full Disk Access, scans will only find a fraction of what's reclaimable.

## What's currently disabled in v1.0

A few features require a privileged helper daemon, which itself requires the paid Developer ID:

- System cache cleanup (`/Library/Caches/*`)
- App leftovers in `/Library/LaunchDaemons/`, `/Library/PrivilegedHelperTools/`

These appear in the UI with a **Requires helper** badge so you know what's there. They'll light up automatically in a future release.

## Uninstalling Mac Cleaner Pro

The cleanest way: open Mac Cleaner Pro, go to **App Uninstaller**, search for "Mac Cleaner Pro", and use it to uninstall itself. Otherwise, drag `Applications/Mac Cleaner Pro.app` to the Trash and (optionally) remove `~/Library/Application Support/MacCleanerPro/` for a complete cleanup.
