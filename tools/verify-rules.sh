#!/usr/bin/env bash
# verify-rules.sh — verify a rule-pack signature with the public key.
#
# Usage:  ./tools/verify-rules.sh RulePacks/v1.json [RulePacks/v1.json.sig]
#
# Used in CI smoke tests and as a sanity check after signing. The Swift app does
# the real verification at runtime; this script mirrors that logic.

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <rules.json> [rules.json.sig]" >&2
  exit 2
fi

INPUT="$1"
SIG="${2:-${INPUT}.sig}"
PUB="$(cd "$(dirname "$0")/.." && pwd)/keys/rulepack_public.pem"

[[ -f "$INPUT" ]] || { echo "ERROR: $INPUT not found" >&2; exit 1; }
[[ -f "$SIG"   ]] || { echo "ERROR: $SIG not found"   >&2; exit 1; }
[[ -f "$PUB"   ]] || { echo "ERROR: public key missing at $PUB" >&2; exit 1; }

RAW_SIG="$(mktemp)"
trap 'rm -f "$RAW_SIG"' EXIT
base64 -d -i "$SIG" > "$RAW_SIG"

if openssl pkeyutl -verify -pubin -inkey "$PUB" -rawin -in "$INPUT" -sigfile "$RAW_SIG" >/dev/null; then
  echo "OK: signature valid for $INPUT"
else
  echo "FAIL: signature verification FAILED for $INPUT" >&2
  exit 1
fi
