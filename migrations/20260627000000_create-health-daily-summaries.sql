CREATE TABLE IF NOT EXISTS health_daily_summaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  timezone TEXT NOT NULL CHECK (length(trim(timezone)) > 0),
  steps INTEGER NOT NULL DEFAULT 0 CHECK (steps >= 0),
  dietary_energy_kcal NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (dietary_energy_kcal >= 0),
  protein_g NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (protein_g >= 0),
  carbs_g NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (carbs_g >= 0),
  fat_g NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (fat_g >= 0),
  source TEXT NOT NULL DEFAULT 'apple_health_ios' CHECK (length(trim(source)) > 0),
  synced_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT health_daily_summaries_date_source_key UNIQUE (date, source)
);

CREATE INDEX IF NOT EXISTS health_daily_summaries_date_idx
  ON health_daily_summaries (date DESC);

DROP TRIGGER IF EXISTS health_daily_summaries_updated_at ON health_daily_summaries;
CREATE TRIGGER health_daily_summaries_updated_at
  BEFORE UPDATE ON health_daily_summaries
  FOR EACH ROW
  EXECUTE FUNCTION system.update_updated_at();
