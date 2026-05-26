/**
 * Get license key by payment/order ID for success page display
 *
 * This allows the success page to fetch and display the license key
 * immediately after payment, before the email arrives.
 */

import { getPurchaseByPaymentId, getPurchaseByOrderId } from '../../lib/supabase';

export const handler = async (event: any) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method Not Allowed' };
  }

  try {
    const body = JSON.parse(event.body || '{}');
    const { payment_id, order_id, email } = body;

    if (!payment_id && !order_id) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'payment_id or order_id required' }),
      };
    }

    // Try to find purchase by payment ID first, then order ID
    let purchase;
    if (payment_id) {
      purchase = await getPurchaseByPaymentId(payment_id);
    } else if (order_id) {
      purchase = await getPurchaseByOrderId(order_id);
    }

    if (!purchase) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          error: 'Purchase not found',
          message: 'Your payment is being processed. Please check your email in a few moments.'
        }),
      };
    }

    // Verify email matches (security check)
    if (email && purchase.email.toLowerCase() !== email.toLowerCase()) {
      return {
        statusCode: 403,
        body: JSON.stringify({ error: 'Email mismatch' }),
      };
    }

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        license_key: purchase.license_key,
        plan: purchase.plan,
        email: purchase.email,
        purchase_date: purchase.created_at,
      }),
    };
  } catch (error: any) {
    console.error('Error fetching license:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Failed to fetch license key' }),
    };
  }
};
