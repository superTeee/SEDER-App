-- 146: Samlet 'fyll alt'-runde for Oliva, Cohiba, Montecristo, Eiroa, Casdagli, Warped.
-- Kun tomme felt fylles. Flavor fra CA/halfwheel/anmeldere; dekkblad fra produsent/halfwheel;
-- styrke 1-5 fra anmelder-body; beskrivelser skrevet paa norsk i etablert stil. Idempotent.

-- Smaksnoter
UPDATE public.cigars c SET flavor_notes = d.notes
FROM (VALUES
  ('Cohiba','Ambar',ARRAY['Hay','Grass','Sweetness']::text[]),
  ('Cohiba','Behike BHK 52',ARRAY['Cocoa','Cedar','Espresso','Leather','Cream']::text[]),
  ('Cohiba','Behike BHK 54',ARRAY['Cedar','Spice','Hay','Earth','Dark Chocolate']::text[]),
  ('Cohiba','Behike BHK 56',ARRAY['Cocoa','Espresso','Earth','Cedar','Leather']::text[]),
  ('Cohiba','Behike BHK 58',ARRAY['Dark Fruit','Vanilla','Cream']::text[]),
  ('Cohiba','Coronas Especiales',ARRAY['Nuts','Honey','Leather','Spice','Cocoa']::text[]),
  ('Cohiba','Espléndidos',ARRAY['Cedar','Cream','Coffee','Spice','Leather']::text[]),
  ('Cohiba','Exquisitos',ARRAY['Earth','Smoke','Nuts','Herbal']::text[]),
  ('Cohiba','Lanceros',ARRAY['Cedar','Cream','Honey','Pepper','Floral']::text[]),
  ('Cohiba','Maduro 5 Genios',ARRAY['Dark Chocolate','Espresso','Spice','Cedar']::text[]),
  ('Cohiba','Maduro 5 Magicos',ARRAY['Cocoa','Cedar','Espresso','Almonds','Dark Chocolate']::text[]),
  ('Cohiba','Maduro 5 Secretos',ARRAY['Dark Chocolate','Espresso','Molasses','Leather','Dark Fruit']::text[]),
  ('Cohiba','Medio Siglo',ARRAY['Cedar','Cream','Cocoa','Leather','Pepper']::text[]),
  ('Cohiba','Novedosos',ARRAY['Cedar','Cocoa','Cream','Espresso','Nutmeg']::text[]),
  ('Cohiba','Panetelas',ARRAY['Cedar','Cocoa','Honey','Spice']::text[]),
  ('Cohiba','Pirámides Extra',ARRAY['Cedar','Leather','Spice','Earth']::text[]),
  ('Cohiba','Robustos',ARRAY['Cedar','Nuts','Butter','Honey','White Pepper']::text[]),
  ('Cohiba','Siglo I',ARRAY['Earth','Leather','Black Pepper','Oak','Nuts']::text[]),
  ('Cohiba','Siglo II',ARRAY['Cedar','Coffee','Cocoa','Vanilla']::text[]),
  ('Cohiba','Siglo III',ARRAY['Cedar','Cream','Toasted Nuts','Caramel','Spice']::text[]),
  ('Cohiba','Siglo IV',ARRAY['Cedar','Toasted Nuts','Cocoa','Honey','Black Pepper']::text[]),
  ('Cohiba','Siglo V',ARRAY['Chocolate','Cedar','Honey','Coffee','Leather']::text[]),
  ('Cohiba','Siglo VI',ARRAY['Cedar','Vanilla','Spice','Leather','Citrus']::text[]),
  ('Montecristo','"A"',ARRAY['Leather','Almonds','Spice','Cocoa','Cedar']::text[]),
  ('Montecristo','Double Edmundo',ARRAY['Cocoa','Coffee','Cedar','Leather','Oak']::text[]),
  ('Montecristo','Dumas',ARRAY['Cream','Leather','Vanilla','Nuts','Earth']::text[]),
  ('Montecristo','Eagle',ARRAY['Cream','Floral','Nuts','Pepper']::text[]),
  ('Montecristo','Especial',ARRAY['Cedar','Coffee','Cocoa','Almonds','Oak']::text[]),
  ('Montecristo','Herederos',ARRAY['Cocoa','Vanilla','Oak','Leather','Honey']::text[]),
  ('Montecristo','Joyitas',ARRAY['Cedar','Leather','Earth','Cocoa','Pepper']::text[]),
  ('Montecristo','Junior',ARRAY['Earth','Wood','Leather','Nuts','Honey']::text[]),
  ('Montecristo','Leyenda',ARRAY['Dark Chocolate','Leather','Cedar','Espresso','Dried Fruit']::text[]),
  ('Montecristo','Maltés',ARRAY['Nuts','Baking Spice','Citrus','Cedar']::text[]),
  ('Montecristo','Master',ARRAY['Wood','Coffee','Spice','Pepper','Chocolate']::text[]),
  ('Montecristo','Media Corona',ARRAY['Almonds','Wood','Earth','Spice','Coffee']::text[]),
  ('Montecristo','No. 1',ARRAY['Cedar','Cream','Coffee','Cocoa','Nuts']::text[]),
  ('Montecristo','No. 3',ARRAY['Cedar','Espresso','Cocoa','Almonds','Black Pepper']::text[]),
  ('Montecristo','No. 5',ARRAY['Coffee','Leather','Cocoa','Almonds','Earth']::text[]),
  ('Montecristo','Petit No. 2',ARRAY['Cedar','Nuts','Cream','White Pepper','Nutmeg']::text[]),
  ('Montecristo','Petit Tubos',ARRAY['Earth','Pepper','Coffee','Cedar']::text[]),
  ('Montecristo','Regata',ARRAY['Cedar','Vanilla','Almonds','White Pepper','Caramel']::text[]),
  ('Montecristo','Slam',ARRAY['Wood','Toasted Nuts','Cocoa','Honey','Earth']::text[]),
  ('Montecristo','Tubos',ARRAY['Cedar','Leather','Almonds','Cream','Tobacco']::text[]),
  ('Eiroa','CBT Maduro',ARRAY['Dark Chocolate','Espresso','Cocoa','Leather','Black Pepper']::text[]),
  ('Eiroa','Natural',ARRAY['Pepper','Tobacco','Baking Spice','Cream','Sweetness']::text[]),
  ('Eiroa','The First 20 Years',ARRAY['Cocoa','Cedar','Espresso','Cinnamon','Leather']::text[]),
  ('Eiroa','The First 20 Years Colorado',ARRAY['Cedar','Vanilla','Black Pepper','Cinnamon','Leather']::text[])
) AS d(brand,series,notes)
WHERE c.brand=d.brand AND c.series=d.series AND coalesce(c.is_public,true)=true
  AND (c.flavor_notes IS NULL OR array_length(c.flavor_notes,1) IS NULL);

