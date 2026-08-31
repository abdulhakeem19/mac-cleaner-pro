/**
 * Single source of truth for all marketing copy.
 *
 * Truthfulness rules:
 *  - Don't claim notarization until we have it.
 *  - Don't claim user counts, press features, or benchmark numbers we haven't measured.
 *  - "Coming soon" features must say so, with no false delivery dates.
 *  - Numbers (trial days, USD price, INR price) match the real LicenseManager.swift.
 */

export const brand = {
  name: "Mac Cleaner Pro",
  tagline: "The honest System Data cleaner for macOS — native Swift, free & open source, zero telemetry.",
  domain: "maccleanerpro.com",
  bundleId: "com.maccleanerpro",
  // Updated at every release.
  version: "1.0.0",
  channel: "indie · v1.0",
} as const;

export const hero = {
  eyebrow: "Built natively for macOS · indie · v1.0",
  headlineTop: "Your Mac,",
  headlineGradient: "reborn.",
  headlineSubPrefix: "Reclaim",
  headlineSubNum: "tens of GB",
  headlineSubAfter: "on your first scan.",
  description:
    "Finally see what's hiding in System Data — and actually clean it. A privacy-first Mac cleaner written in native Swift. No telemetry, no cloud uploads, no subscription. The honest CleanMyMac alternative.",
  primaryCta: { label: "Download free · for macOS", href: "/download/" },
  secondaryCta: { label: "Watch Smart Scan", href: "/#scan" },
  bullets: [
    "Free & open source — no license required",
    "Universal binary · Apple Silicon + Intel",
    "System Data breakdown · Trash-first · 30-day undo",
  ],
  // Honest replacement for the "Trusted by 84,000 users · MacStories" strip:
  trustBlurb: "Built in public. Open about what's shipped and what's coming.",
} as const;

/** Single glass card between Hero and Smart Scan demo — the v1.0 honesty pitch. */
export const honestyCard = {
  eyebrow: "What's actually in v1.0",
  title: "Indie. Honest. Already useful.",
  body: [
    "Three flagship modules ship today: Smart Scan, Large & Old Files, and App Uninstaller — plus a tamper-evident Activity Log.",
    "Everything you delete goes to a staged trash you can undo from. The rules engine is signed and updateable separately from the app.",
    "Some features (system-cache cleanup, malware scanner, Space Lens) need an Apple Developer Program signature — that's exactly what donations from the community go toward.",
  ],
  bullets: [
    "Three modules shipping today",
    "Trash-first + Undo (30 days)",
    "33 unit tests · open about ship state",
    "Roadmap above is not a deadline — it's a direction",
  ],
} as const;

/** Smart Scan demo step list — uses the REAL rule pack categories from desktop/RulePacks/v1.json. */
export const smartScanDemo = {
  eyebrow: "One-click · Smart Scan",
  title: "Everything that's slowing you down.",
  titleGradient: "Found in seconds.",
  description:
    "14 cleanup rules — including a System Data breakdown — run in parallel Swift TaskGroups. No guessing what's eating your disk. See it, decide, clean it. Reverting any clean is one click.",
  stats: [
    { k: "Parallel", v: "Swift TaskGroup" },
    { k: "Local", v: "zero telemetry" },
    { k: "Reversible", v: "30-day undo" },
  ],
  // These match the actual rules in desktop/RulePacks/v1.json.
  steps: [
    { t: "Scanning user caches", path: "~/Library/Caches/*", found: "3.0 GB" },
    { t: "Hashing Xcode artifacts", path: "~/Library/Developer/Xcode/DerivedData", found: "3.3 GB" },
    { t: "Browser caches", path: "Chrome · Firefox · Safari", found: "120 MB" },
    { t: "User logs", path: "~/Library/Logs/**", found: "1.9 MB" },
    { t: "App leftovers", path: "~/Library/Application Support", found: "scanning…" },
    { t: "System Data breakdown", path: "~/Library · /Library · SwiftUI caches", found: "identifying…" },
  ],
} as const;

