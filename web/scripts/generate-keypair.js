#!/usr/bin/env node
/**
 * Generate Ed25519 keypair for license signing.
 *
 * Run: node scripts/generate-keypair.js
 *
 * Outputs:
 * - Private key (keep secret, add to env vars)
 * - Public key (embed in desktop app)
 */

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

function generateKeypair() {
  const { publicKey, privateKey } = crypto.generateKeyPairSync('ed25519', {
    publicKeyEncoding: { type: 'spki', format: 'pem' },
    privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
  });

  return { publicKey, privateKey };
}

console.log('🔐 Generating Ed25519 keypair for license signing...\n');

const { publicKey, privateKey } = generateKeypair();

// Create keys directory if it doesn't exist (gitignored)
const keysDir = path.join(__dirname, '..', 'keys');
if (!fs.existsSync(keysDir)) {
  fs.mkdirSync(keysDir, { recursive: true });
}

// Save to files
fs.writeFileSync(path.join(keysDir, 'license_private.pem'), privateKey);
fs.writeFileSync(path.join(keysDir, 'license_public.pem'), publicKey);

console.log('✅ Keys generated and saved to web/keys/\n');
console.log('━'.repeat(80));
console.log('PRIVATE KEY (add to Netlify env vars as LICENSE_PRIVATE_KEY):');
console.log('━'.repeat(80));
console.log(privateKey);
console.log('━'.repeat(80));
console.log('PUBLIC KEY (embed in desktop app Swift code):');
console.log('━'.repeat(80));
console.log(publicKey);
console.log('━'.repeat(80));
console.log('\n📝 Next steps:');
console.log('1. Add LICENSE_PRIVATE_KEY to Netlify environment variables');
console.log('2. Copy public key to desktop/Core/Licensing/LicenseKeys.swift');
console.log('3. Add web/keys/ to .gitignore (already done if following repo structure)\n');
console.log('⚠️  NEVER commit the private key to git!');