-- Dekkblad
UPDATE public.cigars c SET wrapper_leaf = d.w
FROM (VALUES
  ('Casdagli','Basilica Line','Dominican Cotui'),
  ('Casdagli','Brothers of the Sabre','Ecuadorian'),
  ('Casdagli','Club Mareva Line','Ecuadorian'),
  ('Casdagli','Cypher 3311','Ecuadorian'),
  ('Casdagli','D''Boiss Line','Ecuador Claro Colorado'),
  ('Casdagli','Daughters of the Wind Line','Ecuadorian HVA'),
  ('Casdagli','Traditional Line','Dominican'),
  ('Casdagli','Villa Casdagli Line','Ecuador Habano'),
  ('Casdagli','Villa Casdagli Petit Exquisitos','Ecuador Habano'),
  ('Eiroa','Natural','Corojo')
) AS d(brand,series,w)
WHERE c.brand=d.brand AND c.series=d.series AND coalesce(c.is_public,true)=true
  AND (c.wrapper_leaf IS NULL OR length(trim(c.wrapper_leaf))=0);

-- Styrke (1-5)
UPDATE public.cigars c SET strength = d.s
FROM (VALUES
  ('Warped','Cloud Hopper',4),
  ('Warped','Companion de Warped',3),
  ('Warped','Corto',4),
  ('Warped','Corto Maduro',5),
  ('Warped','Don Reynaldo',3),
  ('Warped','Isla del Cocodrilo',3),
  ('Warped','La Colmena',4),
  ('Warped','La Hacienda',3),
  ('Warped','Maestro del Tiempo',4),
  ('Warped','Nicotina',5),
  ('Warped','Sarto',4),
  ('Warped','Serie Gran Reserva 1988',3),
  ('Warped','The Devil''s Hands',3),
  ('Eiroa','CBT Maduro',4),
  ('Eiroa','Natural',4),
  ('Eiroa','The First 20 Years',4),
  ('Eiroa','The First 20 Years Colorado',3)
) AS d(brand,series,s)
WHERE c.brand=d.brand AND c.series=d.series AND coalesce(c.is_public,true)=true
  AND c.strength IS NULL;

-- Beskrivelse
UPDATE public.cigars c SET description = d.descr
FROM (VALUES
  ('Oliva','Gilberto Oliva Reserva','En balansert mellomsterk sigar med ecuadoriansk Sumatra-dekkblad og nicaraguansk fyll, med myke toner av karamell, sedertre, ristede nøtter og kaffe.'),
  ('Oliva','Gilberto Oliva Reserva Blanc','En mild til mellomsterk sigar med ecuadoriansk Connecticut-dekkblad — kremet og jevn med toner av nøtter, sedertre og et hint av hvit pepper.'),
  ('Oliva','Serie G','En mellomsterk sigar med afrikansk Cameroon-dekkblad og nicaraguansk fyll, kjent for sin naturlige sødme og toner av tre, nøtter, kaffe og sedertre.'),
  ('Oliva','Serie G Maduro','En mellomsterk maduro med meksikansk San Andrés-dekkblad, med søte toner av kakao, kaffe, tre og et snev av krydder.'),
  ('Oliva','Serie O Maduro','En mellomsterk til kraftig sigar med amerikansk Connecticut Broadleaf maduro-dekkblad, med fyldige toner av kakao, sedertre, kaffe og krydder.'),
  ('Oliva','Serie V Maduro','En fyldig, kraftig sigar med meksikansk San Andrés-dekkblad og nicaraguansk ligero-fyll, med dype toner av mørk sjokolade, espresso, pepper og sødme.'),
  ('Eiroa','CBT Maduro','En medium-fyldig honduransk maduro med Connecticut Broadleaf-dekkblad, med toner av mørk sjokolade, espresso, lær og svart pepper.'),
  ('Eiroa','Natural','En medium-fyldig honduransk puro med Corojo-dekkblad, med toner av pepper, tobakk, bakekrydder og en kremet sødme.'),
  ('Eiroa','The First 20 Years','En kraftig honduransk puro med Corojo-dekkblad, med toner av kakao, seder, espresso og kanel.'),
  ('Eiroa','The First 20 Years Colorado','En medium og kompleks honduransk puro med Corojo Colorado-dekkblad, med toner av seder, vanilje, svart pepper og lær.')
) AS d(brand,series,descr)
WHERE c.brand=d.brand AND c.series=d.series AND coalesce(c.is_public,true)=true
  AND (c.description IS NULL OR length(trim(c.description))=0);