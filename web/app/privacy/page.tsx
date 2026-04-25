import type { Metadata } from "next";
import { LegalLayout, LegalSection } from "@/components/LegalLayout";
import { brand } from "@/content/site";

export const metadata: Metadata = {
  title: "Privacy Notice",
  description:
    "Mac Cleaner Pro runs entirely on your Mac. We don't collect file contents, paths, or scan results. Full privacy notice.",
  alternates: { canonical: `https://${brand.domain}/privacy/` },
};

export default function PrivacyPage() {
  return (
    <LegalLayout eyebrow="Legal" title="Privacy Notice" effective="2026-04-26">
      <p>
        <strong>{brand.name}</strong> is built privacy-first. The desktop app
        runs entirely on your Mac. We do not see your files, your scan results,
        or how you use individual features. This page describes the very small
        amount of data we do touch.
      </p>

      <LegalSection title="What never leaves your Mac">
        <ul className="bulleted">
          <li>File contents, file names, and paths</li>
          <li>Scan results and the Activity Log</li>
          <li>Trashed/staged files (they sit in <code>~/.Trash/MacCleanerPro/</code> on your machine)</li>
          <li>Your license key contents (only a structural validity check is performed locally)</li>
        </ul>
      </LegalSection>

      <LegalSection title="What we receive when you visit the website">
        <p>
          The website at <a href={`https://${brand.domain}`}>{brand.domain}</a>{" "}
          is statically hosted. Standard HTTP request logs (IP address,
          user-agent, requested path, referrer, timestamp) may be retained by
          our hosting provider for security and abuse prevention, typically
          for 30–90 days. We do not run third-party tracking scripts, set
          marketing cookies, or use ad networks.
        </p>
      </LegalSection>

      <LegalSection title="What we receive when you buy a license">
        <p>
          Payments are processed by our Merchant of Record (currently Paddle or
          Lemon Squeezy). When you buy a license they collect your name, email,
          billing address, payment method details, and tax-relevant information,
          and pass us only what we need to deliver your license — your name,
          email, country, and order ID. Your full payment details never touch
          our systems.
        </p>
        <p>
          We use your email solely to deliver your license key, send a one-time
          purchase receipt, and respond to support requests. We do not subscribe
          you to a newsletter without explicit opt-in.
        </p>
      </LegalSection>

      <LegalSection title="Optional in-app telemetry">
        <p>
          The desktop app contains an optional anonymous usage / crash reporting
          toggle in Settings → Privacy. Both are <strong>off by default</strong>.
          When enabled, payloads contain no file paths, no file contents, and no
          identifiers other than a randomly-generated install UUID that you can
          reset by reinstalling.
        </p>
      </LegalSection>

      <LegalSection title="Update checks">
        <p>
          By default, the app pings our update server roughly once per day to
          check for new versions. The request includes only the running version
          number and macOS major version. You can disable update checks in
          Settings → General.
        </p>
      </LegalSection>

      <LegalSection title="Your rights">
        <p>
          You can request access to, correction of, or deletion of any data we
          hold about you (typically: your purchase record) by emailing{" "}
          <a href="mailto:hello@maccleanerpro.com">
            hello@maccleanerpro.com
          </a>
          . We respond within 30 days.
        </p>
        <p>
          If you are in the EU/UK, this notice also serves as our GDPR/UK GDPR
          disclosure: the legal basis for processing your purchase data is{" "}
          <em>contract performance</em>; for security logs,{" "}
          <em>legitimate interest</em>.
        </p>
      </LegalSection>

      <LegalSection title="Children">
        <p>
          The Service is not directed at children under 13 (under 16 in the
          EU/UK). We do not knowingly collect data from children.
        </p>
      </LegalSection>

      <LegalSection title="Changes">
        <p>
          We will post material changes to this notice on this page with an
          updated effective date. If the change affects how we use data we
          already hold, we will notify licensed users by email.
        </p>
      </LegalSection>

      <LegalSection title="Contact">
        <p>
          Privacy questions:{" "}
          <a href="mailto:hello@maccleanerpro.com">
            hello@maccleanerpro.com
          </a>
          .
        </p>
      </LegalSection>
    </LegalLayout>
  );
}
