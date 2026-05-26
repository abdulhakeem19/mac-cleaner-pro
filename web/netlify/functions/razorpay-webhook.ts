/**
 * Razorpay webhook handler for payment events.
 *
 * Handles:
 * - payment.captured: Generate license key, store purchase, send email
 * - payment.failed: Mark purchase as failed
 * - refund.created: Mark purchase as refunded
 *
 * Webhook setup in Razorpay Dashboard:
 * - URL: https://your-domain.com/.netlify/functions/razorpay-webhook
 * - Events: payment.captured, payment.failed, refund.created
 * - Secret: Add RAZORPAY_WEBHOOK_SECRET to env vars
 */

import crypto from 'node:crypto';
import { generateLicenseKey } from '../../lib/license';
import { storePurchase, updatePurchaseStatus } from '../../lib/supabase';

const RAZORPAY_WEBHOOK_SECRET = process.env.RAZORPAY_WEBHOOK_SECRET ?? '';
const LICENSE_PRIVATE_KEY = process.env.LICENSE_PRIVATE_KEY ?? '';
const RESEND_API_KEY = process.env.RESEND_API_KEY ?? '';

if (!RAZORPAY_WEBHOOK_SECRET) {
  console.error('⚠️  RAZORPAY_WEBHOOK_SECRET not configured');
}

interface RazorpayWebhookPayload {
  event: string;
  payload: {
    payment: {
      entity: {
        id: string;
        amount: number;
        currency: string;
        status: string;
        order_id: string;
        email?: string;
        contact?: string;
        notes?: Record<string, string>;
        created_at: number;
      };
    };
  };
}

/**
 * Verify Razorpay webhook signature
 */
function verifyWebhookSignature(body: string, signature: string): boolean {
  if (!RAZORPAY_WEBHOOK_SECRET) {
    console.warn('Skipping webhook signature verification (no secret configured)');
    return true; // Allow in development
  }

  const expectedSignature = crypto
    .createHmac('sha256', RAZORPAY_WEBHOOK_SECRET)
    .update(body)
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}

/**
 * Send license email via Resend
 */
