"use client";

import { m } from "framer-motion";
import {
  Sparkles,
  Search,
  Trash2,
  Clock,
  ChevronRight,
} from "lucide-react";
import { ScanRing } from "./ScanRing";

/**
 * The faux Smart Scan dashboard rendered inside the hero's AppWindow.
 * Mirrors the actual app's three-pane sidebar + content layout so the
 * landing page screenshot is grounded in real UI shapes.
 */
export function AppDashboard() {
  const items = [
    { i: Sparkles, t: "Smart Scan", c: "var(--accent)", active: true },
    { i: Search, t: "Large & Old Files", c: "var(--text-dim)" },
    { i: Trash2, t: "App Uninstaller", c: "var(--text-dim)" },
    { i: Clock, t: "Activity Log", c: "var(--text-dim)" },
  ];
  const rules = [
    { name: "User caches", size: "3.03 GB", safety: "Safe", c: "var(--ok)", checked: true, items: "82 items" },
    { name: "Xcode DerivedData", size: "3.33 GB", safety: "Safe", c: "var(--ok)", checked: true, items: "5 items" },
    { name: "User logs", size: "1.9 MB", safety: "Safe", c: "var(--ok)", checked: true, items: "87 items" },
    { name: "Chrome cache", size: "3.7 MB", safety: "Safe", c: "var(--ok)", checked: true, items: "2 items" },
    { name: "System caches", size: "—", safety: "Helper", c: "var(--warn)", checked: false, items: "Approve helper" },
  ];

  return (
    <div className="grid h-full" style={{ gridTemplateColumns: "200px 1fr" }}>
      <aside
        style={{
          background: "linear-gradient(180deg, var(--bg-2), var(--bg-1))",
          borderRight: "1px solid var(--border)",
          padding: "18px 12px",
        }}
      >
        <div
          style={{
            fontSize: 11,
            letterSpacing: "0.16em",
            textTransform: "uppercase",
            color: "var(--text-muted)",
            padding: "6px 10px 12px",
          }}
        >
          Mac Cleaner Pro
        </div>
        {items.map((it, i) => {
          const Ic = it.i;
          return (
            <div
              key={i}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 10,
                padding: "9px 10px",
                borderRadius: 8,
                background: it.active ? "var(--accent-soft)" : "transparent",
                color: it.active ? "var(--accent)" : it.c,
                fontSize: 13,
                marginBottom: 2,
              }}
            >
              <Ic size={16} />
              <span style={{ fontWeight: it.active ? 600 : 500 }}>{it.t}</span>
            </div>
          );
        })}
      </aside>

      <div style={{ padding: 26, position: "relative" }}>
        <div className="flex items-baseline justify-between mb-5">
          <div>
            <div style={{ fontSize: 22, fontWeight: 600, letterSpacing: "-0.02em" }}>
              Smart Scan
            </div>
            <div style={{ fontSize: 12, color: "var(--text-muted)", marginTop: 2 }}>
              Last scanned just now · 6.36 GB reclaimable
            </div>
          </div>
          <div className="flex items-center gap-3">
            <ScanRing size={70} progress={0.85} label="6.36" sub="GB" />
          </div>
        </div>

        <div className="flex flex-col gap-2">
          {rules.map((r, i) => (
            <m.div
              key={i}
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.06 * i, duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
              style={{
                display: "grid",
                gridTemplateColumns: "20px 1fr auto auto",
                gap: 12,
                padding: "12px 14px",
                borderRadius: 10,
                background: "var(--bg-2)",
                border: "1px solid var(--border)",
                alignItems: "center",
              }}
            >
              <div
                aria-hidden
                style={{
                  width: 16,
                  height: 16,
                  borderRadius: 4,
                  background: r.checked ? "var(--accent-grad)" : "transparent",
                  border: r.checked ? "none" : "1.5px solid var(--border-hi)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  color: "white",
                  fontSize: 10,
                }}
              >
                {r.checked ? "✓" : ""}
              </div>
              <div>
                <div style={{ fontSize: 13, fontWeight: 500 }}>{r.name}</div>
                <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 1 }}>
                  {r.items}
                </div>
              </div>
              <span
                className="pill"
                style={{
                  background: `color-mix(in oklab, ${r.c} 14%, transparent)`,
                  color: r.c,
                  borderColor: `color-mix(in oklab, ${r.c} 32%, transparent)`,
                  padding: "2px 8px",
                  fontSize: 10,
                }}
              >
                {r.safety}
              </span>
              <div
                className="mono"
                style={{
                  fontSize: 13,
                  fontWeight: 500,
                  color: r.c === "var(--warn)" ? "var(--text-muted)" : "var(--text)",
                  minWidth: 64,
                  textAlign: "right",
                }}
              >
                {r.size}
              </div>
            </m.div>
          ))}
        </div>

        <div
          className="flex items-center justify-between mt-5 pt-4"
          style={{ borderTop: "1px solid var(--border)" }}
        >
          <div style={{ fontSize: 12, color: "var(--text-dim)" }}>
            Reclaimable: <span className="mono" style={{ color: "var(--text)", fontWeight: 600 }}>6.36 GB</span>
          </div>
          <div className="btn btn-primary" style={{ padding: "8px 16px", fontSize: 13 }}>
            Clean Selected <ChevronRight size={14} />
          </div>
        </div>
      </div>
    </div>
  );
}
