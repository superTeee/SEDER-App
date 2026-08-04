-- 132: La Barba — fra datahull/skann «TH BARBA» (= La Barba Cigars).
-- Produsentens egen side (labarbacigars.com/the-lineup) lister linjene med blend/smak,
-- men IKKE størrelser — derfor legges linjene inn på linje-nivå (series) med verifisert
-- blend, og mål (ring/lengde) står tomme (tomt slår gjetning). Størrelser fylles senere
-- per skann. Alias 'La Barba'/'Barba'/'Th Barba' så det skannede båndet matcher.
INSERT INTO public.cigars
  (brand, series, vitola, wrapper_country, wrapper_leaf, country_origin, strength,
   manufacturer, description, is_public, source_tier, source_url, verified_at, aliases)
VALUES
('La Barba', 'Red', NULL, 'Dominican Republic', 'Corojo', 'Dominican Republic', 3.5,
 'La Barba Cigars',
 'Dominikansk puro med Corojo-dekkblad. Krydret og søtt — graham crackers, sjokolade og ristet marshmallow. Medium+.',
 true, 'manufacturer', 'http://labarbacigars.com/the-lineup', now(),
 ARRAY['La Barba','Barba','Th Barba']),
('La Barba', 'Purple', NULL, 'Ecuador', 'Habano', NULL, 2.5,
 'La Barba Cigars',
 'Ecuadoriansk Habano-dekkblad. Søt, med hvit og sort pepper, floral og elegant. Medium−.',
 true, 'manufacturer', 'http://labarbacigars.com/the-lineup', now(),
 ARRAY['La Barba','Barba','Th Barba']),
('La Barba', 'One & Only', NULL, 'Ecuador', 'Habano', NULL, 4.5,
 'La Barba Cigars',
 'Samarbeid Caldwell × La Barba. 15 år gammelt Ecuador Habano-dekkblad, Corojo og Pelo de Oro. Raffinert, rik og krydret — lær, mineralitet og jord. Fyldig.',
 true, 'manufacturer', 'http://labarbacigars.com/the-lineup', now(),
 ARRAY['La Barba','Barba','Th Barba']);
