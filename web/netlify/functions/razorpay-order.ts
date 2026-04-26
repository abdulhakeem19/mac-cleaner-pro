const RAZORPAY_KEY_ID     = process.env.RAZORPAY_KEY_ID     ?? "";
const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET ?? "";

const PLANS: Record<string, { amount: number; name: string }> = {
  pro:    { amount: 329900, name: "Mac Cleaner Pro — 1 Mac"         }, // ₹3,299 in paise
  family: { amount: 579900, name: "Mac Cleaner Pro — Family 5 Macs" }, // ₹5,799 in paise
};

// Netlify serverless handler — no @netlify/functions dep needed for basic JS exports
export const handler = async (event: { httpMethod: string; body: string | null }) => {
  if (event.httpMethod !== "POST") {
    return { statusCode: 405, body: "Method Not Allowed" };
  }

  if (!RAZORPAY_KEY_ID || !RAZORPAY_KEY_SECRET) {
    return { statusCode: 503, body: JSON.stringify({ error: "Razorpay not configured" }) };
  }

  let planKey: string;
  try {
    planKey = JSON.parse(event.body ?? "{}").plan;
  } catch {
    return { statusCode: 400, body: JSON.stringify({ error: "Invalid body" }) };
  }

  const plan = PLANS[planKey];
  if (!plan) {
    return { statusCode: 400, body: JSON.stringify({ error: "Unknown plan" }) };
  }

  const auth = Buffer.from(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`).toString("base64");

  const resp = await fetch("https://api.razorpay.com/v1/orders", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Basic ${auth}`,
    },
    body: JSON.stringify({
      amount: plan.amount,
      currency: "INR",
      receipt: `mcp-${planKey}-${Date.now()}`,
      notes: { plan: planKey },
    }),
  });

  if (!resp.ok) {
    const err = await resp.text();
    console.error("Razorpay order error:", err);
    return { statusCode: 502, body: JSON.stringify({ error: "Order creation failed" }) };
  }

  const order = await resp.json();
  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      orderId: order.id,
      amount:  order.amount,
      currency: order.currency,
      keyId: RAZORPAY_KEY_ID,
      name: plan.name,
    }),
  };
};
