"use client";

import {
  Activity,
  ArrowUpFromDot,
  Clock as ClockArrowDown,
  Copy,
  FileSignature,
  Layers,
  Search,
  ShieldAlert,
  ShieldCheck,
  Sparkles,
  Trash2,
  Undo2,
  type LucideIcon,
} from "lucide-react";
import { featuresGrid } from "@/content/site";
import { BlurIn, FadeUp, Stagger, StaggerItem } from "./Motion";

const ICON_MAP: Record<string, LucideIcon> = {
  Sparkles,
  Search,
  Trash2,
  ClockArrowDown,
  ArrowUpFromDot,
  Undo2,
  ShieldCheck,
  FileSignature,
  Copy,
  Activity,
  Layers,
  ShieldAlert,
};

export function FeaturesGrid() {
  return (
    <section id="features" className="section">
      <div className="container-x">
        <div className="text-center mb-16">
          <BlurIn>
            <div className="eyebrow" style={{ marginBottom: 20 }}>
              <span className="eyebrow-dot" />
              {featuresGrid.eyebrow}
            </div>
          </BlurIn>
          <FadeUp delay={1}>
            <h2 className="h-section" style={{ maxWidth: 800, margin: "0 auto" }}>
              {featuresGrid.title}{" "}
              <span className="gradient-text">{featuresGrid.titleGradient}</span>
            </h2>
          </FadeUp>
          <FadeUp delay={2}>
            <p
              className="lede"
              style={{ margin: "20px auto 0", textAlign: "center" }}
            >
              {featuresGrid.description}
            </p>
          </FadeUp>
        </div>

        <div className="flex flex-col gap-7">
          {featuresGrid.groups.map((g, gi) => (
            <FadeUp key={gi}>
              <div
                className="glass relative overflow-hidden"
                style={{ padding: 36 }}
              >
                <div
                  aria-hidden
                  style={{
                    position: "absolute",
                    top: -80,
                    right: -80,
                    width: 280,
                    height: 280,
                    background: `radial-gradient(circle, ${g.color}33, transparent 70%)`,
                    filter: "blur(40px)",
                  }}
                />
                <div className="relative grid gap-10 md:grid-cols-[320px_1fr] items-start">
                  <div>
                    <div
                      className="inline-flex items-center gap-2"
                      style={{
                        padding: "4px 10px",
                        borderRadius: 999,
                        background: `${g.color}18`,
                        border: `1px solid ${g.color}44`,
                        fontSize: 11,
                        letterSpacing: "0.12em",
                        textTransform: "uppercase",
                        color: g.color,
                        fontWeight: 600,
                      }}
                    >
                      <span
                        style={{
                          width: 6,
                          height: 6,
                          borderRadius: "50%",
                          background: g.color,
                        }}
                      />
                      {g.number}
                      {("comingSoon" in g && g.comingSoon) && (
                        <>
                          <span aria-hidden style={{ opacity: 0.4 }}>
                            ·
                          </span>
                          Coming soon
                        </>
                      )}
                    </div>
                    <h3
                      style={{
                        fontSize: 30,
                        fontWeight: 600,
                        letterSpacing: "-0.02em",
                        marginTop: 14,
                        lineHeight: 1.1,
                      }}
                    >
                      {g.title}
                    </h3>
                    <p style={{ marginTop: 12, fontSize: 15 }}>{g.desc}</p>
                  </div>
                  <Stagger
                    className="grid gap-3.5 md:grid-cols-2"
                    step={0.06}
                  >
                    {g.feats.map((f, i) => {
                      const Ic = ICON_MAP[f.icon] ?? Sparkles;
                      const isComingSoon = "comingSoon" in g && g.comingSoon;
                      return (
                        <StaggerItem key={i}>
                          <div
                            className="group transition-all"
                            style={{
                              padding: 18,
                              borderRadius: 14,
                              background: "var(--bg-2)",
                              border: "1px solid var(--border)",
                              transition: "all .3s var(--ease)",
                              opacity: isComingSoon ? 0.85 : 1,
                            }}
                            onMouseEnter={(e) => {
                              e.currentTarget.style.borderColor = `${g.color}66`;
                              e.currentTarget.style.transform = "translateY(-2px)";
                            }}
                            onMouseLeave={(e) => {
                              e.currentTarget.style.borderColor = "var(--border)";
                              e.currentTarget.style.transform = "none";
                            }}
                          >
                            <div className="flex items-center justify-between mb-3">
                              <div
                                style={{
                                  width: 36,
                                  height: 36,
                                  borderRadius: 10,
                                  background: `${g.color}18`,
                                  color: g.color,
                                  display: "flex",
                                  alignItems: "center",
                                  justifyContent: "center",
                                }}
                              >
                                <Ic size={18} />
                              </div>
                              {isComingSoon && (
                                <span
                                  className="pill"
                                  style={{
                                    padding: "2px 8px",
                                    fontSize: 10,
                                    background: "rgba(255,179,64,0.10)",
                                    color: "var(--warn)",
                                    borderColor: "rgba(255,179,64,0.25)",
                                  }}
                                >
                                  Coming soon
                                </span>
                              )}
                            </div>
                            <div
                              style={{
                                fontWeight: 600,
                                fontSize: 14,
                                letterSpacing: "-0.01em",
                              }}
                            >
                              {f.t}
                            </div>
                            <div
                              style={{
                                fontSize: 13,
                                color: "var(--text-dim)",
                                marginTop: 4,
                                lineHeight: 1.5,
                              }}
                            >
                              {f.d}
                            </div>
                          </div>
                        </StaggerItem>
                      );
                    })}
                  </Stagger>
                </div>
              </div>
            </FadeUp>
          ))}
        </div>
      </div>
    </section>
  );
}
