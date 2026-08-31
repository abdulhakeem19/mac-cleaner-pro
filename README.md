# Mac Cleaner Pro — private monorepo

This is the **private** development home for Mac Cleaner Pro: the desktop
app source, the marketing site, and the licensing/payment backend for
pre-open-source purchasers, all in one place for convenience during
day-to-day development.

**Looking for the open-source app instead?** The public, MIT-licensed
desktop app (no `web/` backend, fresh history) lives at
**https://github.com/vunexolabs/mac-cleaner-pro** — that's where issues,
pull requests, and community contributions go.

This repo stays private because `web/` contains the Razorpay/Paddle
checkout flow, Supabase schema, and Ed25519 license-signing logic used to
support pre-open-source buyers. There is nothing sensitive in `desktop/`
itself; it's kept here only because it's still actively developed
alongside `web/`.

## Layout

- **`desktop/`** — native macOS app (Swift / SwiftUI / SMAppService). This
  is the same content published to the public repo above. See
  [`desktop/README.md`](desktop/README.md) for build instructions and
  [`desktop/CONTRIBUTING.md`](desktop/CONTRIBUTING.md) for the public
  contribution workflow.
- **`web/`** — Next.js 15 landing page (statically exported) plus the
  Netlify functions handling license issuance, Razorpay/Paddle checkout,
  and Supabase-backed activation tracking. Private — never published.
- **`maccleanerpro/`** — HTML/CSS/JS design prototypes. Read
  `maccleanerpro/README.md` before treating anything here as production
  code.

## Quick start

```sh
# Desktop
cd desktop
brew install xcodegen
xcodegen generate
xcodebuild -project MacCleanerPro.xcodeproj -scheme MacCleanerPro test

# Web
cd web
npm install
npm run dev      # localhost:3000
```

Full commands, architecture notes, and the $0-mode/paid-mode distinction
are in [`CLAUDE.md`](CLAUDE.md) — written for AI coding agents, but
equally useful as a human reference since it's kept up to date.

## Keeping the public repo in sync

When `desktop/` changes here, mirror them to the public repo:

```sh
# from a scratch checkout of just desktop/'s current content —
# the public repo keeps its own independent (squashed) history,
# it is NOT a subtree/submodule of this repo.
```

There's no automated sync yet; changes are ported over manually. If this
becomes a frequent papercut, `git subtree` or a small CI job is the next
step — not set up today to avoid extra moving parts before the open-source
launch has settled.

## Secrets

Never commit real values for anything in `web/.env.example` or
`desktop/keys/`. See [`desktop/docs/rule-pack-signing.md`](desktop/docs/rule-pack-signing.md)
for the rule-pack signing key workflow. If a secret ever leaks into git
history, rotating it is not optional — assume it's compromised even if the
repo was only public/shared briefly.
