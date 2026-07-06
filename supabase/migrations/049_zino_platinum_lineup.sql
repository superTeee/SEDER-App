-- Migration 049: Zino Platinum — full lineup
-- Eksisterende (beholdes): Crown/Toro, Exclusive/Belicoso, Scepter/Robusto
-- Ny data verifisert mot BestCigarPrices.com juli 2026

-- ──────────────────────────────────────────────────────────
-- CROWN SERIES (Ecuador Connecticut wrapper, medium-full)
-- Distinctive Gordo/Perfecto shapes; comes in metal cans/tubos
-- ──────────────────────────────────────────────────────────
INSERT INTO cigars (
  manufacturer, brand, series, vitola, common_format,
  ring_gauge, length_inches, shape,
  body_type, head_type, foot_type,
  wrapper_country, wrapper_leaf, binder, filler,
  country_origin, strength, price_range,
  description, flavor_notes, avg_rating
)
VALUES
(
  'Davidoff', 'Zino Platinum', 'Crown Series', 'Barrel', 'Gordo',
  60, 6.0, 'Parejo',
  null, null, null,
  'Ecuador', 'Ecuador Connecticut', 'Dominican Republic', ARRAY['Dominican Republic', 'Peru'],
  'Dominican Republic', 4, '$25-35',
  'Zino Platinum Crown Barrel — et massivt 6×60 Gordo-format med Ecuador Connecticut-dekkblad. Medium-full styrke med kremet sødme og varme kryddertoner. Leveres i signaturens metallboks.',
  ARRAY['cedar', 'cream', 'earth', 'mild pepper', 'toasted nuts'], 8.5
),
(
  'Davidoff', 'Zino Platinum', 'Crown Series', 'Chubby Especial', 'Gordo',
  61, 5.875, 'Perfecto',
  null, null, null,
  'Ecuador', 'Ecuador Connecticut', 'Dominican Republic', ARRAY['Dominican Republic', 'Peru'],
  'Dominican Republic', 4, '$28-38',
  'Zino Platinum Crown Chubby Especial — 5⅞×61 Perfecto med smalnet hode og fot. Ecuador Connecticut-dekkblad gir lys gyllen farge og rik kremet profil med mediu-full styrke.',
  ARRAY['cream', 'cedar', 'earth', 'mild spice', 'toasted nuts'], 8.5
)
ON CONFLICT DO NOTHING;

-- ──────────────────────────────────────────────────────────
-- SCEPTER SERIES (Ecuador Connecticut shade wrapper, medium)
-- Dominican + Peruvian filler aged 4 years; Connecticut binder
-- ──────────────────────────────────────────────────────────
INSERT INTO cigars (
  manufacturer, brand, series, vitola, common_format,
  ring_gauge, length_inches, shape,
  body_type, head_type, foot_type,
  wrapper_country, wrapper_leaf, binder, filler,
  country_origin, strength, price_range,
  description, flavor_notes, avg_rating
)
VALUES
(
  'Davidoff', 'Zino Platinum', 'Scepter Series', 'Chubby', 'Perfecto',
  54, 5.0, 'Perfecto',
  null, null, null,
  'Ecuador', 'Connecticut Shade', 'Connecticut', ARRAY['Dominican Republic', 'Peru'],
  'Dominican Republic', 3, '$18-24',
  'Zino Platinum Scepter Chubby — 5×54 Perfecto som er flaggskipet i Scepter-serien. Ratet 87 av Cigar Aficionado. Kremet og balansert med behagelig sødme fra det Ecuador-dyrkede Connecticut Shade-dekkbladet.',
  ARRAY['cream', 'cedar', 'toasted nuts', 'gentle spice', 'sweet earth'], 8.7
),
(
  'Davidoff', 'Zino Platinum', 'Scepter Series', 'Grand Master', 'Toro',
  52, 5.5, 'Parejo',
  null, null, null,
  'Ecuador', 'Connecticut Shade', 'Connecticut', ARRAY['Dominican Republic', 'Peru'],
  'Dominican Republic', 3, '$18-24',
  'Zino Platinum Scepter Grand Master — 5½×52 Toro med samme karakteristiske blanding som Chubby. Litt mer røyketid og gradvis smaksutvikling fra kremet til varmere kryddertoner mot slutten.',
  ARRAY['cream', 'cedar', 'toasted nuts', 'gentle spice', 'earth'], 8.5
)
ON CONFLICT DO NOTHING;

