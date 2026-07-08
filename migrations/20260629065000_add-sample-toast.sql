DELETE FROM recipe_ingredients
WHERE recipe_id = (
  SELECT id FROM recipes WHERE title = 'Sample Toast'
);

WITH recipe AS (
  INSERT INTO recipes (
    title,
    photo_url,
    photo_key,
    total_calories,
    carbs_g,
    fat_g,
    protein_g,
    instructions
  )
  VALUES (
    'Sample Toast',
    NULL,
    NULL,
    420,
    46,
    14,
    28,
    'Toast bread with a protein filling, cheese, vegetables, and a savory spread until warmed through.'
  )
  ON CONFLICT (title) DO UPDATE
  SET photo_url = EXCLUDED.photo_url,
      photo_key = EXCLUDED.photo_key,
      total_calories = EXCLUDED.total_calories,
      carbs_g = EXCLUDED.carbs_g,
      fat_g = EXCLUDED.fat_g,
      protein_g = EXCLUDED.protein_g,
      instructions = EXCLUDED.instructions
  RETURNING id
)
INSERT INTO recipe_ingredients (recipe_id, name, amount, calories, sort_order)
SELECT recipe.id, ingredient.name, ingredient.amount, ingredient.calories, ingredient.sort_order
FROM recipe
CROSS JOIN (
  VALUES
    ('Bread', '2 slices', 160, 1),
    ('Protein filling', '100 g', 150, 2),
    ('Cheese', '20 g', 80, 3),
    ('Vegetables', '50 g', 15, 4),
    ('Savory spread', '1 tbsp', 15, 5)
) AS ingredient(name, amount, calories, sort_order);
