-- 148: Batch 3 'fyll alt' — CAO (opphav+styrke), Dunbarton (styrke), Sinistro (detaljer),
-- + ferske norske beskrivelser for Ashton, Dunbarton og Sinistro. Kun tomme felt. Idempotent.
-- CAO opphav = produksjonsland (STG Esteli NI / STG Danli HN / General Cigar DR), verifisert per linje.

-- CAO opphav (produksjonsland)
UPDATE public.cigars c SET country_origin=d.x FROM (VALUES
  ('CAO','Amazon Basin','Nicaragua'),
  ('CAO','Amazon Basin Extra Añejo','Nicaragua'),
  ('CAO','America 250th Anniversary','Nicaragua'),
  ('CAO','Bella Vanilla','Dominican Republic'),
  ('CAO','Bones','Nicaragua'),
  ('CAO','Brazilia','Nicaragua'),
  ('CAO','BX3','Nicaragua'),
  ('CAO','Cameroon','Nicaragua'),
  ('CAO','Cherrybomb','Dominican Republic'),
  ('CAO','Colombia','Nicaragua'),
  ('CAO','Consigliere','Nicaragua'),
  ('CAO','Eileen''s Dream','Dominican Republic'),
  ('CAO','FASA Noche','Nicaragua'),
  ('CAO','FASA Sol','Honduras'),
  ('CAO','FASA Sombra','Dominican Republic'),
  ('CAO','Firewalker','Nicaragua'),
  ('CAO','Flathead V21','Nicaragua'),
  ('CAO','Flathead V23','Nicaragua'),
  ('CAO','Gold','Nicaragua'),
  ('CAO','Gold Honey','Dominican Republic'),
  ('CAO','Gold Maduro','Nicaragua'),
  ('CAO','Italia','Honduras'),
  ('CAO','Maduro','Nicaragua'),
  ('CAO','Moontrance','Dominican Republic'),
  ('CAO','Mortal Coil','Nicaragua'),
  ('CAO','Nicaragua','Nicaragua'),
  ('CAO','Orellana','Nicaragua'),
  ('CAO','OSA SOL','Honduras'),
  ('CAO','Pilón','Nicaragua'),
  ('CAO','Pilón Añejo','Honduras'),
  ('CAO','Session','Dominican Republic'),
  ('CAO','Speed Shop','Nicaragua'),
  ('CAO','Steel Horse','Nicaragua'),
  ('CAO','Stokk','Nicaragua'),
  ('CAO','Thunder Smoke','Dominican Republic'),
  ('CAO','V19','Nicaragua'),
  ('CAO','Vision','Nicaragua'),
  ('CAO','Vision 2022','Nicaragua'),
  ('CAO','Zócalo','Nicaragua')
) AS d(brand,series,x)
WHERE c.brand=d.brand AND c.series=d.series AND coalesce(c.is_public,true)=true
  AND (c.country_origin IS NULL OR length(trim(c.country_origin))=0);

