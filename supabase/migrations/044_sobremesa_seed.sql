-- Migration 044: Sobremesa full lineup (Dunbarton Tobacco & Trust)
-- Adds missing vitolas for Sobremesa and Sobremesa Brûlée
-- Skips the existing Toro (Sobremesa) already in DB

INSERT INTO cigars (
  brand, series, vitola, common_format,
  manufacturer, country_origin,
  wrapper_leaf, wrapper_country,
  binder, filler,
  strength, ring_gauge, length_inches,
  flavor_notes, description
) VALUES

-- ============================================================
-- SOBREMESA (main line) — Nicaragua puro, medium-full
-- ============================================================
('Dunbarton Tobacco & Trust', 'Sobremesa', 'Frédéric', 'Petit Robusto',
 'Dunbarton Tobacco & Trust', 'Nicaragua',
 'Nicaragua', 'Nicaragua',
 'Nicaragua', 'Nicaragua',
 3, 48, 4.5,
 'cedar, dark fruit, espresso, leather',
 'Compact and concentrated Sobremesa. Nicaragua puro crafted by Steve Saka. Rich and complex with a creamy draw.'),

('Dunbarton Tobacco & Trust', 'Sobremesa', 'Brûlée', 'Robusto',
 'Dunbarton Tobacco & Trust', 'Nicaragua',
 'Nicaragua', 'Nicaragua',
 'Nicaragua', 'Nicaragua',
 3, 54, 5.0,
 'dark chocolate, espresso, cedar, black pepper',
 'The namesake vitola of the Sobremesa line. A wide-ring Robusto with exceptional balance and complexity.'),

('Dunbarton Tobacco & Trust', 'Sobremesa', 'Robusto', 'Robusto',
 'Dunbarton Tobacco & Trust', 'Nicaragua',
 'Nicaragua', 'Nicaragua',
 'Nicaragua', 'Nicaragua',
 3, 52, 5.0,
 'cedar, leather, espresso, dark cherry',
 'Classic Robusto format from the Sobremesa line. Full of Nicaraguan complexity with a smooth, satisfying finish.'),

('Dunbarton Tobacco & Trust', 'Sobremesa', 'Passionado', 'Toro',
 'Dunbarton Tobacco & Trust', 'Nicaragua',
 'Nicaragua', 'Nicaragua',
 'Nicaragua', 'Nicaragua',
 3, 50, 6.0,
 'cedar, dark fruit, espresso, cream',
 'A refined Toro with elegant balance. The Passionado showcases the full depth of Nicaraguan tobacco.'),

('Dunbarton Tobacco & Trust', 'Sobremesa', 'Cervantes', 'Lonsdale',
 'Dunbarton Tobacco & Trust', 'Nicaragua',
 'Nicaragua', 'Nicaragua',
 'Nicaragua', 'Nicaragua',
 3, 44, 6.5,
 'cedar, leather, nuts, espresso',
 'Elegant Lonsdale format. The longer length and narrow ring gauge bring out nuanced, refined flavors.'),

('Dunbarton Tobacco & Trust', 'Sobremesa', 'El Americano', 'Gigante',
 'Dunbarton Tobacco & Trust', 'Nicaragua',
 'Nicaragua', 'Nicaragua',
 'Nicaragua', 'Nicaragua',
 3, 58, 7.0,
 'dark chocolate, espresso, leather, cedar, black pepper',
 'A bold and commanding Gigante. Delivers a long, complex smoke with the full power of Nicaragua.'),

('Dunbarton Tobacco & Trust', 'Sobremesa', 'Lancero', 'Lancero',
 'Dunbarton Tobacco & Trust', 'Nicaragua',
 'Nicaragua', 'Nicaragua',
 'Nicaragua', 'Nicaragua',
 3, 38, 7.5,
 'cedar, leather, floral, espresso, white pepper',
 'A true Lancero for aficionados. Elegant and nuanced with remarkable draw consistency.'),

-- ============================================================
-- SOBREMESA BRÛLÉE — Connecticut Shade wrapper, medium
-- ============================================================
('Dunbarton Tobacco & Trust', 'Sobremesa Brûlée', 'Humito', 'Petit Corona',
 'Dunbarton Tobacco & Trust', 'Nicaragua',
 'Connecticut Shade', 'USA',
 'Nicaragua', 'Nicaragua',
 2, 46, 4.0,
 'cream, cedar, cashew, light pepper, honey',
 'A small but satisfying smoke. Connecticut Shade wrapper brings creaminess and sweetness to the Sobremesa blend.'),

('Dunbarton Tobacco & Trust', 'Sobremesa Brûlée', 'Robusto', 'Robusto',
 'Dunbarton Tobacco & Trust', 'Nicaragua',
 'Connecticut Shade', 'USA',
 'Nicaragua', 'Nicaragua',
 2, 54, 5.0,
 'cream, cedar, cashew, toasted nuts, light spice',
 'Classic Robusto in the Brûlée line. Creamy Connecticut Shade wrapper over Nicaraguan tobacco for an approachable, refined smoke.'),

('Dunbarton Tobacco & Trust', 'Sobremesa Brûlée', 'Toro', 'Toro',
 'Dunbarton Tobacco & Trust', 'Nicaragua',
 'Connecticut Shade', 'USA',
 'Nicaragua', 'Nicaragua',
 2, 52, 6.0,
 'cream, cedar, toasted nuts, honey, light pepper',
 'The Toro format in the Sobremesa Brûlée line. Smooth and elegant with the classic Connecticut Shade profile.'),

('Dunbarton Tobacco & Trust', 'Sobremesa Brûlée', 'Gordo', 'Gordo',
 'Dunbarton Tobacco & Trust', 'Nicaragua',
 'Connecticut Shade', 'USA',
 'Nicaragua', 'Nicaragua',
 2, 60, 6.0,
 'cream, cashew, cedar, light sweetness, toasted bread',
 'The largest format in the Brûlée line. Wide ring gauge delivers an exceptionally smooth, creamy experience.');

-- Verify
SELECT series, vitola, common_format, strength FROM cigars
WHERE manufacturer = 'Dunbarton Tobacco & Trust' AND series ILIKE '%Sobremesa%'
ORDER BY series, vitola;
