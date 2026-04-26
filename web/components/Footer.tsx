"use client";

import { Github } from "lucide-react";
import { AppleLogo } from "./Logo";
import Link from "next/link";
import { footer } from "@/content/site";
import { LogoLockup } from "./Logo";

export function Footer() {
  return (
    <footer
      style={{
        borderTop: "1px solid var(--border)",
        padding: "60px 0 40px",
        marginTop: 40,
      }}
    >
      <div className="container-x">
        <div
          className="grid mb-12 gap-10 grid-cols-2 md:grid-cols-4"
        >
          <div className="col-span-2 md:col-span-1">
            <div style={{ marginBottom: 14 }}>
              <Link href="/" style={{ textDecoration: "none", color: "inherit" }}>
                <LogoLockup />
              </Link>
            </div>
            <p style={{ fontSize: 14, maxWidth: 280 }}>{footer.blurb}</p>
            <div className="flex gap-2.5 mt-5">
              <Link
                href="/download/"
                className="btn btn-secondary"
                style={{ padding: "10px 14px", fontSize: 13 }}
              >
                <AppleLogo size={14} /> Download
              </Link>
              <Link
                href="https://github.com/abdulhakeem19/maccleanerpro"
                className="btn btn-ghost"
                style={{ padding: "10px 14px", fontSize: 13 }}
              >
                <Github size={14} /> GitHub
              </Link>
            </div>
          </div>
          {footer.cols.map((c) => (
            <div key={c.title}>
              <div
                style={{
                  fontSize: 12,
                  letterSpacing: "0.14em",
                  textTransform: "uppercase",
                  color: "var(--text-muted)",
                  marginBottom: 14,
                }}
              >
                {c.title}
              </div>
              <ul className="flex flex-col gap-2.5 m-0 p-0 list-none">
                {c.links.map((l) => (
                  <li key={l.l}>
                    <Link
                      href={l.h}
                      style={{ fontSize: 14, color: "var(--text-dim)" }}
                    >
                      {l.l}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
        <hr className="hr" />
        <div
          className="flex justify-between flex-wrap gap-4"
          style={{ marginTop: 28, fontSize: 12.5, color: "var(--text-muted)" }}
        >
          <div>{footer.copyright}</div>
          <div className="flex gap-5 flex-wrap">
            <Link href="/terms/">Terms</Link>
            <Link href="/privacy/">Privacy</Link>
            <Link href="/refund/">Refund</Link>
            <Link href="/install/">Install</Link>
            <Link href="/changelog/">Changelog</Link>
          </div>
        </div>
      </div>
    </footer>
  );
}
