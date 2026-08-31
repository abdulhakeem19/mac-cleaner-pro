# Rule-Pack Signing — Operator Guide

This document is the source of truth for how `mac-cleaner-pro` rule packs are
generated, signed, distributed, and verified. If anything here is unclear,
fix the doc — don't improvise.

## Why we sign rule packs

Rule packs tell the app *which files to delete*. If an attacker swaps a pack
for a malicious one, they can wipe user data. Signing makes that infeasible
even if the entire distribution channel (GitHub Releases) is compromised,
because the private key never lives in that channel — it lives in 1Password
and (only as a secret) in GitHub Actions.

We use **Ed25519** because it's fast, has small (32-byte public, 64-byte
signature) artifacts, and CryptoKit supports it natively.

## Trust roots

| Artifact | Where it lives | Sensitivity |
|---|---|---|
| Private key (PEM) | 1Password vault `mac-cleaner-pro` + GitHub secret `RULEPACK_PRIVATE_KEY` (rules repo only) | Never commit. Never log. Never email. |
| Public key (PEM)  | `keys/rulepack_public.pem` (committed) | Public. |
| Public key (b64)  | Hard-coded in `RulePackVerifier.trustedPublicKeyB64` | Public, but treat changes as a security event. |

Rotating the public key requires shipping a new app version. So **don't rotate casually** — only on confirmed compromise.

## One-time setup

Run on a clean, trusted machine (not in CI, not on a shared dev box):

```bash
./tools/keygen.sh
```

This creates `keys/rulepack_private.pem`, `keys/rulepack_public.pem`, and
`keys/rulepack_public.b64`. Then:

1. Copy `rulepack_private.pem` contents into 1Password.
2. Add the same contents as a GitHub Actions secret named `RULEPACK_PRIVATE_KEY`
   in the `mac-cleaner-pro-rules` repo — **not** the app repo.
3. Paste the base64 string from `rulepack_public.b64` into
   `Core/RulesEngine/RulePackVerifier.swift` (the `trustedPublicKeyB64` constant).
4. Securely delete the local private key:
   ```bash
   rm -P keys/rulepack_private.pem
   ```
5. Commit `keys/rulepack_public.pem` and `keys/rulepack_public.b64`.

## Releasing a new rule pack

Edit `RulePacks/v1.json`, bump `packVersion`, then:

```bash
git commit -am "rules: bump to 1.2.3"
git tag rules-v1.2.3
git push origin main rules-v1.2.3
```

The GitHub Actions workflow signs the pack and publishes a Release with two
assets: `v1.json` and `v1.json.sig`. The app fetches both at startup.

## Local signing (for testing without pushing)

```bash
./tools/sign-rules.sh RulePacks/v1.json
./tools/verify-rules.sh RulePacks/v1.json
```

Both must succeed before you tag.

## How the app verifies

`RulePackVerifier.verify(packData:signatureB64:currentAppVersion:)`:

1. Loads the pinned 32-byte public key.
2. Decodes the base64 signature → exactly 64 bytes.
3. Calls CryptoKit's `Curve25519.Signing.PublicKey.isValidSignature(_:for:)`
   on the **raw fetched bytes** — not a re-encoded copy.
4. Decodes JSON, checks `schemaVersion`, gates `minAppVersion`.

If any step fails, the app falls back to the rule pack bundled at build time.
It never executes an unverified pack.

## Schema versioning

`schemaVersion` increments only when the pack format changes in a
backwards-incompatible way. Old apps refuse newer schemas; bundling a fallback
pack with the app means users always have *something* to clean with.

Add fields as optional first; promote to required only in a new schema version.

## Incident response

If the private key is exposed:

1. Generate a new keypair (`tools/keygen.sh` after deleting old keys).
2. Ship a hot-fix app build with the new `trustedPublicKeyB64`.
3. Rotate the GitHub Actions secret.
4. Re-sign and re-publish the latest pack with the new key.
5. Post-mortem in `docs/incidents/`.

Old app versions will be unable to verify new packs and will run on bundled
rules until users update. That's the safe-fail mode and is preferred over
extending trust to a new key in the field.
