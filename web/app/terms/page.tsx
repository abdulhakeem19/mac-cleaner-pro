import type { Metadata } from "next";
import { LegalLayout, LegalSection } from "@/components/LegalLayout";
import { brand } from "@/content/site";

export const metadata: Metadata = {
  title: "Terms of Service",
  description:
    "Terms governing your use of Mac Cleaner Pro for macOS. Pay-once licensing, refund policy, and acceptable-use rules.",
  alternates: { canonical: `https://${brand.domain}/terms/` },
};

export default function TermsPage() {
  return (
    <LegalLayout eyebrow="Legal" title="Terms of Service" effective="2026-04-26">
      <p>
        These Terms of Service ("Terms") govern your access to and use of{" "}
        <strong>{brand.name}</strong> ("the Software"), the desktop application
        for macOS, and the website at{" "}
        <a href={`https://${brand.domain}`}>{brand.domain}</a> (together, the
        "Service"), operated by an independent developer based in India ("we",
        "us"). By downloading, installing, or using the Software you agree to
        these Terms.
      </p>

      <LegalSection title="1. Licensing">
        <p>
          The Software is licensed, not sold. A purchased license grants you a
          non-exclusive, non-transferable right to install and use the Software
          on the number of Macs specified in the plan you purchased (1 Mac for
          Pro, up to 5 for Family). Licenses are perpetual for the major version
          you purchased and any future v1.x patch and feature updates.
        </p>
      </LegalSection>

      <LegalSection title="2. Free trial">
        <p>
          New installations include a {`{trial}`}-day free trial of paid features
          (currently {pricingTrialDaysFor()}). After the trial, the Software
          continues to run in a free tier with reduced functionality unless you
          purchase a license.
        </p>
      </LegalSection>

      <LegalSection title="3. Acceptable use">
        <p>You agree not to:</p>
        <ul className="bulleted">
          <li>Reverse engineer, decompile, or extract the Software's source code beyond what is permitted by applicable law.</li>
          <li>Redistribute, resell, or sublicense the Software or your license key.</li>
          <li>Use the Software to violate any law or to damage another person's data or system.</li>
          <li>Bypass or attempt to bypass the license validation or any tamper-evident protections.</li>
        </ul>
      </LegalSection>

      <LegalSection title="4. Data &amp; privacy">
        <p>
          The Software runs entirely on your Mac. We do not collect personal
          data, file contents, paths, or scan results. Optional anonymous usage
          metrics and crash reports are off by default and can be toggled in
          Settings → Privacy. See our{" "}
          <a href="/privacy/">Privacy Notice</a> for full details.
        </p>
      </LegalSection>

      <LegalSection title="5. Refunds">
        <p>
          We offer a 30-day refund window from the date of purchase, no
          questions asked. See our <a href="/refund/">Refund Policy</a>.
        </p>
      </LegalSection>

      <LegalSection title="6. Updates &amp; changes">
        <p>
          We may release software updates that add, modify, or remove features.
          Major version upgrades (v2.0+) may require a separate purchase; v1.x
          updates are included for licensed users.
        </p>
      </LegalSection>

      <LegalSection title="7. Disclaimers">
        <p>
          The Software is provided <strong>as-is</strong> and{" "}
          <strong>as-available</strong>, without warranties of any kind, express
          or implied. While the Software uses Trash-first deletion with 30-day
          undo, you remain responsible for your own backups. We are not liable
          for indirect, incidental, or consequential damages arising from your
          use of the Software, to the maximum extent permitted by applicable
          law.
        </p>
      </LegalSection>

      <LegalSection title="8. Termination">
        <p>
          We may suspend or terminate access to the Service if you violate these
          Terms. You may stop using the Software at any time. Refund eligibility
          remains governed by the Refund Policy.
        </p>
      </LegalSection>

      <LegalSection title="9. Governing law">
        <p>
          These Terms are governed by the laws of India. Disputes will be
          resolved in the courts having jurisdiction in Tamil Nadu, India,
          unless required otherwise by applicable consumer law in your country
          of residence.
        </p>
      </LegalSection>

      <LegalSection title="10. Changes to these Terms">
        <p>
          We may update these Terms from time to time. Material changes will be
          announced on this page with a new effective date. Continued use of the
          Software after changes take effect constitutes acceptance.
        </p>
      </LegalSection>

      <LegalSection title="11. Contact">
        <p>
          Questions about these Terms? Email{" "}
          <a href="mailto:hello@maccleanerpro.com">
            hello@maccleanerpro.com
          </a>
          .
        </p>
      </LegalSection>
    </LegalLayout>
  );
}

// Inlined helper so we don't import the entire pricing object just for one number.
function pricingTrialDaysFor() {
  return "14 days";
}
