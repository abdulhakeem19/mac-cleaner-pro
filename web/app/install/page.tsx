import type { Metadata } from "next";
import { Footer } from "@/components/Footer";
import { Nav } from "@/components/Nav";
import { brand } from "@/content/site";

export const metadata: Metadata = {
  title: "How to Install Mac Cleaner Pro on macOS — Step-by-Step Guide",
  description:
    "Install Mac Cleaner Pro on macOS Ventura, Sonoma, or Sequoia. Drag to Applications, grant Full Disk Access, right-click Open to bypass Gatekeeper. Takes under 2 minutes.",
  alternates: { canonical: `https://${brand.domain}/install/` },
};

export default function InstallPage() {
  return (
    <>
      <Nav />
      <main className="container-x" style={{ maxWidth: 800, paddingTop: 140, paddingBottom: 120 }}>
        <div className="eyebrow" style={{ marginBottom: 20 }}>
          <span className="eyebrow-dot" />
          Install · macOS 13+
        </div>
        <h1 className="h-section" style={{ marginBottom: 18 }}>
          Installing {brand.name}
        </h1>
        <p className="lede">
          {brand.name} v1.0 ships <strong>without notarization</strong> while we bootstrap.
          macOS Gatekeeper will warn you on first launch. This is a <strong>one-time</strong>{" "}
          workaround — every subsequent launch opens normally.
        </p>

        <Section title="Step 1 — Drag to Applications">
          <ol className="numbered">
            <li>
              Open the downloaded <code>MacCleanerPro-1.0.0.dmg</code>.
            </li>
            <li>
              Drag <strong>Mac Cleaner Pro</strong> onto the <strong>Applications</strong> folder
              shortcut.
            </li>
            <li>Eject the DMG.</li>
          </ol>
        </Section>

        <Section title="Step 2 — First launch (the Gatekeeper bypass)">
          <p>If you double-click the app, macOS will say:</p>
          <blockquote>
            "Mac Cleaner Pro" cannot be opened because Apple cannot check it for malicious
            software.
          </blockquote>
          <p>
            Don't worry — that just means we haven't paid Apple's $99/yr developer fee yet. Bypass
            it once:
          </p>
          <ol className="numbered">
            <li>
              Open the <strong>Applications</strong> folder in Finder.
            </li>
            <li>
              <strong>Right-click</strong> (or Control-click) <strong>Mac Cleaner Pro</strong>.
            </li>
            <li>
              Choose <strong>Open</strong> from the context menu.
            </li>
            <li>
              Click <strong>Open</strong> in the confirmation dialog.
            </li>
          </ol>
          <p>After this once, double-clicking will always work.</p>
          <Callout>
            <strong>Why is this needed?</strong> Apple requires every distributed app to be signed
            by a paid Developer ID and notarized through their service. Until {brand.name} reaches
            that revenue milestone, we ship ad-hoc signed builds that work identically — Gatekeeper
            just adds a one-time prompt.
          </Callout>
        </Section>

        <Section title="Step 3 — Grant Full Disk Access">
          <p>The first-run wizard will guide you through this. You'll need to:</p>
          <ol className="numbered">
            <li>
              Open <strong>System Settings → Privacy &amp; Security → Full Disk Access</strong>.
            </li>
            <li>
              Toggle <strong>Mac Cleaner Pro</strong> on.
            </li>
          </ol>
          <p>
            Without Full Disk Access, scans will only find a fraction of what's reclaimable.
          </p>
        </Section>

        <Section title="What's currently disabled in v1.0">
          <p>
            A few features require a privileged helper daemon, which itself requires the paid
            Developer ID:
          </p>
          <ul className="bulleted">
            <li>
              System cache cleanup (<code>/Library/Caches/*</code>)
            </li>
            <li>
              App leftovers in <code>/Library/LaunchDaemons/</code>,{" "}
              <code>/Library/PrivilegedHelperTools/</code>
            </li>
          </ul>
          <p>
            These appear in the UI with a <strong>Requires helper</strong> badge so you know
            what's there. They'll light up automatically in a future release.
          </p>
        </Section>

        <Section title="Uninstalling Mac Cleaner Pro">
          <p>
            The cleanest way: open Mac Cleaner Pro, go to <strong>App Uninstaller</strong>, search
            for "Mac Cleaner Pro", and use it to uninstall itself. Otherwise, drag{" "}
            <code>Applications/Mac Cleaner Pro.app</code> to the Trash and (optionally) remove{" "}
            <code>~/Library/Application Support/MacCleanerPro/</code> for a complete cleanup.
          </p>
        </Section>
      </main>
      <Footer />
    </>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section style={{ marginTop: 56 }}>
      <h2 style={{ fontSize: 24, fontWeight: 600, letterSpacing: "-0.02em", marginBottom: 14 }}>
        {title}
      </h2>
      <div className="prose">{children}</div>
    </section>
  );
}

function Callout({ children }: { children: React.ReactNode }) {
  return (
    <div
      className="glass"
      style={{
        padding: "16px 20px",
        marginTop: 16,
        fontSize: 14,
        color: "var(--text-dim)",
        lineHeight: 1.6,
      }}
    >
      {children}
    </div>
  );
}
