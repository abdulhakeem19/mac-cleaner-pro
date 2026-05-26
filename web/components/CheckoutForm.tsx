"use client";

import { useState, useEffect } from "react";
import { useSearchParams } from "next/navigation";
import { m } from "framer-motion";
import { Loader2, Check, AlertCircle, CreditCard, Shield, Mail } from "lucide-react";
import { pricing } from "@/content/site";

type Plan = 'pro' | 'family';

export function CheckoutForm() {
  const searchParams = useSearchParams();

  const [plan, setPlan] = useState<Plan>('pro');
  const [email, setEmail] = useState('');
  const [emailError, setEmailError] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    // Get plan from URL parameter
    const planParam = searchParams.get('plan');
    if (planParam === 'family' || planParam === 'pro') {
      setPlan(planParam);
    }

    // Load Razorpay SDK
    if (typeof window !== 'undefined' && !window.Razorpay) {
      const script = document.createElement('script');
      script.src = 'https://checkout.razorpay.com/v1/checkout.js';
      script.async = true;
      document.body.appendChild(script);
    }
  }, [searchParams]);

  const validateEmail = (email: string): boolean => {
    const trimmed = email.trim();
    const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!trimmed) {
      setEmailError('Email is required');
      return false;
    }

    if (!regex.test(trimmed)) {
      setEmailError('Please enter a valid email address');
      return false;
    }

    setEmailError('');
    return true;
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    if (!validateEmail(email)) {
      return;
    }

    setLoading(true);
    setError('');

    try {
      // Create Razorpay order
      const res = await fetch('/.netlify/functions/razorpay-order', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ plan, email: email.trim() }),
      });

      if (!res.ok) {
        throw new Error('Failed to create order');
      }

      const data = await res.json();

      // Open Razorpay modal
      if (!window.Razorpay) {
        throw new Error('Payment gateway not loaded');
      }

      const rzp = new window.Razorpay({
        key: data.keyId,
        amount: data.amount,
        currency: data.currency,
        name: 'Mac Cleaner Pro',
        description: data.name,
        order_id: data.orderId,
        prefill: {
          email: email.trim(),
        },
        theme: { color: '#7C5CFF' },
        async handler(response: any) {
          // Payment successful - verify signature before redirecting
          try {
            const verifyRes = await fetch('/.netlify/functions/verify-payment', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                razorpay_order_id: response.razorpay_order_id,
                razorpay_payment_id: response.razorpay_payment_id,
                razorpay_signature: response.razorpay_signature,
              }),
            });

            if (!verifyRes.ok) {
              throw new Error('Payment verification failed');
            }

            const verifyData = await verifyRes.json();

            if (!verifyData.verified) {
              throw new Error('Invalid payment signature');
            }

            // Signature verified - redirect to success page
            const params = new URLSearchParams({
              payment_id: response.razorpay_payment_id,
              order_id: response.razorpay_order_id,
              plan,
              email: email.trim(),
            });
            window.location.href = `/success/?${params}`;
          } catch (err: any) {
            setError('Payment verification failed. Please contact support.');
            setLoading(false);
          }
        },
        modal: {
          ondismiss() {
            setLoading(false);
          },
        },
      });

      rzp.open();
    } catch (err: any) {
      setError(err.message || 'Something went wrong. Please try again.');
      setLoading(false);
    }
  };

  const planData = pricing.plans.find(p => p.key === plan);
  if (!planData || planData.key === 'free') {
    return null;
  }

  return (
    <m.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      className="glass"
      style={{
        maxWidth: 520,
        width: '100%',
        padding: 40,
        border: '1px solid var(--border)',
      }}
    >
      {/* Header */}
      <div style={{ marginBottom: 32 }}>
        <h1 style={{ fontSize: 28, fontWeight: 600, marginBottom: 8 }}>
          Complete Your Purchase
        </h1>
        <p style={{ fontSize: 14, color: 'var(--text-muted)' }}>
          Secure checkout powered by Razorpay
        </p>
      </div>

      {/* Plan Selection */}
      <div style={{ marginBottom: 28 }}>
        <label style={{ display: 'block', fontSize: 13, fontWeight: 500, marginBottom: 10, color: 'var(--text-dim)' }}>
          Select Plan
        </label>
        <div style={{ display: 'flex', gap: 12 }}>
          {['pro', 'family'].map((p) => {
            const isPro = p === 'pro';
            const isSelected = plan === p;
            const planInfo = pricing.plans.find(pl => pl.key === p);

            return (
              <button
                key={p}
                type="button"
                onClick={() => setPlan(p as Plan)}
                style={{
                  flex: 1,
                  padding: 16,
                  border: isSelected ? '2px solid var(--accent)' : '1px solid var(--border)',
                  borderRadius: 10,
                  background: isSelected ? 'rgba(124,92,255,0.1)' : 'var(--bg-2)',
                  cursor: 'pointer',
                  textAlign: 'left',
                  transition: 'all 0.2s',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', marginBottom: 8 }}>
                  <div style={{ fontSize: 16, fontWeight: 600 }}>
                    {isPro ? 'Pro' : 'Family'}
                  </div>
                  {isSelected && (
                    <Check size={18} color="var(--accent)" strokeWidth={3} />
                  )}
                </div>
                <div className="mono" style={{ fontSize: 22, fontWeight: 600, marginBottom: 4 }}>
                  {planInfo?.inr}
                </div>
                <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>
                  {isPro ? '1 Mac' : 'Up to 5 Macs'}
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Email Input */}
      <form onSubmit={handleSubmit}>
        <div style={{ marginBottom: 24 }}>
          <label htmlFor="email" style={{ display: 'block', fontSize: 13, fontWeight: 500, marginBottom: 10, color: 'var(--text-dim)' }}>
            Email Address
          </label>
          <div style={{ position: 'relative' }}>
            <Mail
              size={18}
              style={{
                position: 'absolute',
                left: 14,
                top: '50%',
                transform: 'translateY(-50%)',
                color: 'var(--text-muted)',
              }}
            />
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => {
                setEmail(e.target.value);
                setEmailError('');
              }}
              onBlur={() => email && validateEmail(email)}
              placeholder="you@example.com"
              disabled={loading}
              style={{
                width: '100%',
                padding: '12px 14px 12px 44px',
                fontSize: 15,
                border: emailError ? '1px solid var(--error)' : '1px solid var(--border)',
                borderRadius: 8,
                background: 'var(--bg)',
                color: 'var(--text)',
                outline: 'none',
                transition: 'border-color 0.2s',
              }}
            />
          </div>
          {emailError && (
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 8, fontSize: 13, color: 'var(--error)' }}>
              <AlertCircle size={14} />
              {emailError}
            </div>
          )}
          <p style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 8 }}>
            Your license key will be sent to this email address
          </p>
        </div>

        {/* Error Message */}
        {error && (
          <div
            style={{
              padding: 12,
              background: 'rgba(255,69,58,0.1)',
              border: '1px solid rgba(255,69,58,0.3)',
              borderRadius: 8,
              marginBottom: 20,
              fontSize: 13,
              color: 'var(--error)',
            }}
          >
            {error}
          </div>
        )}

        {/* Submit Button */}
        <button
          type="submit"
          disabled={loading || !email}
          className="btn btn-primary"
          style={{
            width: '100%',
            justifyContent: 'center',
            padding: '14px 20px',
            fontSize: 15,
            fontWeight: 600,
            opacity: loading || !email ? 0.6 : 1,
            cursor: loading || !email ? 'not-allowed' : 'pointer',
          }}
        >
          {loading ? (
            <>
              <Loader2 size={18} className="animate-spin" />
              <span>Opening checkout...</span>
            </>
          ) : (
            <>
              <CreditCard size={18} />
              <span>Pay {planData.inr}</span>
            </>
          )}
        </button>
      </form>

      {/* Trust Badges */}
      <div style={{ marginTop: 28, paddingTop: 24, borderTop: '1px solid var(--border)' }}>
        <div style={{ display: 'flex', gap: 24, justifyContent: 'center', flexWrap: 'wrap', fontSize: 12, color: 'var(--text-muted)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <Shield size={14} />
            <span>Secure payment</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <Check size={14} />
            <span>30-day refund</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <Check size={14} />
            <span>Instant delivery</span>
          </div>
        </div>
        <div style={{ textAlign: 'center', marginTop: 16, fontSize: 11, color: 'var(--text-muted)' }}>
          Payments processed by <a href="https://razorpay.com" target="_blank" rel="noopener" style={{ color: 'var(--accent)', textDecoration: 'none' }}>Razorpay</a>
        </div>
      </div>
    </m.div>
  );
}
