/**
 * License verification API endpoint.
 *
 * Used by desktop app to:
 * 1. Verify license key signature
 * 2. Check machine activation limits
 * 3. Register new device activation
 *
 * POST /.netlify/functions/license-verify
 * Body: { licenseKey, deviceId, deviceName, action: 'verify' | 'activate' | 'deactivate' }
 */

import { validateLicenseKey } from '../../lib/license';
import {
  getPurchaseByLicenseKey,
  getActivations,
  createActivation,
  updateActivationLastSeen,
  deactivateDevice,
} from '../../lib/supabase';

const LICENSE_PUBLIC_KEY = process.env.LICENSE_PUBLIC_KEY ?? '';

if (!LICENSE_PUBLIC_KEY) {
  console.error('⚠️  LICENSE_PUBLIC_KEY not configured');
}

interface VerifyRequest {
  licenseKey: string;
  deviceId?: string;
  deviceName?: string;
  action: 'verify' | 'activate' | 'deactivate';
}

interface VerifyResponse {
  valid: boolean;
  payload?: {
    email: string;
    plan: 'pro' | 'family';
    purchaseDate: string;
    machineLimit: number;
  };
  activations?: {
    count: number;
    limit: number;
    devices: Array<{
      deviceId: string;
      deviceName: string;
      activatedAt: string;
      lastSeenAt: string;
    }>;
  };
  error?: string;
}

export const handler = async (event: any) => {
  // Only POST
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method Not Allowed' };
  }

  try {
    const body: VerifyRequest = JSON.parse(event.body || '{}');
    const { licenseKey, deviceId, deviceName, action } = body;

    if (!licenseKey) {
      return {
        statusCode: 400,
        body: JSON.stringify({ valid: false, error: 'Missing licenseKey' }),
      };
    }

    // Step 1: Verify signature
    const payload = await validateLicenseKey(licenseKey, LICENSE_PUBLIC_KEY);

    if (!payload) {
      return {
        statusCode: 200,
        body: JSON.stringify({ valid: false, error: 'Invalid license signature' }),
      };
    }

    // Step 2: Check if license exists in database
    const purchase = await getPurchaseByLicenseKey(licenseKey);

    if (!purchase) {
      return {
        statusCode: 200,
        body: JSON.stringify({ valid: false, error: 'License not found' }),
      };
    }

    if (purchase.status === 'refunded') {
      return {
        statusCode: 200,
        body: JSON.stringify({ valid: false, error: 'License has been refunded' }),
      };
    }

    // Step 3: Get current activations
    const activations = await getActivations(licenseKey);

    // Handle different actions
    switch (action) {
      case 'verify': {
        // Just verify the license, no activation changes
        return {
          statusCode: 200,
          body: JSON.stringify({
            valid: true,
            payload,
            activations: {
              count: activations.length,
              limit: payload.machineLimit,
              devices: activations.map(a => ({
                deviceId: a.device_id,
                deviceName: a.device_name,
                activatedAt: a.activated_at,
                lastSeenAt: a.last_seen_at,
              })),
            },
          } as VerifyResponse),
        };
      }

      case 'activate': {
        if (!deviceId || !deviceName) {
          return {
            statusCode: 400,
            body: JSON.stringify({ valid: false, error: 'Missing deviceId or deviceName' }),
          };
        }

        // Check if device already activated
        const existingActivation = activations.find(a => a.device_id === deviceId);

        if (existingActivation) {
          // Update last seen
          await updateActivationLastSeen(licenseKey, deviceId);
          return {
            statusCode: 200,
            body: JSON.stringify({
              valid: true,
              payload,
              activations: {
                count: activations.length,
                limit: payload.machineLimit,
                devices: activations.map(a => ({
                  deviceId: a.device_id,
                  deviceName: a.device_name,
                  activatedAt: a.activated_at,
                  lastSeenAt: a.device_id === deviceId ? new Date().toISOString() : a.last_seen_at,
                })),
              },
            } as VerifyResponse),
          };
        }

        // Check if limit reached
        if (activations.length >= payload.machineLimit) {
          return {
            statusCode: 200,
            body: JSON.stringify({
              valid: false,
              error: `Machine limit reached (${payload.machineLimit}). Deactivate a device first.`,
              activations: {
                count: activations.length,
                limit: payload.machineLimit,
                devices: activations.map(a => ({
                  deviceId: a.device_id,
                  deviceName: a.device_name,
                  activatedAt: a.activated_at,
                  lastSeenAt: a.last_seen_at,
                })),
              },
            }),
          };
        }

        // Create new activation
        await createActivation({
          license_key: licenseKey,
          device_id: deviceId,
          device_name: deviceName,
        });

        const updatedActivations = await getActivations(licenseKey);

        return {
          statusCode: 200,
          body: JSON.stringify({
            valid: true,
            payload,
            activations: {
              count: updatedActivations.length,
              limit: payload.machineLimit,
              devices: updatedActivations.map(a => ({
                deviceId: a.device_id,
                deviceName: a.device_name,
                activatedAt: a.activated_at,
                lastSeenAt: a.last_seen_at,
              })),
            },
          } as VerifyResponse),
        };
      }

      case 'deactivate': {
        if (!deviceId) {
          return {
            statusCode: 400,
            body: JSON.stringify({ valid: false, error: 'Missing deviceId' }),
          };
        }

        await deactivateDevice(licenseKey, deviceId);
        const updatedActivations = await getActivations(licenseKey);

        return {
          statusCode: 200,
          body: JSON.stringify({
            valid: true,
            payload,
            activations: {
              count: updatedActivations.length,
              limit: payload.machineLimit,
              devices: updatedActivations.map(a => ({
                deviceId: a.device_id,
                deviceName: a.device_name,
                activatedAt: a.activated_at,
                lastSeenAt: a.last_seen_at,
              })),
            },
          } as VerifyResponse),
        };
      }

      default:
        return {
          statusCode: 400,
          body: JSON.stringify({ valid: false, error: 'Invalid action' }),
        };
    }
  } catch (error: any) {
    console.error('❌ License verification error:', error);

    // Return more helpful error messages
    let errorMessage = 'Internal server error';
    if (error.message) {
      if (error.message.includes('fetch')) {
        errorMessage = 'Database connection failed - please try again';
      } else if (error.message.includes('SUPABASE')) {
        errorMessage = 'Database not configured - license will work in offline mode';
      } else {
        errorMessage = error.message;
      }
    }

    return {
      statusCode: 200,  // Return 200 with error in body for better client handling
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        valid: false,
        error: errorMessage,
        offlineMode: true  // Signal that offline activation is available
      }),
    };
  }
};
