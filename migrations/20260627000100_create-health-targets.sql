CREATE TABLE IF NOT EXISTS health_targets (
  metric TEXT PRIMARY KEY CHECK (metric IN ('steps', 'calories')),
  label TEXT NOT NULL CHECK (length(trim(label)) > 0),
  target_value NUMERIC(10, 2) NOT NULL CHECK (target_value > 0),
  unit TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS health_targets_updated_at ON health_targets;
CREATE TRIGGER health_targets_updated_at
  BEFORE UPDATE ON health_targets
  FOR EACH ROW
  EXECUTE FUNCTION system.update_updated_at();

INSERT INTO health_targets (metric, label, target_value, unit)
VALUES
  ('steps', 'STEPS', 10000, 'steps'),
  ('calories', 'CALORIES', 2000, 'kcal')
ON CONFLICT (metric) DO UPDATE
SET label = EXCLUDED.label,
    target_value = EXCLUDED.target_value,
    unit = EXCLUDED.unit;
