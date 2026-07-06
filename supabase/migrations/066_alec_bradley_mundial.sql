-- Migration 066: Alec Bradley Mundial (Punta Lanza)
-- 5 perfecto-størrelser. Honduransk dekkblad (Trojes Corojo), honduransk
-- omblad og innlegg fra Honduras + Nicaragua. Laget hos Raíces Cubanas,
-- Danlí, Honduras. Medium-full styrke. Tilbaketrukket ("The Vault").
-- Kilde: alecbradley.com/cigars/mundial

INSERT INTO cigars (
  brand, manufacturer, series, vitola, common_format,
  ring_gauge, length_inches,
  shape, body_type, head_type, foot_type,
  wrapper_country, wrapper_leaf,
  binder, filler,
  country_origin,
  strength,
  flavor_notes, description
) VALUES

-- PL #4 — 4¼" × 48 (perfecto)
('Alec Bradley', 'Alec Bradley', 'Mundial', 'Punta Lanza No. 4', 'Perfecto',
 48, 4.3,
 'Figurado', 'Perfecto', 'Pointed', 'Closed',
 'Honduras', 'Corojo',
 'Honduran', ARRAY['Honduras', 'Nicaragua'],
 'Honduras',
 4,
 ARRAY['spice', 'leather', 'mineral'],
 'Alec Bradley Mundial Punta Lanza No. 4 — 4¼"×48 perfecto. Honduransk Corojo-dekkblad over honduransk omblad og en honduransk/nicaraguansk kjerne. Medium-full med krydder, lær og mineral. Del av Alec Bradleys "The Vault" (tilbaketrukket).'),

-- PL #5 — 5⅛" × 52 (perfecto)
('Alec Bradley', 'Alec Bradley', 'Mundial', 'Punta Lanza No. 5', 'Perfecto',
 52, 5.1,
 'Figurado', 'Perfecto', 'Pointed', 'Closed',
 'Honduras', 'Corojo',
 'Honduran', ARRAY['Honduras', 'Nicaragua'],
 'Honduras',
 4,
 ARRAY['spice', 'leather', 'mineral'],
 'Alec Bradley Mundial Punta Lanza No. 5 — 5⅛"×52 perfecto. Den mest populære størrelsen i serien. Honduransk Corojo-dekkblad, honduransk omblad, honduransk/nicaraguansk innlegg. Medium-full med krydder, lær og mineral.'),

-- PL #6 — 6" × 54 (perfecto)
('Alec Bradley', 'Alec Bradley', 'Mundial', 'Punta Lanza No. 6', 'Perfecto',
 54, 6.0,
 'Figurado', 'Perfecto', 'Pointed', 'Closed',
 'Honduras', 'Corojo',
 'Honduran', ARRAY['Honduras', 'Nicaragua'],
 'Honduras',
 4,
 ARRAY['spice', 'leather', 'mineral'],
 'Alec Bradley Mundial Punta Lanza No. 6 — 6"×54 perfecto. Bredere ringmål gir et rundere, kremet trekk. Honduransk Corojo-dekkblad over honduransk/nicaraguansk blend. Krydder, lær og mineral med lang ettersmak.'),

-- PL #7 — 7" × 52 (perfecto)
('Alec Bradley', 'Alec Bradley', 'Mundial', 'Punta Lanza No. 7', 'Perfecto',
 52, 7.0,
 'Figurado', 'Perfecto', 'Pointed', 'Closed',
 'Honduras', 'Corojo',
 'Honduran', ARRAY['Honduras', 'Nicaragua'],
 'Honduras',
 4,
 ARRAY['spice', 'leather', 'mineral'],
 'Alec Bradley Mundial Punta Lanza No. 7 — 7"×52 perfecto. Det lengste formatet gir gradvis utvikling og mer kompleksitet. Honduransk Corojo-dekkblad, honduransk omblad og honduransk/nicaraguansk innlegg.'),

-- PL #8 — 6½" × 52 (perfecto)
('Alec Bradley', 'Alec Bradley', 'Mundial', 'Punta Lanza No. 8', 'Perfecto',
 52, 6.5,
 'Figurado', 'Perfecto', 'Pointed', 'Closed',
 'Honduras', 'Corojo',
 'Honduran', ARRAY['Honduras', 'Nicaragua'],
 'Honduras',
 4,
 ARRAY['spice', 'leather', 'mineral'],
 'Alec Bradley Mundial Punta Lanza No. 8 — 6½"×52 perfecto. Honduransk Corojo-dekkblad over honduransk/nicaraguansk kjerne. Krydder, lær og mineral. Del av Alec Bradleys "The Vault" (tilbaketrukket).');

-- Aliaser for OCR-gjenkjenning
INSERT INTO cigar_aliases (alias, manufacturer, brand, series) VALUES
('AB Mundial',       'Alec Bradley', 'Alec Bradley', 'Mundial'),
('Alec Bradley AB Mundial', 'Alec Bradley', 'Alec Bradley', 'Mundial'),
('Mundial Punta Lanza', 'Alec Bradley', 'Alec Bradley', 'Mundial');
