-- ============================================================
-- 057_fermin_perez_seed.sql
--
-- Fermin Perez Premium Cigars — full debut-lineup
-- Produsent: FP Premium Cigars, Estelí, Nicaragua
-- Lansert: Mars 2025
--
-- Kilde: cuencacigars.com (bekreftet per vitola)
--
-- 6 serier / 10 vitolas:
--   1) Bold Maduro          — Toro, Toro Gordo
--   2) Classic Habano       — Toro, Toro Gordo
--   3) Classic Connecticut  — Toro, Toro Gordo
--   4) Esmeralda            — Robusto, Toro
--   5) Miami Special Edition — Toro
--   6) Royal Box Press      — Toro (box-pressed)
-- ============================================================

INSERT INTO cigars (
  manufacturer, brand, series, vitola, common_format,
  ring_gauge, length_inches, shape,
  body_type, head_type, foot_type, cross_section,
  wrapper_country, wrapper_leaf, binder, filler,
  country_origin, strength, price_range,
  description, flavor_notes, avg_rating
) VALUES

-- ================================================================
-- 1) BOLD MADURO
-- Wrapper: San Andrés (Mexico), Binder: Indonesia,
-- Filler: Jalapa / Estelí / Pueblo Nuevo, Nicaragua
-- Styrke: Medium-Full
-- ================================================================

('FP Premium Cigars', 'Fermin Perez', 'Bold Maduro', 'Toro', 'Toro',
 54, 6.0, 'Parejo',
 'colorado maduro', 'rounded', 'open', 'Round',
 'Mexico', 'San Andrés Maduro', 'Indonesia', ARRAY['Jalapa, Nicaragua', 'Estelí, Nicaragua', 'Pueblo Nuevo, Nicaragua'],
 'Nicaragua', 4, '$',
 'Fermin Perez Bold Maduro Toro er kjernen i boutique-merkets kraftigste linje. San Andrés maduro-dekkbladet fra Mexico gir mørkfruktlig sødme og fyldig dybde, mens nikotinsterk Jalapa/Estelí-kjerne bygger kompleksitet gjennom hele røyken.',
 ARRAY['dark chocolate', 'espresso', 'leather', 'earth', 'black pepper', 'dried fruit'], 8.5),

('FP Premium Cigars', 'Fermin Perez', 'Bold Maduro', 'Toro Gordo', 'Gordo',
 60, 6.0, 'Parejo',
 'colorado maduro', 'rounded', 'open', 'Round',
 'Mexico', 'San Andrés Maduro', 'Indonesia', ARRAY['Jalapa, Nicaragua', 'Estelí, Nicaragua', 'Pueblo Nuevo, Nicaragua'],
 'Nicaragua', 4, '$$',
 'Fermin Perez Bold Maduro Toro Gordo gir samme mørke San Andrés-profil som Toro-en, men i 60-ring-format som åpner opp røyken og gir lengre, langsommere utvikling av espresso og mørk frukt.',
 ARRAY['dark chocolate', 'espresso', 'leather', 'earth', 'black pepper', 'dried fruit'], 8.5),

-- ================================================================
-- 2) CLASSIC HABANO
-- Wrapper: Habano, Binder: Indonesia,
-- Filler: Jalapa / Estelí / Pueblo Nuevo, Nicaragua
-- Styrke: Medium
-- ================================================================

('FP Premium Cigars', 'Fermin Perez', 'Classic Habano', 'Toro', 'Toro',
 54, 6.0, 'Parejo',
 'colorado', 'rounded', 'open', 'Round',
 'Nicaragua', 'Habano', 'Indonesia', ARRAY['Jalapa, Nicaragua', 'Estelí, Nicaragua', 'Pueblo Nuevo, Nicaragua'],
 'Nicaragua', 3, '$',
 'Fermin Perez Classic Habano Toro er hjørnesteinen i sortimentet — en klassisk nicaraguansk Habano-sigaret som starter kontrollert og dypner jevnt gjennom røyken. Balansert krydderprofil, medium styrke.',
 ARRAY['cedar', 'earth', 'leather', 'spice', 'nuts', 'cocoa'], 8.3),

