#!/usr/bin/env node
/**
 * Generate a development license key for testing
 * Usage: node scripts/generate-dev-license.js
 */

import { generateLicenseKey } from '../lib/license.ts';

const privateKey = `-----BEGIN PRIVATE KEY-----
MC4CAQAwBQYDK2VwBCIEIOeP9Ne7clcCwtT51DfqvNiwm4ieOyjpgvbagtoIgvVC
-----END PRIVATE KEY-----`;

async function main() {
  // Pro license for development
  const proLicense = await generateLicenseKey(
    {
      email: 'dev@maccleanerpro.com',
      plan: 'pro',
      purchaseDate: new Date().toISOString(),
      machineLimit: 1,
    },
    privateKey
  );

  // Family license for development
  const familyLicense = await generateLicenseKey(
    {
      email: 'dev@maccleanerpro.com',
      plan: 'family',
      purchaseDate: new Date().toISOString(),
      machineLimit: 5,
    },
    privateKey
  );

  console.log('\n📦 Development License Keys\n');
  console.log('Pro License (1 Mac):');
  console.log(proLicense);
  console.log('\nFamily License (5 Macs):');
  console.log(familyLicense);
  console.log('\nℹ️  Use these keys for testing the desktop app.\n');
}

main().catch(console.error);
