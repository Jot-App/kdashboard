UPDATE recipes
SET rating = LEAST(rating, 5)
WHERE rating > 5;

ALTER TABLE recipes
  DROP CONSTRAINT IF EXISTS recipes_rating_check;

ALTER TABLE recipes
  ALTER COLUMN rating TYPE NUMERIC(2, 1);

ALTER TABLE recipes
  ADD CONSTRAINT recipes_rating_check CHECK (rating >= 0 AND rating <= 5);
