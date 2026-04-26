"use client";

import { CheckCircle2, Send } from "lucide-react";
import { useState, type FormEvent } from "react";

const TOPICS = [
  { v: "general", l: "General question" },
  { v: "support", l: "Bug or support request" },
  { v: "license", l: "License or refund" },
  { v: "press", l: "Press / partnership" },
  { v: "beta", l: "Beta program" },
] as const;

export function ContactForm() {
  const [topic, setTopic] = useState<(typeof TOPICS)[number]["v"]>("general");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [body, setBody] = useState("");
  const [status, setStatus] = useState<"idle" | "sending" | "done" | "error">("idle");

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setStatus("sending");
    try {
      const payload = new URLSearchParams({
        "form-name": "contact",
        name,
        email,
        topic,
        message: body,
      });
      const res = await fetch("/contact/", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: payload.toString(),
      });
      setStatus(res.ok ? "done" : "error");
    } catch {
      setStatus("error");
    }
  };

  if (status === "done") {
    return (
      <div
        className="flex flex-col items-center gap-4 py-12 text-center"
        style={{ color: "var(--ok)" }}
      >
        <CheckCircle2 size={40} strokeWidth={1.5} />
        <div>
          <p style={{ fontSize: 18, fontWeight: 600, color: "var(--text)" }}>Message sent!</p>
          <p style={{ fontSize: 14, color: "var(--text-muted)", marginTop: 6 }}>
            We'll reply within one business day.
          </p>
        </div>
      </div>
    );
  }

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
        <Field label="Email">
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="you@example.com"
            required
            style={fieldStyle}
          />
        </Field>
      </div>
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
          {status === "error"
            ? "Something went wrong — please try again."
            : "We reply within one business day. No mailing list, no autoresponder."}
        </div>
        <button
          type="submit"
          disabled={status === "sending"}
          className="btn btn-primary"
          style={{ padding: "12px 22px", fontSize: 14, opacity: status === "sending" ? 0.6 : 1 }}
        >
          <Send size={14} />
          {status === "sending" ? "Sending…" : "Send message"}
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