export const featuresGrid = {
  eyebrow: "Capabilities",
  title: "Eight modules.",
  titleGradient: "One free, open-source app.",
  description:
    "Everything you'd run manually — bundled into a single native app that knows when to ask, when to defer, and when to just do it. Every line of it is on GitHub.",
  groups: [
    {
      color: "#0A84FF",
      number: "01",
      title: "Cleaning & space recovery",
      desc: "Find and reclaim gigabytes without touching anything important.",
      feats: [
        { icon: "Sparkles", t: "Smart Scan", d: "10+ rules across caches, logs, dev artifacts, browsers." },
        { icon: "Search", t: "Large & Old Files", d: "Walk any folder by size and age. Quick Look any match." },
        { icon: "Hammer", t: "Developer Junk", d: "Finds node_modules, DerivedData, .gradle and more — each one labelled with how to bring it back." },
        { icon: "Trash2", t: "App Uninstaller", d: "Find leftovers across 12 user-space locations per app." },
      ],
    },
    {
      color: "#30D158",
      number: "02",
      title: "See where your space goes",
      desc: "Shipped today — not on a roadmap.",
      feats: [
        { icon: "Layers", t: "Space Lens", d: "Treemap + sunburst of every byte on disk. Drill in, reclaim out." },
        { icon: "Copy", t: "Duplicate Finder", d: "Hash-based with smart auto-select — keeps the newest copy by default." },
        { icon: "Cpu", t: "Memory Manager", d: "Live RAM gauge, top-consumer list, Quick Free, Quit Selected." },
        { icon: "ClockArrowDown", t: "Activity Log", d: "Every clean and undo is auditable from one screen." },
      ],
    },
    {
      color: "#7C5CFF",
      number: "03",
      title: "Built-in safety nets",
      desc: "Designed so the worst case is mildly inconvenient — never destructive.",
      feats: [
        { icon: "ArrowUpFromDot", t: "Trash-first deletion", d: "Files stage to ~/.Trash/MacCleanerPro before going anywhere." },
        { icon: "Undo2", t: "Undo for 30 days", d: "Tokens persist across launches. Reverting is one click." },
        { icon: "ShieldCheck", t: "Helper-gated rules", d: "Anything system-level is opt-in via a separately signed daemon." },
        { icon: "FileSignature", t: "Signed rule pack", d: "Cleanup rules are Ed25519-signed before the app will run them." },
      ],
    },
    {
      color: "#FF9F0A",
      number: "04",
      title: "On the roadmap",
      desc: "Real features in active direction — funded by community donations, not on a fixed date.",
      comingSoon: true,
      feats: [
        { icon: "Activity", t: "Menubar Agent", d: "Live disk + memory tile, click to scan." },
        { icon: "ShieldAlert", t: "Malware Scanner", d: "Daily-updated YARA rules. Local scanning, no cloud." },
        { icon: "BadgeCheck", t: "Notarized, App Store-ready builds", d: "Needs the paid Apple Developer Program — exactly what donations fund." },
      ],
    },
  ],
} as const;

export const nativeEdge = {
  eyebrow: "The native Swift edge",
  titleA: "Most Mac cleaners are",
  titleAccent: "visualize-only tools or subscription bloatware.",
  titleB: "Ours is built from the kernel up.",
  underTheHood: [
    { k: "Swift", v: "Structured concurrency · TaskGroup-parallel scans" },
    { k: "FileManager", v: "Trash API for safe, undoable deletion" },
    { k: "FSEvents", v: "Real-time filesystem events when needed" },
    { k: "XPC", v: "Privileged operations via SMAppService daemon" },
    { k: "GRDB / SQLite", v: "Local activity log, no analytics service" },
  ],
  // Truthful: things we have actually counted today.
  facts: [
    { feat: "System Data breakdown", us: "included", them: "none" },
    { feat: "Lines of Swift", us: "~3,500", them: "—" },
    { feat: "Unit tests passing", us: "33 / 33", them: "—" },
    { feat: "External network calls", us: "0", them: "telemetry" },
    { feat: "Subscription required", us: "no", them: "yes" },
    { feat: "Open about scope", us: "yes", them: "no" },
  ],
} as const;