async function sendLicenseEmail(email: string, licenseKey: string, plan: string) {
  if (!RESEND_API_KEY) {
    console.warn('⚠️  RESEND_API_KEY not configured, skipping email');
    return;
  }

  const planName = plan === 'family' ? 'Family (5 Macs)' : 'Pro (1 Mac)';

  const resp = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${RESEND_API_KEY}`,
    },
    body: JSON.stringify({
      from: 'Mac Cleaner Pro <orders@maccleanerpro.com>',
      to: email,
      subject: 'Your Mac Cleaner Pro License Key',
      html: `
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <title>Your Mac Cleaner Pro License</title>
            <style>
              * { margin: 0; padding: 0; box-sizing: border-box; }
              body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Helvetica Neue', Arial, sans-serif;
                line-height: 1.6;
                color: #1d1d1f;
                background-color: #f5f5f7;
                -webkit-font-smoothing: antialiased;
                -moz-osx-font-smoothing: grayscale;
              }
              .email-wrapper {
                width: 100%;
                background-color: #f5f5f7;
                padding: 40px 20px;
              }
              .email-container {
                max-width: 600px;
                margin: 0 auto;
                background: white;
                border-radius: 16px;
                overflow: hidden;
                box-shadow: 0 4px 24px rgba(0, 0, 0, 0.08);
              }
              .header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                padding: 48px 40px;
                text-align: center;
              }
              .header-icon {
                width: 64px;
                height: 64px;
                margin: 0 auto 20px;
                background: rgba(255, 255, 255, 0.2);
                border-radius: 16px;
                display: flex;
                align-items: center;
                justify-content: center;
              }
              .header h1 {
                color: white;
                font-size: 28px;
                font-weight: 600;
                margin: 0 0 8px 0;
                letter-spacing: -0.5px;
              }
              .header p {
                color: rgba(255, 255, 255, 0.9);
                font-size: 16px;
                margin: 0;
              }
              .content {
                padding: 40px;
              }
              .section {
                margin-bottom: 32px;
              }
              .section-title {
                font-size: 20px;
                font-weight: 600;
                color: #1d1d1f;
                margin-bottom: 16px;
                display: flex;
                align-items: center;
                gap: 10px;
              }
              .license-box {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                border-radius: 12px;
                padding: 24px;
                text-align: center;
                margin: 24px 0;
                position: relative;
                overflow: hidden;
              }
              .license-box::before {
                content: '';
                position: absolute;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: url('data:image/svg+xml,<svg width="100" height="100" xmlns="http://www.w3.org/2000/svg"><defs><pattern id="grid" width="20" height="20" patternUnits="userSpaceOnUse"><path d="M 20 0 L 0 0 0 20" fill="none" stroke="rgba(255,255,255,0.05)" stroke-width="1"/></pattern></defs><rect width="100" height="100" fill="url(%23grid)"/></svg>');
                opacity: 0.3;
              }
              .license-label {
                font-size: 12px;
                font-weight: 600;
                text-transform: uppercase;
                letter-spacing: 1px;
                color: rgba(255, 255, 255, 0.8);
                margin-bottom: 12px;
              }
              .license-key {
                background: rgba(255, 255, 255, 0.15);
                backdrop-filter: blur(10px);
                border: 1px solid rgba(255, 255, 255, 0.2);
                border-radius: 8px;
                padding: 16px;
                font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
                font-size: 14px;
                color: white;
                font-weight: 600;
                word-break: break-all;
                letter-spacing: 0.5px;
                position: relative;
                z-index: 1;
              }
              .steps-list {
                list-style: none;
                padding: 0;
                margin: 0;
              }
              .step-item {
                display: flex;
                gap: 16px;
                margin-bottom: 20px;
                padding: 16px;
                background: #f9f9fb;
                border-radius: 10px;
                align-items: flex-start;
              }
              .step-number {
                flex-shrink: 0;
                width: 32px;
                height: 32px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                font-weight: 600;
                font-size: 14px;
              }
              .step-content h4 {
                font-size: 15px;
                font-weight: 600;
                color: #1d1d1f;
                margin-bottom: 4px;
              }
              .step-content p {
                font-size: 14px;
                color: #6e6e73;
                margin: 0;
              }
              .cta-button {
                display: inline-block;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 16px 32px;
                border-radius: 10px;
                text-decoration: none;
                font-weight: 600;
                font-size: 15px;
                text-align: center;
                margin: 24px 0;
                transition: transform 0.2s;
              }
              .help-section {
                background: #f9f9fb;
                border-radius: 12px;
                padding: 24px;
                margin-top: 32px;
              }
              .help-links {
                display: flex;
                flex-direction: column;
                gap: 12px;
                margin-top: 16px;
              }
              .help-link {
                display: flex;
                align-items: center;
                gap: 12px;
                color: #667eea;
                text-decoration: none;
                font-size: 14px;
                font-weight: 500;
              }
              .info-grid {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 16px;
                margin-top: 16px;
              }
              .info-item {
                background: #f9f9fb;
                padding: 16px;
                border-radius: 8px;
              }
              .info-label {
                font-size: 12px;
                color: #6e6e73;
                margin-bottom: 4px;
                text-transform: uppercase;
                letter-spacing: 0.5px;
                font-weight: 600;
              }
              .info-value {
                font-size: 15px;
                color: #1d1d1f;
                font-weight: 600;
              }
              .footer {
                background: #f9f9fb;
                padding: 32px 40px;
                text-align: center;
                border-top: 1px solid #e5e5e7;
              }
              .footer p {
                font-size: 13px;
                color: #6e6e73;
                margin: 8px 0;
              }
              .footer-links {
                margin-top: 16px;
                font-size: 13px;
              }
              .footer-links a {
                color: #667eea;
                text-decoration: none;
                margin: 0 8px;
              }
              @media only screen and (max-width: 600px) {
                .email-wrapper { padding: 20px 10px; }
                .content { padding: 24px; }
                .header { padding: 32px 24px; }
                .header h1 { font-size: 24px; }
                .info-grid { grid-template-columns: 1fr; }
              }
            </style>
          </head>
          <body>
            <div class="email-wrapper">
              <div class="email-container">
                <!-- Header -->
                <div class="header">
                  <div class="header-icon">
                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M9 11L12 14L22 4" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
                      <path d="M21 12V19C21 19.5304 20.7893 20.0391 20.4142 20.4142C20.0391 20.7893 19.5304 21 19 21H5C4.46957 21 3.96086 20.7893 3.58579 20.4142C3.21071 20.0391 3 19.5304 3 19V5C3 4.46957 3.21071 3.96086 3.58579 3.58579C3.96086 3.21071 4.46957 3 5 3H16" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
                    </svg>
                  </div>
                  <h1>Thank You for Your Purchase!</h1>
                  <p>Mac Cleaner Pro ${planName}</p>
                </div>

                <!-- Content -->
                <div class="content">
                  <!-- License Key Section -->
                  <div class="section">
                    <div class="section-title">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M21 2L11 12M21 2L14 22L11 12M21 2L3 8L11 12" stroke="#667eea" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                      </svg>
                      Your License Key
                    </div>
                    <p style="color: #6e6e73; font-size: 14px; margin-bottom: 16px;">
                      Save this license key securely. You'll need it to activate Mac Cleaner Pro and unlock all premium features.
                    </p>
                    <div class="license-box">
                      <div class="license-label">License Key</div>
                      <div class="license-key">${licenseKey}</div>
                    </div>
                  </div>

                  <!-- Next Steps -->
                  <div class="section">
                    <div class="section-title">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M12 2L2 7L12 12L22 7L12 2Z" stroke="#667eea" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                        <path d="M2 17L12 22L22 17" stroke="#667eea" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                        <path d="M2 12L12 17L22 12" stroke="#667eea" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                      </svg>
                      Getting Started
                    </div>
                    <ul class="steps-list">
                      <li class="step-item">
                        <div class="step-number">1</div>
                        <div class="step-content">
                          <h4>Download Mac Cleaner Pro</h4>
                          <p>Get the latest version for macOS from our website</p>
                        </div>
                      </li>
                      <li class="step-item">
                        <div class="step-number">2</div>
                        <div class="step-content">
                          <h4>Open Settings → License</h4>
                          <p>Launch the app and navigate to the license section</p>
                        </div>
                      </li>
                      <li class="step-item">
                        <div class="step-number">3</div>
                        <div class="step-content">
                          <h4>Enter Your License Key</h4>
                          <p>Paste the license key above to activate all features</p>
                        </div>
                      </li>
                    </ul>
                    <center>
                      <a href="https://maccleanerpro.com/download/" class="cta-button">
                        Download Mac Cleaner Pro
                      </a>
                    </center>
                  </div>

                  <!-- Purchase Details -->
                  <div class="section">
                    <div class="section-title">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <rect x="3" y="3" width="18" height="18" rx="2" stroke="#667eea" stroke-width="2"/>
                        <path d="M9 3V21" stroke="#667eea" stroke-width="2"/>
                      </svg>
                      Purchase Details
                    </div>
                    <div class="info-grid">
                      <div class="info-item">
                        <div class="info-label">Plan</div>
                        <div class="info-value">${planName}</div>
                      </div>
                      <div class="info-item">
                        <div class="info-label">Devices</div>
                        <div class="info-value">${plan === 'family' ? '5 Macs' : '1 Mac'}</div>
                      </div>
                      <div class="info-item">
                        <div class="info-label">Email</div>
                        <div class="info-value">${email}</div>
                      </div>
                      <div class="info-item">
                        <div class="info-label">License Type</div>
                        <div class="info-value">Lifetime</div>
                      </div>
                    </div>
                  </div>

                  <!-- Help Section -->
                  <div class="help-section">
                    <div class="section-title" style="margin-bottom: 8px;">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <circle cx="12" cy="12" r="10" stroke="#667eea" stroke-width="2"/>
                        <path d="M12 16V12" stroke="#667eea" stroke-width="2" stroke-linecap="round"/>
                        <circle cx="12" cy="8" r="1" fill="#667eea"/>
                      </svg>
                      Need Help?
                    </div>
                    <p style="color: #6e6e73; font-size: 14px; margin-bottom: 12px;">
                      Our support team is here to assist you with installation, activation, or any questions.
                    </p>
                    <div class="help-links">
                      <a href="https://maccleanerpro.com/install/" class="help-link">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                          <path d="M14 2H6C5.46957 2 4.96086 2.21071 4.58579 2.58579C4.21071 2.96086 4 3.46957 4 4V20C4 20.5304 4.21071 21.0391 4.58579 21.4142C4.96086 21.7893 5.46957 22 6 22H18C18.5304 22 19.0391 21.7893 19.4142 21.4142C19.7893 21.0391 20 20.5304 20 20V8L14 2Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                          <path d="M14 2V8H20" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                        </svg>
                        Installation Guide
                      </a>
                      <a href="https://maccleanerpro.com/contact/" class="help-link">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                          <path d="M21 11.5C21.0034 12.8199 20.6951 14.1219 20.1 15.3C19.3944 16.7117 18.3098 17.8992 16.9674 18.7293C15.6251 19.5594 14.0782 19.9994 12.5 20C11.1801 20.0034 9.87812 19.6951 8.7 19.1L3 21L4.9 15.3C4.30493 14.1219 3.99656 12.8199 4 11.5C4.00061 9.92176 4.44061 8.37485 5.27072 7.03255C6.10083 5.69025 7.28825 4.60557 8.7 3.89999C9.87812 3.30493 11.1801 2.99656 12.5 2.99999H13C15.0843 3.11502 17.053 3.99479 18.5291 5.47089C20.0052 6.94699 20.885 8.91568 21 11V11.5Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                        </svg>
                        Contact Support
                      </a>
                    </div>
                  </div>
                </div>

                <!-- Footer -->
                <div class="footer">
                  <p style="font-weight: 600; color: #1d1d1f; margin-bottom: 8px;">Mac Cleaner Pro</p>
                  <p>One-time purchase • Lifetime updates (v1.x) • No subscription</p>
                  <p style="margin-top: 16px;">
                    30-day money-back guarantee, no questions asked.
                  </p>
                  <div class="footer-links">
                    <a href="https://maccleanerpro.com/refund/">Refund Policy</a> •
                    <a href="https://maccleanerpro.com/privacy/">Privacy</a> •
                    <a href="https://maccleanerpro.com/terms/">Terms</a>
                  </div>
                  <p style="margin-top: 16px; font-size: 12px; color: #86868b;">
                    © ${new Date().getFullYear()} Mac Cleaner Pro. All rights reserved.
                  </p>
                </div>
              </div>
            </div>
          </body>
        </html>
      `,
    }),
  });

  if (!resp.ok) {
    const error = await resp.text();
    console.error('Failed to send email:', error);
    throw new Error(`Email delivery failed: ${error}`);
  }

  console.log('✅ License email sent to:', email);
}

/**
 * Handle payment.captured event
 */
async function handlePaymentCaptured(payment: any) {
  const { id: paymentId, amount, currency, email, notes, order_id } = payment;

  // Extract email and plan from payment metadata
  const customerEmail = email || notes?.email;
  const plan = notes?.plan || 'pro';

  if (!customerEmail) {
    throw new Error('No email found in payment data');
  }

  if (plan !== 'pro' && plan !== 'family') {
    throw new Error(`Invalid plan: ${plan}`);
  }

  // Generate license key
  const machineLimit = plan === 'family' ? 5 : 1;
  const licenseKey = await generateLicenseKey(
    {
      email: customerEmail.toLowerCase(),
      plan,
      purchaseDate: new Date().toISOString(),
      machineLimit,
    },
    LICENSE_PRIVATE_KEY
  );

  console.log('Generated license key:', licenseKey.substring(0, 20) + '...');

  // Store purchase in database
  await storePurchase({
    email: customerEmail.toLowerCase(),
    plan,
    license_key: licenseKey,
    payment_provider: 'razorpay',
    payment_id: paymentId,
    amount,
    currency: currency.toUpperCase(),
    status: 'completed',
    metadata: {
      order_id,
      notes,
    },
  });

  console.log('✅ Purchase stored for:', customerEmail);

  // Send license email
  await sendLicenseEmail(customerEmail, licenseKey, plan);

  return { licenseKey };
}

/**
 * Main webhook handler
 */
export const handler = async (event: any) => {
  // Only accept POST
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method Not Allowed' };
  }

  try {
    // Verify signature
    const signature = event.headers['x-razorpay-signature'] || '';
    const isValid = verifyWebhookSignature(event.body, signature);

    if (!isValid) {
      console.error('⚠️  Invalid webhook signature');
      return { statusCode: 401, body: 'Invalid signature' };
    }

    // Parse payload
    const payload: RazorpayWebhookPayload = JSON.parse(event.body);
    const { event: eventType } = payload;

    console.log(`📩 Webhook received: ${eventType}`);

    // Handle different event types
    switch (eventType) {
      case 'payment.captured': {
        const { payment } = payload.payload;
        const result = await handlePaymentCaptured(payment.entity);
        return {
          statusCode: 200,
          body: JSON.stringify({ success: true, licenseKey: result.licenseKey }),
        };
      }

      case 'payment.failed': {
        const { payment } = payload.payload;
        await updatePurchaseStatus(payment.entity.id, 'failed');
        console.log('❌ Payment failed:', payment.entity.id);
        return { statusCode: 200, body: JSON.stringify({ success: true }) };
      }

      case 'refund.created': {
        const { payment } = payload.payload;
        await updatePurchaseStatus(payment.entity.id, 'refunded');
        console.log('💸 Refund processed:', payment.entity.id);
        return { statusCode: 200, body: JSON.stringify({ success: true }) };
      }

      default:
        console.log(`ℹ️  Unhandled event type: ${eventType}`);
        return { statusCode: 200, body: JSON.stringify({ success: true }) };
    }
  } catch (error: any) {
    console.error('❌ Webhook error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};
