"use client";

import { ShieldCheck, Sparkles, TestTube2 } from "lucide-react";
import { CountUp } from "./CountUp";
import { FadeUp } from "./Motion";

const STATS = [
  {
    icon: Sparkles,
    color: "var(--accent)",
    bg: "var(--accent-soft)",
    border: "var(--accent-ring)",
    value: <CountUp to={6.36} decimals={2} suffix=" GB" />,
    label: "reclaimable on a developer Mac (real first scan)",
  },
  {
    icon: TestTube2,
    color: "var(--ok)",
    bg: "rgba(48,209,88,0.10)",
    border: "rgba(48,209,88,0.30)",
    value: (
      <>
        <CountUp to={33} suffix="" /> / 33
      </>
    ),
    label: "unit tests passing — every commit",
  },
  {
    icon: ShieldCheck,
    color: "var(--accent-2)",
    bg: "rgba(10,132,255,0.10)",
    border: "rgba(10,132,255,0.30)",
    value: <CountUp to={0} />,
    label: "external network calls during a scan",
  },
];

/**
 * Animated stat pills shown below the hero CTA. Replaces the prototype's plain
 * "trust strip" with concrete numbers that *we have actually measured* — same
 * spirit as the truthful "Native Swift Edge" facts table.
 */
export function HeroStats() {
  return (
    <FadeUp delay={5}>
      <div
        className="grid gap-3 mt-10"
        style={{ gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))" }}
      >
        {STATS.map((s, i) => {
          const Ic = s.icon;
          return (
            <div
              key={i}
              className="glass flex items-center gap-3 text-left"
              style={{
                padding: "14px 18px",
                borderColor: s.border,
              }}
            >
              <div
                style={{
                  width: 38,
                  height: 38,
                  borderRadius: 10,
                  background: s.bg,
                  border: `1px solid ${s.border}`,
                  color: s.color,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  flexShrink: 0,
                }}
              >
                <Ic size={18} />
              </div>
              <div style={{ minWidth: 0 }}>
                <div
                  className="mono"
                  style={{
                    fontSize: 22,
                    fontWeight: 600,
                    letterSpacing: "-0.02em",
                    color: s.color,
                    lineHeight: 1.05,
                  }}
                >
                  {s.value}
                </div>
                <div
                  style={{
                    fontSize: 12,
                    color: "var(--text-dim)",
                    marginTop: 2,
                    lineHeight: 1.35,
                  }}
                >
                  {s.label}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </FadeUp>
  );
}
