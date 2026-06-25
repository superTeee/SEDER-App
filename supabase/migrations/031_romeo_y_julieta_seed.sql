-- Migration 031: Romeo y Julieta (Cuba)
-- Klassiske kubanske vitolaer under serien "1875"
-- OCR leser "ROMEO Y JULIETA Desde 1875 HABANA CUBA"
-- → etter stripping → "ROMEO Y JULIETA 1875" → matcher brand + series
-- Kjørt: 2026-06-24

INSERT INTO cigars (
    brand, series, vitola, wrapper_leaf, binder_leaf, filler_blend,
    origin_country, body_strength, flavor_notes, common_format,
    ring_gauge, length_inches, description
) VALUES

-- Churchill — ikonisk vitola, oppkalt etter Winston Churchill
('Romeo y Julieta', '1875', 'Churchill',
 'Cuban', 'Cuban', 'Cuban',
 'Cuba', 'medium', ARRAY['cedar', 'leather', 'earth', 'coffee', 'spice'],
 'churchill', 47, 7.0,
 'Romeo y Julieta sin signaturvitola — en Churchill på 7" x 47. Balansert og elegant med noter av seder, lær og jord. Oppkalt etter Winston Churchill som angivelig røykte 8–10 daglig.'),

-- Short Churchill
('Romeo y Julieta', '1875', 'Short Churchill',
 'Cuban', 'Cuban', 'Cuban',
 'Cuba', 'medium', ARRAY['cedar', 'cream', 'earth', 'mild spice'],
 'robusto', 50, 4.875,
 'En kortere og tykkere versjon av Churchill-vitolaen. 4 7/8" x 50. Lettere tilgjengelig for en kortere økt, men beholder den klassiske R&J-karakteren.'),

-- Wide Churchill
('Romeo y Julieta', '1875', 'Wide Churchill',
 'Cuban', 'Cuban', 'Cuban',
 'Cuba', 'medium', ARRAY['cedar', 'cream', 'nut', 'earth'],
 'robusto', 55, 5.625,
 'Den bredeste Churchill-varianten på 5 5/8" x 55. Kremete røyk med rund finish.'),

-- No. 1 (Lonsdale)
('Romeo y Julieta', '1875', 'No. 1',
 'Cuban', 'Cuban', 'Cuban',
 'Cuba', 'medium', ARRAY['cedar', 'leather', 'floral', 'earth'],
 'lonsdale', 44, 6.625,
 'En klassisk Lonsdale på 6 5/8" x 44. Elegant og langstrakt med blomsteraktige og jordete toner.'),

-- No. 2 (Torpedo)
('Romeo y Julieta', '1875', 'No. 2',
 'Cuban', 'Cuban', 'Cuban',
 'Cuba', 'medium-full', ARRAY['cedar', 'spice', 'leather', 'dark chocolate'],
 'torpedo', 52, 6.125,
 'Torpedo-vitola på 6 1/8" x 52. Det tilspissede hodet konsentrerer smaken — mer kraft enn de fleste R&J-vitolaer.'),

-- No. 3 (Corona)
('Romeo y Julieta', '1875', 'No. 3',
 'Cuban', 'Cuban', 'Cuban',
 'Cuba', 'mild-medium', ARRAY['cedar', 'floral', 'cream', 'hay'],
 'corona', 42, 5.625,
 'Klassisk corona-vitola på 5 5/8" x 42. Lett og aromatisk — et godt introduksjonssigar til merket.'),

-- Mille Fleurs
('Romeo y Julieta', '1875', 'Mille Fleurs',
 'Cuban', 'Cuban', 'Cuban',
 'Cuba', 'mild-medium', ARRAY['floral', 'cedar', 'cream', 'grass'],
 'panatela', 42, 5.125,
 'En slank panatela på 5 1/8" x 42. "Tusen blomster" — blomsteraktig og lett, perfekt til formiddagen.'),

-- Petit Churchill
('Romeo y Julieta', '1875', 'Petit Churchill',
 'Cuban', 'Cuban', 'Cuban',
 'Cuba', 'mild-medium', ARRAY['cedar', 'cream', 'mild spice'],
 'petit-robusto', 50, 4.0,
 'Den minste Churchill-varianten på 4" x 50. Kompakt og kremete, ferdig på under 30 minutter.'),

-- Exhibicion No. 3
('Romeo y Julieta', '1875', 'Exhibicion No. 3',
 'Cuban', 'Cuban', 'Cuban',
 'Cuba', 'medium', ARRAY['cedar', 'coffee', 'earth', 'spice'],
 'lonsdale', 46, 6.0,
 'Lonsdale-variant på 6" x 46 med en litt tykkere ring gauge enn No. 1. Rik og balansert.'),

-- Exhibicion No. 4
('Romeo y Julieta', '1875', 'Exhibicion No. 4',
 'Cuban', 'Cuban', 'Cuban',
 'Cuba', 'medium', ARRAY['cedar', 'nut', 'cream', 'earth'],
 'robusto', 48, 5.0,
 'Robusto-variant på 5" x 48. En av de mest populære R&J-vitolaene — allsidig og velbalansert.');

-- Sjekk at det kom inn
SELECT brand, series, vitola, common_format, ring_gauge, length_inches
FROM cigars
WHERE brand = 'Romeo y Julieta'
ORDER BY series, vitola;
