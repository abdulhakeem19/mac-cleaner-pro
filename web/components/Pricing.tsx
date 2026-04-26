"use client";

import { LayoutGroup, m } from "framer-motion";
import { Check } from "lucide-react";
import { useEffect, useState } from "react";
import { pricing } from "@/content/site";
import { BlurIn, FadeUp, Stagger, StaggerItem } from "./Motion";

type Currency = "USD" | "INR";
type IndicLang = "en" | "hi" | "ta";

const CURRENCY_KEY = "mcp.currency";
const LANG_KEY = "mcp.indic-lang";

/** Default to INR if the browser locale looks Indian; otherwise USD. */
function detectCurrency(): Currency {
  if (typeof window === "undefined") return "USD";
  const stored = window.localStorage.getItem(CURRENCY_KEY) as Currency | null;
  if (stored === "USD" || stored === "INR") return stored;
  const lang = navigator.language || "";
  const tz = Intl.DateTimeFormat().resolvedOptions().timeZone || "";
  return lang.startsWith("hi") ||
    lang.startsWith("ta") ||
    lang.endsWith("-IN") ||
    tz.startsWith("Asia/Kolkata") ||
    tz.startsWith("Asia/Calcutta")
    ? "INR"
    : "USD";
}

function detectLang(): IndicLang {
  if (typeof window === "undefined") return "en";
  const stored = window.localStorage.getItem(LANG_KEY) as IndicLang | null;
  if (stored === "en" || stored === "hi" || stored === "ta") return stored;
  const lang = (navigator.language || "").toLowerCase();
  if (lang.startsWith("ta")) return "ta";
  if (lang.startsWith("hi")) return "hi";
  return "en";
}

const LANG_LABEL: Record<IndicLang, string> = {
  en: "English",
  hi: "हिन्दी",
  ta: "தமிழ்",
};

async function openRazorpay(planKey: string, planName: string) {
  if (typeof window === "undefined" || !window.Razorpay) return false;
  try {
    const res = await fetch("/.netlify/functions/razorpay-order", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ plan: planKey }),
    });
    if (!res.ok) return false;
    const data = await res.json();
    const rzp = new window.Razorpay({
      key: data.keyId,
      amount: data.amount,
      currency: data.currency,
      name: "Mac Cleaner Pro",
      description: planName,
      order_id: data.orderId,
      theme: { color: "#7C5CFF" },
      handler(response) {
        // Payment captured — send user to a thank-you page
        const params = new URLSearchParams({
          payment_id: response.razorpay_payment_id,
          order_id:   response.razorpay_order_id,
          plan:       planKey,
        });
        window.location.href = `/thank-you/?${params}`;
      },
    });
    rzp.open();
    return true;
  } catch {
    return false;
  }
}

