DELETE FROM recipe_ingredients
WHERE recipe_id = (
  SELECT id FROM recipes WHERE title = 'Sample Smoothie'
);

WITH recipe AS (
  INSERT INTO recipes (
    id,
    title,
    photo_url,
    photo_key,
    total_calories,
    carbs_g,
    fat_g,
    protein_g,
    rating,
    instructions
  )
  VALUES (
    '3202ae4d-131a-4ef1-8bee-887cff72ac5a',
    'Sample Smoothie',
    NULL,
    NULL,
    180,
    28,
    4,
    6,
    0,
    'Blend milk, fruit, flavoring, and a crunchy add-in into a cold smoothie.'
  )
  ON CONFLICT (title) DO UPDATE
  SET photo_url = EXCLUDED.photo_url,
      photo_key = EXCLUDED.photo_key,
      total_calories = EXCLUDED.total_calories,
      carbs_g = EXCLUDED.carbs_g,
      fat_g = EXCLUDED.fat_g,
      protein_g = EXCLUDED.protein_g,
      rating = EXCLUDED.rating,
      instructions = EXCLUDED.instructions
  RETURNING id
)
INSERT INTO recipe_ingredients (recipe_id, name, amount, calories, sort_order)
SELECT recipe.id, ingredient.name, ingredient.amount, ingredient.calories, ingredient.sort_order
FROM recipe
CROSS JOIN (
  VALUES
    ('Milk', '200 ml', 90, 1),
    ('Fruit', '0.5 cup', 55, 2),
    ('Flavoring', '1 tsp', 10, 3),
    ('Crunchy add-in', '10 g', 25, 4)
) AS ingredient(name, amount, calories, sort_order);
