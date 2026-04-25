#!/usr/bin/env bash
# keygen.sh — generate the Ed25519 keypair used to sign mac-cleaner-pro rule packs.
#
# Run this ONCE on a secure machine. The private key never leaves that machine
# (or 1Password). The public key is committed to the app repo and embedded in
# the binary so the app can verify rule packs offline.
#
# Output:
#   keys/rulepack_private.pem   <- KEEP SECRET, copy to 1Password, then shred locally
#   keys/rulepack_public.pem    <- safe to commit
#   keys/rulepack_public.b64    <- single-line base64 raw 32-byte key, paste into Swift

set -euo pipefail

KEYDIR="$(cd "$(dirname "$0")/.." && pwd)/keys"
mkdir -p "$KEYDIR"

PRIV="$KEYDIR/rulepack_private.pem"
PUB="$KEYDIR/rulepack_public.pem"
PUB_B64="$KEYDIR/rulepack_public.b64"

if [[ -e "$PRIV" || -e "$PUB" ]]; then
  echo "ERROR: key files already exist in $KEYDIR" >&2
  echo "       Refusing to overwrite. Move or delete them first if you really mean to rotate." >&2
  exit 1
fi

echo "Generating Ed25519 keypair..."
openssl genpkey -algorithm ed25519 -out "$PRIV"
openssl pkey -in "$PRIV" -pubout -out "$PUB"

# Extract the raw 32-byte public key (last 32 bytes of the DER) and base64 it.
# The PEM has a fixed 12-byte SPKI prefix for Ed25519, so we strip it.
openssl pkey -in "$PRIV" -pubout -outform DER \
  | tail -c 32 \
  | base64 \
  | tr -d '\n' > "$PUB_B64"
echo "" >> "$PUB_B64"

chmod 600 "$PRIV"
chmod 644 "$PUB" "$PUB_B64"

cat <<EOF

Done.

  Private key: $PRIV   (chmod 600)
  Public PEM:  $PUB
  Public b64:  $(cat "$PUB_B64")

NEXT STEPS — do these in order:
  1. Copy the contents of $PRIV into 1Password (item: "mac-cleaner-pro rule-pack signing key").
  2. Add the same content as a GitHub Actions secret named RULEPACK_PRIVATE_KEY in
     the mac-cleaner-pro-rules repo.
  3. Paste the base64 string above into App/Core/RulesEngine/RulePackVerifier.swift
     (constant: trustedPublicKeyB64).
  4. Securely delete the local private key:
        rm -P "$PRIV"
     The PUBLIC key files are safe to commit.

EOF
