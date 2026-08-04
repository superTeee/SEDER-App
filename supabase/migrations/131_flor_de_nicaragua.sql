-- 131: Flor de Nicaragua (Robusto + Toro) — fra datahull/skann som ikke ga treff.
-- Rimelig longfiller-bundleserie laget av Joya de Nicaragua, importert av Sol Cigar Co.
-- Robusto verifisert: 127mm (5.0") x ring 50, longfiller. Toro satt til standard
-- toro-mål (52x6.0) — eksakt Toro-mål ikke bekreftet ennå. Kilde: retailer (Sol Cigar).
-- Alias 'Flor Nicaragua'/'Flor Nicaragua Mexico' så det skannede båndet matcher.
INSERT INTO public.cigars
  (brand, series, vitola, binder, filler, country_origin, ring_gauge, length_inches,
   shape, manufacturer, common_format, description, is_public, source_tier, aliases)
VALUES
('Flor de Nicaragua', NULL, 'Robusto', NULL, ARRAY['Nicaragua'], 'Nicaragua', 50, 5.0,
 'Parejo', 'Joya de Nicaragua', 'Robusto',
 'Rimelig longfiller-bundlesigar laget av Joya de Nicaragua. Overraskende kompleks til prisen — åpner med et fint krydderpreg og blir etter hvert godt balansert med en myk, rund og aromatisk røyk.',
 true, 'retailer', ARRAY['Flor Nicaragua','Flor Nicaragua Mexico']),
('Flor de Nicaragua', NULL, 'Toro', NULL, ARRAY['Nicaragua'], 'Nicaragua', 52, 6.0,
 'Parejo', 'Joya de Nicaragua', 'Toro',
 'Rimelig longfiller-bundlesigar laget av Joya de Nicaragua. Overraskende kompleks til prisen — åpner med et fint krydderpreg og blir etter hvert godt balansert med en myk, rund og aromatisk røyk.',
 true, 'retailer', ARRAY['Flor Nicaragua','Flor Nicaragua Mexico']);
