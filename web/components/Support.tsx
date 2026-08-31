"use client";

import { Github, Heart } from "lucide-react";
import Link from "next/link";
import { support } from "@/content/site";
import { BlurIn, FadeUp, Stagger, StaggerItem } from "./Motion";

/**
 * Replaces the old paid Pricing section now that the desktop app is free
 * and open source (MIT). Explains what donations actually fund instead of
 * selling a license.
 */
export function Support() {
  return (
    <section id="support" className="section">
      <div className="container-x">
        <div className="text-center mb-14">
          <BlurIn>
            <div className="eyebrow" style={{ marginBottom: 20, justifyContent: "center" }}>
              <span className="eyebrow-dot" />
              {support.eyebrow}
            </div>
          </BlurIn>
          <FadeUp delay={1}>
            <h2 className="h-section" style={{ maxWidth: 760, margin: "0 auto" }}>
              {support.title} <span className="gradient-text">{support.titleGradient}</span>
            </h2>
          </FadeUp>
          <FadeUp delay={2}>
            <p className="lede" style={{ margin: "20px auto 0", maxWidth: 620, textAlign: "center" }}>
              {support.description}
            </p>
          </FadeUp>
        </div>

        <FadeUp>
          <div className="glass relative overflow-hidden px-5 py-8 md:p-10">
            <div
              aria-hidden
              style={{
                position: "absolute",
                inset: 0,
                background:
                  "radial-gradient(700px 240px at 10% 0%, rgba(255,69,120,0.14), transparent 60%)",
                pointerEvents: "none",
              }}
            />
            <div className="relative grid gap-10 md:grid-cols-[1fr_360px] items-start">
              <div>
                <div
                  className="flex items-center gap-2 mb-4"
                  style={{ color: "var(--accent)" }}
                >
                  <Heart size={16} />
                  <div
                    style={{
                      fontSize: 11,
                      letterSpacing: "0.16em",
                      textTransform: "uppercase",
                      fontWeight: 600,
                    }}
                  >
                    Where donations go
                  </div>
                </div>
                <Stagger className="flex flex-col gap-3" step={0.06}>
                  {support.goals.map((g) => (
                    <StaggerItem key={g.label}>
                      <div
                        style={{
                          padding: "14px 16px",
                          borderRadius: 12,
                          background: "var(--bg-2)",
                          border: "1px solid var(--border)",
                        }}
                      >
                        <div style={{ fontSize: 14.5, fontWeight: 600 }}>{g.label}</div>
                        <div style={{ fontSize: 13, color: "var(--text-dim)", marginTop: 3 }}>
                          {g.detail}
                        </div>
                      </div>
                    </StaggerItem>
                  ))}
                </Stagger>
              </div>

              <div
                style={{
                  background: "var(--bg-2)",
                  border: "1px solid var(--border)",
                  borderRadius: "var(--r-md)",
                  padding: 22,
                  display: "flex",
                  flexDirection: "column",
                  gap: 10,
                }}
              >
                <div
                  style={{
                    fontSize: 11,
                    letterSpacing: "0.16em",
                    textTransform: "uppercase",
                    fontWeight: 600,
                    color: "var(--text-muted)",
                    marginBottom: 4,
                  }}
                >
                  Support the project
                </div>
                {support.links.map((l) => (
                  <Link key={l.label} href={l.href} className="btn btn-secondary" style={{ justifyContent: "center" }}>
                    {l.label}
                  </Link>
                ))}
                <div style={{ height: 1, background: "var(--border)", margin: "6px 0" }} />
                <Link
                  href={support.sourceHref}
                  className="btn btn-ghost"
                  style={{ justifyContent: "center", gap: 8 }}
                >
                  <Github size={14} /> View source on GitHub
                </Link>
              </div>
            </div>
          </div>
        </FadeUp>
      </div>
    </section>
  );
}
