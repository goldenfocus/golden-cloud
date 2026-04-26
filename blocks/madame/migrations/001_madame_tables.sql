-- MADAME — portable schema.
-- Apply via supabase migrations OR psql. RLS policies are app-specific
-- (each consumer applies its own — see p69's RLS migration).

CREATE TABLE IF NOT EXISTS madame_posting_events (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     uuid NOT NULL,                  -- business_id (p69), org_id (Zemium), etc.
  platform      text NOT NULL,                  -- e.g. 'escorteintime.com'
  listing_id    text,                           -- nullable for single-listing platforms
  event_type    text NOT NULL CHECK (event_type IN (
                  'toggle_on',
                  'toggle_bump',
                  'toggle_skip',
                  'session_refresh',
                  'error',
                  'lock_contention'
                )),
  payload       jsonb,
  online_until  timestamptz,
  triggered_by  text NOT NULL DEFAULT 'cron',
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS madame_platform_config (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       uuid NOT NULL,
  platform        text NOT NULL,
  listing_id      text,                         -- nullable for single-listing platforms
  is_active       boolean NOT NULL DEFAULT true,
  credentials_enc text,                         -- AES-256-GCM: base64(iv):base64(ciphertext+tag)
  interval_min    int NOT NULL DEFAULT 15,
  interval_max    int NOT NULL DEFAULT 30,
  last_event_at   timestamptz,
  last_error      text,
  next_run_at     timestamptz,                  -- persisted schedule (so cron crash doesn't lose it)
  run_lock_until  timestamptz,                  -- atomic lock for race-condition guard
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

-- listing_id is part of identity, but NULL ≠ NULL in Postgres uniqueness.
-- Use a partial unique index pair to cover both shapes.
CREATE UNIQUE INDEX IF NOT EXISTS madame_config_unique_with_listing
  ON madame_platform_config(tenant_id, platform, listing_id)
  WHERE listing_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS madame_config_unique_no_listing
  ON madame_platform_config(tenant_id, platform)
  WHERE listing_id IS NULL;

CREATE INDEX IF NOT EXISTS idx_madame_events_tenant_platform
  ON madame_posting_events(tenant_id, platform, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_madame_events_created
  ON madame_posting_events(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_madame_config_tenant
  ON madame_platform_config(tenant_id, platform);

CREATE INDEX IF NOT EXISTS idx_madame_config_next_run
  ON madame_platform_config(next_run_at)
  WHERE is_active = true;

-- Atomic lock acquisition. Returns true iff this caller now holds the lock.
-- Caller sets run_lock_until = NULL when finished (or on error).
CREATE OR REPLACE FUNCTION madame_acquire_lock(
  p_tenant_id    uuid,
  p_platform     text,
  p_listing_id   text,
  p_lock_until   timestamptz
) RETURNS boolean AS $$
DECLARE
  rows_updated int;
BEGIN
  UPDATE madame_platform_config
     SET run_lock_until = p_lock_until,
         updated_at     = now()
   WHERE tenant_id = p_tenant_id
     AND platform  = p_platform
     AND (
       (listing_id = p_listing_id)
       OR (listing_id IS NULL AND p_listing_id IS NULL)
     )
     AND (run_lock_until IS NULL OR run_lock_until < now());

  GET DIAGNOSTICS rows_updated = ROW_COUNT;
  RETURN rows_updated = 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- updated_at touch trigger
CREATE OR REPLACE FUNCTION madame_touch_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_madame_config_updated_at ON madame_platform_config;
CREATE TRIGGER trg_madame_config_updated_at
  BEFORE UPDATE ON madame_platform_config
  FOR EACH ROW EXECUTE FUNCTION madame_touch_updated_at();
