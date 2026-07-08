CREATE TABLE IF NOT EXISTS meal_plan_entries (
  date DATE NOT NULL,
  recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  sort_order INTEGER NOT NULL CHECK (sort_order > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (date, sort_order),
  CONSTRAINT meal_plan_entries_date_recipe_key UNIQUE (date, recipe_id)
);

CREATE INDEX IF NOT EXISTS meal_plan_entries_date_sort_idx
  ON meal_plan_entries (date, sort_order);

DROP TRIGGER IF EXISTS meal_plan_entries_updated_at ON meal_plan_entries;
CREATE TRIGGER meal_plan_entries_updated_at
  BEFORE UPDATE ON meal_plan_entries
  FOR EACH ROW
  EXECUTE FUNCTION system.update_updated_at();
