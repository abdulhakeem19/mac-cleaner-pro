import type { Metadata } from "next";
import { Footer } from "@/components/Footer";
import { Nav } from "@/components/Nav";
import { brand } from "@/content/site";

export const metadata: Metadata = {
  title: "Downloading Mac Cleaner Pro",
  description: "Your download of Mac Cleaner Pro is starting automatically.",
  alternates: { canonical: `https://${brand.domain}/download/` },
  robots: { index: false, follow: false },
};

const DMG = `/download/MacCleanerPro-${brand.version}.dmg`;

export default function DownloadPage() {
  return (
    <>
      {/* Auto-start download after 1 second */}
      <head>
        <meta httpEquiv="refresh" content={`1;url=${DMG}`} />
      </head>
      <Nav />
      <main
        className="container-x"
        style={{ maxWidth: 700, paddingTop: 140, paddingBottom: 120, textAlign: "center" }}
      >
        <div className="eyebrow" style={{ marginBottom: 20, justifyContent: "center" }}>
          <span className="eyebrow-dot" />
          Downloading
        </div>
        <h1 className="h-section" style={{ marginBottom: 16 }}>
          Your download is starting…
        </h1>
        <p className="lede" style={{ marginBottom: 32 }}>
          <code>MacCleanerPro-{brand.version}.dmg</code> should begin automatically.{" "}
          <a href={DMG} download style={{ color: "var(--accent)" }}>
            Click here if it doesn&apos;t start.
          </a>
        </p>

        <div
          className="glass"
          style={{ padding: "24px 28px", textAlign: "left", marginBottom: 24 }}
        >
          <p
            style={{
              fontSize: 15,
              fontWeight: 600,
              marginBottom: 14,
              letterSpacing: "-0.01em",
            }}
          >
            macOS will show a security notice — here&apos;s the 30-second fix:
          </p>
          <ol
            style={{
              paddingLeft: 20,
              lineHeight: 2.1,
              fontSize: 14,
              color: "var(--text-dim)",
              margin: 0,
            }}
          >
            <li>
              Open <strong>MacCleanerPro-{brand.version}.dmg</strong> from Downloads
            </li>
            <li>
              Drag <strong>Mac Cleaner Pro</strong> to the Applications folder
            </li>
            <li>
              In Applications, <strong>right-click → Open</strong>{" "}
              <span style={{ color: "var(--text-muted)" }}>(first launch only)</span>
            </li>
            <li>
              Click <strong>Open</strong> in the dialog — done forever after
            </li>
          </ol>
        </div>

        <p style={{ fontSize: 14, color: "var(--text-muted)" }}>
          Need more detail?{" "}
          <a href="/install/" style={{ color: "var(--accent)" }}>
            Full install guide →
          </a>
        </p>
      </main>
      <Footer />
    </>
  );
}
