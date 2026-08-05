-- 147: Batch 2 'fyll alt' — MBombay, Nat Cicco, Condega, Nicarao, El Septimo.
-- Kun tomme felt. Flavor/styrke/beskrivelse fra halfwheel/CA/cigar-coop/anmeldere.
-- El Septimo-dekkblad stort sett udisclosed -> bevisst tomt (tomt slaar gjetting). Idempotent.

-- Smaksnoter
UPDATE public.cigars c SET flavor_notes=d.notes FROM (VALUES
  ('MBombay','Classic',ARRAY['Wood','Black Pepper','Cream','Tobacco']::text[]),
  ('MBombay','Corojo Oscuro',ARRAY['Cedar','Wood','Cherry','Black Pepper']::text[]),
  ('MBombay','Gaaja',ARRAY['Pepper','Wood','Toast','Sweetness']::text[]),
  ('MBombay','Gaaja Maduro',ARRAY['Toast','Cinnamon','Black Pepper','Chocolate','Cream']::text[]),
  ('MBombay','KeSara',ARRAY['Wood','Sweetness','Hay','Pepper','Citrus']::text[]),
  ('MBombay','Vintage Reserve',ARRAY['Cedar','Cream','Tobacco','Wood','Citrus']::text[]),
  ('Nat Cicco','Cuban Legends',ARRAY['Spice','Cedar','Citrus']::text[]),
  ('Nat Cicco','Elephant Ears',ARRAY['Mocha','Pepper','Wood','Earth','Sweetness']::text[]),
  ('Condega','Serie F',ARRAY['Cocoa','Earth','Cedar','Spice','Sweetness']::text[]),
  ('Condega','Serie S',ARRAY['Cedar','Cinnamon','Cocoa','Pepper']::text[]),
  ('Condega','Volcanes',ARRAY['Coffee','Cedar','Pepper','Nuts','Cocoa']::text[]),
  ('Nicarao','Clasico',ARRAY['Cedar','Spice','Cream','Coffee']::text[]),
  ('Nicarao','Especial',ARRAY['Coffee','Cocoa','Black Pepper','Dark Chocolate','Leather']::text[]),
  ('Nicarao','Exclusivo',ARRAY['Earth','Cocoa','Espresso','Leather','Black Pepper']::text[]),
  ('El Septimo','Emperor',ARRAY['Nuts','Leather','Hay','White Pepper','Vanilla']::text[]),
  ('El Septimo','Gilgamesh',ARRAY['Oak','Black Pepper','Earth','Cream','Mint']::text[]),
  ('El Septimo','Sacred Arts',ARRAY['Coffee','Earth','Dark Chocolate','Cherry','Cedar']::text[])
) AS d(brand,series,notes)
WHERE c.brand=d.brand AND c.series=d.series AND coalesce(c.is_public,true)=true
  AND (c.flavor_notes IS NULL OR array_length(c.flavor_notes,1) IS NULL);

-- Styrke
UPDATE public.cigars c SET strength=d.s FROM (VALUES
  ('MBombay','Gaaja',3),
  ('MBombay','Gaaja Maduro',4),
  ('MBombay','KeSara',3),
  ('MBombay','Vintage Reserve',2),
  ('Condega','Serie F',4),
  ('Condega','Serie S',3),
  ('Condega','Volcanes',4),
  ('Nicarao','Clasico',2),
  ('Nicarao','Especial',4),
  ('Nicarao','Exclusivo',4),
  ('El Septimo','Emperor',3),
  ('El Septimo','Zaya',4)
) AS d(brand,series,s)
WHERE c.brand=d.brand AND c.series=d.series AND coalesce(c.is_public,true)=true
  AND c.strength IS NULL;

-- Dekkblad
UPDATE public.cigars c SET wrapper_leaf=d.w FROM (VALUES
  ('Nat Cicco','Nicaraguan Long Filler','Nicaraguan'),
  ('El Septimo','Culinary Art','Ecuador Connecticut'),
  ('El Septimo','Emperor','Connecticut')
) AS d(brand,series,w)
WHERE c.brand=d.brand AND c.series=d.series AND coalesce(c.is_public,true)=true
  AND (c.wrapper_leaf IS NULL OR length(trim(c.wrapper_leaf))=0);

-- Beskrivelse
UPDATE public.cigars c SET description=d.descr FROM (VALUES
  ('Condega','Serie F','En mellomsterk til fyldig nicaraguansk sigar med San Andrés Maduro-dekkblad, med toner av kakao, jord, sedertre og et snev av krydder.'),
  ('Condega','Serie S','En mellomsterk nicaraguansk sigar med Corojo-dekkblad, med toner av sedertre, kanel, kakao og et snev av pepper.'),
  ('Condega','Volcanes','En mellomsterk til fyldig nicaraguansk sigar med sungrown-dekkblad, med toner av kaffe, sedertre, pepper og nøtter.'),
  ('Nicarao','Clasico','En mild til mellomsterk nicaraguansk sigar med Habano Rosado-dekkblad, med toner av seder, krydder og kremethet.'),
  ('Nicarao','Especial','En mellomsterk til sterk nicaraguansk sigar med Habano Rosado Oscuro-dekkblad, med toner av kaffe, kakao og svart pepper.'),
  ('Nicarao','Exclusivo','En mellomsterk til sterk nicaraguansk sigar med Habano Maduro Natural-dekkblad, med toner av jord, kakao og lær.')
) AS d(brand,series,descr)
WHERE c.brand=d.brand AND c.series=d.series AND coalesce(c.is_public,true)=true
  AND (c.description IS NULL OR length(trim(c.description))=0);
