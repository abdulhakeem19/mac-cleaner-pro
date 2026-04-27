"use client";

import { AnimatePresence, m, useScroll, useTransform } from "framer-motion";
import { Menu, X } from "lucide-react";
import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { AppleLogo, LogoLockup } from "./Logo";
import { ThemeToggle } from "./ThemeToggle";
import { nav } from "@/content/site";

const glassStyle = {
  background: "var(--surface-hi)",
  border: "1px solid var(--border)",
  backdropFilter: "blur(24px) saturate(160%)",
  WebkitBackdropFilter: "blur(24px) saturate(160%)",
} as const;

export function Nav() {
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  const { scrollY } = useScroll();
  const padding = useTransform(scrollY, [0, 80], [10, 7]);
  const shadow = useTransform(scrollY, [0, 80], [
    "0 1px 0 rgba(255,255,255,0.04) inset, 0 10px 30px -20px rgba(0,0,0,0.5)",
    "0 1px 0 rgba(255,255,255,0.06) inset, 0 24px 60px -22px rgba(0,0,0,0.7)",
  ]);

  useEffect(() => {
    if (!isOpen) return;
    const handler = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, [isOpen]);

  const close = () => setIsOpen(false);

  return (
    <m.div
      ref={containerRef}
      initial={{ y: -20, opacity: 0 }}
      
      animate={{ y: 0, opacity: 1 }}
      transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
      style={{
        position: "fixed",
        top: 16,
        left: "50%",
        translateX: "-50%",
        zIndex: 100,
        width: "calc(100% - 32px)",
        maxWidth: 1120,
      }}
      role="navigation"
    >
      {/* Pill bar — always stays a pill */}
      <m.div
        style={{
          ...glassStyle,
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          paddingTop: padding,
          paddingBottom: padding,
          paddingLeft: 20,
          paddingRight: 14,
          borderRadius: 999,
          boxShadow: shadow,
        }}
      >
        <Link href="/" style={{ textDecoration: "none", color: "inherit", whiteSpace: "nowrap" }} onClick={close}>
          <LogoLockup showName logoSize={26} priority />
        </Link>

        {/* Desktop nav links */}
        <div className="hidden md:flex gap-1.5 items-center text-sm" style={{ color: "var(--text-dim)" }}>
          {nav.links.map((l) => (
            <Link
              key={l.h}
              href={l.h}
              className="px-3 py-2 rounded-full transition-colors hover:text-(--text)"
              style={{ transition: "background .2s var(--ease), color .2s var(--ease)" }}
            >
              {l.l}
            </Link>
          ))}
        </div>

        <div className="flex gap-2 items-center">
          <ThemeToggle />
          {/* Desktop-only CTAs — wrapper div hides both reliably despite .btn { display: inline-flex } */}
          <div className="hidden md:flex gap-2 items-center">
            <Link
              href="/pricing/"
              className="btn btn-ghost"
              style={{ fontSize: 13, padding: "8px 14px" }}
            >
              License
            </Link>
            <Link
              href="/download/"
              className="btn btn-primary"
              style={{ fontSize: 13, padding: "7px 12px" }}
            >
              <AppleLogo size={14} />
              Download
            </Link>
          </div>

          {/* Hamburger — mobile only */}
          <button
            onClick={() => setIsOpen((v) => !v)}
            className="md:hidden flex items-center justify-center"
            style={{
              width: 36,
              height: 36,
              borderRadius: 999,
              border: "1px solid var(--border)",
              background: "transparent",
              color: "var(--text-dim)",
              cursor: "pointer",
              flexShrink: 0,
            }}
            aria-label={isOpen ? "Close menu" : "Open menu"}
          >
            <AnimatePresence mode="wait" initial={false}>
              {isOpen ? (
                <m.span
                  key="x"
                  initial={{ rotate: -90, opacity: 0 }}
                  animate={{ rotate: 0, opacity: 1 }}
                  exit={{ rotate: 90, opacity: 0 }}
                  transition={{ duration: 0.15 }}
                  style={{ display: "flex" }}
                >
                  <X size={16} />
                </m.span>
              ) : (
                <m.span
                  key="menu"
                  initial={{ rotate: 90, opacity: 0 }}
                  animate={{ rotate: 0, opacity: 1 }}
                  exit={{ rotate: -90, opacity: 0 }}
                  transition={{ duration: 0.15 }}
                  style={{ display: "flex" }}
                >
                  <Menu size={16} />
                </m.span>
              )}
            </AnimatePresence>
          </button>
        </div>
      </m.div>

      {/* Mobile dropdown — separate card, pill never morphs */}
      <AnimatePresence>
        {isOpen && (
          <m.div
            key="mobile-menu"
            initial={{ opacity: 0, y: -8, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -8, scale: 0.96 }}
            transition={{ duration: 0.22, ease: [0.22, 1, 0.36, 1] }}
            className="md:hidden"
            style={{
              ...glassStyle,
              marginTop: 8,
              borderRadius: 20,
              padding: "14px 14px 18px",
              transformOrigin: "top center",
            }}
          >
            {/* Staggered nav links */}
            <div className="flex flex-col gap-0.5">
              {nav.links.map((l, i) => (
                <m.div
                  key={l.h}
                  initial={{ opacity: 0, y: -6 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: i * 0.04, duration: 0.2, ease: "easeOut" }}
                >
                  <Link
                    href={l.h}
                    onClick={close}
                    className="flex items-center px-3 py-2.5 rounded-xl text-sm transition-colors hover:bg-(--surface-lo) hover:text-(--text)"
                    style={{ color: "var(--text-dim)" }}
                  >
                    {l.l}
                  </Link>
                </m.div>
              ))}
            </div>

            {/* Divider */}
            <div style={{ height: 1, background: "var(--border)", margin: "12px 0" }} />

            {/* CTA buttons */}
            <m.div
              initial={{ opacity: 0, y: 6 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: nav.links.length * 0.04 + 0.05, duration: 0.2, ease: "easeOut" }}
              className="flex flex-col gap-2"
            >
              <Link
                href="/pricing/"
                onClick={close}
                className="btn btn-ghost"
                style={{ fontSize: 13, justifyContent: "center" }}
              >
                License
              </Link>
              <Link
                href="/download/"
                onClick={close}
                className="btn btn-primary"
                style={{ fontSize: 13, justifyContent: "center", gap: 6 }}
              >
                <AppleLogo size={14} />
                Download for Mac
              </Link>
            </m.div>
          </m.div>
        )}
      </AnimatePresence>
    </m.div>
  );
}