export const howItWorks = {
  eyebrow: "How it works",
  title: "From download to gigabytes free,",
  titleGradient: "under a minute.",
  steps: [
    {
      n: "01",
      t: "Drag to Applications",
      d: "v1.0 is ad-hoc signed (notarization needs a paid Apple cert). Right-click → Open the first time. After that, double-click works forever.",
    },
    {
      n: "02",
      t: "Grant Full Disk Access",
      d: "One-time toggle in System Settings. Without it, scans miss most of what's reclaimable. Nothing leaves your Mac — not even a ping.",
    },
    {
      n: "03",
      t: "Hit Smart Scan",
      d: "Three seconds later, review what's reclaimable. Click Clean. If you regret anything, Undo restores it.",
    },
  ],
} as const;

export const security = {
  eyebrow: "Fully local · privacy-first",
  title: "Your Mac's data never leaves your Mac.",
  body: "All scanning, hashing, and analysis runs on-device. Zero telemetry. The only outbound call is checking for app updates — and you can disable that.",
  honestyLine: "v1.0 is ad-hoc signed. Notarization needs the paid Apple Developer Program — funded by community donations.",
  badges: ["Zero telemetry", "Local-only scan", "Open scope"],
} as const;

const PADDLE_PRO    = process.env.NEXT_PUBLIC_PADDLE_PRO_PRODUCT    ?? null;
const PADDLE_FAMILY = process.env.NEXT_PUBLIC_PADDLE_FAMILY_PRODUCT ?? null;
// Razorpay: only the public key ID goes in the browser; key_secret stays in the Netlify function
const RAZORPAY_KEY  = process.env.NEXT_PUBLIC_RAZORPAY_KEY_ID       ?? null;

/** Pricing — USD + INR. Numbers match LicenseManager trial length. */
export const pricing = {
  eyebrow: "Pricing",
  title: "Pay once.",
  titleGradient: "Own it forever.",
  description: "No subscriptions. No locked features hidden behind a yearly renewal. Just a fair price for an honest app.",
  trialDays: 14,
  rates: { usdToInr: 85 },
  plans: [
    {
      key: "free" as const,
      name: "Free",
      usd: "$0",
      inr: "₹0",
      usdSub: "forever",
      inrSubEn: "forever",
      inrSubHi: "हमेशा के लिए",
      inrSubTa: "எப்போதும்",
      desc: "Try the core scan and see what you can reclaim.",
      cta: "Download free",
      primary: false,
      paddleProductId: null as string | null,
      razorpayPlan: null as string | null,
      feats: [
        "Smart Scan (preview)",
        "Clean up to 500 MB / month",
        "User-space cleanup",
        "Activity Log",
      ],
    },
    {
      key: "pro" as const,
      name: "Pro",
      usd: "$39",
      inr: "₹3,299",
      usdSub: "one-time · 1 Mac",
      inrSubEn: "one-time · 1 Mac",
      inrSubHi: "एकबार · 1 Mac",
      inrSubTa: "ஒரு முறை · 1 Mac",
      desc: "Everything that's shipped, unlocked. Pay once, own it.",
      cta: "Buy Mac Cleaner Pro",
      primary: true,
      tag: "Most popular",
      paddleProductId: PADDLE_PRO as string | null,
      razorpayPlan: RAZORPAY_KEY ? "pro" : null,
      feats: [
        "Unlimited Smart Scan & cleanup",
        "Large & Old Files",
        "App Uninstaller",
        "Activity Log + 30-day Undo",
        "All future v1.x updates",
        "Email support",
      ],
    },
    {
      key: "family" as const,
      name: "Family",
      usd: "$69",
      inr: "₹5,799",
      usdSub: "one-time · up to 5 Macs",
      inrSubEn: "one-time · up to 5 Macs",
      inrSubHi: "एकबार · 5 Macs तक",
      inrSubTa: "ஒரு முறை · 5 Mac வரை",
      desc: "Share Pro with your household.",
      cta: "Get the Family plan",
      primary: false,
      paddleProductId: PADDLE_FAMILY as string | null,
      razorpayPlan: RAZORPAY_KEY ? "family" : null,
      feats: [
        "Everything in Pro",
        "Up to 5 Macs on one license",
        "Lifetime v1.x updates",
        "Priority support",
      ],
    },
  ],
  guarantees: [
    "30-day refund · no questions asked",
    "Lifetime v1.x updates — never a re-purchase",
    "EMI available via Razorpay (India)",
  ],
};

