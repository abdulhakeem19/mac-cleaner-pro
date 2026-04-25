"use client";

import { Apple } from "lucide-react";
import Link from "next/link";
import { footerCta } from "@/content/site";
import { FadeUp } from "./Motion";

export function FooterCTA() {
  return (
    <section id="download" className="section" style={{ paddingBottom: 60 }}>
      <div className="container-x">
        <FadeUp>
          <div
            className="glass relative overflow-hidden text-center"
            style={{
              padding: "72px 56px",
              borderColor: "var(--accent-ring)",
            }}
          >
            <div
              aria-hidden
              style={{
                position: "absolute",
                inset: 0,
                background:
                  "radial-gradient(600px 240px at 50% 0%, rgba(124,92,255,0.3), transparent 70%)",
                pointerEvents: "none",
              }}
            />
            <div className="relative">
              <h2 className="h-section" style={{ maxWidth: 780, margin: "0 auto" }}>
                {footerCta.title}{" "}
                <span className="gradient-text">{footerCta.titleGradient}</span>
              </h2>
              <p
                className="lede"
                style={{ margin: "20px auto 0", textAlign: "center" }}
              >
                {footerCta.body}
              </p>
              <div className="flex gap-3 justify-center mt-7 flex-wrap">
                <Link
                  href={footerCta.primary.href}
                  className="btn btn-primary"
                  style={{ padding: "14px 26px", fontSize: 16 }}
                >
                  <Apple size={16} /> {footerCta.primary.label}
                </Link>
                <Link
                  href={footerCta.secondary.href}
                  className="btn btn-ghost"
                  style={{ padding: "14px 26px", fontSize: 16 }}
                >
                  {footerCta.secondary.label}
                </Link>
              </div>
            </div>
          </div>
        </FadeUp>
      </div>
    </section>
  );
}