-- ──────────────────────────────────────────────────────────
-- Z-CLASS SERIES (Connecticut Shade, medium-full)
-- Named by ring gauge × length code (e.g. 654 T = 6 ring/54 gauge/Toro)
-- ──────────────────────────────────────────────────────────
INSERT INTO cigars (
  manufacturer, brand, series, vitola, common_format,
  ring_gauge, length_inches, shape,
  body_type, head_type, foot_type,
  wrapper_country, wrapper_leaf, binder, filler,
  country_origin, strength, price_range,
  description, flavor_notes, avg_rating
)
VALUES
(
  'Davidoff', 'Zino Platinum', 'Z-Class Series', '654 T', 'Toro',
  54, 5.875, 'Parejo',
  null, null, null,
  'Ecuador', 'Connecticut Shade', 'Dominican Republic', ARRAY['Dominican Republic', 'Peru'],
  'Dominican Republic', 4, '$20-28',
  'Zino Platinum Z-Class 654 T — 5⅞×54 Toro. Koden 654 refererer til ringgauge og lengde. Connecticut Shade-dekkblad over dominikansk/peruansk fylt gir medium-full styrke med cedre og skinnaktige toner.',
  ARRAY['cedar', 'leather', 'cream', 'mild pepper', 'earth'], 8.4
),
(
  'Davidoff', 'Zino Platinum', 'Z-Class Series', '550 R', 'Robusto',
  50, 4.875, 'Parejo',
  null, null, null,
  'Ecuador', 'Connecticut Shade', 'Dominican Republic', ARRAY['Dominican Republic', 'Peru'],
  'Dominican Republic', 4, '$18-25',
  'Zino Platinum Z-Class 550 R — 4⅞×50 Robusto. Kompakt format som leverer en konsentrert medium-full smaksopplevelse med typisk Connecticut Shade-kremhet og pepperaktige undertonar.',
  ARRAY['cedar', 'leather', 'cream', 'pepper', 'earth'], 8.4
),
(
  'Davidoff', 'Zino Platinum', 'Z-Class Series', '546 P', 'Piramide',
  46, 5.25, 'Torpedo',
  null, 'Torpedo', null,
  'Ecuador', 'Connecticut Shade', 'Dominican Republic', ARRAY['Dominican Republic', 'Peru'],
  'Dominican Republic', 4, '$20-28',
  'Zino Platinum Z-Class 546 P — 5¼×46 Piramide. Det spissede hodet konsentrerer smaken og gir en unik røyksopplevelse som åpner seg bredere mot foten. Kremet og kompleks.',
  ARRAY['cedar', 'leather', 'cream', 'spice', 'nuts'], 8.4
),
(
  'Davidoff', 'Zino Platinum', 'Z-Class Series', '643 C', 'Corona',
  43, 5.625, 'Parejo',
  null, null, null,
  'Ecuador', 'Connecticut Shade', 'Dominican Republic', ARRAY['Dominican Republic', 'Peru'],
  'Dominican Republic', 4, '$18-25',
  'Zino Platinum Z-Class 643 C — 5⅝×43 Corona. Det tradisjonelle Corona-formatet fremhever Connecticut Shade-dekkbladets kremet-søte profil med en lenger og smalere røyk enn Robusto.',
  ARRAY['cream', 'cedar', 'earth', 'gentle pepper', 'toasted nuts'], 8.4
)
ON CONFLICT DO NOTHING;
