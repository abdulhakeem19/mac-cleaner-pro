"use client";

import { PlayCircle } from "lucide-react";
import { AppleLogo } from "./Logo";
import Link from "next/link";
import { hero } from "@/content/site";
import { AppDashboard } from "./app-mockup/AppDashboard";
import { AppWindow } from "./app-mockup/AppWindow";
import { HeroStats } from "./HeroStats";

export function Hero() {
  return (
    <section
      className="section noise pt-28 md:pt-40"
      style={{ paddingBottom: 80, position: "relative" }}
    >
      <div
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
        }}
      />
      <div
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
        }}
      />

      <div className="container-x relative text-center">
        <div
          className="hero-anim"
          style={{ animationName: "hero-blur-in", animationDuration: "0.85s", animationDelay: "0s" }}
        >
          <div className="eyebrow" style={{ marginBottom: 24 }}>
            <span className="eyebrow-dot" />
            {hero.eyebrow}
          </div>
        </div>

        <h1
          className="h-display hero-anim"
          style={{
            maxWidth: 1000,
            margin: "0 auto",
            animationName: "hero-fade-up",
            animationDuration: "0.8s",
            animationDelay: "0.05s",
          }}
        >
          {hero.headlineTop}{" "}
          <span className="gradient-text">{hero.headlineGradient}</span>
          <br />
          {hero.headlineSubPrefix}{" "}
          <span className="mono" style={{ fontWeight: 600 }}>
            {hero.headlineSubNum}
          </span>{" "}
          {hero.headlineSubAfter}
        </h1>

        {/* Lede — CSS fade-up so it's visible immediately at parse time (no JS needed → fast LCP) */}
        <p
          className="lede hero-anim"
          style={{
            margin: "24px auto 0",
            fontSize: 20,
            textAlign: "center",
            animationName: "hero-fade-up",
            animationDuration: "0.75s",
            animationDelay: "0.1s",
          }}
        >
          {hero.description}
        </p>

        <div
          className="hero-anim"
          style={{ animationName: "hero-fade-up", animationDuration: "0.75s", animationDelay: "0.2s" }}
        >
          <div
            className="flex flex-col sm:flex-row justify-center flex-wrap"
            style={{ gap: 12, marginTop: 34 }}
          >
            <Link
              href={hero.primaryCta.href}
              className="btn btn-primary"
              style={{ padding: "14px 24px", fontSize: 16 }}
            >
              <AppleLogo size={16} /> {hero.primaryCta.label}
            </Link>
            <Link
              href={hero.secondaryCta.href}
              className="btn btn-secondary"
              style={{ padding: "14px 24px", fontSize: 16 }}
            >
              <PlayCircle size={16} /> {hero.secondaryCta.label}
            </Link>
          </div>
        </div>

        <div
          className="hero-anim"
          style={{ animationName: "hero-fade-up", animationDuration: "0.75s", animationDelay: "0.3s" }}
        >
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
        </div>

        <div style={{ maxWidth: 880, margin: "0 auto" }}>
          <HeroStats />
        </div>

        <div
          className="hero-anim"
          style={{ animationName: "hero-scale-up", animationDuration: "0.9s", animationDelay: "0.35s" }}
        >
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
        </div>

        <div
          className="hero-anim"
          style={{ animationName: "hero-fade-in", animationDuration: "0.7s", animationDelay: "0.5s" }}
        >
          <div
            className="inline-flex items-center gap-3 mt-14 px-4 py-2 rounded-full"
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
          </div>
        </div>
      </div>
    </section>
  );
}