/**
 * Support/donate section — Mac Cleaner Pro's desktop app is free and open
 * source. Donations fund the concrete costs of running this as a
 * one-person project: Apple's Developer Program fee (needed for
 * notarization and a Mac App Store listing), server/hosting costs for the
 * license/download backend, and ongoing maintenance time.
 *
 * TODO(maintainer): verify each handle/slug once the account exists —
 * github.com/sponsors needs GitHub approval; open_collective/ko-fi need the
 * project registered under the vunexolabs account first.
 */
export const support = {
  eyebrow: "Support",
  title: "Free, open source,",
  titleGradient: "and community-funded.",
  description:
    "Mac Cleaner Pro doesn't have a paywall, a subscription, or telemetry to sell. If it's useful to you, donations go directly toward the Apple Developer Program fee, hosting, and keeping this maintained as a solo project.",
  goals: [
    { label: "Apple Developer Program", detail: "$99/yr — unlocks notarization + Mac App Store listing" },
    { label: "Server & hosting", detail: "Licensing backend, downloads, email delivery" },
    { label: "Maintenance", detail: "Bug fixes, new rule packs, new macOS versions" },
  ],
  links: [
    { label: "GitHub Sponsors", href: "https://github.com/sponsors/vunexolabs" },
    { label: "Open Collective", href: "https://opencollective.com/mac-cleaner-pro" },
    { label: "Ko-fi", href: "https://ko-fi.com/vunexolabs" },
  ],
  sourceHref: "https://github.com/vunexolabs/mac-cleaner-pro",
} as const;

export const faq = {
  eyebrow: "FAQ",
  title: "Questions,",
  titleGradient: "answered honestly.",
  items: [
    {
      q: "Is Mac Cleaner Pro really free now? What happened to the paid version?",
      a: "Yes — it's free and open source (MIT license) as of the latest release. There's no trial, no license key, and no feature gate. If you bought a license before the switch, it still works and shows as \"Supporter\" in Settings — nothing changes for you. Development is now funded by voluntary donations (GitHub Sponsors, Open Collective, Ko-fi) instead of sales.",
    },
    {
      q: "Why does macOS warn me on first launch?",
      a: "v1.0 is ad-hoc signed. Apple's notarization service requires a $99/yr Developer Program membership, which is one of the things community donations go toward. Until then: right-click → Open once. After that, double-clicking works forever. Detailed instructions live at /install.",
    },
    {
      q: "Does it explain what's in System Data?",
      a: "Yes. System Data is macOS's catch-all bucket for caches, logs, app support files, and more that Apple's own storage panel hides behind a single opaque number. Mac Cleaner Pro's Smart Scan breaks it down rule-by-rule — user caches, system caches, browser caches, Xcode artifacts, app leftovers — and shows you exactly how many bytes each category holds before you decide to clean anything.",
    },
    {
      q: "How is this different from CleanMyMac or other cleaners?",
      a: "Three things. (1) It's free and open source (MIT) — no subscription, no license key, and you can read every line on GitHub. (2) We're radically transparent — this site lists exactly what's shipped and what isn't. (3) We're built in native Swift with structured concurrency from day one — no shell scripts wrapped in a GUI.",
    },
    {
      q: "Is it safe to clean system files?",
      a: "Every cleaning operation moves files to a staged trash inside ~/.Trash/MacCleanerPro/ first. You can undo for 30 days. The cleanup rules are signed and reviewed; protected files are marked non-removable at the engine level.",
    },
    {
      q: "Does it work on Apple Silicon?",
      a: "Yes — universal binary, native arm64. macOS 13 Ventura or later, Intel and M-series both supported.",
    },
    {
      q: "Do you collect any data?",
      a: "None. No telemetry, no analytics, no crash reports unless you explicitly send one. Scans run entirely on-device. The only outbound call is the optional update check (toggle off in Settings → Privacy).",
    },
    {
      q: "What happens to my license when notarization arrives?",
      a: "Your Supporter badge keeps working exactly as before. Notarized builds roll out to everyone — licensed or not — via the same update channel. Nothing to re-buy, no migration steps.",
    },
    {
      q: "Can I get a refund for a license I already bought?",
      a: "If you purchased before Mac Cleaner Pro went free and open source: yes, within 30 days of your original purchase, no questions asked — email us. New downloads don't need a refund since there's nothing to buy.",
    },
  ],
} as const;

