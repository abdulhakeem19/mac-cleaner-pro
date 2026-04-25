# Mac Cleaner Pro

A privacy-first, indie macOS performance analyzer & system cleaner — and the marketing site that sells it. One repo, two roots:

```
mac-cleaner-pro/
├── desktop/        # Native Swift app (Xcode/SwiftUI/SMAppService)
└── web/            # Next.js 15 + Tailwind v4 + Framer Motion landing page
```

## The desktop app — `desktop/`

macOS 13+ utility shipping in $0-mode (ad-hoc signed; notarization arrives with the first paid Apple Developer membership). Three modules in v1.0 — Smart Scan, Large & Old Files, App Uninstaller — plus an auditable Activity Log and a 30-day Trash + Undo system.

```sh
cd desktop
xcodegen generate
xcodebuild -project MacCleanerPro.xcodeproj -scheme MacCleanerPro test     # 33/33 passing
./tools/build-release.sh                                                    # produces a DMG in out/
```

Read [`desktop/docs/SHIP_READINESS.md`](desktop/docs/SHIP_READINESS.md) for the launch checklist and [`desktop/docs/INSTALL.md`](desktop/docs/INSTALL.md) for end-user installation.

## The landing page — `web/`

Next.js 15 App Router, statically exported, deployable to any static host (Vercel, Cloudflare Pages, S3 + CloudFront).

```sh
cd web
npm install
npm run dev          # localhost:3000
npm run build        # → out/  (static export)
```

All marketing copy lives in [`web/content/site.ts`](web/content/site.ts) as a typed module. Pricing is dual-currency (USD + INR) with locale auto-detect. Animations use Framer Motion with `prefers-reduced-motion` honored.

## License

Proprietary. The desktop app's source is open during development for transparency, but redistribution requires a Pro license.
