"use client";

import { Send } from "lucide-react";
import { useState, type FormEvent } from "react";

const TOPICS = [
  { v: "general", l: "General question" },
  { v: "support", l: "Bug or support request" },
  { v: "license", l: "License or refund" },
  { v: "press", l: "Press / partnership" },
  { v: "beta", l: "Beta program" },
] as const;

/**
 * Static-export-safe contact form. We don't run a server, so submitting opens
 * the user's mail client with a pre-filled message. Works on every device,
 * forwards reliably, and there's no spam-form-api dependency to maintain.
 *
 * If we want true async submission later, swap this for a Formspree / Resend
 * action URL — the field names are already shaped for that.
 */
export function ContactForm() {
  const [topic, setTopic] = useState<(typeof TOPICS)[number]["v"]>("general");
  const [name, setName] = useState("");
  const [body, setBody] = useState("");

  const submit = (e: FormEvent) => {
    e.preventDefault();
    const t = TOPICS.find((x) => x.v === topic)?.l ?? "General question";
    const subject = `[${t}] from ${name || "Mac Cleaner Pro user"}`;
    const lines = [
      `From: ${name || "(no name)"}`,
      "",
      body,
      "",
      "—",
      "Sent from maccleanerpro.com/contact",
    ];
    const url = `mailto:hello@maccleanerpro.com?subject=${encodeURIComponent(
      subject,
    )}&body=${encodeURIComponent(lines.join("\n"))}`;
    window.location.href = url;
  };

  const fieldStyle = {
    width: "100%",
    padding: "12px 14px",
    borderRadius: 10,
    background: "var(--bg-2)",
    border: "1px solid var(--border)",
    color: "var(--text)",
    fontSize: 14,
    fontFamily: "inherit",
    outline: "none",
  } as const;

  return (
    <form className="flex flex-col gap-4" onSubmit={submit}>
      <div className="grid gap-4 md:grid-cols-2">
        <Field label="Your name">
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Aanya Patel"
            style={fieldStyle}
          />
        </Field>
        <Field label="Topic">
          <select
            value={topic}
            onChange={(e) => setTopic(e.target.value as typeof topic)}
            style={fieldStyle}
          >
            {TOPICS.map((t) => (
              <option key={t.v} value={t.v}>
                {t.l}
              </option>
            ))}
          </select>
        </Field>
      </div>
      <Field label="Message">
        <textarea
          value={body}
          onChange={(e) => setBody(e.target.value)}
          rows={6}
          required
          placeholder="What's on your mind?"
          style={{ ...fieldStyle, resize: "vertical", minHeight: 120 }}
        />
      </Field>
      <div className="flex gap-3 items-center justify-between flex-wrap">
        <div style={{ fontSize: 12, color: "var(--text-muted)" }}>
          We reply within one business day. No mailing list, no autoresponder.
        </div>
        <button
          type="submit"
          className="btn btn-primary"
          style={{ padding: "12px 22px", fontSize: 14 }}
        >
          <Send size={14} /> Send via email
        </button>
      </div>
    </form>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="flex flex-col gap-1.5">
      <span
        style={{
          fontSize: 11,
          letterSpacing: "0.14em",
          textTransform: "uppercase",
          color: "var(--text-muted)",
          fontWeight: 600,
        }}
      >
        {label}
      </span>
      {children}
    </label>
  );
}
