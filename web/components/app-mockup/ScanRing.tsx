"use client";

import { m, useReducedMotion } from "framer-motion";

/**
 * Animated SVG progress ring. The outer arc length tracks `progress` (0..1).
 * A faint pulsing inner ring sells "live scanning" without burning CPU.
 */
export function ScanRing({
  size = 200,
  progress,
  label,
  sub,
}: {
  size?: number;
  progress: number;
  label: string;
  sub?: string;
}) {
  const reduce = useReducedMotion();
  const stroke = 9;
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const dash = c * Math.max(0, Math.min(1, progress));
  return (
    <div className="relative" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="block" aria-hidden>
        <defs>
          <linearGradient id="scanGrad" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor="#0A84FF" />
            <stop offset="60%" stopColor="#7C5CFF" />
            <stop offset="100%" stopColor="#B47BFF" />
          </linearGradient>
        </defs>
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          stroke="rgba(255,255,255,0.06)"
          strokeWidth={stroke}
          fill="none"
        />
        <m.circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          stroke="url(#scanGrad)"
          strokeWidth={stroke}
          strokeLinecap="round"
          fill="none"
          strokeDasharray={`${dash} ${c}`}
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
          initial={false}
          animate={{ strokeDasharray: `${dash} ${c}` }}
          transition={{ duration: reduce ? 0 : 0.6, ease: [0.22, 1, 0.36, 1] }}
        />
      </svg>
      <div
        className="absolute inset-0 flex flex-col items-center justify-center"
        style={{ fontFamily: "var(--font-mono)" }}
      >
        <div
          style={{ fontSize: size * 0.115, fontWeight: 600, letterSpacing: "-0.02em", lineHeight: 1 }}
        >
          {label}
        </div>
        {sub && (
          <div
            style={{
              fontSize: 11,
              color: "var(--text-muted)",
              letterSpacing: "0.18em",
              textTransform: "uppercase",
              marginTop: 2,
            }}
          >
            {sub}
          </div>
        )}
      </div>
    </div>
  );
}
