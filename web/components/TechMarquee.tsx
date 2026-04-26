"use client";

import { m, useReducedMotion } from "framer-motion";

const ITEMS = [
  "Swift 5.10",
  "SwiftUI",
  "Structured concurrency",
  "TaskGroup",
  "FSEvents",
  "FileManager.trashItem",
  "SMAppService",
  "XPC",
  "Ed25519",
  "GRDB",
  "macOS 13+",
  "Universal binary",
];

/**
 * Subtle infinite marquee strip listing the *real* APIs powering the app.
 * Doubles as a subtle "what we're built on" trust signal between hero
 * and the honesty card.
 */
export function TechMarquee() {
  const reduce = useReducedMotion();
  // Duplicate the list so the loop is seamless when the first copy slides off.
  const list = [...ITEMS, ...ITEMS];
  return (
    <section
      className="relative overflow-hidden"
      style={{
        padding: "32px 0",
        borderTop: "1px solid var(--border)",
        borderBottom: "1px solid var(--border)",
        background:
          "linear-gradient(90deg, transparent, var(--surface) 30%, var(--surface) 70%, transparent)",
        maskImage:
          "linear-gradient(90deg, transparent, black 10%, black 90%, transparent)",
        WebkitMaskImage:
          "linear-gradient(90deg, transparent, black 10%, black 90%, transparent)",
      }}
    >
      <m.div
        className="flex items-center gap-12 whitespace-nowrap"
        animate={reduce ? undefined : { x: ["0%", "-50%"] }}
        transition={{
          duration: 32,
          repeat: Infinity,
          ease: "linear",
        }}
        style={{ width: "200%" }}
      >
        {list.map((it, i) => (
          <span
            key={i}
            className="mono inline-flex items-center gap-3"
            style={{
              fontSize: 13,
              color: "var(--text-dim)",
              letterSpacing: "0.04em",
            }}
          >
            <span
              aria-hidden
              style={{
                width: 5,
                height: 5,
                borderRadius: 999,
                background: "var(--accent)",
                boxShadow: "0 0 10px var(--accent-ring)",
              }}
            />
            {it}
          </span>
        ))}
      </m.div>
    </section>
  );
}
