DELETE FROM recipe_ingredients
WHERE recipe_id = (
  SELECT id FROM recipes WHERE title = 'Sample Protein Snack'
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
    '7bad2478-b0cc-4df9-a497-79fea6eeb449',
    'Sample Protein Snack',
    NULL,
    NULL,
    430,
    52,
    14,
    26,
    0,
    'Mix a high-protein batter with oil and seasoning, then steam or bake until set.'
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
    ('Protein flour', '80 g', 300, 1),
    ('Yogurt', '60 g', 60, 2),
    ('Oil', '0.5 tbsp', 70, 3)
) AS ingredient(name, amount, calories, sort_order);