-- CAO + Sinistro opphav / styrke
UPDATE public.cigars c SET strength=d.x FROM (VALUES
  ('CAO','Amazon Basin',4),
  ('CAO','Amazon Basin Extra Añejo',4),
  ('CAO','America 250th Anniversary',4),
  ('CAO','Bella Vanilla',1),
  ('CAO','Bones',4),
  ('CAO','Brazilia',4),
  ('CAO','BX3',4),
  ('CAO','Cameroon',2),
  ('CAO','Cherrybomb',1),
  ('CAO','Colombia',2),
  ('CAO','Consigliere',3),
  ('CAO','Eileen''s Dream',1),
  ('CAO','FASA Noche',4),
  ('CAO','FASA Sol',3),
  ('CAO','FASA Sombra',3),
  ('CAO','Firewalker',3),
  ('CAO','Flathead V21',4),
  ('CAO','Flathead V23',4),
  ('CAO','Gold',2),
  ('CAO','Gold Honey',1),
  ('CAO','Gold Maduro',2),
  ('CAO','Italia',3),
  ('CAO','Maduro',4),
  ('CAO','Moontrance',1),
  ('CAO','Mortal Coil',3),
  ('CAO','Nicaragua',4),
  ('CAO','Orellana',5),
  ('CAO','OSA SOL',2),
  ('CAO','Pilón',3),
  ('CAO','Pilón Añejo',4),
  ('CAO','Session',3),
  ('CAO','Speed Shop',3),
  ('CAO','Steel Horse',4),
  ('CAO','Stokk',3),
  ('CAO','Thunder Smoke',3),
  ('CAO','V19',5),
  ('CAO','Vision',3),
  ('CAO','Vision 2022',4),
  ('CAO','Zócalo',3),
  ('Dunbarton Tobacco & Trust','Mi Querida',4),
  ('Dunbarton Tobacco & Trust','Mi Querida Black',4),
  ('Dunbarton Tobacco & Trust','Mi Querida Triqui Traca',4),
  ('Dunbarton Tobacco & Trust','Muestra de Saka',4),
  ('Dunbarton Tobacco & Trust','Polpetta',3),
  ('Dunbarton Tobacco & Trust','Red Meat Lovers',4),
  ('Dunbarton Tobacco & Trust','Sin Compromiso',4),
  ('Dunbarton Tobacco & Trust','Sobremesa',3),
  ('Dunbarton Tobacco & Trust','Sobremesa Brûlée',2),
  ('Dunbarton Tobacco & Trust','Stillwell Star',2),
  ('Dunbarton Tobacco & Trust','Todos Las Dias',5),
  ('Dunbarton Tobacco & Trust','Umbagog',3),
  ('Dunbarton Tobacco & Trust','Unicorns',5),
  ('Sinistro','La Fabrica',4)
) AS d(brand,series,x)
WHERE c.brand=d.brand AND c.series=d.series AND coalesce(c.is_public,true)=true
  AND c.strength IS NULL;

-- Sinistro La Fabrica opphav
UPDATE public.cigars c SET country_origin=d.x FROM (VALUES
  ('Sinistro','La Fabrica','Dominican Republic')
) AS d(brand,series,x)
WHERE c.brand=d.brand AND c.series=d.series AND coalesce(c.is_public,true)=true
  AND (c.country_origin IS NULL OR length(trim(c.country_origin))=0);

-- Sinistro Mr. Sinistro dekkblad
UPDATE public.cigars c SET wrapper_leaf=d.x FROM (VALUES
  ('Sinistro','Mr. Sinistro','Ecuadorian Habano')
) AS d(brand,series,x)
WHERE c.brand=d.brand AND c.series=d.series AND coalesce(c.is_public,true)=true
  AND (c.wrapper_leaf IS NULL OR length(trim(c.wrapper_leaf))=0);

-- Sinistro La Fabrica smak
UPDATE public.cigars c SET flavor_notes=d.x FROM (VALUES
  ('Sinistro','La Fabrica',ARRAY['Cocoa','Earth','Pepper','Coffee','Leather']::text[])
) AS d(brand,series,x)
WHERE c.brand=d.brand AND c.series=d.series AND coalesce(c.is_public,true)=true
  AND (c.flavor_notes IS NULL OR array_length(c.flavor_notes,1) IS NULL);

