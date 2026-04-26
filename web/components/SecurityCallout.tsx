"use client";

import { Lock } from "lucide-react";
import { security } from "@/content/site";
import { FadeUp } from "./Motion";

export function SecurityCallout() {
  return (
    <section className="section">
      <div className="container-x">
        <FadeUp>
          <div
            className="glass relative overflow-hidden px-5 py-8 md:px-12 md:py-12"
          >
            <div
              aria-hidden
              style={{
                position: "absolute",
                inset: 0,
                background:
                  "radial-gradient(800px 300px at 80% 50%, rgba(48,209,88,0.12), transparent 60%)",
                pointerEvents: "none",
              }}
            />
            <div className="relative grid gap-10 md:grid-cols-[auto_1fr_auto] items-center">
              <div
                style={{
                  width: 80,
                  height: 80,
                  borderRadius: 22,
                  background:
                    "linear-gradient(135deg, rgba(48,209,88,0.25), rgba(48,209,88,0.05))",
                  border: "1px solid rgba(48,209,88,0.35)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  color: "#30D158",
                }}
              >
                <Lock size={36} />
              </div>
              <div>
                <div
                  style={{
                    fontSize: 12,
                    letterSpacing: "0.16em",
                    textTransform: "uppercase",
                    color: "var(--text-muted)",
                    marginBottom: 8,
                  }}
                >
                  {security.eyebrow}
                </div>
                <h3
                  style={{
                    fontSize: 28,
                    fontWeight: 600,
                    letterSpacing: "-0.02em",
                    lineHeight: 1.2,
                  }}
                >
                  {security.title}
                </h3>
                <p style={{ fontSize: 15, marginTop: 10, maxWidth: 700 }}>
                  {security.body}
                </p>
                <p
                  style={{
                    fontSize: 13,
                    marginTop: 10,
                    color: "var(--text-muted)",
                    maxWidth: 700,
                  }}
                >
                  {security.honestyLine}
                </p>
              </div>
              <div className="flex flex-col gap-2.5 md:items-end">
                {security.badges.map((b) => (
                  <div key={b} className="pill pill-ok">
                    {b}
                  </div>
                ))}
              </div>
            </div>
          </div>
        </FadeUp>
      </div>
    </section>
  );
}
