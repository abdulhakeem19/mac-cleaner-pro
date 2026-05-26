/**
 * Supabase client configuration for server-side operations.
 * Database schema is defined in supabase/migrations/
 */

import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.SUPABASE_URL ?? '';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY ?? '';

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
  throw new Error('Missing Supabase environment variables');
}

// Server-side client with service role key (bypass RLS)
export const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

// Database types
export interface Purchase {
  id: string;
  email: string;
  plan: 'pro' | 'family';
  license_key: string;
  payment_provider: 'razorpay' | 'stripe' | 'paddle';
  payment_id: string;
  amount: number;
  currency: string;
  status: 'pending' | 'completed' | 'failed' | 'refunded';
  created_at: string;
  updated_at: string;
  metadata?: Record<string, unknown>;
}

export interface Activation {
  id: string;
  license_key: string;
  device_id: string;
  device_name: string;
  activated_at: string;
  last_seen_at: string;
  deactivated_at?: string;
}

/**
 * Store a purchase record
 */
export async function storePurchase(purchase: Omit<Purchase, 'id' | 'created_at' | 'updated_at'>) {
  const { data, error } = await supabaseAdmin
    .from('purchases')
    .insert(purchase)
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to store purchase: ${error.message}`);
  }

  return data as Purchase;
}

/**
 * Get purchase by license key
 */
export async function getPurchaseByLicenseKey(licenseKey: string) {
  const { data, error } = await supabaseAdmin
    .from('purchases')
    .select('*')
    .eq('license_key', licenseKey)
    .single();

  if (error && error.code !== 'PGRST116') { // PGRST116 = not found
    throw new Error(`Failed to get purchase: ${error.message}`);
  }

  return data as Purchase | null;
}

/**
 * Get purchase by payment ID
 */
export async function getPurchaseByPaymentId(paymentId: string) {
  const { data, error } = await supabaseAdmin
    .from('purchases')
    .select('*')
    .eq('payment_id', paymentId)
    .single();

  if (error && error.code !== 'PGRST116') {
    throw new Error(`Failed to get purchase: ${error.message}`);
  }

  return data as Purchase | null;
}

/**
 * Get purchase by order ID (from metadata)
 */
export async function getPurchaseByOrderId(orderId: string) {
  const { data, error } = await supabaseAdmin
    .from('purchases')
    .select('*')
    .contains('metadata', { order_id: orderId })
    .single();

  if (error && error.code !== 'PGRST116') {
    throw new Error(`Failed to get purchase: ${error.message}`);
  }

  return data as Purchase | null;
}

/**
 * Get purchase by email
 */
export async function getPurchasesByEmail(email: string) {
  const { data, error } = await supabaseAdmin
    .from('purchases')
    .select('*')
    .eq('email', email.toLowerCase())
    .order('created_at', { ascending: false });

  if (error) {
    throw new Error(`Failed to get purchases: ${error.message}`);
  }

  return data as Purchase[];
}

/**
 * Update purchase status
 */
export async function updatePurchaseStatus(
  paymentId: string,
  status: Purchase['status']
) {
  const { data, error } = await supabaseAdmin
    .from('purchases')
    .update({ status, updated_at: new Date().toISOString() })
    .eq('payment_id', paymentId)
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to update purchase: ${error.message}`);
  }

  return data as Purchase;
}

/**
 * Get activations for a license key
 */
export async function getActivations(licenseKey: string) {
  const { data, error } = await supabaseAdmin
    .from('activations')
    .select('*')
    .eq('license_key', licenseKey)
    .is('deactivated_at', null)
    .order('activated_at', { ascending: false });

  if (error) {
    throw new Error(`Failed to get activations: ${error.message}`);
  }

  return data as Activation[];
}

/**
 * Create a new activation
 */
export async function createActivation(activation: Omit<Activation, 'id' | 'activated_at' | 'last_seen_at'>) {
  const { data, error } = await supabaseAdmin
    .from('activations')
    .insert({
      ...activation,
      activated_at: new Date().toISOString(),
      last_seen_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to create activation: ${error.message}`);
  }

  return data as Activation;
}

/**
 * Update last seen timestamp for an activation
 */
export async function updateActivationLastSeen(licenseKey: string, deviceId: string) {
  const { data, error } = await supabaseAdmin
    .from('activations')
    .update({ last_seen_at: new Date().toISOString() })
    .eq('license_key', licenseKey)
    .eq('device_id', deviceId)
    .is('deactivated_at', null)
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to update activation: ${error.message}`);
  }

  return data as Activation;
}

/**
 * Deactivate a device
 */
export async function deactivateDevice(licenseKey: string, deviceId: string) {
  const { data, error } = await supabaseAdmin
    .from('activations')
    .update({ deactivated_at: new Date().toISOString() })
    .eq('license_key', licenseKey)
    .eq('device_id', deviceId)
    .is('deactivated_at', null)
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to deactivate device: ${error.message}`);
  }

  return data as Activation;
}
