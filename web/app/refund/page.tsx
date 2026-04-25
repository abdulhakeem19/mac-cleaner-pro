import type { Metadata } from "next";
import { LegalLayout, LegalSection } from "@/components/LegalLayout";
import { brand } from "@/content/site";

export const metadata: Metadata = {
  title: "Refund Policy",
  description:
    "30-day no-questions-asked refund policy for Mac Cleaner Pro Pro and Family licenses.",
  alternates: { canonical: `https://${brand.domain}/refund/` },
};

export default function RefundPage() {
  return (
    <LegalLayout eyebrow="Legal" title="Refund Policy" effective="2026-04-26">
      <p>
        We offer a <strong>30-day, no-questions-asked refund</strong> for any
        paid license of <strong>{brand.name}</strong>.
      </p>

      <LegalSection title="How to request a refund">
        <ol className="numbered">
          <li>
            Email{" "}
            <a href="mailto:hello@maccleanerpro.com">
              hello@maccleanerpro.com
            </a>{" "}
            from the address you used to purchase.
          </li>
          <li>
            Include the order ID from your purchase receipt (Paddle / Lemon
            Squeezy will have emailed it to you). If you can't find it, just
            include the approximate purchase date.
          </li>
          <li>
            We aim to respond within one business day. Once approved, the refund
            is issued by our payment processor and typically reflects on your
            original payment method within 5–10 business days.
          </li>
        </ol>
      </LegalSection>

      <LegalSection title="Eligibility">
        <ul className="bulleted">
          <li>
            Refund requests must be made within <strong>30 days</strong> of the
            original purchase date.
          </li>
          <li>
            Refunds apply to license purchases only. We don't sell add-ons,
            consumables, or subscriptions; everything is a one-time license.
          </li>
          <li>
            Once a refund is processed, the corresponding license key is
            revoked. The app will revert to free-tier mode on next launch /
            license re-check.
          </li>
        </ul>
      </LegalSection>

      <LegalSection title="What we don't do">
        <ul className="bulleted">
          <li>
            We do not require a reason. "Changed my mind" is a valid reason.
          </li>
          <li>
            We do not partial-refund or pro-rate. The license is either active
            or refunded.
          </li>
          <li>
            We do not refund chargebacks separately — if you initiate a
            chargeback through your bank, please email us first; we will issue
            the refund directly and avoid the dispute fee for both of us.
          </li>
        </ul>
      </LegalSection>

      <LegalSection title="Free trial">
        <p>
          The 14-day free trial means you can fully evaluate the paid features
          before paying. Most users find the trial enough to decide; the 30-day
          refund window after purchase is an additional safety net.
        </p>
      </LegalSection>

      <LegalSection title="Statutory rights (EU / UK / India)">
        <p>
          This policy is in addition to any rights you have under applicable
          consumer-protection law. Indian residents purchasing through Razorpay
          have rights under the Consumer Protection Act 2019; EU/UK consumers
          have a 14-day right of withdrawal under the Consumer Rights Directive
          / UK Consumer Contracts Regulations. The 30-day window we offer is
          longer than either statutory minimum.
        </p>
      </LegalSection>

      <LegalSection title="Contact">
        <p>
          Refund or billing questions:{" "}
          <a href="mailto:hello@maccleanerpro.com">
            hello@maccleanerpro.com
          </a>
          . Please include the word "refund" in the subject line so it routes
          fast.
        </p>
      </LegalSection>
    </LegalLayout>
  );
}
