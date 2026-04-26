import type { Metadata } from "next";
import { ContactForm } from "@/components/ContactForm";
import { Footer } from "@/components/Footer";
import { Nav } from "@/components/Nav";
import { brand } from "@/content/site";
import { Mail, MessageSquare, ShieldCheck, Zap } from "lucide-react";

export const metadata: Metadata = {
  title: "Contact Mac Cleaner Pro — Support, Sales & Feedback",
  description:
    "Get help with Mac Cleaner Pro. Email us for support, license questions, bug reports, or feature requests. Fast response from the indie dev team.",
  alternates: { canonical: `https://${brand.domain}/contact/` },
};

const channels = [
  {
    icon: MessageSquare,
    label: "General",
    email: "hello@maccleanerpro.com",
    subject: "[General]",
    desc: "Anything that isn't an active support ticket — feedback, ideas, partnerships, press.",
  },
  {
    icon: ShieldCheck,
    label: "Support",
    email: "hello@maccleanerpro.com",
    subject: "[Support]",
    desc: "Bugs, license issues, refund requests. Include your order ID for fastest routing.",
  },
  {
    icon: Zap,
    label: "Beta Program",
    email: "hello@maccleanerpro.com",
    subject: "[Beta]",
    desc: "Early-access testers — bug reports, weekly build feedback, feature requests.",
  },
];

export default function ContactPage() {
  return (
    <>
      <Nav />
      <main
        className="container-x"
        style={{ maxWidth: 980, paddingTop: 140, paddingBottom: 120 }}
      >
        <div className="text-center mb-12">
          <div className="eyebrow" style={{ marginBottom: 20 }}>
            <span className="eyebrow-dot" />
            Contact
          </div>
          <h1 className="h-section">Talk to a real human.</h1>
          <p className="lede" style={{ margin: "16px auto 0", textAlign: "center" }}>
            One developer, one inbox. Replies within one business day, usually faster.
          </p>
        </div>

        {/* Hidden form — Netlify scrapes this at build time to register the form */}
        <form name="contact" data-netlify="true" hidden>
          <input type="hidden" name="form-name" value="contact" />
          <input type="text" name="name" />
          <input type="email" name="email" />
          <select name="topic">
            <option value="general" />
            <option value="support" />
            <option value="license" />
            <option value="press" />
            <option value="beta" />
          </select>
          <textarea name="message" />
        </form>

        <div className="grid gap-5 md:grid-cols-3 mb-10">
          {channels.map((c) => {
            const Ic = c.icon;
            return (
              <a
                key={c.label}
                href={`mailto:${c.email}?subject=${encodeURIComponent(c.subject)}`}
                className="glass block transition-transform hover:-translate-y-0.5"
                style={{ padding: 24 }}
              >
                <div
                  style={{
                    width: 38,
                    height: 38,
                    borderRadius: 10,
                    background: "var(--accent-soft)",
                    color: "var(--accent)",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    marginBottom: 14,
                  }}
                >
                  <Ic size={18} />
                </div>
                <div
                  style={{
                    fontSize: 11,
                    letterSpacing: "0.16em",
                    textTransform: "uppercase",
                    color: "var(--text-muted)",
                    marginBottom: 6,
                  }}
                >
                  {c.label}
                </div>
                <div
                  className="mono"
                  style={{
                    fontSize: 14,
                    fontWeight: 600,
                    color: "var(--text)",
                    marginBottom: 8,
                  }}
                >
                  {c.email}
                </div>
                <div style={{ fontSize: 13.5, color: "var(--text-dim)", lineHeight: 1.55 }}>
                  {c.desc}
                </div>
              </a>
            );
          })}
        </div>

        <div className="glass" style={{ padding: 36 }}>
          <div className="flex items-center gap-3 mb-5">
            <div
              style={{
                width: 36,
                height: 36,
                borderRadius: 10,
                background: "var(--accent-grad)",
                color: "white",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <Mail size={18} />
            </div>
            <div>
              <div style={{ fontSize: 18, fontWeight: 600, letterSpacing: "-0.01em" }}>
                Or send a quick note
              </div>
              <div style={{ fontSize: 13, color: "var(--text-muted)", marginTop: 2 }}>
                Opens your default mail client with the right subject prefix.
              </div>
            </div>
          </div>
          <ContactForm />
        </div>
      </main>
      <Footer />
    </>
  );
}
