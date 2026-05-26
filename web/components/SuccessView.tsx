"use client";

import { useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { m } from "framer-motion";
import { CheckCircle2, Download, Mail, Copy, Check, Loader2, ExternalLink } from "lucide-react";
import Link from "next/link";

export function SuccessView() {
  const searchParams = useSearchParams();
  const [copied, setCopied] = useState(false);
  const [licenseKey, setLicenseKey] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const paymentId = searchParams.get('payment_id');
  const orderId = searchParams.get('order_id');
  const plan = searchParams.get('plan');
  const email = searchParams.get('email');

  useEffect(() => {
    // Fetch license key from server using payment/order ID
    const fetchLicense = async () => {
      if (!paymentId && !orderId) {
        setError('Missing payment information');
        setLoading(false);
        return;
      }

      try {
        const response = await fetch('/.netlify/functions/get-license', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            payment_id: paymentId,
            order_id: orderId,
            email: email,
          }),
        });

        if (!response.ok) {
          const error = await response.json();

          // If purchase not found yet, webhook might still be processing
          if (response.status === 404) {
            setLicenseKey(null); // Show "emailed" message
            setLoading(false);
            return;
          }

          throw new Error(error.message || 'Failed to fetch license key');
        }

        const data = await response.json();
        setLicenseKey(data.license_key);
        setLoading(false);
      } catch (err: any) {
        console.error('Error fetching license:', err);
        // Don't show error - just show "emailed" message as fallback
        setLicenseKey(null);
        setLoading(false);
      }
    };

    fetchLicense();
  }, [paymentId, orderId, email]);

  const copyLicenseKey = () => {
    if (licenseKey) {
      navigator.clipboard.writeText(licenseKey);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  if (loading) {
    return (
      <m.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.3 }}
        className="glass"
        style={{
          maxWidth: 560,
          width: '100%',
          padding: 48,
          border: '1px solid var(--border)',
          textAlign: 'center',
        }}
      >
        <Loader2 size={48} className="animate-spin" style={{ margin: '0 auto 20px', color: 'var(--accent)' }} />
        <h2 style={{ fontSize: 20, fontWeight: 600, marginBottom: 8 }}>
          Processing your purchase...
        </h2>
        <p style={{ fontSize: 14, color: 'var(--text-muted)' }}>
          Generating your license key
        </p>
      </m.div>
    );
  }

  if (error) {
    return (
      <m.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.3 }}
        className="glass"
        style={{
          maxWidth: 560,
          width: '100%',
          padding: 48,
          border: '1px solid var(--border)',
          textAlign: 'center',
        }}
      >
        <div style={{ width: 64, height: 64, borderRadius: '50%', background: 'rgba(255,69,58,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 24px' }}>
          <Mail size={32} color="var(--error)" />
        </div>
        <h1 style={{ fontSize: 28, fontWeight: 600, marginBottom: 12 }}>
          Something went wrong
        </h1>
        <p style={{ fontSize: 15, color: 'var(--text-muted)', marginBottom: 28 }}>
          {error}
        </p>
        <Link href="/contact/" className="btn btn-primary">
          Contact Support
        </Link>
      </m.div>
    );
  }

  const planName = plan === 'family' ? 'Family Plan (5 Macs)' : 'Pro Plan (1 Mac)';

  return (
    <m.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.5, type: 'spring' }}
      className="glass"
      style={{
        maxWidth: 560,
        width: '100%',
        padding: 48,
        border: '1px solid var(--border)',
      }}
    >
      {/* Success Icon */}
      <m.div
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ delay: 0.2, type: 'spring', bounce: 0.5 }}
        style={{
          width: 80,
          height: 80,
          borderRadius: '50%',
          background: 'linear-gradient(135deg, #30D158 0%, #00C7BE 100%)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          margin: '0 auto 24px',
        }}
      >
        <CheckCircle2 size={44} color="white" strokeWidth={2.5} />
      </m.div>

      {/* Header */}
      <h1 style={{ fontSize: 32, fontWeight: 600, textAlign: 'center', marginBottom: 12 }}>
        Payment Successful! 🎉
      </h1>
      <p style={{ fontSize: 15, color: 'var(--text-muted)', textAlign: 'center', marginBottom: 32 }}>
        Thank you for purchasing Mac Cleaner Pro {planName}
      </p>

      {/* License Key Section */}
      <div
        style={{
          background: 'var(--bg-2)',
          border: '2px solid var(--accent)',
          borderRadius: 12,
          padding: 24,
          marginBottom: 28,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
          <Mail size={20} color="var(--accent)" />
          <h3 style={{ fontSize: 16, fontWeight: 600, margin: 0 }}>
            {licenseKey ? 'Your License Key' : 'License Key Sent to Your Email'}
          </h3>
        </div>

        {licenseKey ? (
          <>
            <p style={{ fontSize: 14, color: 'var(--text-muted)', marginBottom: 16 }}>
              Save this license key in a safe place. We've also sent it to your email.
            </p>
            <div
              style={{
                background: 'var(--bg)',
                border: '1px solid var(--border)',
                borderRadius: 8,
                padding: 16,
                fontSize: 13,
                fontFamily: 'var(--font-mono)',
                wordBreak: 'break-all',
                position: 'relative',
              }}
            >
              <div style={{ paddingRight: 40 }}>
                {licenseKey}
              </div>
              <button
                onClick={copyLicenseKey}
                style={{
                  position: 'absolute',
                  top: 12,
                  right: 12,
                  background: copied ? 'var(--accent)' : 'var(--bg-2)',
                  border: '1px solid var(--border)',
                  borderRadius: 6,
                  padding: '6px 12px',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 6,
                  fontSize: 12,
                  color: copied ? 'white' : 'var(--text)',
                  transition: 'all 0.2s',
                }}
              >
                {copied ? (
                  <>
                    <Check size={14} />
                    Copied!
                  </>
                ) : (
                  <>
                    <Copy size={14} />
                    Copy
                  </>
                )}
              </button>
            </div>
          </>
        ) : (
          <>
            {email && (
              <p style={{ fontSize: 14, color: 'var(--text-muted)', marginBottom: 16 }}>
                We've sent your license key to <strong style={{ color: 'var(--text)' }}>{email}</strong>
              </p>
            )}
            <div
              style={{
                background: 'var(--bg)',
                border: '1px solid var(--border)',
                borderRadius: 8,
                padding: 16,
                fontSize: 13,
                color: 'var(--text-muted)',
              }}
            >
              <p style={{ margin: 0, lineHeight: 1.6 }}>
                📧 Check your inbox (and spam folder) for an email with:
                <br />• Your unique license key
                <br />• Download link
                <br />• Activation instructions
              </p>
            </div>
          </>
        )}
      </div>

      {/* Next Steps */}
      <div style={{ marginBottom: 28 }}>
        <h3 style={{ fontSize: 16, fontWeight: 600, marginBottom: 16 }}>
          Next Steps
        </h3>
        <ol style={{ margin: 0, paddingLeft: 20, fontSize: 14, lineHeight: 1.8, color: 'var(--text-dim)' }}>
          <li>Download Mac Cleaner Pro for macOS</li>
          <li>Open the app and go to Settings → License</li>
          <li>Enter your license key to unlock all Pro features</li>
        </ol>
      </div>

      {/* Action Buttons */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 28 }}>
        <Link
          href="/download/"
          className="btn btn-primary"
          style={{
            justifyContent: 'center',
            padding: '14px 20px',
            fontSize: 15,
            fontWeight: 600,
          }}
        >
          <Download size={18} />
          <span>Download Mac Cleaner Pro</span>
        </Link>
        <Link
          href="/install/"
          className="btn btn-secondary"
          style={{
            justifyContent: 'center',
            padding: '12px 20px',
            fontSize: 14,
          }}
        >
          View Installation Guide
        </Link>
      </div>

      {/* Help Section */}
      <div
        style={{
          paddingTop: 24,
          borderTop: '1px solid var(--border)',
          textAlign: 'center',
        }}
      >
        <p style={{ fontSize: 13, color: 'var(--text-muted)', marginBottom: 12 }}>
          Need help? We're here for you.
        </p>
        <div style={{ display: 'flex', gap: 16, justifyContent: 'center', fontSize: 13 }}>
          <Link href="/contact/" style={{ color: 'var(--accent)', textDecoration: 'none', display: 'flex', alignItems: 'center', gap: 4 }}>
            Contact Support
            <ExternalLink size={12} />
          </Link>
          <Link href="/#faq" style={{ color: 'var(--accent)', textDecoration: 'none', display: 'flex', alignItems: 'center', gap: 4 }}>
            View FAQ
            <ExternalLink size={12} />
          </Link>
        </div>
      </div>

      {/* Transaction Details (collapsible/expandable in future) */}
      {paymentId && (
        <details style={{ marginTop: 24, fontSize: 12, color: 'var(--text-muted)' }}>
          <summary style={{ cursor: 'pointer', userSelect: 'none' }}>
            Transaction Details
          </summary>
          <div style={{ marginTop: 12, padding: 12, background: 'var(--bg-2)', borderRadius: 6, fontFamily: 'var(--font-mono)' }}>
            {orderId && <p style={{ margin: '4px 0' }}>Order ID: {orderId}</p>}
            <p style={{ margin: '4px 0' }}>Payment ID: {paymentId}</p>
            <p style={{ margin: '4px 0' }}>Plan: {planName}</p>
          </div>
        </details>
      )}
    </m.div>
  );
}
