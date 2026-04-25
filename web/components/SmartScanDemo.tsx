"use client";

import { motion, AnimatePresence } from "framer-motion";
import { useEffect, useState } from "react";
import { smartScanDemo } from "@/content/site";
import { BlurIn, FadeLeft, FadeUp } from "./Motion";
import { ScanRing } from "./app-mockup/ScanRing";

export function SmartScanDemo() {
  const steps = smartScanDemo.steps;
  const [step, setStep] = useState(0);

  useEffect(() => {
    const t = setInterval(() => setStep((s) => (s + 1) % steps.length), 1800);
    return () => clearInterval(t);
  }, [steps.length]);

  const progress = 0.12 + (step / steps.length) * 0.85;
  const reclaimed = (progress * 78).toFixed(1);

  return (
    <section id="scan" className="section">
      <div className="container-x">
        <div className="grid gap-12 md:gap-16 md:grid-cols-2 items-center">
          <div>
            <BlurIn>
              <div className="eyebrow" style={{ marginBottom: 20 }}>
                <span className="eyebrow-dot" />
                {smartScanDemo.eyebrow}
              </div>
            </BlurIn>
            <FadeUp delay={1}>
              <h2 className="h-section">
                {smartScanDemo.title}
                <br />
                <span className="gradient-text">{smartScanDemo.titleGradient}</span>
              </h2>
            </FadeUp>
            <FadeUp delay={2}>
              <p className="lede" style={{ marginTop: 24, maxWidth: 520 }}>
                {smartScanDemo.description}
              </p>
            </FadeUp>
            <FadeUp delay={3}>
              <div className="flex gap-3.5 mt-7 flex-wrap">
                {smartScanDemo.stats.map((s, i) => (
                  <div
                    key={i}
                    style={{
                      padding: "14px 18px",
                      borderRadius: 14,
                      background: "var(--surface)",
                      border: "1px solid var(--border)",
                      minWidth: 130,
                    }}
                  >
                    <div
                      className="mono"
                      style={{
                        fontSize: 18,
                        fontWeight: 600,
                        letterSpacing: "-0.02em",
                        color: "var(--text)",
                      }}
                    >
                      {s.k}
                    </div>
                    <div
                      style={{ fontSize: 12, color: "var(--text-dim)", marginTop: 2 }}
                    >
                      {s.v}
                    </div>
                  </div>
                ))}
              </div>
            </FadeUp>
          </div>

          <FadeLeft>
            <div className="glass relative overflow-hidden" style={{ padding: 28 }}>
              <div className="flex items-start justify-between mb-5">
                <div>
                  <div
                    style={{
                      fontSize: 12,
                      letterSpacing: "0.14em",
                      textTransform: "uppercase",
                      color: "var(--text-muted)",
                    }}
                  >
                    Live
                  </div>
                  <div style={{ fontSize: 18, fontWeight: 600, marginTop: 2 }}>
                    Smart Scan in progress
                  </div>
                </div>
                <span className="pill pill-accent">
                  <span
                    style={{
                      width: 6,
                      height: 6,
                      borderRadius: "50%",
                      background: "var(--accent)",
                      animation: "pulse 1.2s infinite",
                    }}
                  />
                  {Math.round(progress * 100)}%
                </span>
              </div>

              <div className="flex justify-center mb-5">
                <ScanRing
                  size={200}
                  progress={progress}
                  label={`${reclaimed} GB`}
                  sub="scanned"
                />
              </div>

              <div className="flex flex-col gap-2">
                {steps.map((s, i) => {
                  const state = i < step ? "done" : i === step ? "active" : "pending";
                  return (
                    <motion.div
                      key={i}
                      animate={{
                        backgroundColor:
                          state === "active" ? "rgba(124,92,255,0.15)" : "rgba(0,0,0,0)",
                        borderColor:
                          state === "active" ? "rgba(124,92,255,0.35)" : "rgba(0,0,0,0)",
                        opacity: state === "pending" ? 0.4 : 1,
                      }}
                      transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: 12,
                        padding: "10px 14px",
                        borderRadius: 10,
                        border: "1px solid transparent",
                      }}
                    >
                      <div
                        style={{
                          width: 18,
                          height: 18,
                          borderRadius: "50%",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          background:
                            state === "done"
                              ? "var(--ok)"
                              : state === "active"
                                ? "var(--accent-grad)"
                                : "var(--bg-3)",
                          color: "white",
                          fontSize: 10,
                          flexShrink: 0,
                        }}
                      >
                        <AnimatePresence mode="wait">
                          {state === "done" && (
                            <motion.span
                              key="done"
                              initial={{ scale: 0.5, opacity: 0 }}
                              animate={{ scale: 1, opacity: 1 }}
                              exit={{ opacity: 0 }}
                            >
                              ✓
                            </motion.span>
                          )}
                          {state === "active" && (
                            <motion.span
                              key="active"
                              animate={{ rotate: 360 }}
                              transition={{ duration: 1.4, repeat: Infinity, ease: "linear" }}
                              style={{ display: "inline-block" }}
                            >
                              ⟳
                            </motion.span>
                          )}
                        </AnimatePresence>
                      </div>
                      <div className="flex-1 min-w-0">
                        <div style={{ fontSize: 13, fontWeight: 500 }}>{s.t}</div>
                        <div
                          className="mono"
                          style={{
                            fontSize: 11,
                            color: "var(--text-muted)",
                            whiteSpace: "nowrap",
                            overflow: "hidden",
                            textOverflow: "ellipsis",
                          }}
                        >
                          {s.path}
                        </div>
                      </div>
                      <div
                        className="mono"
                        style={{
                          fontSize: 12,
                          color: state === "done" ? "var(--ok)" : "var(--text-dim)",
                        }}
                      >
                        {state === "pending" ? "—" : s.found}
                      </div>
                    </motion.div>
                  );
                })}
              </div>
            </div>
          </FadeLeft>
        </div>
      </div>
    </section>
  );
}
