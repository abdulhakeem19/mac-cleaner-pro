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
            <div className="glass" style={{ padding: 32 }}>
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
                  <div key={i} className="flex gap-4 items-start">
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
                        textAlign: "center",
                        fontWeight: 600,
                      }}
                    >
                      {r.k}
                    </div>
                    <div
                      style={{
                        fontSize: 14,
                        color: "var(--text-dim)",
                        paddingTop: 4,
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
            <div className="glass" style={{ padding: 32 }}>
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
              <div
                className="grid"
                style={{
                  gridTemplateColumns: "1.4fr 1fr 1fr",
                  fontSize: 13,
                }}
              >
                <div
                  style={{
                    color: "var(--text-muted)",
                    padding: "12px 0",
                    borderBottom: "1px solid var(--border)",
                  }}
                >
                  Metric
                </div>
                <div
                  style={{
                    color: "var(--accent)",
                    padding: "12px 0",
                    borderBottom: "1px solid var(--border)",
                    fontWeight: 600,
                  }}
                >
                  Mac Cleaner Pro
                </div>
                <div
                  style={{
                    color: "var(--text-muted)",
                    padding: "12px 0",
                    borderBottom: "1px solid var(--border)",
                  }}
                >
                  Industry default
                </div>
                {nativeEdge.facts.map((c, i) => {
                  const last = i === nativeEdge.facts.length - 1;
                  const cell = {
                    padding: "14px 0",
                    borderBottom: last ? "none" : "1px solid var(--border)",
                  };
                  return (
                    <div key={i} className="contents">
                      <div style={cell}>{c.feat}</div>
                      <div
                        className="mono"
                        style={{
                          ...cell,
                          color: "var(--ok)",
                          fontWeight: 600,
                        }}
                      >
                        {c.us}
                      </div>
                      <div
                        className="mono"
                        style={{ ...cell, color: "var(--text-muted)" }}
                      >
                        {c.them}
                      </div>
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
