CREATE TABLE IF NOT EXISTS challenge_daily_logs (
  date DATE PRIMARY KEY,
  water_l NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (water_l >= 0),
  sleep_hours NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (sleep_hours >= 0),
  workouts INTEGER NOT NULL DEFAULT 0 CHECK (workouts >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS challenge_daily_logs_updated_at ON challenge_daily_logs;
CREATE TRIGGER challenge_daily_logs_updated_at
  BEFORE UPDATE ON challenge_daily_logs
  FOR EACH ROW
  EXECUTE FUNCTION system.update_updated_at();
