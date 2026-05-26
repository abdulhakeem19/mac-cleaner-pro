/**
 * License recovery endpoint - "Lost your license?" flow.
 *
 * POST /.netlify/functions/license-recover
 * Body: { email }
 *
 * Sends an email with all license keys associated with the email address.
 * Rate limited to prevent abuse.
 */

import { getPurchasesByEmail } from '../../lib/supabase';

const RESEND_API_KEY = process.env.RESEND_API_KEY ?? '';

// Simple in-memory rate limiting (resets on cold start)
const rateLimits = new Map<string, number>();
const RATE_LIMIT_WINDOW = 60 * 60 * 1000; // 1 hour
const MAX_REQUESTS = 3; // 3 requests per hour per email

function isRateLimited(email: string): boolean {
  const now = Date.now();
  const key = email.toLowerCase();
  const lastRequest = rateLimits.get(key) || 0;

  if (now - lastRequest < RATE_LIMIT_WINDOW) {
    return true;
  }

  rateLimits.set(key, now);
  return false;
}

async function sendRecoveryEmail(email: string, purchases: any[]) {
  if (!RESEND_API_KEY) {
    console.warn('⚠️  RESEND_API_KEY not configured, skipping email');
    return;
  }

  const licensesList = purchases
    .map(
      (p, i) => `
        <div style="background: white; border: 2px solid #0A84FF; border-radius: 8px; padding: 20px; margin: 15px 0;">
          <h3 style="margin: 0 0 10px 0; color: #0A84FF;">
            ${p.plan === 'family' ? 'Family Plan (5 Macs)' : 'Pro Plan (1 Mac)'}
          </h3>
          <div style="font-family: 'Monaco', monospace; font-size: 14px; word-break: break-all; background: #f5f5f5; padding: 12px; border-radius: 4px;">
            <strong>${p.license_key}</strong>
          </div>
          <p style="margin: 10px 0 0 0; font-size: 12px; color: #666;">
            Purchased: ${new Date(p.created_at).toLocaleDateString()}
          </p>
        </div>
      `
    )
    .join('');

  const resp = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${RESEND_API_KEY}`,
    },
    body: JSON.stringify({
      from: 'Mac Cleaner Pro <orders@maccleanerpro.com>',
      to: email,
      subject: 'Your Mac Cleaner Pro License Keys',
      html: `
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <style>
              body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: linear-gradient(135deg, #0A84FF 0%, #7C5CFF 100%); color: white; padding: 30px; border-radius: 12px 12px 0 0; }
              .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 12px 12px; }
              .footer { color: #666; font-size: 12px; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1 style="margin: 0;">Your License Keys 🔑</h1>
                <p style="margin: 10px 0 0 0; opacity: 0.9;">Mac Cleaner Pro</p>
              </div>
              <div class="content">
                <p>We found ${purchases.length} license ${purchases.length === 1 ? 'key' : 'keys'} associated with <strong>${email}</strong>:</p>
                ${licensesList}
                <h3>Need Help?</h3>
                <p>
                  • <a href="https://maccleanerpro.com/install/">Installation guide</a><br>
                  • <a href="https://maccleanerpro.com/contact/">Contact support</a><br>
                  • Reply to this email for questions
                </p>
                <div class="footer">
                  <p style="font-size: 11px; color: #999;">
                    You received this email because someone requested license recovery for this email address.<br>
                    If you didn't request this, you can safely ignore this email.
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
    console.error('Failed to send recovery email:', error);
    throw new Error(`Email delivery failed: ${error}`);
  }

  console.log('✅ Recovery email sent to:', email);
}

export const handler = async (event: any) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method Not Allowed' };
  }

  try {
    const { email } = JSON.parse(event.body || '{}');

    if (!email) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Email required' }),
      };
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Invalid email format' }),
      };
    }

    // Rate limiting
    if (isRateLimited(email)) {
      return {
        statusCode: 429,
        body: JSON.stringify({
          error: 'Too many requests. Please try again in an hour.',
        }),
      };
    }

    // Get purchases
    const purchases = await getPurchasesByEmail(email);

    if (purchases.length === 0) {
      // Don't reveal if email exists or not (privacy)
      return {
        statusCode: 200,
        body: JSON.stringify({
          success: true,
          message: 'If we found any licenses for this email, we sent them.',
        }),
      };
    }

    // Send recovery email
    await sendRecoveryEmail(email, purchases);

    return {
      statusCode: 200,
      body: JSON.stringify({
        success: true,
        message: `We sent ${purchases.length} license ${purchases.length === 1 ? 'key' : 'keys'} to ${email}`,
      }),
    };
  } catch (error: any) {
    console.error('❌ License recovery error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Internal server error' }),
    };
  }
};
