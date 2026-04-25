"use client";

import { motion, useScroll, useTransform } from "framer-motion";
import { Apple, PlayCircle } from "lucide-react";
import Link from "next/link";
import { useRef } from "react";
import { hero } from "@/content/site";
import { AppDashboard } from "./app-mockup/AppDashboard";
import { AppWindow } from "./app-mockup/AppWindow";
import { HeroStats } from "./HeroStats";
import { BlurIn, FadeUp, ScaleUp } from "./Motion";

export function Hero() {
  const ref = useRef<HTMLElement>(null);
  // Parallax floats — orbs drift slower than the rest of the content.
  const { scrollY } = useScroll();
  const orbA = useTransform(scrollY, [0, 600], [0, -120]);
  const orbB = useTransform(scrollY, [0, 600], [0, -180]);

  return (
    <section
      ref={ref}
      className="section noise"
      style={{ paddingTop: 160, paddingBottom: 80, position: "relative" }}
    >
      <motion.div
        aria-hidden
        style={{
          position: "absolute",
          top: 100,
          left: "10%",
          width: 380,
          height: 380,
          background: "radial-gradient(circle, rgba(10,132,255,0.35), transparent 70%)",
          filter: "blur(60px)",
          pointerEvents: "none",
          y: orbA,
        }}
      />
      <motion.div
        aria-hidden
        style={{
          position: "absolute",
          top: 300,
          right: "8%",
          width: 420,
          height: 420,
          background: "radial-gradient(circle, rgba(124,92,255,0.28), transparent 70%)",
          filter: "blur(80px)",
          pointerEvents: "none",
          y: orbB,
        }}
      />

      <div className="container-x relative text-center">
        <BlurIn>
          <div className="eyebrow" style={{ marginBottom: 24 }}>
            <span className="eyebrow-dot" />
            {hero.eyebrow}
          </div>
        </BlurIn>

        <FadeUp delay={1}>
          <h1 className="h-display" style={{ maxWidth: 1000, margin: "0 auto" }}>
            {hero.headlineTop}{" "}
            <span className="gradient-text">{hero.headlineGradient}</span>
            <br />
            {hero.headlineSubPrefix}{" "}
            <span className="mono" style={{ fontWeight: 600 }}>
              {hero.headlineSubNum}
            </span>{" "}
            {hero.headlineSubAfter}
          </h1>
        </FadeUp>

        <FadeUp delay={2}>
          <p
            className="lede"
            style={{ margin: "24px auto 0", fontSize: 20, textAlign: "center" }}
          >
            {hero.description}
          </p>
        </FadeUp>

        <FadeUp delay={3}>
          <div
            style={{
              display: "flex",
              gap: 12,
              justifyContent: "center",
              marginTop: 34,
              flexWrap: "wrap",
            }}
          >
            <Link
              href={hero.primaryCta.href}
              className="btn btn-primary"
              style={{ padding: "14px 24px", fontSize: 16 }}
            >
              <Apple size={16} /> {hero.primaryCta.label}
            </Link>
            <Link
              href={hero.secondaryCta.href}
              className="btn btn-secondary"
              style={{ padding: "14px 24px", fontSize: 16 }}
            >
              <PlayCircle size={16} /> {hero.secondaryCta.label}
            </Link>
          </div>
        </FadeUp>

        <FadeUp delay={4}>
          <div
            style={{
              display: "flex",
              gap: 20,
              justifyContent: "center",
              marginTop: 20,
              fontSize: 13,
              color: "var(--text-muted)",
              flexWrap: "wrap",
            }}
          >
            {hero.bullets.map((b) => (
              <span key={b}>✓ {b}</span>
            ))}
          </div>
        </FadeUp>

        <div style={{ maxWidth: 880, margin: "0 auto" }}>
          <HeroStats />
        </div>

        <ScaleUp delay={5}>
          <div style={{ marginTop: 72, perspective: 2000 }}>
            <div
              style={{
                transform: "rotateX(8deg)",
                transformOrigin: "center bottom",
                margin: "0 auto",
                maxWidth: 1120,
              }}
            >
              <AppWindow title="Mac Cleaner Pro — Smart Scan" height={560}>
                <AppDashboard />
              </AppWindow>
            </div>
            <div
              aria-hidden
              style={{
                width: 800,
                height: 140,
                margin: "-40px auto 0",
                background:
                  "radial-gradient(ellipse at center, rgba(124,92,255,0.4), transparent 65%)",
                filter: "blur(30px)",
              }}
            />
          </div>
        </ScaleUp>

        <FadeUp delay={6}>
          <motion.div
            className="inline-flex items-center gap-3 mt-14 px-4 py-2 rounded-full"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 1.2, delay: 0.6 }}
            style={{
              background: "var(--surface)",
              border: "1px solid var(--border)",
              fontSize: 13,
              color: "var(--text-dim)",
              backdropFilter: "blur(12px)",
              WebkitBackdropFilter: "blur(12px)",
            }}
          >
            <span
              aria-hidden
              style={{
                width: 8,
                height: 8,
                borderRadius: 999,
                background: "var(--ok)",
                boxShadow: "0 0 12px rgba(48,209,88,0.6)",
              }}
            />
            <span>{hero.trustBlurb}</span>
          </motion.div>
        </FadeUp>
      </div>
    </section>
  );
}
