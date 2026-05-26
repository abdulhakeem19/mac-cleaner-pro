/**
 * TEST PAYMENT ENDPOINT - For testing live payments with small amount
 *
 * Use this to test real payments with ₹10 or ₹100 instead of full price.
 * Delete or disable this endpoint after testing!
 *
 * Test URL: https://maccleanerpro.com/checkout?plan=test
 */

const RAZORPAY_KEY_ID = process.env.RAZORPAY_KEY_ID ?? '';
const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET ?? '';

const TEST_PLAN = {
  amount: 10000, // ₹100 in paise (change to 1000 for ₹10)
  name: 'Mac Cleaner Pro - TEST',
  machines: 1,
};

export const handler = async (event: { httpMethod: string; body: string | null }) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method Not Allowed' };
  }

  if (!RAZORPAY_KEY_ID || !RAZORPAY_KEY_SECRET) {
    return { statusCode: 503, body: JSON.stringify({ error: 'Razorpay not configured' }) };
  }

  let email: string;
  try {
    const body = JSON.parse(event.body ?? '{}');
    email = body.email;
  } catch {
    return { statusCode: 400, body: JSON.stringify({ error: 'Invalid body' }) };
  }

  if (!email) {
    return { statusCode: 400, body: JSON.stringify({ error: 'Email required' }) };
  }

  const auth = Buffer.from(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`).toString('base64');

  const resp = await fetch('https://api.razorpay.com/v1/orders', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Basic ${auth}`,
    },
    body: JSON.stringify({
      amount: TEST_PLAN.amount,
      currency: 'INR',
      receipt: `mcp-test-${Date.now()}`,
      notes: {
        plan: 'pro', // Will generate real license
        email: email,
        machines: TEST_PLAN.machines.toString(),
        test: 'true', // Mark as test
      },
    }),
  });

  if (!resp.ok) {
    const err = await resp.text();
    console.error('Razorpay order error:', err);
    return { statusCode: 502, body: JSON.stringify({ error: 'Order creation failed' }) };
  }

  const order = await resp.json();
  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      orderId: order.id,
      amount: order.amount,
      currency: order.currency,
      keyId: RAZORPAY_KEY_ID,
      name: TEST_PLAN.name,
      email: email,
    }),
  };
};
