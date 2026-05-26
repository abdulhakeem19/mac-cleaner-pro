/**
 * License key generation and verification library.
 *
 * Format: MCP-{base64url(payload)}.{base64url(signature)}
 * Payload: email|plan|purchaseDate|machineLimit
 * Signature: Ed25519 signature of payload
 *
 * Example: MCP-dXNlckBleGFtcGxlLmNvbXxwcm98MjAyNi0wNS0yNXwx.SGVsbG9Xb3JsZFNpZ25hdHVyZUhlcmVGb3JUZXN0aW5n
 */

export type LicensePlan = 'pro' | 'family';

export interface LicensePayload {
  email: string;
  plan: LicensePlan;
  purchaseDate: string; // ISO 8601
  machineLimit: number; // 1 for pro, 5 for family
}

export interface LicenseKey {
  key: string;
  payload: LicensePayload;
}

/**
 * Base64url encoding (URL-safe, no padding)
 */
function base64urlEncode(data: Uint8Array): string {
  const base64 = Buffer.from(data).toString('base64');
  return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

/**
 * Base64url decoding
 */
function base64urlDecode(str: string): Uint8Array {
  const base64 = str.replace(/-/g, '+').replace(/_/g, '/');
  const padding = '='.repeat((4 - base64.length % 4) % 4);
  return new Uint8Array(Buffer.from(base64 + padding, 'base64'));
}

/**
 * Generate a license key (server-side only - requires private key)
 *
 * @param payload License information
 * @param privateKeyPem Ed25519 private key in PEM format
 * @returns Complete license key string
 */
export async function generateLicenseKey(
  payload: LicensePayload,
  privateKeyPem: string
): Promise<string> {
  // Import crypto for Node.js
  const crypto = await import('node:crypto');

  // Create payload string
  const payloadStr = `${payload.email}|${payload.plan}|${payload.purchaseDate}|${payload.machineLimit}`;
  const payloadBytes = new TextEncoder().encode(payloadStr);
  const payloadB64 = base64urlEncode(payloadBytes);

  // Import private key
  const privateKey = crypto.createPrivateKey(privateKeyPem);

  // Sign the payload
  const signature = crypto.sign(null, payloadBytes, privateKey);
  const signatureB64 = base64urlEncode(new Uint8Array(signature));

  return `MCP-${payloadB64}.${signatureB64}`;
}

/**
 * Parse a license key without verification
 *
 * @param licenseKey The license key string
 * @returns Parsed payload or null if invalid format
 */
export function parseLicenseKey(licenseKey: string): LicensePayload | null {
  try {
    // Check format: MCP-{payload}.{signature}
    if (!licenseKey.startsWith('MCP-')) {
      return null;
    }

    const parts = licenseKey.slice(4).split('.');
    if (parts.length !== 2) {
      return null;
    }

    const [payloadB64] = parts;
    const payloadBytes = base64urlDecode(payloadB64);
    const payloadStr = new TextDecoder().decode(payloadBytes);

    // Parse: email|plan|purchaseDate|machineLimit
    const fields = payloadStr.split('|');
    if (fields.length !== 4) {
      return null;
    }

    const [email, plan, purchaseDate, machineLimitStr] = fields;
    const machineLimit = parseInt(machineLimitStr, 10);

    if (!email || !plan || !purchaseDate || isNaN(machineLimit)) {
      return null;
    }

    if (plan !== 'pro' && plan !== 'family') {
      return null;
    }

    return {
      email,
      plan: plan as LicensePlan,
      purchaseDate,
      machineLimit,
    };
  } catch {
    return null;
  }
}

/**
 * Verify a license key signature (server-side or client-side)
 *
 * @param licenseKey The license key string
 * @param publicKeyPem Ed25519 public key in PEM format
 * @returns true if signature is valid, false otherwise
 */
export async function verifyLicenseKey(
  licenseKey: string,
  publicKeyPem: string
): Promise<boolean> {
  try {
    // Import crypto
    const crypto = await import('node:crypto');

    // Parse the key
    if (!licenseKey.startsWith('MCP-')) {
      return false;
    }

    const parts = licenseKey.slice(4).split('.');
    if (parts.length !== 2) {
      return false;
    }

    const [payloadB64, signatureB64] = parts;
    const payloadBytes = base64urlDecode(payloadB64);
    const signatureBytes = base64urlDecode(signatureB64);

    // Import public key
    const publicKey = crypto.createPublicKey(publicKeyPem);

    // Verify signature
    return crypto.verify(
      null,
      payloadBytes,
      publicKey,
      Buffer.from(signatureBytes)
    );
  } catch {
    return false;
  }
}

/**
 * Validate license key and return parsed payload if valid
 *
 * @param licenseKey The license key string
 * @param publicKeyPem Ed25519 public key in PEM format
 * @returns Parsed payload if valid, null otherwise
 */
export async function validateLicenseKey(
  licenseKey: string,
  publicKeyPem: string
): Promise<LicensePayload | null> {
  const payload = parseLicenseKey(licenseKey);
  if (!payload) {
    return null;
  }

  const isValid = await verifyLicenseKey(licenseKey, publicKeyPem);
  if (!isValid) {
    return null;
  }

  return payload;
}

/**
 * Check if license key is structurally valid (basic format check)
 * Same as Swift's isStructurallyValid - useful for quick validation
 */
export function isStructurallyValid(key: string): boolean {
  const trimmed = key.trim();
  if (!trimmed.startsWith('MCP-')) {
    return false;
  }
  const rest = trimmed.slice(4);
  return rest.length >= 12 && rest.includes('.');
}
