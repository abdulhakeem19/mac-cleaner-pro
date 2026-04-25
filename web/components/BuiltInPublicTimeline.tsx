"use client";

import { Check, Sparkles } from "lucide-react";
import { builtInPublic } from "@/content/site";
import { BlurIn, FadeUp, Stagger, StaggerItem } from "./Motion";

const STATE_STYLE = {
  done: { color: "var(--ok)", bg: "rgba(48,209,88,0.10)", border: "rgba(48,209,88,0.30)" },
  current: { color: "var(--accent)", bg: "var(--accent-soft)", border: "var(--accent-ring)" },
  next: { color: "var(--text-muted)", bg: "var(--bg-2)", border: "var(--border)" },
} as const;

export function BuiltInPublicTimeline() {
  return (
    <section id="timeline" className="section">
      <div className="container-x">
        <div className="text-center mb-14">
          <BlurIn>
            <div className="eyebrow" style={{ marginBottom: 20 }}>
              <span className="eyebrow-dot" />
              {builtInPublic.eyebrow}
            </div>
          </BlurIn>
          <FadeUp delay={1}>
            <h2 className="h-section" style={{ maxWidth: 800, margin: "0 auto" }}>
              {builtInPublic.title}
            </h2>
          </FadeUp>
          <FadeUp delay={2}>
            <p className="lede" style={{ margin: "16px auto 0", textAlign: "center" }}>
              {builtInPublic.description}
            </p>
          </FadeUp>
        </div>
        <FadeUp>
          <div className="glass" style={{ padding: 28 }}>
            <Stagger className="flex flex-col gap-2" step={0.04}>
              {builtInPublic.milestones.map((m) => {
                const s = STATE_STYLE[m.state as keyof typeof STATE_STYLE];
                return (
                  <StaggerItem key={m.title}>
                    <div
                      className="grid items-center gap-4"
                      style={{
                        gridTemplateColumns: "100px 28px 1fr auto",
                        padding: "12px 14px",
                        borderRadius: 10,
                        background:
                          m.state === "current" ? "var(--accent-soft)" : "transparent",
                        border:
                          m.state === "current"
                            ? "1px solid var(--accent-ring)"
                            : "1px solid transparent",
                      }}
                    >
                      <div
                        className="mono"
                        style={{
                          fontSize: 12,
                          color: "var(--text-muted)",
                          letterSpacing: "0.04em",
                        }}
                      >
                        {m.week}
                      </div>
                      <div
                        style={{
                          width: 24,
                          height: 24,
                          borderRadius: "50%",
                          background: s.bg,
                          border: `1px solid ${s.border}`,
                          color: s.color,
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          flexShrink: 0,
                        }}
                      >
                        {m.state === "done" ? (
                          <Check size={14} strokeWidth={3} />
                        ) : m.state === "current" ? (
                          <Sparkles size={14} />
                        ) : (
                          <span
                            style={{
                              width: 6,
                              height: 6,
                              borderRadius: 999,
                              background: "var(--text-muted)",
                            }}
                          />
                        )}
                      </div>
                      <div style={{ fontSize: 14.5, fontWeight: 500 }}>{m.title}</div>
                      <span
                        className="pill"
                        style={{
                          padding: "2px 10px",
                          fontSize: 11,
                          color: s.color,
                          background: s.bg,
                          borderColor: s.border,
                          textTransform: "capitalize",
                        }}
                      >
                        {m.state}
                      </span>
                    </div>
                  </StaggerItem>
                );
              })}
            </Stagger>
          </div>
        </FadeUp>
      </div>
    </section>
  );
}
