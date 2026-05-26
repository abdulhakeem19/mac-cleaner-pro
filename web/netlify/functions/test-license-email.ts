/**
 * Manual test endpoint for license email generation.
 *
 * Use this to test the complete flow locally since webhooks don't work on localhost.
 *
 * POST /.netlify/functions/test-license-email
 * Body: { email, plan }
 */

import { generateLicenseKey } from '../../lib/license';
import { storePurchase } from '../../lib/supabase';

const LICENSE_PRIVATE_KEY = process.env.LICENSE_PRIVATE_KEY ?? '';
const RESEND_API_KEY = process.env.RESEND_API_KEY ?? '';

interface TestRequest {
  email: string;
  plan: 'pro' | 'family';
}

async function sendLicenseEmail(email: string, licenseKey: string, plan: string) {
  if (!RESEND_API_KEY) {
    throw new Error('RESEND_API_KEY not configured');
  }

  const planName = plan === 'family' ? 'Family (5 Macs)' : 'Pro (1 Mac)';

  const resp = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${RESEND_API_KEY}`,
    },
    body: JSON.stringify({
      from: 'Mac Cleaner Pro <hello@maccleanerpro.com>', // Using Resend test domain
      to: email,
      subject: '🎉 Your Mac Cleaner Pro License Key (TEST)',
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
              .license-box { background: white; border: 2px solid #0A84FF; border-radius: 8px; padding: 20px; margin: 20px 0; font-family: 'Monaco', monospace; font-size: 14px; word-break: break-all; }
              .button { display: inline-block; background: #0A84FF; color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none; margin: 20px 0; }
              .footer { color: #666; font-size: 12px; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1 style="margin: 0;">Thank you for your purchase! 🎉</h1>
                <p style="margin: 10px 0 0 0; opacity: 0.9;">Mac Cleaner Pro ${planName}</p>
              </div>
              <div class="content">
                <h2>Your License Key</h2>
                <p>Save this license key in a safe place. You'll need it to activate Mac Cleaner Pro on your Mac.</p>
                <div class="license-box">
                  <strong>${licenseKey}</strong>
                </div>

                <h3>Next Steps</h3>
                <ol>
                  <li><strong>Download Mac Cleaner Pro</strong> from <a href="https://maccleanerpro.com/download/">maccleanerpro.com/download</a></li>
                  <li><strong>Open the app</strong> and go to Settings → License</li>
                  <li><strong>Enter your license key</strong> to unlock all Pro features</li>
                </ol>

                <a href="https://maccleanerpro.com/download/" class="button">Download Now</a>

                <h3>Need Help?</h3>
                <p>
                  • <a href="https://maccleanerpro.com/install/">Installation guide</a><br>
                  • <a href="https://maccleanerpro.com/contact/">Contact support</a><br>
                  • Reply to this email for any questions
                </p>

                <div class="footer">
                  <p>
                    <strong>Purchase Details:</strong><br>
                    Plan: Mac Cleaner Pro ${planName}<br>
                    Email: ${email}<br>
                    Machines: ${plan === 'family' ? '5' : '1'}<br>
                  </p>
                  <p>This is a one-time purchase with lifetime updates to v1.x. No subscription required.</p>
                  <p style="font-size: 11px; color: #999;">
                    Questions about refunds? We offer a 30-day money-back guarantee, no questions asked.<br>
                    Visit <a href="https://maccleanerpro.com/refund/">maccleanerpro.com/refund</a> for details.
                  </p>
                  <p style="font-size: 11px; color: #ff6b6b;">
                    <strong>TEST MODE:</strong> This is a test email generated for development purposes.
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

  const result = await resp.json();
  console.log('✅ License email sent:', result);
  return result;
}

export const handler = async (event: any) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method Not Allowed' };
  }

  try {
    const body: TestRequest = JSON.parse(event.body || '{}');
    const { email, plan } = body;

    if (!email || !plan) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Email and plan required' }),
      };
    }

    if (plan !== 'pro' && plan !== 'family') {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Plan must be "pro" or "family"' }),
      };
    }

    console.log(`🧪 TEST: Generating license for ${email} (${plan})`);

    // Generate license key
    const machineLimit = plan === 'family' ? 5 : 1;
    const licenseKey = await generateLicenseKey(
      {
        email: email.toLowerCase(),
        plan,
        purchaseDate: new Date().toISOString(),
        machineLimit,
      },
      LICENSE_PRIVATE_KEY
    );

    console.log('Generated license key:', licenseKey.substring(0, 30) + '...');

    // Store in database
    const testPaymentId = `test_${Date.now()}`;
    await storePurchase({
      email: email.toLowerCase(),
      plan,
      license_key: licenseKey,
      payment_provider: 'razorpay',
      payment_id: testPaymentId,
      amount: plan === 'family' ? 579900 : 329900,
      currency: 'INR',
      status: 'completed',
      metadata: {
        test: true,
        note: 'Generated via test endpoint',
      },
    });

    console.log('✅ Purchase stored in database');

    // Send email
    const emailResult = await sendLicenseEmail(email, licenseKey, plan);

    console.log('✅ Email sent successfully');

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        success: true,
        licenseKey,
        email: email,
        plan: plan,
        emailSent: true,
        emailId: emailResult.id,
        message: 'License generated and email sent! Check your inbox.',
      }),
    };
  } catch (error: any) {
    console.error('❌ Test endpoint error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        error: error.message,
        stack: process.env.NODE_ENV === 'development' ? error.stack : undefined,
      }),
    };
  }
};
