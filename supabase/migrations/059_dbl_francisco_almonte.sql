-- Migration 059: DBL (Dominican Big Leaguer) – Francisco Almonte Amarillo
-- Grunnlagt av Francisco Almonte. Connecticut Shade-dekkblad, dominikansk opphav.

INSERT INTO cigars (
  brand, manufacturer, series, vitola, common_format,
  ring_gauge, length_inches,
  body_type, head_type, foot_type,
  wrapper_country, wrapper_leaf, binder_country, filler_countries,
  country_of_origin,
  strength, body, sweetness, flavor_intensity,
  flavor_notes, description
) VALUES

-- Robusto 5" × 52
('DBL', 'Dominican Big Leaguer', 'Francisco Almonte Amarillo', 'Robusto', 'Robusto',
 52, 5.0,
 'Parejo', 'Regular', 'Open',
 'USA', 'Connecticut', 'Dominican Republic', ARRAY['Dominican Republic'],
 'Dominican Republic',
 1.5, 2.0, 2.5, 2.0,
 ARRAY['sweet cream', 'cinnamon', 'butter', 'maple', 'light wood'],
 'DBL Francisco Almonte Amarillo Robusto — 5"×52. Rum fat-lagret Connecticut Shade-dekkblad over dominikansk filler fra Francisco Almontes gård i Santiago. Mild styrke med rik smaksprofil: søt smør, kanel og hint av lønnesirup.'),

-- Toro 6" × 56
('DBL', 'Dominican Big Leaguer', 'Francisco Almonte Amarillo', 'Toro', 'Toro',
 56, 6.0,
 'Parejo', 'Regular', 'Open',
 'USA', 'Connecticut', 'Dominican Republic', ARRAY['Dominican Republic'],
 'Dominican Republic',
 1.5, 2.0, 2.5, 2.0,
 ARRAY['sweet cream', 'cinnamon', 'butter', 'maple', 'light wood'],
 'DBL Francisco Almonte Amarillo Toro — 6"×56. Rum fat-lagret Connecticut Shade-dekkblad over dominikansk filler. Bred ringmål gir kremet trekk og lang ettersmak av kanel og smør.'),

-- Churchill 6.8" × 50
('DBL', 'Dominican Big Leaguer', 'Francisco Almonte Amarillo', 'Churchill', 'Churchill',
 50, 6.8,
 'Parejo', 'Regular', 'Open',
 'USA', 'Connecticut', 'Dominican Republic', ARRAY['Dominican Republic'],
 'Dominican Republic',
 1.5, 2.0, 2.5, 2.0,
 ARRAY['sweet cream', 'cinnamon', 'butter', 'maple', 'light wood'],
 'DBL Francisco Almonte Amarillo Churchill — 6.8"×50. Lengre format gir mer kompleksitet og en gradvis utvikling fra søt krem til subtile krydder mot foten.'),

-- Belicoso (Fancy Belicoso) 5.6" × 54
('DBL', 'Dominican Big Leaguer', 'Francisco Almonte Amarillo', 'Belicoso', 'Belicoso',
 54, 5.6,
 'Parejo', 'Belicoso', 'Open',
 'USA', 'Connecticut', 'Dominican Republic', ARRAY['Dominican Republic'],
 'Dominican Republic',
 1.5, 2.0, 2.5, 2.0,
 ARRAY['sweet cream', 'cinnamon', 'butter', 'maple', 'light wood'],
 'DBL Francisco Almonte Amarillo Belicoso — 5.6"×54. Fancy Belicoso-hode konsentrerer smakene i de første dragene. Kremet og søt med hint av lønnesirup og lett sjokolade.');
