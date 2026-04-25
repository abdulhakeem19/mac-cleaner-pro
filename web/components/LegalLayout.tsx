import type { ReactNode } from "react";
import { Footer } from "./Footer";
import { Nav } from "./Nav";

/**
 * Shared shell for /terms, /privacy, /refund. Reuses the prose styles defined
 * in globals.css so all three pages typeset identically.
 */
export function LegalLayout({
  eyebrow,
  title,
  effective,
  children,
}: {
  eyebrow: string;
  title: string;
  effective: string;
  children: ReactNode;
}) {
  return (
    <>
      <Nav />
      <main
        className="container-x"
        style={{ maxWidth: 800, paddingTop: 140, paddingBottom: 120 }}
      >
        <div className="eyebrow" style={{ marginBottom: 20 }}>
          <span className="eyebrow-dot" />
          {eyebrow}
        </div>
        <h1 className="h-section" style={{ marginBottom: 8 }}>
          {title}
        </h1>
        <p
          style={{
            fontSize: 13,
            color: "var(--text-muted)",
            letterSpacing: "0.04em",
          }}
        >
          Effective {effective}
        </p>
        <div className="prose" style={{ marginTop: 32 }}>
          {children}
        </div>
      </main>
      <Footer />
    </>
  );
}

export function LegalSection({
  title,
  children,
}: {
  title: string;
  children: ReactNode;
}) {
  return (
    <section style={{ marginTop: 36 }}>
      <h2
        style={{
          fontSize: 22,
          fontWeight: 600,
          letterSpacing: "-0.02em",
          marginBottom: 10,
        }}
      >
        {title}
      </h2>
      {children}
    </section>
  );
}