export const systemReq = {
  eyebrow: "System Requirements",
  title: "Runs on every modern Mac.",
  body: "30 MB to download. Works offline.",
  rows: [
    { k: "macOS", v: "13 Ventura or later" },
    { k: "Processor", v: "Apple Silicon (M1/M2/M3/M4) or Intel" },
    { k: "Memory", v: "4 GB minimum · 8 GB recommended" },
    { k: "Storage", v: "80 MB installed" },
    { k: "Permissions", v: "Full Disk Access for deep cleaning" },
    { k: "Languages", v: "English (more coming)" },
  ],
} as const;

export const builtInPublic = {
  eyebrow: "Built in public",
  title: "Eight modules. Fully open source. Counting.",
  description: "Every milestone from spec to ship to open-sourced — visible.",
  milestones: [
    { week: "Week 1", title: "CI + signing pipeline", state: "done" },
    { week: "Week 2", title: "Privileged helper + XPC bridge", state: "done" },
    { week: "Week 3", title: "Cleanup rules engine + Smart Scan UI", state: "done" },
    { week: "Week 4", title: "Trash + Undo + Activity Log", state: "done" },
    { week: "Week 5", title: "Large & Old Files + Quick Look", state: "done" },
    { week: "Week 6", title: "App Uninstaller + leftover finder", state: "done" },
    { week: "Week 7", title: "v1.0 ship — DMG + landing page", state: "done" },
    { week: "Week 8", title: "Space Lens, Memory Manager, Duplicate Finder", state: "done" },
    { week: "Week 9", title: "Developer Junk scanner", state: "done" },
    { week: "Week 10", title: "Open sourced under MIT — free for everyone", state: "current" },
    { week: "Next", title: "Apple Developer cert + notarization (donation-funded)", state: "next" },
    { week: "Next", title: "Menubar Agent + Malware Scanner", state: "next" },
  ],
} as const;

export const footerCta = {
  title: "Stop guessing about System Data.",
  titleGradient: "Clean it tonight — free.",
  body: "Free forever. No trial, no subscription, no license key. MIT-licensed and open source on GitHub — donations keep it maintained.",
  primary: { label: "Download for macOS", href: "/download/" },
  secondary: { label: "Support the project", href: "/support/" },
} as const;

export const footer = {
  blurb:
    "An indie, native Mac performance analyzer and cleaner — free, open source, built in public.",
  cols: [
    { title: "Product", links: [
      { l: "Smart Scan", h: "/#scan" },
      { l: "Large & Old Files", h: "/#features" },
      { l: "App Uninstaller", h: "/#features" },
      { l: "Changelog", h: "/changelog/" },
    ]},
    { title: "Help", links: [
      { l: "Install guide", h: "/install/" },
      { l: "Support", h: "/support/" },
      { l: "FAQ", h: "/#faq" },
      { l: "Contact", h: "/contact/" },
    ]},
    { title: "Company", links: [
      { l: "Open Source (GitHub)", h: "https://github.com/vunexolabs/mac-cleaner-pro" },
      { l: "Built in public", h: "/#timeline" },
      { l: "Terms", h: "/terms/" },
      { l: "Privacy", h: "/privacy/" },
      { l: "Refund Policy", h: "/refund/" },
    ]},
  ],
  copyright: "© 2026 Mac Cleaner Pro. Not affiliated with Apple Inc. macOS is a trademark of Apple Inc.",
} as const;

export const nav = {
  links: [
    { l: "Features", h: "/#features" },
    { l: "Smart Scan", h: "/#scan" },
    { l: "Open Source", h: "https://github.com/vunexolabs/mac-cleaner-pro" },
    { l: "Support", h: "/support/" },
    { l: "FAQ", h: "/#faq" },
    { l: "Install", h: "/install/" },
  ],
} as const;
