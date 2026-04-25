"use client";

import { systemReq } from "@/content/site";
import { BlurIn, FadeLeft, FadeUp } from "./Motion";

export function SystemRequirements() {
  return (
    <section className="section">
      <div className="container-x" style={{ maxWidth: 980 }}>
        <div className="grid gap-10 md:grid-cols-[1fr_1.4fr] items-start">
          <div>
            <BlurIn>
              <div className="eyebrow" style={{ marginBottom: 20 }}>
                <span className="eyebrow-dot" />
                {systemReq.eyebrow}
              </div>
            </BlurIn>
            <FadeUp delay={1}>
              <h2
                style={{
                  fontSize: 36,
                  fontWeight: 600,
                  letterSpacing: "-0.02em",
                  lineHeight: 1.1,
                }}
              >
                {systemReq.title}
              </h2>
            </FadeUp>
            <p
              style={{
                fontSize: 14.5,
                marginTop: 16,
                color: "var(--text-dim)",
              }}
            >
              {systemReq.body}
            </p>
          </div>
          <FadeLeft>
            <div className="glass" style={{ padding: 8 }}>
              {systemReq.rows.map((r, i) => {
                const last = i === systemReq.rows.length - 1;
                return (
                  <div
                    key={r.k}
                    className="grid"
                    style={{
                      gridTemplateColumns: "140px 1fr",
                      padding: "16px 20px",
                      borderBottom: last ? "none" : "1px solid var(--border)",
                      fontSize: 14,
                    }}
                  >
                    <div
                      style={{
                        color: "var(--text-muted)",
                        letterSpacing: "0.06em",
                        textTransform: "uppercase",
                        fontSize: 11,
                        paddingTop: 3,
                      }}
                    >
                      {r.k}
                    </div>
                    <div style={{ color: "var(--text)" }}>{r.v}</div>
                  </div>
                );
              })}
            </div>
          </FadeLeft>
        </div>
      </div>
    </section>
  );
}
