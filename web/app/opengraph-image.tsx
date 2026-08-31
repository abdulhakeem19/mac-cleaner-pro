import { ImageResponse } from "next/og";
import { brand } from "@/content/site";

/**
 * Build-time OG card. 1200×630 — the canonical Twitter/Facebook/LinkedIn/iMessage size.
 * `next/og` runs in an Edge-like environment, so we keep the markup simple:
 * - No `<svg>` glyphs that aren't in the default font
 * - Single background gradient (no comma-separated layers; satori is picky)
 * - Plain ASCII only — emoji/unicode requires a network font fetch we don't want at build
 */
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";
export const alt = `${brand.name} — privacy-first macOS cleaner`;
export const dynamic = "force-static";

export default function OG() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: 80,
          background:
            "linear-gradient(135deg, #0A0B0F 0%, #14171F 50%, #1A1530 100%)",
          color: "#F4F6FA",
          fontFamily: "system-ui, -apple-system, BlinkMacSystemFont, sans-serif",
        }}
      >
        {/* Decorative orbs (single layered gradient, satori-safe) */}
        <div
          style={{
            position: "absolute",
            top: -120,
            right: -120,
            width: 600,
            height: 600,
            borderRadius: 9999,
            background:
              "radial-gradient(circle, rgba(124,92,255,0.45) 0%, rgba(124,92,255,0) 70%)",
            display: "flex",
          }}
        />
        <div
          style={{
            position: "absolute",
            bottom: -180,
            left: -120,
            width: 700,
            height: 700,
            borderRadius: 9999,
            background:
              "radial-gradient(circle, rgba(10,132,255,0.35) 0%, rgba(10,132,255,0) 70%)",
            display: "flex",
          }}
        />

        <div style={{ display: "flex", alignItems: "center", gap: 16, position: "relative" }}>
          <div
            style={{
              width: 56,
              height: 56,
              borderRadius: 14,
              background:
                "linear-gradient(135deg,#0A84FF 0%,#7C5CFF 60%,#B47BFF 100%)",
              boxShadow: "0 12px 32px -8px rgba(124,92,255,0.7)",
              display: "flex",
            }}
          />
          <div style={{ fontSize: 32, fontWeight: 600, letterSpacing: "-0.02em" }}>
            {brand.name}
          </div>
        </div>

        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: 18,
            position: "relative",
          }}
        >
          <div
            style={{
              fontSize: 90,
              fontWeight: 700,
              letterSpacing: "-0.04em",
              lineHeight: 1.0,
            }}
          >
            Reclaim disk space.
          </div>
          <div
            style={{
              fontSize: 46,
              fontWeight: 600,
              letterSpacing: "-0.03em",
              lineHeight: 1.05,
              background: "linear-gradient(135deg,#0A84FF,#7C5CFF,#B47BFF)",
              backgroundClip: "text",
              color: "transparent",
              display: "flex",
            }}
          >
            Privacy-first. Free & open source.
          </div>
        </div>

        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "flex-end",
            color: "#A4ABB8",
            fontSize: 22,
            position: "relative",
          }}
        >
          <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
            <div>Native Swift -- macOS 13+ -- Apple Silicon &amp; Intel</div>
            <div>MIT licensed -- no subscription -- zero telemetry</div>
          </div>
          <div
            style={{
              padding: "10px 22px",
              borderRadius: 999,
              background: "linear-gradient(135deg,#0A84FF,#7C5CFF)",
              color: "white",
              fontSize: 22,
              fontWeight: 600,
              display: "flex",
            }}
          >
            {brand.domain}
          </div>
        </div>
      </div>
    ),
    { ...size },
  );
}
