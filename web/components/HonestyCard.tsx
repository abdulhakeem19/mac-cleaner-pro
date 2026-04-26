"use client";

import { Check, Sparkles } from "lucide-react";
import { honestyCard } from "@/content/site";
import { BlurIn, FadeUp, Stagger, StaggerItem } from "./Motion";

/**
 * Trust-anchor card. Sits between Hero and Smart Scan demo. Differentiates
 * from "trust me bro" cleaners by being explicit about scope, gates, and roadmap.
 */
export function HonestyCard() {
  return (
    <section className="section" style={{ paddingTop: 40, paddingBottom: 40 }}>
      <div className="container-x">
        <FadeUp>
          <div className="glass relative overflow-hidden px-5 py-8 md:p-10">
            <div
              aria-hidden
              style={{
                position: "absolute",
                inset: 0,
                background:
                  "radial-gradient(700px 240px at 90% 0%, rgba(124,92,255,0.18), transparent 60%)",
                pointerEvents: "none",
              }}
            />
            <div className="relative grid gap-10 md:grid-cols-[1fr_360px] items-start">
              <div>
                <BlurIn>
                  <div className="eyebrow" style={{ marginBottom: 14 }}>
                    <span className="eyebrow-dot" />
                    {honestyCard.eyebrow}
                  </div>
                </BlurIn>
                <h2
                  className="h-section"
                  style={{ fontSize: "clamp(28px, 3vw, 42px)", marginBottom: 16 }}
                >
                  {honestyCard.title}
                </h2>
                <Stagger className="flex flex-col gap-3" step={0.06}>
                  {honestyCard.body.map((p, i) => (
                    <StaggerItem key={i}>
                      <p style={{ fontSize: 15.5 }}>{p}</p>
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
                }}
              >
                <div
                  className="flex items-center gap-2 mb-3"
                  style={{ color: "var(--accent)" }}
                >
                  <Sparkles size={16} />
                  <div
                    style={{
                      fontSize: 11,
                      letterSpacing: "0.16em",
                      textTransform: "uppercase",
                      fontWeight: 600,
                    }}
                  >
                    What this means for you
                  </div>
                </div>
                <ul className="flex flex-col gap-2.5 m-0 p-0 list-none">
                  {honestyCard.bullets.map((b) => (
                    <li
                      key={b}
                      className="flex items-start gap-2.5"
                      style={{ fontSize: 13.5, color: "var(--text)" }}
                    >
                      <span
                        className="shrink-0 mt-0.5"
                        style={{
                          width: 18,
                          height: 18,
                          borderRadius: 999,
                          background: "var(--accent-soft)",
                          color: "var(--accent)",
                          display: "inline-flex",
                          alignItems: "center",
                          justifyContent: "center",
                        }}
                      >
                        <Check size={12} strokeWidth={3} />
                      </span>
                      {b}
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </div>
        </FadeUp>
      </div>
    </section>
  );
}
