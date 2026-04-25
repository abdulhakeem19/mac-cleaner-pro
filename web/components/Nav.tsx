"use client";

import { motion, useScroll, useTransform } from "framer-motion";
import { Apple } from "lucide-react";
import Link from "next/link";
import { LogoLockup } from "./Logo";
import { ThemeToggle } from "./ThemeToggle";
import { nav } from "@/content/site";

export function Nav() {
  const { scrollY } = useScroll();
  // Slight elevation lift as the user scrolls past the hero — deepens shadow + tightens padding.
  const padding = useTransform(scrollY, [0, 80], [10, 7]);
  const shadow = useTransform(
    scrollY,
    [0, 80],
    [
      "0 1px 0 rgba(255,255,255,0.04) inset, 0 10px 30px -20px rgba(0,0,0,0.5)",
      "0 1px 0 rgba(255,255,255,0.06) inset, 0 24px 60px -22px rgba(0,0,0,0.7)",
    ],
  );

  return (
    <motion.nav
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
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        paddingTop: padding,
        paddingBottom: padding,
        paddingLeft: 20,
        paddingRight: 14,
        borderRadius: 999,
        background: "var(--surface-hi)",
        border: "1px solid var(--border)",
        backdropFilter: "blur(24px) saturate(160%)",
        WebkitBackdropFilter: "blur(24px) saturate(160%)",
        boxShadow: shadow,
      }}
    >
      <LogoLockup />
      <div className="hidden md:flex gap-1.5 items-center text-sm" style={{ color: "var(--text-dim)" }}>
        {nav.links.map((l) => (
          <Link
            key={l.h}
            href={l.h}
            className="px-3 py-2 rounded-full transition-colors hover:text-[var(--text)]"
            style={{ transition: "background .2s var(--ease), color .2s var(--ease)" }}
          >
            {l.l}
          </Link>
        ))}
      </div>
      <div className="flex gap-2 items-center">
        <ThemeToggle />
        <Link
          href="#pricing"
          className="btn btn-ghost hidden sm:inline-flex"
          style={{ fontSize: 13, padding: "8px 14px" }}
        >
          License
        </Link>
        <Link
          href="#download"
          className="btn btn-primary"
          style={{ fontSize: 13, padding: "8px 14px" }}
        >
          <Apple size={14} /> Download
        </Link>
      </div>
    </motion.nav>
  );
}
