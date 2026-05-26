/**
 * Simple analytics and monitoring utilities.
 *
 * Tracks key events for payment flow, license activations, and errors.
 * Can be extended with Sentry, LogSnag, or other services.
 */

export interface AnalyticsEvent {
  event: string;
  properties?: Record<string, any>;
  timestamp?: string;
}

/**
 * Track a payment event
 */
export function trackPayment(event: {
  action: 'order_created' | 'payment_completed' | 'payment_failed' | 'refund_created';
  plan: 'pro' | 'family';
  amount: number;
  currency: string;
  paymentId?: string;
  email?: string;
  error?: string;
}) {
  const analyticsEvent: AnalyticsEvent = {
    event: `payment_${event.action}`,
    properties: {
      plan: event.plan,
      amount: event.amount,
      currency: event.currency,
      paymentId: event.paymentId,
      email: event.email ? hashEmail(event.email) : undefined,
      error: event.error,
    },
    timestamp: new Date().toISOString(),
  };

  logEvent(analyticsEvent);

  // TODO: Send to analytics service (e.g., Mixpanel, Amplitude)
  // TODO: Send to error tracking (e.g., Sentry) if error
}

/**
 * Track a license event
 */
export function trackLicense(event: {
  action: 'generated' | 'verified' | 'activated' | 'deactivated' | 'recovered';
  plan?: 'pro' | 'family';
  email?: string;
  deviceId?: string;
  success: boolean;
  error?: string;
}) {
  const analyticsEvent: AnalyticsEvent = {
    event: `license_${event.action}`,
    properties: {
      plan: event.plan,
      email: event.email ? hashEmail(event.email) : undefined,
      deviceId: event.deviceId ? hashString(event.deviceId) : undefined,
      success: event.success,
      error: event.error,
    },
    timestamp: new Date().toISOString(),
  };

  logEvent(analyticsEvent);
}

/**
 * Track an error
 */
export function trackError(error: {
  context: string;
  message: string;
  stack?: string;
  metadata?: Record<string, any>;
}) {
  const analyticsEvent: AnalyticsEvent = {
    event: 'error',
    properties: {
      context: error.context,
      message: error.message,
      stack: error.stack,
      ...error.metadata,
    },
    timestamp: new Date().toISOString(),
  };

  console.error(`[ERROR] ${error.context}:`, error.message);
  logEvent(analyticsEvent);

  // TODO: Send to Sentry or similar service
}

/**
 * Log event to console (development) or storage (production)
 */
function logEvent(event: AnalyticsEvent) {
  if (process.env.NODE_ENV === 'development') {
    console.log('[Analytics]', event.event, event.properties);
  }

  // TODO: In production, send to:
  // - Analytics service (Mixpanel, Amplitude, PostHog)
  // - Error tracking (Sentry)
  // - Logging service (LogSnag, Datadog)
  // - Database (for internal dashboards)
}

/**
 * Hash email for privacy-preserving analytics
 */
function hashEmail(email: string): string {
  // Simple hash for privacy - not cryptographic
  const domain = email.split('@')[1];
  const hash = simpleHash(email);
  return `${hash}@${domain}`;
}

/**
 * Hash any string
 */
function hashString(str: string): string {
  return simpleHash(str);
}

/**
 * Simple hash function (not cryptographic)
 */
function simpleHash(str: string): string {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash = hash & hash; // Convert to 32bit integer
  }
  return Math.abs(hash).toString(36).substring(0, 8);
}

/**
 * Get revenue metrics
 */
export interface RevenueMetrics {
  totalRevenue: number;
  totalPurchases: number;
  proPurchases: number;
  familyPurchases: number;
  averageOrderValue: number;
}

/**
 * Calculate revenue metrics from purchases
 */
export function calculateRevenue(purchases: Array<{ amount: number; plan: string }>): RevenueMetrics {
  const totalRevenue = purchases.reduce((sum, p) => sum + p.amount, 0);
  const totalPurchases = purchases.length;
  const proPurchases = purchases.filter(p => p.plan === 'pro').length;
  const familyPurchases = purchases.filter(p => p.plan === 'family').length;
  const averageOrderValue = totalPurchases > 0 ? totalRevenue / totalPurchases : 0;

  return {
    totalRevenue,
    totalPurchases,
    proPurchases,
    familyPurchases,
    averageOrderValue,
  };
}
