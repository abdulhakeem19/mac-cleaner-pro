#!/usr/bin/env node
/**
 * Test license key generation and verification.
 *
 * Run: node scripts/test-license.js
 */

const crypto = require('crypto');

// Load keys from .env.local or use the ones from generation
const privateKeyPem = `-----BEGIN PRIVATE KEY-----
MC4CAQAwBQYDK2VwBCIEIOeP9Ne7clcCwtT51DfqvNiwm4ieOyjpgvbagtoIgvVC
-----END PRIVATE KEY-----`;

const publicKeyPem = `-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAKnIyzginaZwN7MOyjuFZmVSo22t+Gep1+45wvY7xqlM=
-----END PUBLIC KEY-----`;

function base64urlEncode(data) {
  const base64 = Buffer.from(data).toString('base64');
  return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

function base64urlDecode(str) {
  const base64 = str.replace(/-/g, '+').replace(/_/g, '/');
  const padding = '='.repeat((4 - base64.length % 4) % 4);
  return Buffer.from(base64 + padding, 'base64');
}

function generateLicenseKey(email, plan, machineLimit) {
  const payload = `${email}|${plan}|${new Date().toISOString()}|${machineLimit}`;
  const payloadBytes = Buffer.from(payload, 'utf8');
  const payloadB64 = base64urlEncode(payloadBytes);

  // Sign
  const privateKey = crypto.createPrivateKey(privateKeyPem);
  const signature = crypto.sign(null, payloadBytes, privateKey);
  const signatureB64 = base64urlEncode(signature);

  return `MCP-${payloadB64}.${signatureB64}`;
}

function verifyLicenseKey(licenseKey) {
  try {
    if (!licenseKey.startsWith('MCP-')) {
      return { valid: false, error: 'Invalid format' };
    }

    const parts = licenseKey.slice(4).split('.');
    if (parts.length !== 2) {
      return { valid: false, error: 'Invalid format' };
    }

    const [payloadB64, signatureB64] = parts;
    const payloadBytes = base64urlDecode(payloadB64);
    const signatureBytes = base64urlDecode(signatureB64);

    // Verify signature
    const publicKey = crypto.createPublicKey(publicKeyPem);
    const valid = crypto.verify(null, payloadBytes, publicKey, signatureBytes);

    if (!valid) {
      return { valid: false, error: 'Invalid signature' };
    }

    // Parse payload
    const payload = payloadBytes.toString('utf8');
    const [email, plan, purchaseDate, machineLimit] = payload.split('|');

    return {
      valid: true,
      payload: {
        email,
        plan,
        purchaseDate,
        machineLimit: parseInt(machineLimit, 10),
      },
    };
  } catch (error) {
    return { valid: false, error: error.message };
  }
}

// Run tests
console.log('🔐 License Key Generation & Verification Test\n');
console.log('━'.repeat(80));

// Test 1: Generate Pro license
console.log('\n📝 Test 1: Generate Pro License (1 Mac)');
const proKey = generateLicenseKey('test@example.com', 'pro', 1);
console.log('Generated:', proKey);
console.log('Length:', proKey.length, 'chars');

// Test 2: Verify Pro license
console.log('\n✅ Test 2: Verify Pro License');
const proVerify = verifyLicenseKey(proKey);
console.log('Valid:', proVerify.valid);
if (proVerify.valid) {
  console.log('Email:', proVerify.payload.email);
  console.log('Plan:', proVerify.payload.plan);
  console.log('Machine Limit:', proVerify.payload.machineLimit);
  console.log('Purchase Date:', proVerify.payload.purchaseDate);
}

// Test 3: Generate Family license
console.log('\n📝 Test 3: Generate Family License (5 Macs)');
const familyKey = generateLicenseKey('family@example.com', 'family', 5);
console.log('Generated:', familyKey);

// Test 4: Verify Family license
console.log('\n✅ Test 4: Verify Family License');
const familyVerify = verifyLicenseKey(familyKey);
console.log('Valid:', familyVerify.valid);
if (familyVerify.valid) {
  console.log('Email:', familyVerify.payload.email);
  console.log('Plan:', familyVerify.payload.plan);
  console.log('Machine Limit:', familyVerify.payload.machineLimit);
}

// Test 5: Tampered key
console.log('\n❌ Test 5: Tampered License Key');
const tamperedKey = proKey.slice(0, -5) + 'AAAAA';
const tamperedVerify = verifyLicenseKey(tamperedKey);
console.log('Valid:', tamperedVerify.valid);
console.log('Error:', tamperedVerify.error);

// Test 6: Invalid format
console.log('\n❌ Test 6: Invalid Format');
const invalidVerify = verifyLicenseKey('INVALID-KEY');
console.log('Valid:', invalidVerify.valid);
console.log('Error:', invalidVerify.error);

console.log('\n━'.repeat(80));
console.log('\n✅ All tests completed!\n');
console.log('💡 Use these test license keys for development:');
console.log('   Pro:', proKey.substring(0, 40) + '...');
console.log('   Family:', familyKey.substring(0, 40) + '...');
console.log('\n📋 Next step: Test the complete payment flow with `netlify dev`\n');
