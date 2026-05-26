/**
 * Verify Razorpay payment signature (client-side verification)
 *
 * This endpoint is called by the frontend after successful payment
 * to verify the signature before showing the success page.
 *
 * Algorithm: HMAC-SHA256(order_id + "|" + payment_id, KEY_SECRET)
 */

import crypto from 'node:crypto';

const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET ?? '';

export const handler = async (event: any) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method Not Allowed' };
  }

  if (!RAZORPAY_KEY_SECRET) {
    return {
      statusCode: 503,
      body: JSON.stringify({ error: 'Razorpay not configured' }),
    };
  }

  try {
    const body = JSON.parse(event.body || '{}');
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = body;

    // Validate required fields
    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Missing required fields' }),
      };
    }

    // Generate expected signature
    const message = `${razorpay_order_id}|${razorpay_payment_id}`;
    const expectedSignature = crypto
      .createHmac('sha256', RAZORPAY_KEY_SECRET)
      .update(message)
      .digest('hex');

    // Compare signatures (timing-safe)
    const isValid = crypto.timingSafeEqual(
      Buffer.from(expectedSignature),
      Buffer.from(razorpay_signature)
    );

    if (!isValid) {
      console.error('⚠️  Invalid payment signature');
      return {
        statusCode: 400,
        body: JSON.stringify({
          error: 'Invalid signature',
          verified: false,
        }),
      };
    }

    console.log('✅ Payment signature verified:', razorpay_payment_id);

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        verified: true,
        payment_id: razorpay_payment_id,
        order_id: razorpay_order_id,
      }),
    };
  } catch (error: any) {
    console.error('Error verifying payment:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Verification failed' }),
    };
  }
};