('FP Premium Cigars', 'Fermin Perez', 'Classic Habano', 'Toro Gordo', 'Gordo',
 60, 6.0, 'Parejo',
 'colorado', 'rounded', 'open', 'Round',
 'Nicaragua', 'Habano', 'Indonesia', ARRAY['Jalapa, Nicaragua', 'Estelí, Nicaragua', 'Pueblo Nuevo, Nicaragua'],
 'Nicaragua', 3, '$$',
 'Fermin Perez Classic Habano Toro Gordo er den store utgaven av Classic Habano-blenden — 60-ring-formatet gir saktere nikotinutvikling og mer luftig røyk, ideelt for lange røykeøkter.',
 ARRAY['cedar', 'earth', 'leather', 'spice', 'nuts', 'cocoa'], 8.3),

-- ================================================================
-- 3) CLASSIC CONNECTICUT
-- Wrapper: Connecticut (USA), Binder: Indonesia,
-- Filler: Jalapa / Estelí / Pueblo Nuevo, Nicaragua
-- Styrke: Medium til Full
-- ================================================================

('FP Premium Cigars', 'Fermin Perez', 'Classic Connecticut', 'Toro', 'Toro',
 54, 6.0, 'Parejo',
 'claro', 'rounded', 'open', 'Round',
 'USA', 'Connecticut', 'Indonesia', ARRAY['Jalapa, Nicaragua', 'Estelí, Nicaragua', 'Pueblo Nuevo, Nicaragua'],
 'Nicaragua', 3, '$',
 'Fermin Perez Classic Connecticut Toro overrasker med mer fylde enn man forventer av Connecticut-dekkbladet. Glatt og kremet profil med god overgangsdybde — et utmerket valg for morgen- og middagstid.',
 ARRAY['cream', 'cedar', 'toasted nuts', 'mild spice', 'hay', 'vanilla'], 8.2),

('FP Premium Cigars', 'Fermin Perez', 'Classic Connecticut', 'Toro Gordo', 'Gordo',
 60, 6.0, 'Parejo',
 'claro', 'rounded', 'open', 'Round',
 'USA', 'Connecticut', 'Indonesia', ARRAY['Jalapa, Nicaragua', 'Estelí, Nicaragua', 'Pueblo Nuevo, Nicaragua'],
 'Nicaragua', 3, '$$',
 'Fermin Perez Classic Connecticut Toro Gordo er den store, brede utgaven av Connecticut-blenden — det silkemyke dekkbladet holder seg kremet og tilgjengelig selv i 60-ring-format.',
 ARRAY['cream', 'cedar', 'toasted nuts', 'mild spice', 'hay', 'vanilla'], 8.2),

-- ================================================================
-- 4) ESMERALDA
-- Wrapper: Connecticut (USA), Binder: Jalapa (Nicaragua),
-- Filler: Condega / Dominican Republic / Estelí
-- Styrke: Medium
-- ================================================================

('FP Premium Cigars', 'Fermin Perez', 'Esmeralda', 'Robusto', 'Robusto',
 50, 5.875, 'Parejo',
 'claro', 'rounded', 'open', 'Round',
 'USA', 'Connecticut', 'Jalapa, Nicaragua', ARRAY['Condega, Nicaragua', 'Dominican Republic', 'Estelí, Nicaragua'],
 'Nicaragua', 3, '$',
 'Fermin Perez Esmeralda Robusto er den korteste og mest kompakte størrelsen i Esmeralda-linjen. Connecticut-dekkbladet kombinert med Jalapa-bindeblad og trefils-kjerne gir en lagdelt, nyansert røyk med flotte overganger.',
 ARRAY['cream', 'floral', 'cedar', 'toasted nuts', 'mild pepper', 'honey'], 8.6),