-- Beskrivelser (Ashton, Dunbarton, Sinistro)
UPDATE public.cigars c SET description=d.x FROM (VALUES
  ('Ashton','Aged Maduro','En fyldig dominikansk maduro med Connecticut Broadleaf-dekkblad, med dype toner av lær, jord, eik, kakao og espresso.'),
  ('Ashton','Cabinet Selection','En mild, elegant dominikansk sigar med Connecticut Shade-dekkblad, med kremete toner av mandler, smør, vanilje og et snev av krydder.'),
  ('Ashton','Classic','En mild dominikansk sigar med Connecticut Shade-dekkblad, med jevne toner av seder, fløte, mandler, kaffe og honning.'),
  ('Ashton','ESG','En raffinert dominikansk sigar med dominikansk dekkblad og ni års lagret tobakk, med toner av mandler, kaffe, fløte og lær.'),
  ('Ashton','Esquire','En liten, praktisk dominikansk sigar for en kort røyk, med milde toner av mandler, kaffe, kakao og fløte.'),
  ('Ashton','Heritage Puro Sol','En mellomsterk dominikansk sigar med ecuadoriansk Habano-dekkblad, med toner av nøtter, kanel, lær, jord og karamell.'),
  ('Ashton','Small Cigars Cameroon','En liten sigar med Cameroon-dekkblad, med toner av tre, kakao, svart pepper og et snev av muskat.'),
  ('Ashton','Small Cigars Connecticut','En liten, mild sigar med Connecticut Shade-dekkblad, med kremete toner av nøtter, seder og et snev av krydder.'),
  ('Ashton','Symmetry','En mellomsterk dominikansk sigar med ecuadoriansk Habano-dekkblad, med toner av pepper, lær, kaffe, seder og fløte.'),
  ('Ashton','VSG','En fyldig dominikansk sigar med ecuadoriansk Sumatra-dekkblad (Virgin Sun Grown), med kraftige toner av espresso, lær, seder, pepper og mørk frukt.'),
  ('Dunbarton Tobacco & Trust','Mi Querida','En fyldig nicaraguansk sigar med Connecticut Broadleaf-dekkblad, med toner av sjokolade, pepper, jord, kaffe og tre.'),
  ('Dunbarton Tobacco & Trust','Mi Querida Black','En kraftig nicaraguansk sigar med mørkt Connecticut Broadleaf-dekkblad, med toner av fløte, pepper, ristet brød, jord og tre.'),
  ('Dunbarton Tobacco & Trust','Mi Querida Triqui Traca','En kraftig, krydret nicaraguansk sigar med mørkt Connecticut Broadleaf-dekkblad, med toner av svart pepper, sødme, seder, jord og mørk sjokolade.'),
  ('Dunbarton Tobacco & Trust','Muestra de Saka','En fyldig eksperimentell nicaraguansk sigar med ecuadoriansk Habano-dekkblad, med toner av sjokolade, jord, ristede nøtter, seder og pepper.'),
  ('Dunbarton Tobacco & Trust','Polpetta','En mellomsterk nicaraguansk sigar med Connecticut Broadleaf-dekkblad, med toner av kaffe, sjokolade, pepper, jord og et snev av sitrus.'),
  ('Dunbarton Tobacco & Trust','Red Meat Lovers','En fyldig nicaraguansk sigar med Connecticut Broadleaf-dekkblad, med toner av kakao, seder, eik, kaffe og lær.'),
  ('Dunbarton Tobacco & Trust','Sin Compromiso','En fyldig nicaraguansk sigar med San Andrés Negro-dekkblad, med toner av sjokolade, pepper, jord, sødme og kaffe.'),
  ('Dunbarton Tobacco & Trust','Sobremesa','En mellomsterk nicaraguansk sigar med ecuadoriansk Habano-dekkblad, med toner av kanel, sjokolade, fløte, malt og jord.'),
  ('Dunbarton Tobacco & Trust','Sobremesa Brûlée','En mild til mellomsterk nicaraguansk sigar med ecuadoriansk Connecticut Shade-dekkblad, med søte toner av nøtter, fløte, karamell og sitrus.'),
  ('Dunbarton Tobacco & Trust','Stillwell Star','En mild til mellomsterk nicaraguansk sigar med ecuadoriansk Connecticut Shade-dekkblad og innblandet pipetobakk, med toner av kaffe, røyk, mørk sjokolade og pepper.'),
  ('Dunbarton Tobacco & Trust','Todos Las Dias','En kraftig nicaraguansk puro med nicaraguansk Sun Grown-dekkblad, med toner av pepper, jord, tobakk, kakao og tre.'),
  ('Dunbarton Tobacco & Trust','Umbagog','En mellomsterk nicaraguansk sigar med rustikt Connecticut Broadleaf-dekkblad, med toner av seder, jord, svart pepper, kaffe og bakekrydder.'),
  ('Dunbarton Tobacco & Trust','Unicorns','En kraftig nicaraguansk sigar med mørkt Connecticut Broadleaf-dekkblad, med toner av jord, kaffe, seder, pepper og mokka.'),
  ('Sinistro','El Burro Connecticut','En mild til mellomsterk dominikansk sigar med Connecticut-dekkblad, med kremete toner av seder, nøtter, hvit pepper og jord.'),
  ('Sinistro','El Burro Corojo','En mellomsterk dominikansk sigar med Corojo-dekkblad, med toner av pepper, ristede nøtter, lær og en naturlig sødme.'),
  ('Sinistro','El Burro Maduro','En fyldig dominikansk sigar med San Andrés Maduro-dekkblad, med toner av kakao, pepper, lær, jord og kaffe.'),
  ('Sinistro','Habana Vieja','En mellomsterk dominikansk sigar med Habano-dekkblad, med toner av seder, pepper, tre og en naturlig sødme.'),
  ('Sinistro','Honor Among Thieves','En fyldig dominikansk sigar med Cubra Maduro-dekkblad, med toner av kakao, pepper, lær og mørk frukt.'),
  ('Sinistro','La Fabrica','En mellomsterk til fyldig dominikansk sigar med San Andrés Maduro-dekkblad, med toner av kakao, jord, pepper, kaffe og lær.'),
  ('Sinistro','Last Cowboy Maduro','En fyldig dominikansk sigar med Connecticut Broadleaf Maduro-dekkblad, med toner av kakao, kaffe, pepper og tre.'),
  ('Sinistro','Last Cowboy Natural','En mellomsterk dominikansk sigar med Connecticut-dekkblad, med toner av kaffe, vanilje og jord.'),
  ('Sinistro','Mr. Black','En fyldig dominikansk sigar med Habano-dekkblad, med toner av ristede nøtter, kakao, krydder, karamell og fløte.'),
  ('Sinistro','Mr. Desflorado','En mild til mellomsterk dominikansk sigar med Desflorado Connecticut-dekkblad, med toner av honning, fløte, floral sødme, ristede nøtter og hvit pepper.'),
  ('Sinistro','Mr. Red','En mellomsterk til fyldig dominikansk sigar med San Andrés Maduro-dekkblad, med toner av kaffe, sjokolade, ristede nøtter, fløte og hvit pepper.'),
  ('Sinistro','Mr. White','En mild til mellomsterk dominikansk sigar med HVA-dekkblad, med kremete toner av nøtter, seder og et snev av krydder.'),
  ('Sinistro','Mr. White Gold Edition','En mellomsterk dominikansk sigar med Connecticut Broadleaf Maduro-dekkblad, med toner av kakao, kaffe, tre og en naturlig sødme.'),
  ('Sinistro','NV','En mellomsterk til fyldig dominikansk sigar med Corojo Maduro-dekkblad, med toner av fløte, svart pepper, tre, nøtter og jord.'),
  ('Sinistro','The Last Barbarian','En fyldig dominikansk sigar med Maduro-dekkblad, med toner av tobakk, seder, lær, pepper og eik.'),
  ('Sinistro','Year of the Cowboy Maduro','En fyldig dominikansk sigar med Connecticut Broadleaf Maduro-dekkblad, med toner av melasse, kaffe, eik, svart pepper og jord.'),
  ('Sinistro','Year of the Cowboy Natural','En mellomsterk dominikansk sigar med Connecticut-dekkblad, med toner av seder, vanilje, høy, krydder og karamell.')
) AS d(brand,series,x)
WHERE c.brand=d.brand AND c.series=d.series AND coalesce(c.is_public,true)=true
  AND (c.description IS NULL OR length(trim(c.description))=0);
