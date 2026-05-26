-- Mac Cleaner Pro — License and Payment Database Schema
-- Run once against your Supabase project via:
--   supabase db push          (Supabase CLI, after setting project_id in config.toml)
--   OR paste into SQL Editor in the Supabase dashboard.

-- ──────────────────────────────────────────────
-- Tables
-- ──────────────────────────────────────────────

-- purchases: one row per completed payment; holds the generated license key.
CREATE TABLE IF NOT EXISTS purchases (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  email            TEXT        NOT NULL,
  plan             TEXT        NOT NULL CHECK (plan IN ('pro', 'family')),
  license_key      TEXT        NOT NULL UNIQUE,
  payment_provider TEXT        NOT NULL CHECK (payment_provider IN ('razorpay', 'stripe', 'paddle')),
  payment_id       TEXT        NOT NULL UNIQUE,
  amount           INTEGER     NOT NULL,          -- smallest currency unit (paise / cents)
  currency         TEXT        NOT NULL,
  status           TEXT        NOT NULL DEFAULT 'pending'
                               CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
  metadata         JSONB,                         -- order_id, notes, etc.
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- activations: one active row per (license_key, device_id) pair.
-- Soft-delete via deactivated_at so history is preserved.
CREATE TABLE IF NOT EXISTS activations (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  license_key    TEXT        NOT NULL REFERENCES purchases(license_key) ON DELETE CASCADE,
  device_id      TEXT        NOT NULL,
  device_name    TEXT        NOT NULL,
  activated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_seen_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deactivated_at TIMESTAMPTZ,                     -- NULL = active
  UNIQUE (license_key, device_id)
);

-- ──────────────────────────────────────────────
-- Indexes
-- ──────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_purchases_email       ON purchases (email);
CREATE INDEX IF NOT EXISTS idx_purchases_license_key ON purchases (license_key);
CREATE INDEX IF NOT EXISTS idx_purchases_payment_id  ON purchases (payment_id);
CREATE INDEX IF NOT EXISTS idx_purchases_status      ON purchases (status);

-- GIN index required for the JSONB containment query in getPurchaseByOrderId:
--   .contains('metadata', { order_id: orderId })  →  metadata @> '{"order_id":"..."}'
CREATE INDEX IF NOT EXISTS idx_purchases_metadata ON purchases USING GIN (metadata);

CREATE INDEX IF NOT EXISTS idx_activations_license_key ON activations (license_key);
CREATE INDEX IF NOT EXISTS idx_activations_device_id   ON activations (device_id);
-- Partial index speeds up the "active activations only" filter used everywhere
CREATE INDEX IF NOT EXISTS idx_activations_active
  ON activations (license_key, deactivated_at)
  WHERE deactivated_at IS NULL;

-- ──────────────────────────────────────────────
-- updated_at trigger (purchases only — activations use last_seen_at / deactivated_at)
-- ──────────────────────────────────────────────

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- DROP + CREATE keeps this idempotent across repeated runs
DROP TRIGGER IF EXISTS update_purchases_updated_at ON purchases;
CREATE TRIGGER update_purchases_updated_at
  BEFORE UPDATE ON purchases
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ──────────────────────────────────────────────
-- Row-Level Security
-- ──────────────────────────────────────────────

-- RLS is ON with no permissive policies → default-deny for all non-privileged roles.
-- All Netlify functions use the service-role key which bypasses RLS entirely.
-- Never expose the service-role key client-side.
ALTER TABLE purchases  ENABLE ROW LEVEL SECURITY;
ALTER TABLE activations ENABLE ROW LEVEL SECURITY;

GRANT ALL ON purchases  TO service_role;
GRANT ALL ON activations TO service_role;

-- ──────────────────────────────────────────────
-- Column comments
-- ──────────────────────────────────────────────

COMMENT ON TABLE  purchases                   IS 'Payment transactions and generated license keys';
COMMENT ON TABLE  activations                 IS 'Device activations per license (machine-limit enforcement)';
COMMENT ON COLUMN purchases.amount            IS 'Smallest currency unit: paise for INR, cents for USD';
COMMENT ON COLUMN purchases.metadata          IS 'Razorpay order_id, customer notes, etc.';
COMMENT ON COLUMN activations.device_id       IS 'IOPlatformUUID or Keychain-persisted fallback from desktop app';
COMMENT ON COLUMN activations.deactivated_at  IS 'NULL = active; set to NOW() on deactivation';
