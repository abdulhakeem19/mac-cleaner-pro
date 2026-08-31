#!/usr/bin/env bash
# sign-rules.sh — sign a rule pack with the Ed25519 private key.
#
# Usage:  ./tools/sign-rules.sh RulePacks/v1.json
# Output: RulePacks/v1.json.sig  (raw 64-byte Ed25519 signature, base64-encoded)
#
# In CI: $RULEPACK_PRIVATE_KEY env var holds the PEM contents.
# Locally: reads from keys/rulepack_private.pem (which should NOT be committed).

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <path-to-rules.json>" >&2
  exit 2
fi

INPUT="$1"
[[ -f "$INPUT" ]] || { echo "ERROR: $INPUT not found" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIG_OUT="${INPUT}.sig"

# Load private key from env (CI) or local file (dev).
if [[ -n "${RULEPACK_PRIVATE_KEY:-}" ]]; then
  PRIV_FILE="$(mktemp)"
  trap 'rm -f "$PRIV_FILE"' EXIT
  printf '%s' "$RULEPACK_PRIVATE_KEY" > "$PRIV_FILE"
else
  PRIV_FILE="$REPO_ROOT/keys/rulepack_private.pem"
  if [[ ! -f "$PRIV_FILE" ]]; then
    echo "ERROR: no private key found." >&2
    echo "       Set RULEPACK_PRIVATE_KEY env var, or place the key at $PRIV_FILE" >&2
    exit 1
  fi
fi

# Sanity: pack must be valid JSON.
python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$INPUT" \
  || { echo "ERROR: $INPUT is not valid JSON" >&2; exit 1; }

# Ed25519 signs the message in one shot — no pre-hash needed (it uses SHA-512 internally).
RAW_SIG="$(mktemp)"
trap 'rm -f "$RAW_SIG" "${PRIV_FILE:-}"' EXIT
openssl pkeyutl -sign -inkey "$PRIV_FILE" -rawin -in "$INPUT" -out "$RAW_SIG"

# Encode as base64 (single line, no wrap).
base64 -i "$RAW_SIG" | tr -d '\n' > "$SIG_OUT"
echo "" >> "$SIG_OUT"

echo "Signed: $INPUT"
echo "Sig:    $SIG_OUT"
echo "Size:   $(wc -c < "$RAW_SIG") raw bytes / $(wc -c < "$SIG_OUT") b64 bytes"
