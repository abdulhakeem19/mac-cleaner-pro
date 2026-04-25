"use client";

import { AnimatePresence, motion } from "framer-motion";
import { Minus, Plus } from "lucide-react";
import { useState } from "react";
import { faq } from "@/content/site";
import { BlurIn, FadeUp } from "./Motion";

export function FAQ() {
  const [open, setOpen] = useState<number>(0);

  return (
    <section id="faq" className="section">
      <div className="container-x" style={{ maxWidth: 880 }}>
        <div className="text-center mb-12">
          <BlurIn>
            <div className="eyebrow" style={{ marginBottom: 20 }}>
              <span className="eyebrow-dot" />
              {faq.eyebrow}
            </div>
          </BlurIn>
          <FadeUp delay={1}>
            <h2 className="h-section">
              {faq.title}{" "}
              <span className="gradient-text">{faq.titleGradient}</span>
            </h2>
          </FadeUp>
        </div>
        <div className="flex flex-col gap-2.5">
          {faq.items.map((it, i) => {
            const o = open === i;
            return (
              <FadeUp key={i}>
                <div
                  className="glass overflow-hidden"
                  style={{
                    padding: 0,
                    borderColor: o ? "var(--accent-ring)" : "var(--border)",
                  }}
                >
                  <button
                    onClick={() => setOpen(o ? -1 : i)}
                    className="w-full text-left"
                    style={{
                      padding: "20px 24px",
                      background: "transparent",
                      border: "none",
                      color: "var(--text)",
                      cursor: "pointer",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "space-between",
                      fontFamily: "inherit",
                      fontSize: 16,
                      fontWeight: 500,
                      letterSpacing: "-0.01em",
                    }}
                  >
                    {it.q}
                    <span
                      style={{
                        color: "var(--text-dim)",
                        flexShrink: 0,
                        marginLeft: 16,
                      }}
                    >
                      {o ? <Minus size={18} /> : <Plus size={18} />}
                    </span>
                  </button>
                  <AnimatePresence initial={false}>
                    {o && (
                      <motion.div
                        key="content"
                        initial={{ height: 0, opacity: 0 }}
                        animate={{ height: "auto", opacity: 1 }}
                        exit={{ height: 0, opacity: 0 }}
                        transition={{ duration: 0.36, ease: [0.22, 1, 0.36, 1] }}
                        style={{ overflow: "hidden" }}
                      >
                        <div
                          style={{
                            padding: "0 24px 22px",
                            fontSize: 14.5,
                            color: "var(--text-dim)",
                            lineHeight: 1.6,
                          }}
                        >
                          {it.a}
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>
              </FadeUp>
            );
          })}
        </div>
      </div>
    </section>
  );
}
