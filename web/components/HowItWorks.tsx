"use client";

import { howItWorks } from "@/content/site";
import { BlurIn, FadeUp, Stagger, StaggerItem } from "./Motion";

export function HowItWorks() {
  return (
    <section className="section">
      <div className="container-x">
        <div className="text-center mb-14">
          <BlurIn>
            <div className="eyebrow" style={{ marginBottom: 20 }}>
              <span className="eyebrow-dot" />
              {howItWorks.eyebrow}
            </div>
          </BlurIn>
          <FadeUp delay={1}>
            <h2 className="h-section">
              {howItWorks.title}
              <br />
              <span className="gradient-text">{howItWorks.titleGradient}</span>
            </h2>
          </FadeUp>
        </div>
        <Stagger className="grid gap-7 md:grid-cols-3" step={0.1}>
          {howItWorks.steps.map((s) => (
            <StaggerItem key={s.n}>
              <div className="glass relative overflow-hidden h-full" style={{ padding: 32 }}>
                <div
                  className="mono"
                  style={{
                    fontSize: 72,
                    fontWeight: 600,
                    letterSpacing: "-0.04em",
                    color: "transparent",
                    WebkitTextStroke: "1px var(--border-hi)",
                    lineHeight: 1,
                    marginBottom: 16,
                  }}
                >
                  {s.n}
                </div>
                <div
                  style={{
                    fontSize: 22,
                    fontWeight: 600,
                    letterSpacing: "-0.02em",
                    marginBottom: 8,
                  }}
                >
                  {s.t}
                </div>
                <div
                  style={{
                    fontSize: 14.5,
                    color: "var(--text-dim)",
                    lineHeight: 1.55,
                  }}
                >
                  {s.d}
                </div>
              </div>
            </StaggerItem>
          ))}
        </Stagger>
      </div>
    </section>
  );
}
