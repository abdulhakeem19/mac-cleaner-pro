"use client";

import { nativeEdge } from "@/content/site";
import { BlurIn, FadeUp, Stagger, StaggerItem } from "./Motion";

export function NativeEdge() {
  return (
    <section className="section">
      <div className="container-x">
        <div className="text-center mb-14">
          <BlurIn>
            <div className="eyebrow" style={{ marginBottom: 20 }}>
              <span className="eyebrow-dot" />
              {nativeEdge.eyebrow}
            </div>
          </BlurIn>
          <FadeUp delay={1}>
            <h2 className="h-section" style={{ maxWidth: 880, margin: "0 auto" }}>
              {nativeEdge.titleA}{" "}
              <span style={{ color: "var(--text-muted)" }}>
                {nativeEdge.titleAccent}
              </span>
              <br />
              {nativeEdge.titleB}
            </h2>
          </FadeUp>
        </div>

        <Stagger className="grid gap-7 md:grid-cols-2" step={0.1}>
          <StaggerItem>
            <div className="glass px-4 py-6 md:p-8">
              <div
                style={{
                  fontSize: 13,
                  color: "var(--text-muted)",
                  letterSpacing: "0.12em",
                  textTransform: "uppercase",
                  marginBottom: 14,
                }}
              >
                Under the hood
              </div>
              <div className="flex flex-col gap-3.5">
                {nativeEdge.underTheHood.map((r, i) => (
                  <div key={i} className="flex flex-col sm:flex-row sm:items-start gap-1.5 sm:gap-4">
                    <div
                      className="mono"
                      style={{
                        fontSize: 12,
                        color: "var(--accent)",
                        background: "var(--accent-soft)",
                        border: "1px solid var(--accent-ring)",
                        padding: "4px 10px",
                        borderRadius: 6,
                        minWidth: 110,
                        width: "fit-content",
                        textAlign: "center",
                        fontWeight: 600,
                        flexShrink: 0,
                      }}
                    >
                      {r.k}
                    </div>
                    <div
                      style={{
                        fontSize: 14,
                        color: "var(--text-dim)",
                        paddingTop: 2,
                      }}
                    >
                      {r.v}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </StaggerItem>
          <StaggerItem>
            <div className="glass px-4 py-6 md:p-8">
              <div
                style={{
                  fontSize: 13,
                  color: "var(--text-muted)",
                  letterSpacing: "0.12em",
                  textTransform: "uppercase",
                  marginBottom: 14,
                }}
              >
                What we measured
              </div>
              {/* Mobile: 2-col (metric + our value). sm+: 3-col (adds industry default) */}
              <div className="grid" style={{ fontSize: 13, gridTemplateColumns: "1.4fr 1fr" }}>
                <div style={{ color: "var(--text-muted)", padding: "12px 0", borderBottom: "1px solid var(--border)" }}>Metric</div>
                <div style={{ color: "var(--accent)", padding: "12px 0", borderBottom: "1px solid var(--border)", fontWeight: 600 }}>Mac Cleaner Pro</div>
                {nativeEdge.facts.map((c, i) => {
                  const last = i === nativeEdge.facts.length - 1;
                  const cell = { padding: "14px 0", borderBottom: last ? "none" : "1px solid var(--border)" };
                  return (
                    <div key={i} className="contents">
                      <div style={cell}>{c.feat}</div>
                      <div className="mono" style={{ ...cell, color: "var(--ok)", fontWeight: 600 }}>{c.us}</div>
                    </div>
                  );
                })}
              </div>
              {/* sm+: also show industry default as a third column */}
              <div className="hidden sm:grid mt-4 pt-4" style={{ fontSize: 13, gridTemplateColumns: "1.4fr 1fr 1fr", borderTop: "1px solid var(--border)" }}>
                <div style={{ color: "var(--text-muted)", padding: "8px 0", fontWeight: 600 }}>Metric</div>
                <div style={{ color: "var(--accent)", padding: "8px 0", fontWeight: 600 }}>Mac Cleaner Pro</div>
                <div style={{ color: "var(--text-muted)", padding: "8px 0" }}>Industry default</div>
                {nativeEdge.facts.map((c, i) => {
                  const last = i === nativeEdge.facts.length - 1;
                  const cell = { padding: "14px 0", borderBottom: last ? "none" : "1px solid var(--border)" };
                  return (
                    <div key={i} className="contents">
                      <div style={cell}>{c.feat}</div>
                      <div className="mono" style={{ ...cell, color: "var(--ok)", fontWeight: 600 }}>{c.us}</div>
                      <div className="mono" style={{ ...cell, color: "var(--text-muted)" }}>{c.them}</div>
                    </div>
                  );
                })}
              </div>
            </div>
          </StaggerItem>
        </Stagger>
      </div>
    </section>
  );
}