('FP Premium Cigars', 'Fermin Perez', 'Esmeralda', 'Toro', 'Toro',
 56, 6.5, 'Parejo',
 'claro', 'rounded', 'open', 'Round',
 'USA', 'Connecticut', 'Jalapa, Nicaragua', ARRAY['Condega, Nicaragua', 'Dominican Republic', 'Estelí, Nicaragua'],
 'Nicaragua', 3, '$$',
 'Fermin Perez Esmeralda Toro er flaggskipstørrelsen i Esmeralda-linjen — den litt bredere 56-ringen kombinert med den lange røyken gir tid til komplekse aromatiske overganger fra blomsterlige til nøttete toner.',
 ARRAY['cream', 'floral', 'cedar', 'toasted nuts', 'mild pepper', 'honey'], 8.7),

-- ================================================================
-- 5) MIAMI SPECIAL EDITION
-- Wrapper: Habano, Binder: Indonesia,
-- Filler: Jalapa / Ometepe / Condega, Nicaragua
-- Styrke: Mild til Medium
-- ================================================================

('FP Premium Cigars', 'Fermin Perez', 'Miami Special Edition', 'Toro', 'Toro',
 56, 6.5, 'Parejo',
 'colorado', 'rounded', 'open', 'Round',
 'Nicaragua', 'Habano', 'Indonesia', ARRAY['Jalapa, Nicaragua', 'Ometepe, Nicaragua', 'Condega, Nicaragua'],
 'Nicaragua', 2, '$$',
 'Fermin Perez Miami Special Edition Toro er en limitert utgave med Habano-dekkblad og særegne overganger mellom ristede cashew-toner og blomsterlige hint. Milder styrke gjør den tilgjengelig for de fleste røykere.',
 ARRAY['roasted cashews', 'floral', 'cream', 'cedar', 'mild spice', 'caramel'], 8.4),

-- ================================================================
-- 6) ROYAL BOX PRESS
-- Wrapper: Habano (Ecuador), Binder: Habano,
-- Filler: Jalapa / Estelí / Pueblo Nuevo, Nicaragua
-- Styrke: Medium — Box-Pressed
-- ================================================================

('FP Premium Cigars', 'Fermin Perez', 'Royal Box Press', 'Toro', 'Toro',
 52, 6.0, 'Parejo',
 'colorado', 'rounded', 'open', 'Box Pressed',
 'Ecuador', 'Habano', 'Habano', ARRAY['Jalapa, Nicaragua', 'Estelí, Nicaragua', 'Pueblo Nuevo, Nicaragua'],
 'Nicaragua', 3, '$$',
 'Fermin Perez Royal Box Press Toro er boutique-merkets mest elegante sigaret — den box-pressed formen gir en karakteristisk firkantprofil og jevnere trekk. Habano wrapper og binder gir klassisk krydder-og-seder-kompleksitet i medium styrke.',
 ARRAY['cedar', 'earth', 'leather', 'spice', 'cocoa', 'toasted nuts'], 8.5);

-- ================================================================
-- Alias for søk
-- ================================================================

INSERT INTO cigar_aliases (alias, manufacturer, brand, series)
VALUES
  ('Fermin Perez',          'FP Premium Cigars', 'Fermin Perez', NULL),
  ('Fermin Pérez',          'FP Premium Cigars', 'Fermin Perez', NULL),
  ('FP Premium Cigars',     'FP Premium Cigars', 'Fermin Perez', NULL),
  ('Bold Maduro',           'FP Premium Cigars', 'Fermin Perez', 'Bold Maduro'),
  ('Classic Habano',        'FP Premium Cigars', 'Fermin Perez', 'Classic Habano'),
  ('Classic Connecticut',   'FP Premium Cigars', 'Fermin Perez', 'Classic Connecticut'),
  ('Esmeralda',             'FP Premium Cigars', 'Fermin Perez', 'Esmeralda'),
  ('Emeralda',              'FP Premium Cigars', 'Fermin Perez', 'Esmeralda'),
  ('Miami Special Edition', 'FP Premium Cigars', 'Fermin Perez', 'Miami Special Edition'),
  ('Miami Habano',          'FP Premium Cigars', 'Fermin Perez', 'Miami Special Edition'),
  ('Royal Box Press',       'FP Premium Cigars', 'Fermin Perez', 'Royal Box Press');