export function Pricing() {
  const [currency, setCurrency] = useState<Currency>("USD");
  const [lang, setLang] = useState<IndicLang>("en");
  const [loading, setLoading] = useState<string | null>(null);

  useEffect(() => {
    setCurrency(detectCurrency());
    setLang(detectLang());
  }, []);

  const setAndPersistCurrency = (c: Currency) => {
    setCurrency(c);
    try {
      window.localStorage.setItem(CURRENCY_KEY, c);
    } catch {}
  };
  const setAndPersistLang = (l: IndicLang) => {
    setLang(l);
    try {
      window.localStorage.setItem(LANG_KEY, l);
    } catch {}
  };

  const isINR = currency === "INR";

  const inrSubFor = (
    p: (typeof pricing.plans)[number],
  ): string => {
    if (lang === "hi") return p.inrSubHi;
    if (lang === "ta") return p.inrSubTa;
    return p.inrSubEn;
  };

  return (
    <section id="pricing" className="section">
      <div className="container-x">
        <div className="text-center mb-14">
          <BlurIn>
            <div className="eyebrow" style={{ marginBottom: 20 }}>
              <span className="eyebrow-dot" />
              {pricing.eyebrow}
            </div>
          </BlurIn>
          <FadeUp delay={1}>
            <h2 className="h-section">
              {pricing.title}{" "}
              <span className="gradient-text">{pricing.titleGradient}</span>
            </h2>
          </FadeUp>
          <FadeUp delay={2}>
            <p
              className="lede"
              style={{ margin: "20px auto 0", textAlign: "center" }}
            >
              {pricing.description}
            </p>
          </FadeUp>

          <FadeUp delay={3}>
            <LayoutGroup id="currency">
              <div
                className="inline-flex items-center gap-3 mt-7"
                style={{
                  padding: "6px 8px",
                  borderRadius: 999,
                  background: "var(--bg-2)",
                  border: "1px solid var(--border)",
                }}
              >
                <span
                  style={{
                    fontSize: 12,
                    color: "var(--text-muted)",
                    paddingLeft: 8,
                  }}
                >
                  Currency
                </span>
                {(["USD", "INR"] as const).map((c) => (
                  <button
                    key={c}
                    onClick={() => setAndPersistCurrency(c)}
                    className="relative isolate"
                    style={{
                      padding: "7px 18px",
                      borderRadius: 999,
                      border: "none",
                      cursor: "pointer",
                      fontFamily: "inherit",
                      fontWeight: 600,
                      fontSize: 13,
                      background: "transparent",
                      color: currency === c ? "white" : "var(--text-dim)",
                    }}
                  >
                    {currency === c && (
                      <m.span
                        layoutId="currency-pill"
                        transition={{ type: "spring", bounce: 0.2, duration: 0.6 }}
                        style={{
                          position: "absolute",
                          inset: 0,
                          background: "var(--accent-grad)",
                          borderRadius: 999,
                          zIndex: 0,
                        }}
                      />
                    )}
                    <span style={{ position: "relative", zIndex: 1 }}>
                      {c === "USD" ? "$ USD" : "₹ INR"}
                    </span>
                  </button>
                ))}
                {isINR && (
                  <span
                    style={{
                      fontSize: 11,
                      color: "var(--text-muted)",
                      paddingRight: 8,
                      fontFamily: "var(--font-mono)",
                    }}
                  >
                    1 USD ≈ ₹{pricing.rates.usdToInr}
                  </span>
                )}
              </div>
            </LayoutGroup>
          </FadeUp>

          {isINR && (
            <FadeUp delay={4}>
              <div className="flex flex-col items-center gap-3 mt-3.5">
                <div
                  className="inline-flex items-center gap-2"
                  style={{
                    padding: "8px 16px",
                    borderRadius: 10,
                    background: "rgba(48,209,88,0.08)",
                    border: "1px solid rgba(48,209,88,0.2)",
                    fontSize: 13,
                    color: "var(--ok)",
                  }}
                >
                  <span aria-hidden>🇮🇳</span> GST-inclusive · UPI · Razorpay · Netbanking accepted
                </div>
                <LayoutGroup id="indic-lang">
                  <div
                    className="inline-flex items-center gap-2"
                    style={{
                      padding: "5px 7px",
                      borderRadius: 999,
                      background: "var(--bg-2)",
                      border: "1px solid var(--border)",
                    }}
                  >
                    <span
                      style={{
                        fontSize: 11,
                        color: "var(--text-muted)",
                        paddingLeft: 8,
                        letterSpacing: "0.06em",
                        textTransform: "uppercase",
                      }}
                    >
                      Language
                    </span>
                    {(["en", "hi", "ta"] as const).map((l) => (
                      <button
                        key={l}
                        onClick={() => setAndPersistLang(l)}
                        className="relative isolate"
                        style={{
                          padding: "5px 14px",
                          borderRadius: 999,
                          border: "none",
                          cursor: "pointer",
                          fontFamily: "inherit",
                          fontWeight: 600,
                          fontSize: 12.5,
                          background: "transparent",
                          color: lang === l ? "white" : "var(--text-dim)",
                        }}
                      >
                        {lang === l && (
                          <m.span
                            layoutId="indic-pill"
                            transition={{ type: "spring", bounce: 0.2, duration: 0.5 }}
                            style={{
                              position: "absolute",
                              inset: 0,
                              background: "var(--accent-grad)",
                              borderRadius: 999,
                              zIndex: 0,
                            }}
                          />
                        )}
                        <span style={{ position: "relative", zIndex: 1 }}>
                          {LANG_LABEL[l]}
                        </span>
                      </button>
                    ))}
                  </div>
                </LayoutGroup>
              </div>
            </FadeUp>
          )}
        </div>

        <Stagger className="grid gap-7 md:grid-cols-3" step={0.1}>
          {pricing.plans.map((p) => (
            <StaggerItem key={p.key}>
              <div
                className={`glass relative transition-transform ${
                  p.primary ? "glow-ring" : ""
                }`}
                style={{
                  padding: 32,
                  overflow: p.primary ? "visible" : "hidden",
                  border: p.primary
                    ? "1px solid transparent"
                    : "1px solid var(--border)",
                  background: p.primary
                    ? "linear-gradient(180deg, rgba(124,92,255,0.12), var(--surface))"
                    : "var(--surface)",
                  transition: "transform .3s var(--ease)",
                  transform: p.primary ? "scale(1.02)" : "none",
                }}
                onMouseEnter={(e) => {
                  if (!p.primary)
                    e.currentTarget.style.transform = "translateY(-4px)";
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.transform = "none";
                }}
              >
                {"tag" in p && p.tag && (
                  <div
                    className="absolute"
                    style={{
                      top: 16,
                      right: 16,
                      padding: "4px 10px",
                      borderRadius: 999,
                      background: "var(--accent-grad)",
                      color: "white",
                      fontSize: 11,
                      fontWeight: 600,
                      letterSpacing: "0.04em",
                    }}
                  >
                    {p.tag}
                  </div>
                )}
                <div
                  style={{
                    fontSize: 14,
                    color: "var(--text-dim)",
                    fontWeight: 500,
                  }}
                >
                  {p.name}
                </div>
                <div className="flex items-baseline gap-1.5 mt-2" style={{ minHeight: 68 }}>
                  <div
                    className="mono"
                    style={{
                      fontSize: 52,
                      fontWeight: 600,
                      letterSpacing: "-0.03em",
                    }}
                  >
                    {isINR ? p.inr : p.usd}
                  </div>
                  <div
                    style={{
                      fontSize: 13,
                      color: "var(--text-muted)",
                      lineHeight: 1.4,
                    }}
                  >
                    {isINR ? inrSubFor(p) : p.usdSub}
                  </div>
                </div>
                {isINR && p.key !== "free" && (
                  <div
                    className="mono"
                    style={{
                      fontSize: 12,
                      color: "var(--text-muted)",
                      marginTop: -6,
                      marginBottom: 6,
                    }}
                  >
                    ≈ {p.usd} USD
                  </div>
                )}
                <p style={{ fontSize: 14, marginTop: 10 }}>{p.desc}</p>
                <button
                  className={p.primary ? "btn btn-primary" : "btn btn-secondary"}
                  disabled={loading === p.key}
                  style={{
                    width: "100%",
                    justifyContent: "center",
                    marginTop: 22,
                    padding: "12px 16px",
                    opacity: loading === p.key ? 0.7 : 1,
                    cursor: loading === p.key ? "wait" : "pointer",
                  }}
                  onClick={async () => {
                    if (p.key === "free") {
                      window.location.href = "/download/";
                      return;
                    }
                    setLoading(p.key);
                    try {
                      // India (INR) → Razorpay
                      if (currency === "INR" && p.razorpayPlan) {
                        const ok = await openRazorpay(p.razorpayPlan, p.name);
                        if (ok) return;
                      }
                      // International (USD) → Paddle
                      if (p.paddleProductId && typeof window !== "undefined" && window.Paddle) {
                        window.Paddle.Checkout.open({ product: p.paddleProductId });
                        return;
                      }
                      // Fallback — neither gateway configured
                      window.location.href = "mailto:support@maccleanerpro.com?subject=Purchase%20Mac%20Cleaner%20Pro";
                    } finally {
                      setLoading(null);
                    }
                  }}
                >
                  {loading === p.key ? "Opening checkout…" : p.cta}
                </button>
                <div
                  style={{
                    height: 1,
                    background: "var(--border)",
                    margin: "24px 0",
                  }}
                />
                <ul className="flex flex-col gap-2.5 m-0 p-0 list-none">
                  {p.feats.map((f) => (
                    <li
                      key={f}
                      className="flex gap-2.5 items-start"
                      style={{ fontSize: 13.5 }}
                    >
                      <span
                        style={{
                          color: p.primary ? "var(--accent)" : "var(--ok)",
                          flexShrink: 0,
                          paddingTop: 3,
                        }}
                      >
                        <Check size={14} strokeWidth={3} />
                      </span>
                      <span style={{ color: "var(--text)" }}>{f}</span>
                    </li>
                  ))}
                </ul>
              </div>
            </StaggerItem>
          ))}
        </Stagger>
        <div
          className="flex gap-6 justify-center mt-8 flex-wrap"
          style={{ fontSize: 13, color: "var(--text-muted)" }}
        >
          {pricing.guarantees.map((g) => (
            <span key={g}>✓ {g}</span>
          ))}
        </div>
      </div>
    </section>
  );
}
