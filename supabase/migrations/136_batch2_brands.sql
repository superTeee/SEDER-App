-- 136: Batch 2 — 18 premiummerker fra masterliste-kryssjekk 2026.
-- Blend fra produsent der publisert; størrelser fra produsent/presse/forhandler.
-- Tomme felt der produsenten ikke oppgir data. Opphavsland per linje der det avviker.

-- Meerapfel
WITH l(series,wc,wl,binder,filler,strength,co,man,tier,url,descr) AS (VALUES
('Richard', 'Cameroon', 'Cameroon', NULL::text, NULL::text[], 2, 'Dominican Republic', 'Meerapfel Cigar', 'retailer', 'https://halfwheel.com/meerapfel-cigar-richard-double-robusto/421332/', 'Meerapfels første linje, en mild til medium sigar med vintage Cameroon-dekkblad kjent for elegant og forfinet karakter.'),
('Meir', 'Cameroon', 'Cameroon', NULL::text, NULL::text[], 3, 'Dominican Republic', 'Meerapfel Cigar', 'retailer', 'https://halfwheel.com/meerapfel-meir-robusto/423984/', 'En medium-kraftig sigar med vintage Cameroon-dekkblad, med toner av seder, eik, sjokolade og valnøtt.'),
('Ernest', 'Cameroon', 'Cameroon', NULL::text, NULL::text[], 3, 'Dominican Republic', 'Meerapfel Cigar', 'retailer', 'https://halfwheel.com/meerapfel-cigar-ernest-lonsdale/437891/', 'En medium sigar med vintage Cameroon-dekkblad, en mer eventyrlig og fyldig blanding med toner av grapefrukt, jord og naturlig tobakk.')
),
v(series,vitola,shape,len,ring) AS (VALUES
('Richard', 'Robusto', 'Parejo', 4.875, 50),
('Richard', 'Corona Gorda', 'Parejo', 5.5, 46),
('Richard', 'Double Robusto', 'Parejo', 5.75, 52),
('Richard', 'Pyramide', 'Figurado', 6.125, 52),
('Richard', 'Lonsdale', 'Parejo', 6.75, 43),
('Richard', 'Churchill', 'Parejo', 7.0, 47),
('Richard', 'Lancero', 'Parejo', 7.5, 40),
('Meir', 'Robusto', 'Parejo', 4.875, 50),
('Meir', 'Corona Gorda', 'Parejo', 5.5, 46),
('Meir', 'Double Robusto', 'Parejo', 5.75, 52),
('Meir', 'Pyramid', 'Figurado', 6.125, 52),
('Meir', 'Lonsdale', 'Parejo', 6.75, 43),
('Meir', 'Churchill', 'Parejo', 7.0, 47),
('Ernest', 'Robusto', 'Parejo', 4.875, 50),
('Ernest', 'Corona Gorda', 'Parejo', 5.5, 46),
('Ernest', 'Double Robusto', 'Parejo', 5.75, 52),
('Ernest', 'Lonsdale', 'Parejo', 6.75, 43),
('Ernest', 'Lancero', 'Parejo', 7.5, 40)
)
INSERT INTO public.cigars
  (brand,series,vitola,wrapper_country,wrapper_leaf,binder,filler,strength,
   country_origin,manufacturer,shape,common_format,description,is_public,
   source_tier,source_url,verified_at,aliases)
SELECT 'Meerapfel', l.series, v.vitola, l.wc, l.wl, l.binder, l.filler, l.strength,
       l.co, l.man, v.shape, v.vitola, l.descr, true,
       CASE WHEN l.tier='press' THEN 'retailer' ELSE l.tier END, l.url, now(), ARRAY['Meerapfel']
FROM l JOIN v USING(series);

-- Lost & Found
WITH l(series,wc,wl,binder,filler,strength,co,man,tier,url,descr) AS (VALUES
('Instant Classic Habano', NULL::text, 'Habano', 'Indonesia', ARRAY['Dominican Republic'], 4, 'Dominican Republic', 'Lost & Found', 'retailer', 'https://www.smokingpipes.com/cigars/lost-and-found/', 'En medium til fyldig dominikansk sigar med habano-dekkblad, indonesisk omblad og dominikansk innlegg, lagret før salg.'),
('Instant Classic San Andrés', 'Mexico', 'San Andrés', 'Dominican Republic', ARRAY['Dominican Republic','Nicaragua'], 4, 'Dominican Republic', 'Lost & Found', 'retailer', 'https://www.smokingpipes.com/cigars/lost-and-found/', 'En kraftig, mørk sigar med meksikansk San Andrés-dekkblad, dominikansk omblad og innlegg fra DR og Nicaragua.'),
('22 Minutes to Midnight Habano', NULL::text, 'Habano', NULL::text, NULL::text[], 3, 'Dominican Republic', 'Lost & Found', 'retailer', 'https://www.smokingpipes.com/cigars/lost-and-found/', 'En mild til medium sigar med habano-dekkblad og en hemmelig blanding av godt lagret tobakk, rullet på El Maestro i DR.'),
('22 Minutes to Midnight Criollo', NULL::text, 'Criollo', NULL::text, NULL::text[], 3, 'Dominican Republic', 'Lost & Found', 'retailer', 'https://www.smokingpipes.com/cigars/lost-and-found/', 'En medium sigar med criollo-dekkblad og en hemmelig, godt lagret blanding, ekstra lagret to år.')
),
v(series,vitola,shape,len,ring) AS (VALUES
('Instant Classic Habano', 'Robusto', 'Parejo', 5.0, 50),
('Instant Classic Habano', 'Toro', 'Parejo', 6.75, 50),
('Instant Classic San Andrés', 'Corona', 'Parejo', 6.0, 46),
('Instant Classic San Andrés', 'Torpedo', 'Figurado', 6.0, 52),
('22 Minutes to Midnight Habano', 'Toro', 'Parejo', 6.0, 52),
('22 Minutes to Midnight Criollo', 'Robusto', 'Parejo', 5.5, 50)
)
INSERT INTO public.cigars
  (brand,series,vitola,wrapper_country,wrapper_leaf,binder,filler,strength,
   country_origin,manufacturer,shape,common_format,description,is_public,
   source_tier,source_url,verified_at,aliases)
SELECT 'Lost & Found', l.series, v.vitola, l.wc, l.wl, l.binder, l.filler, l.strength,
       l.co, l.man, v.shape, v.vitola, l.descr, true,
       CASE WHEN l.tier='press' THEN 'retailer' ELSE l.tier END, l.url, now(), ARRAY['Lost & Found','Lost and Found']
FROM l JOIN v USING(series);

-- Dapper
WITH l(series,wc,wl,binder,filler,strength,co,man,tier,url,descr) AS (VALUES
('El Borracho', 'Mexico', 'San Andrés', 'Nicaragua', ARRAY['Nicaragua'], 3, 'Nicaragua', 'Aganorsa Leaf', 'manufacturer', 'https://dappercigars.com/cigars/el-borracho/', 'En mellomkraftig nicaraguansk sigar med meksikansk San Andrés-dekkblad, jordaktige, søtlige og krydrede toner, laget hos Aganorsa Leaf.'),
('El Borracho Maduro', 'United States', 'Connecticut Broadleaf', 'Nicaragua', ARRAY['Nicaragua'], 4, 'Nicaragua', 'Aganorsa Leaf', 'manufacturer', 'https://dappercigars.com/cigars/el-borracho-maduro/', 'En kraftig maduro-utgave med Connecticut Broadleaf-dekkblad og dype smaker av mørk sjokolade, kaffe og pepper.'),
('La Madrina', 'Ecuador', 'Habano', 'Mexico', ARRAY['Nicaragua','Dominican Republic','United States'], 5, 'Nicaragua', 'Aganorsa Leaf', 'manufacturer', 'https://dappercigars.com/cigars/la-madrina/', 'Dappers kraftigste kjernelinje med ecuadoriansk habano-dekkblad og intense smaker av pepper, mørk sjokolade og krydder.'),
('La Madrina Shade', 'Ecuador', 'Connecticut Desflorado', NULL::text, ARRAY['Nicaragua','Dominican Republic','United States'], 4, 'Nicaragua', 'Aganorsa Leaf', 'manufacturer', 'https://dappercigars.com/cigars/la-madrina-shade/', 'En mildere Connecticut shade-utgave med kremete, nøtteaktige og lett pepprede toner, men fortsatt god fylde.'),
('Cubo Sumatra', 'Ecuador', 'Sumatra Rosado', 'Nicaragua', ARRAY['Nicaragua','United States'], 3, 'Nicaragua', 'Aganorsa Leaf', 'manufacturer', 'https://dappercigars.com/cigars/cubo-sumatra/', 'En mellomkraftig sigar med ecuadoriansk Sumatra Rosado-dekkblad og balanserte smaker av kaffe, nøtter og mild krydder.'),
('Desvalido', 'Ecuador', 'Habano Rosado', 'United States', ARRAY['Nicaragua','United States'], 4, 'Nicaragua', 'Aganorsa Leaf', 'manufacturer', 'https://dappercigars.com/cigars/desvalido/', 'En kraftig sigar med ecuadoriansk Habano Rosado-dekkblad og rike, krydrede og søtlige toner av kaffe og mørk frukt.'),
('Siempre', 'Ecuador', 'Sumatra', 'United States', ARRAY['Nicaragua','Honduras'], 3, 'Nicaragua', 'Aganorsa Leaf', 'manufacturer', 'https://dappercigars.com/cigars/siempre/', 'En mellomkraftig sigar med ecuadoriansk soldyrket Sumatra-dekkblad og en jevn, avrundet røyk med nøtter, kaffe og krydder.'),
('Cubata Cru Shade', 'Ecuador', 'Connecticut Desflorado', 'Nicaragua', ARRAY['Nicaragua','Dominican Republic'], 2, 'Nicaragua', 'Aganorsa Leaf', 'manufacturer', 'https://dappercigars.com/cigars/cubata-cru-shade/', 'En mild til mellomkraftig Connecticut shade-sigar med milde, kremete og nøtteaktige smaker.'),
('Union Break', 'Ecuador', 'Connecticut', 'Nicaragua', ARRAY['Nicaragua'], 3, 'Nicaragua', 'Aganorsa Leaf', 'manufacturer', 'https://dappercigars.com/cigars/union-break/', 'En liten mellomkraftig sigar (4×38) som fås med Connecticut shade, Connecticut Broadleaf eller barberpole-dekkblad.')
),
v(series,vitola,shape,len,ring) AS (VALUES
('El Borracho', 'Robusto', 'Parejo', 5.0, 50),
('El Borracho', 'Edmundo', 'Parejo', 5.5, 52),
('El Borracho', 'Toro', 'Parejo', 6.0, 54),
('El Borracho', 'Belicoso', 'Figurado', 6.25, 52),
('El Borracho Maduro', 'Robusto', 'Parejo', 5.0, 50),
('El Borracho Maduro', 'Edmundo', 'Parejo', 5.5, 52),
('El Borracho Maduro', 'Toro', 'Parejo', 6.0, 54),
('El Borracho Maduro', 'Belicoso', 'Figurado', 6.25, 52),
('La Madrina', 'Robusto', 'Parejo', 5.0, 50),
('La Madrina', 'Toro', 'Parejo', 6.125, 52),
('La Madrina', 'Belicoso', 'Figurado', 6.25, 52),
('La Madrina', 'Corona Gorda', 'Parejo', 5.625, 46),
('La Madrina Shade', 'Robusto', 'Parejo', 5.0, 50),
('La Madrina Shade', 'Toro', 'Parejo', 6.125, 52),
('La Madrina Shade', 'Belicoso', 'Figurado', 6.25, 52),
('La Madrina Shade', 'Corona Gorda', 'Parejo', 5.625, 46),
('Cubo Sumatra', 'Corona Gorda', 'Parejo', 5.625, 46),
('Cubo Sumatra', 'Robusto', 'Parejo', 5.0, 50),
('Cubo Sumatra', 'Toro', 'Parejo', 6.125, 52),
('Cubo Sumatra', 'Toro Grande', 'Parejo', 6.0, 54),
('Desvalido', 'Lonsdale', 'Parejo', 6.5, 46),
('Desvalido', 'Robusto', 'Parejo', 5.0, 50),
('Desvalido', 'Toro', 'Parejo', 6.125, 52),
('Desvalido', 'Corona Doble', 'Parejo', 6.75, 54),
('Siempre', 'Rothchilds', 'Parejo', 4.5, 50),
('Siempre', 'Robusto', 'Parejo', 5.0, 50),
('Siempre', 'Corona Gorda', 'Parejo', 5.625, 46),
('Siempre', 'Toro', 'Parejo', 6.125, 52),
('Siempre', 'Toro Grande', 'Parejo', 6.0, 54),
('Cubata Cru Shade', 'Bucko', 'Parejo', 6.0, 44),
('Cubata Cru Shade', 'Blunderbuss', 'Parejo', 5.0, 54),
('Cubata Cru Shade', 'Bumbo', 'Parejo', 6.125, 52),
('Union Break', 'Connecticut Shade', 'Parejo', 4.0, 38),
('Union Break', 'Connecticut Broadleaf', 'Parejo', 4.0, 38),
('Union Break', 'Barberpole', 'Parejo', 4.0, 38)
)
INSERT INTO public.cigars
  (brand,series,vitola,wrapper_country,wrapper_leaf,binder,filler,strength,
   country_origin,manufacturer,shape,common_format,description,is_public,
   source_tier,source_url,verified_at,aliases)
SELECT 'Dapper', l.series, v.vitola, l.wc, l.wl, l.binder, l.filler, l.strength,
       l.co, l.man, v.shape, v.vitola, l.descr, true,
       CASE WHEN l.tier='press' THEN 'retailer' ELSE l.tier END, l.url, now(), ARRAY['Dapper']
FROM l JOIN v USING(series);

-- Black Works Studio
WITH l(series,wc,wl,binder,filler,strength,co,man,tier,url,descr) AS (VALUES
('NBK', 'Ecuador', 'Habano Oscuro', 'Nicaragua', ARRAY['Nicaragua'], 4, 'Nicaragua', 'Fabrica Oveja Negra', 'retailer', 'https://atlanticcigar.com/black-works-studio-nbk-robusto-5x50/', 'En kraftig, boks-presset nikaraguansk sigar med ecuadoriansk Habano Oscuro-dekkblad, mørk, pepret og fyldig.'),
('Green Hornet', 'Ecuador', 'Candela', 'Nicaragua', ARRAY['Nicaragua'], 3, 'Nicaragua', 'Fabrica Oveja Negra', 'retailer', 'https://halfwheel.com/black-works-studio-green-hornet-lancero/403363/', 'En Killer Bee-variant med ecuadoriansk maduro- og candela-dekkblad, middels-kraftig, urteaktig og søtlig.'),
('Killer Bee', 'Ecuador', 'Maduro', 'Nicaragua', ARRAY['Nicaragua'], 4, 'Nicaragua', 'Fabrica Oveja Negra', 'retailer', 'https://cigar-coop.com/2016/05/cigar-review-black-works-studio-killer-bee.html', 'En liten perfecto med ecuadoriansk maduro-dekkblad som leverer konsentrert, kraftig og krydret smak.'),
('Hyena', 'Cameroon', 'Cameroon', 'Nicaragua', ARRAY['Nicaragua'], 3, 'Nicaragua', 'Fabrica Oveja Negra', 'retailer', 'https://cigar-coop.com/2021/09/cigar-review-black-works-studio-hyena-corona-gorda.html', 'En nikaraguansk sigar i Cameroon-dekkblad, middels-kraftig med nøtter, krydder og pepper.'),
('Boondock Saint', 'United States', 'Pennsylvania Broadleaf', 'Nicaragua', ARRAY['Nicaragua','United States'], 4, 'Nicaragua', 'Fabrica Oveja Negra', 'retailer', 'https://cigar-coop.com/2017/10/cigar-review-black-works-studio-boondock-saint-corona-larga.html', 'En kraftig sigar med Pennsylvania Broadleaf-dekkblad, jordaktig sødme og pepper.'),
('Rorschach', 'Ecuador', 'Habano', 'Nicaragua', ARRAY['Nicaragua'], 4, 'Nicaragua', 'Fabrica Oveja Negra', 'retailer', 'https://halfwheel.com/black-works-studio-rorschach/107664/', 'En mørk, kraftig petit lancero med ecuadoriansk Habano-dekkblad, dyp og krydret.')
),
v(series,vitola,shape,len,ring) AS (VALUES
('NBK', 'Corona Larga', 'Parejo', 6.0, 46),
('NBK', 'Robusto', 'Parejo', 5.0, 50),
('Green Hornet', 'Perfecto', 'Figurado', 5.0, 60),
('Green Hornet', 'Lancero', 'Parejo', 7.25, 42),
('Killer Bee', 'Perfecto', 'Figurado', 4.5, 46),
('Hyena', 'Corona Gorda', 'Parejo', 5.0, 46),
('Hyena', 'Lonsdale', 'Parejo', 6.5, 42),
('Boondock Saint', 'Corona Larga', 'Parejo', 6.25, 46),
('Boondock Saint', 'Robusto', 'Parejo', 5.25, 50),
('Rorschach', 'Petit Lancero', 'Parejo', 5.0, 38)
)
INSERT INTO public.cigars
  (brand,series,vitola,wrapper_country,wrapper_leaf,binder,filler,strength,
   country_origin,manufacturer,shape,common_format,description,is_public,
   source_tier,source_url,verified_at,aliases)
SELECT 'Black Works Studio', l.series, v.vitola, l.wc, l.wl, l.binder, l.filler, l.strength,
       l.co, l.man, v.shape, v.vitola, l.descr, true,
       CASE WHEN l.tier='press' THEN 'retailer' ELSE l.tier END, l.url, now(), ARRAY['Black Works Studio','BLK WKS','Black Works']
FROM l JOIN v USING(series);

-- K by Karen Berger
WITH l(series,wc,wl,binder,filler,strength,co,man,tier,url,descr) AS (VALUES
('Connecticut', 'Ecuador', 'Connecticut', 'Nicaragua', ARRAY['Nicaragua'], 2, 'Nicaragua', 'Tabacalera Estelí', 'retailer', 'https://www.neptunecigar.com/cigars/k-by-karen-berger-connecticut-toro', 'En mild til medium boxpresset sigar med ecuadoriansk Connecticut-dekkblad, med toner av seder, mandler, sitrus og sødme.'),
('Cameroon', 'Cameroon', 'Cameroon', 'Nicaragua', ARRAY['Nicaragua'], 3, 'Nicaragua', 'Tabacalera Estelí', 'retailer', 'https://halfwheel.com/k-by-karen-berger-cameroon-robusto/401037/', 'En medium boxpresset sigar med Cameroon-dekkblad og nicaraguansk bind og innmat.'),
('Habano', 'Nicaragua', 'Habano', 'Nicaragua', ARRAY['Nicaragua'], 3, 'Nicaragua', 'Tabacalera Estelí', 'retailer', 'https://www.neptunecigar.com/cigars/k-by-karen-berger-habano-toro', 'En medium sigar med nicaraguansk Habano-dekkblad, med toner av krydder, seder, kaffe og sødme.'),
('Maduro', 'Nicaragua', 'Maduro', 'Nicaragua', ARRAY['Nicaragua'], 4, 'Nicaragua', 'Tabacalera Estelí', 'retailer', 'https://www.neptunecigar.com/cigars/k-by-karen-berger-maduro-toro', 'En medium-fyldig boxpresset sigar med mørkt, oljet nicaraguansk Maduro-dekkblad, med mørk sjokolade, lær, krydder og sødme.')
),
v(series,vitola,shape,len,ring) AS (VALUES
('Connecticut', 'Robusto', 'Parejo', 5.0, 52),
('Connecticut', 'Toro', 'Parejo', 6.0, 52),
('Cameroon', 'Robusto', 'Parejo', 5.0, 52),
('Cameroon', 'Toro', 'Parejo', 6.0, 52),
('Habano', 'Robusto', 'Parejo', 5.0, 52),
('Habano', 'Toro', 'Parejo', 6.0, 52),
('Maduro', 'Robusto', 'Parejo', 5.0, 52),
('Maduro', 'Toro', 'Parejo', 6.0, 52)
)
INSERT INTO public.cigars
  (brand,series,vitola,wrapper_country,wrapper_leaf,binder,filler,strength,
   country_origin,manufacturer,shape,common_format,description,is_public,
   source_tier,source_url,verified_at,aliases)
SELECT 'K by Karen Berger', l.series, v.vitola, l.wc, l.wl, l.binder, l.filler, l.strength,
       l.co, l.man, v.shape, v.vitola, l.descr, true,
       CASE WHEN l.tier='press' THEN 'retailer' ELSE l.tier END, l.url, now(), ARRAY['K by Karen Berger','Karen Berger']
FROM l JOIN v USING(series);

-- Kafie 1901
WITH l(series,wc,wl,binder,filler,strength,co,man,tier,url,descr) AS (VALUES
('Maduro', 'Nicaragua', 'Habano Maduro', 'Cameroon', ARRAY['Dominican Republic','Nicaragua','Pennsylvania'], 4, 'Dominican Republic', 'Kafie 1901 Cigars', 'manufacturer', 'https://kafiecigars.com/core-line-cigars/', 'Kafie 1901s opprinnelige flaggskip, en fyldig maduro med nicaraguansk habano-dekkblad og sjelden dominikansk andullo-tobakk.'),
('Connecticut', 'Ecuador', 'Connecticut Shade', 'Dominican Republic', ARRAY['Dominican Republic'], 2, 'Dominican Republic', 'Kafie 1901 Cigars', 'manufacturer', 'https://kafiecigars.com/core-line-cigars/', 'Merkets bestselger, en mild og kremet Ecuador Connecticut-sigar rullet hos La Aurora med minst fire års lagret tobakk.'),
('Sumatra', 'Ecuador', 'Sumatra', 'Dominican Republic', ARRAY['Dominican Republic','Nicaragua'], 4, 'Dominican Republic', 'Kafie 1901 Cigars', 'manufacturer', 'https://kafiecigars.com/core-line-cigars/', 'En middels til fyldig sigar med solmodnet Ecuador Sumatra-dekkblad og krydrede, søte toner av kanel og vanilje.'),
('San Andrés', 'Mexico', 'San Andrés', 'Nicaragua', ARRAY['Nicaragua'], 4, 'Dominican Republic', 'Kafie 1901 Cigars', 'manufacturer', 'https://kafiecigars.com/core-line-cigars/', 'En fyldig sigar med dobbeltfermentert meksikansk San Andrés-dekkblad og nicaraguansk innmat, med kaffe, kakao og melasse.'),
('Serie L Natural', 'Dominican Republic', 'Corojo', NULL::text, ARRAY['Dominican Republic'], NULL::numeric, 'Dominican Republic', 'Kafie 1901 Cigars', 'manufacturer', 'https://kafiecigars.com/core-line-cigars/', 'En helt dominikansk sigar fra La Aurora med fire år lagret Cibao-corojo dekkblad.'),
('Don Kiki Brown Label', 'Nicaragua', 'Criollo', 'Corojo', ARRAY['Nicaragua'], 4, 'Nicaragua', 'Kafie 1901 Cigars', 'retailer', 'https://cccrafter.com/don-kiki-brown-label-figurado-cigars-4-x-52-cigars/', 'Den kraftigste Don Kiki-en, en middels til fyldig nicaraguansk sigar av cubansk-frø corojo og criollo, med kakao, lær og krydder.'),
('Don Kiki Green Label', NULL::text, 'Claro', 'Nicaragua', ARRAY['Nicaragua'], 2, 'Nicaragua', 'Kafie 1901 Cigars', 'retailer', 'https://cccrafter.com/don-kiki-green-label/', 'En mild, velbalansert nicaraguansk sigar med kremete nougattoner, av lagret cubansk-frø habano-tobakk.'),
('Don Kiki White Label', 'Ecuador', 'Connecticut Shade', NULL::text, ARRAY['Nicaragua'], 2, 'Nicaragua', 'Kafie 1901 Cigars', 'retailer', 'https://cccrafter.com/don-kiki-white-label-toro-cigars-6-x-52/', 'En mild nicaraguansk sigar med ecuadoriansk Connecticut-dekkblad og toner av seder, søt muskatnøtt og kremet røyk.')
),
v(series,vitola,shape,len,ring) AS (VALUES
('Maduro', 'Robusto', 'Parejo', 5.0, 50),
('Maduro', 'Toro', 'Parejo', 5.75, 54),
('Maduro', 'Belicoso', 'Figurado', 6.25, 52),
('Maduro', 'Churchill', 'Parejo', 7.0, 47),
('Maduro', 'Gran Toro', 'Parejo', 6.0, 58),
('Connecticut', 'Robusto', 'Parejo', 5.0, 50),
('Connecticut', 'Toro', 'Parejo', 5.75, 54),
('Connecticut', 'Belicoso', 'Figurado', 6.25, 52),
('Connecticut', 'Churchill', 'Parejo', 7.0, 47),
('Connecticut', 'Gran Toro', 'Parejo', 6.0, 58),
('Sumatra', 'Robusto', 'Parejo', 5.0, 50),
('Sumatra', 'Toro', 'Parejo', 5.75, 54),
('Sumatra', 'Belicoso', 'Figurado', 6.25, 52),
('Sumatra', 'Churchill', 'Parejo', 7.0, 47),
('Sumatra', 'Gran Toro', 'Parejo', 6.0, 58),
('San Andrés', 'Robusto', 'Parejo', 5.0, 50),
('San Andrés', 'Toro', 'Parejo', 5.75, 54),
('San Andrés', 'Belicoso', 'Figurado', 6.25, 52),
('San Andrés', 'Churchill', 'Parejo', 7.0, 47),
('San Andrés', 'Gran Toro', 'Parejo', 6.0, 58),
('Serie L Natural', 'Robusto', 'Parejo', 5.0, 50),
('Serie L Natural', 'Toro', 'Parejo', 5.75, 54),
('Serie L Natural', 'Belicoso', 'Figurado', 6.25, 52),
('Serie L Natural', 'Churchill', 'Parejo', 7.0, 47),
('Serie L Natural', 'Gran Toro', 'Parejo', 6.0, 58),
('Don Kiki Brown Label', 'Figurado', 'Figurado', 4.5, 52),
('Don Kiki Brown Label', 'Toro', 'Parejo', 6.0, 52),
('Don Kiki Brown Label', 'Torpedo', 'Figurado', 6.0, 54),
('Don Kiki Green Label', 'Robusto', 'Parejo', 5.0, 52),
('Don Kiki Green Label', 'Toro', 'Parejo', 6.0, 52),
('Don Kiki Green Label', 'Churchill', 'Parejo', 7.0, 52),
('Don Kiki Green Label', 'Torpedo', 'Figurado', 6.0, 54),
('Don Kiki White Label', 'Toro', 'Parejo', 6.0, 52),
('Don Kiki White Label', 'Churchill', 'Parejo', 7.0, 52),
('Don Kiki White Label', 'Chairman', 'Parejo', 6.0, 60)
)
INSERT INTO public.cigars
  (brand,series,vitola,wrapper_country,wrapper_leaf,binder,filler,strength,
   country_origin,manufacturer,shape,common_format,description,is_public,
   source_tier,source_url,verified_at,aliases)
SELECT 'Kafie 1901', l.series, v.vitola, l.wc, l.wl, l.binder, l.filler, l.strength,
       l.co, l.man, v.shape, v.vitola, l.descr, true,
       CASE WHEN l.tier='press' THEN 'retailer' ELSE l.tier END, l.url, now(), ARRAY['Kafie 1901','Kafie','Don Kiki']
FROM l JOIN v USING(series);

-- Debonaire
WITH l(series,wc,wl,binder,filler,strength,co,man,tier,url,descr) AS (VALUES
('Habano', 'Nicaragua', 'Habano', 'Dominican Republic', ARRAY['Dominican Republic','Nicaragua'], 3, 'Dominican Republic', 'De Los Reyes Cigars', 'retailer', 'https://mikescigars.com/cigars/brands/debonaire', 'En dominikansk-produsert premiumsigar med nicaraguansk Habano-dekkblad, medium til fyldig, med seder, honning og pepper.'),
('Maduro', 'United States', 'Connecticut Broadleaf', 'Dominican Republic', ARRAY['Nicaragua','Dominican Republic'], 3, 'Dominican Republic', 'De Los Reyes Cigars', 'retailer', 'https://cigar-coop.com/2014/11/cigar-review-debonaire-maduro-toro.html', 'Debonaire Maduro har mørkt Connecticut Broadleaf-dekkblad og en fyldigere, søtlig og krydret røyk.'),
('Daybreak', 'Ecuador', 'Connecticut Shade', 'Dominican Republic', ARRAY['Dominican Republic','Nicaragua'], 2, 'Dominican Republic', 'De Los Reyes Cigars', 'retailer', 'https://cigar-coop.com/2018/02/cigar-review-debonaire-daybreak-corona.html', 'Daybreak er den mildeste linjen med solmodnet ecuadoriansk Connecticut-dekkblad, elegant og nøtteaktig.')
),
v(series,vitola,shape,len,ring) AS (VALUES
('Habano', 'First Degree', 'Parejo', 4.0, 44),
('Habano', 'Robusto', 'Parejo', 5.25, 50),
('Habano', 'Toro', 'Parejo', 6.0, 54),
('Habano', 'Belicoso', 'Figurado', 6.0, 54),
('Maduro', 'First Degree', 'Parejo', 4.0, 44),
('Maduro', 'Sagita', 'Parejo', 5.5, 38),
('Maduro', 'Robusto', 'Parejo', 5.25, 50),
('Maduro', 'Belicoso', 'Figurado', 6.0, 54),
('Maduro', 'Toro', 'Parejo', 6.0, 54),
('Daybreak', 'First Degree', 'Parejo', 4.0, 44),
('Daybreak', 'Sagita', 'Parejo', 5.5, 38),
('Daybreak', 'Corona', 'Parejo', 6.0, 46),
('Daybreak', 'Robusto', 'Parejo', 5.0, 50),
('Daybreak', 'Toro', 'Parejo', 6.0, 50),
('Daybreak', 'Belicoso', 'Figurado', 6.0, 54)
)
INSERT INTO public.cigars
  (brand,series,vitola,wrapper_country,wrapper_leaf,binder,filler,strength,
   country_origin,manufacturer,shape,common_format,description,is_public,
   source_tier,source_url,verified_at,aliases)
SELECT 'Debonaire', l.series, v.vitola, l.wc, l.wl, l.binder, l.filler, l.strength,
       l.co, l.man, v.shape, v.vitola, l.descr, true,
       CASE WHEN l.tier='press' THEN 'retailer' ELSE l.tier END, l.url, now(), ARRAY['Debonaire']
FROM l JOIN v USING(series);

-- Hiram & Solomon
WITH l(series,wc,wl,binder,filler,strength,co,man,tier,url,descr) AS (VALUES
('Traveling Man', 'Indonesia', 'Sumatra', 'Indonesia', ARRAY['Brazil','Nicaragua','Dominican Republic'], 3, 'Nicaragua', 'Plasencia Cigars', 'manufacturer', 'https://www.hiramandsolomoncigars.com/our-cigars/traveling-man/', 'En mellomsterk firenasjoners blanding med indonesisk sumatra-dekkblad, kaffe- og krydderpreg med kremet avslutning.'),
('Master Mason', NULL::text, 'Habano Maduro Oscuro', 'Indonesia', ARRAY['Nicaragua'], 5, 'Nicaragua', 'Plasencia Cigars', 'retailer', 'https://www.neptunecigar.com/cigars/hiram-solomon-master-mason-gran-toro', 'En fyldig maduro med mørkt Habano Oscuro-dekkblad og nicaraguansk fyll, med søtt lær, kakao og seder.'),
('Fellow Craft', 'Honduras', 'Habano Oscuro', 'Indonesia', ARRAY['Nicaragua'], 4, 'Nicaragua', 'Plasencia Cigars', 'manufacturer', 'https://www.hiramandsolomoncigars.com/our-cigars/fellow-craft/', 'En mellomsterk til fyldig sigar med honduransk Habano Oscuro-dekkblad og nicaraguansk Estelí-ligero-fyll.'),
('Shriner', 'Ecuador', 'Sumatra', 'Indonesia', ARRAY['Brazil','Nicaragua','Dominican Republic'], NULL::numeric, 'Nicaragua', 'Plasencia Cigars', 'manufacturer', 'https://www.hiramandsolomoncigars.com/our-cigars/shriner/', 'En sigar med ecuadoriansk sumatra-dekkblad og en firenasjoners fyll med krydder- og kaffetoner.'),
('Entered Apprentice', 'Honduras', 'Connecticut Shade', 'Honduras', ARRAY['Nicaragua','United States','Paraguay'], 2, 'Nicaragua', 'Plasencia Cigars', 'manufacturer', 'https://www.hiramandsolomoncigars.com/our-cigars/entered-apprentice/', 'En mild til mellomsterk sigar med Connecticut Shade-dekkblad, kremet og silkeaktig med hvit pepper og kanel.'),
('Grand Architect', 'Nicaragua', 'Corojo', 'Nicaragua', ARRAY['Paraguay','Nicaragua'], 4, 'Nicaragua', 'Plasencia Cigars', 'retailer', 'https://halfwheel.com/hiram-solomon-cigars-releases-the-grand-architect/336125/', 'En mellomsterk til fyldig sigar med nicaraguansk corojo-dekkblad og paraguayansk fyllblad, med sitrus, kanelkrydder og seder.'),
('Veiled Prophet', 'Brazil', 'Arapiraca Colorado', 'Indonesia', ARRAY['Nicaragua','Paraguay'], NULL::numeric, 'Nicaragua', 'Plasencia Cigars', 'retailer', 'https://halfwheel.com/hiram-solomon-veiled-prophet-lancero/378715/', 'En sigar med brasiliansk Arapiraca colorado-dekkblad og nicaraguansk-paraguayansk fyll, med seder, kaffe, karamell og pepper.')
),
v(series,vitola,shape,len,ring) AS (VALUES
('Traveling Man', 'Robusto', 'Parejo', 5.5, 50),
('Traveling Man', 'Toro', 'Parejo', 6.0, 52),
('Traveling Man', 'Torpedo', 'Figurado', 6.0, 54),
('Traveling Man', 'Gran Toro', 'Parejo', 6.0, 60),
('Master Mason', 'Robusto', 'Parejo', 5.0, 52),
('Master Mason', 'Toro', 'Parejo', 6.0, 52),
('Master Mason', 'Gran Toro', 'Parejo', 6.0, 60),
('Fellow Craft', 'Gavel', 'Parejo', 5.0, 60),
('Fellow Craft', 'Robusto', 'Parejo', 5.5, 50),
('Fellow Craft', 'Toro', 'Parejo', 6.0, 52),
('Fellow Craft', 'Gran Toro', 'Parejo', 6.0, 60),
('Shriner', 'Petit Corona', 'Parejo', 5.5, 42),
('Shriner', 'Robusto', 'Parejo', 5.5, 50),
('Shriner', 'Toro', 'Parejo', 6.0, 52),
('Shriner', 'Gran Toro', 'Parejo', 6.0, 60),
('Entered Apprentice', 'Gavel', 'Parejo', 5.0, 60),
('Entered Apprentice', 'Robusto', 'Parejo', 5.5, 50),
('Entered Apprentice', 'Toro', 'Parejo', 6.0, 52),
('Entered Apprentice', 'Gran Toro', 'Parejo', 6.0, 60),
('Grand Architect', 'Robusto', 'Parejo', 5.0, 50),
('Grand Architect', 'Toro', 'Parejo', 6.0, 52),
('Grand Architect', 'Gran Toro', 'Parejo', 6.0, 60),
('Veiled Prophet', 'Monarch', 'Parejo', 6.0, 54),
('Veiled Prophet', 'Grand Monarch', 'Parejo', 7.0, 60),
('Veiled Prophet', 'Lancero', 'Parejo', 7.0, 38)
)
INSERT INTO public.cigars
  (brand,series,vitola,wrapper_country,wrapper_leaf,binder,filler,strength,
   country_origin,manufacturer,shape,common_format,description,is_public,
   source_tier,source_url,verified_at,aliases)
SELECT 'Hiram & Solomon', l.series, v.vitola, l.wc, l.wl, l.binder, l.filler, l.strength,
       l.co, l.man, v.shape, v.vitola, l.descr, true,
       CASE WHEN l.tier='press' THEN 'retailer' ELSE l.tier END, l.url, now(), ARRAY['Hiram & Solomon','Hiram and Solomon']
FROM l JOIN v USING(series);

-- West Tampa Tobacco
WITH l(series,wc,wl,binder,filler,strength,co,man,tier,url,descr) AS (VALUES
('Red', 'Mexico', 'San Andrés', 'Nicaragua', ARRAY['Nicaragua'], 3, 'Nicaragua', 'Garmendia Cigars', 'retailer', 'https://halfwheel.com/west-tampa-tobacco-co-red-toro/428145/', 'En medium til nesten fyldig sigar med meksikansk San Andrés-dekkblad og nicaraguansk innmat, laget hos Garmendia i Estelí.'),
('White', 'Ecuador', 'Habano', 'Nicaragua', ARRAY['Nicaragua'], 2, 'Nicaragua', 'Garmendia Cigars', 'retailer', 'https://halfwheel.com/west-tampa-tobacco-co-white-toro/413234/', 'En mild sigar med ecuadoriansk Habano-dekkblad og nicaraguansk innmat, den mildeste i serien.'),
('Black', 'Ecuador', 'Habano', 'Nicaragua', ARRAY['Nicaragua'], 4, 'Nicaragua', 'Garmendia Cigars', 'retailer', 'https://halfwheel.com/west-tampa-tobacco-co-black-robusto/413190/', 'En medium-fyldig sigar med ecuadoriansk Habano-dekkblad av høyere priming og nicaraguansk innmat.')
),
v(series,vitola,shape,len,ring) AS (VALUES
('Red', 'Robusto', 'Parejo', 5.0, 50),
('Red', 'Toro', 'Parejo', 6.0, 52),
('Red', 'Gigante', 'Parejo', 6.0, 60),
('Red', 'Lancero', 'Parejo', 7.0, 40),
('White', 'Robusto', 'Parejo', 5.0, 50),
('White', 'Toro', 'Parejo', 6.0, 52),
('White', 'Gigante', 'Parejo', 6.0, 60),
('White', 'Lancero', 'Parejo', 7.0, 40),
('Black', 'Robusto', 'Parejo', 5.0, 50),
('Black', 'Toro', 'Parejo', 6.0, 52),
('Black', 'Gigante', 'Parejo', 6.0, 60),
('Black', 'Lancero', 'Parejo', 7.0, 40)
)
INSERT INTO public.cigars
  (brand,series,vitola,wrapper_country,wrapper_leaf,binder,filler,strength,
   country_origin,manufacturer,shape,common_format,description,is_public,
   source_tier,source_url,verified_at,aliases)
SELECT 'West Tampa Tobacco', l.series, v.vitola, l.wc, l.wl, l.binder, l.filler, l.strength,
       l.co, l.man, v.shape, v.vitola, l.descr, true,
       CASE WHEN l.tier='press' THEN 'retailer' ELSE l.tier END, l.url, now(), ARRAY['West Tampa Tobacco','West Tampa']
FROM l JOIN v USING(series);

-- Tabanero
WITH l(series,wc,wl,binder,filler,strength,co,man,tier,url,descr) AS (VALUES
('Habano', 'Ecuador', 'Habano 2000', 'Ecuador', ARRAY['Nicaragua','Ecuador'], 2, 'Nicaragua', 'Tabanero Cigars', 'manufacturer', 'https://tabanerocigars.com/collections/cigars/products/robusto', 'Tabaneros kjernelinje med ecuadoriansk soldyrket Habano 2000-dekkblad, jevn, kremet og lett krydret.'),
('Connecticut', 'United States', 'Connecticut Shade', 'Ecuador', ARRAY['Nicaragua','Ecuador'], 2, 'Nicaragua', 'Tabanero Cigars', 'manufacturer', 'https://tabanerocigars.com/products/robusto-connecticut', 'En mild og kremet linje med amerikansk Connecticut Shade-dekkblad, perfekt til morgenkaffen.'),
('Momentum Maduro', 'Mexico', 'San Andrés', NULL::text, ARRAY['Nicaragua'], 4, 'Nicaragua', 'Tabanero Cigars', 'manufacturer', 'https://tabanerocigars.com/collections/cigars/products/momentum-robusto-maduro', 'Momentum-linjen har mørkt meksikansk San Andrés Maduro-dekkblad og gir en fyldig røyk med søtlige og jordnære toner.')
),
v(series,vitola,shape,len,ring) AS (VALUES
('Habano', 'Corona', 'Parejo', 5.0, 42),
('Habano', 'Robusto', 'Parejo', 5.0, 50),
('Habano', 'Toro', 'Parejo', 6.0, 52),
('Habano', 'Churchill', 'Parejo', 7.0, 50),
('Habano', 'Torpedo', 'Figurado', 6.5, 54),
('Connecticut', 'Robusto', 'Parejo', 5.0, 50),
('Connecticut', 'Toro', 'Parejo', 6.0, 52),
('Connecticut', 'Churchill', 'Parejo', 7.0, 50),
('Connecticut', 'Big Daddy', 'Parejo', 6.5, 60),
('Momentum Maduro', 'Robusto', 'Parejo', 5.0, 50),
('Momentum Maduro', 'Toro', 'Parejo', 6.0, 52)
)
INSERT INTO public.cigars
  (brand,series,vitola,wrapper_country,wrapper_leaf,binder,filler,strength,
   country_origin,manufacturer,shape,common_format,description,is_public,
   source_tier,source_url,verified_at,aliases)
SELECT 'Tabanero', l.series, v.vitola, l.wc, l.wl, l.binder, l.filler, l.strength,
       l.co, l.man, v.shape, v.vitola, l.descr, true,
       CASE WHEN l.tier='press' THEN 'retailer' ELSE l.tier END, l.url, now(), ARRAY['Tabanero']
FROM l JOIN v USING(series);

-- Topper
WITH l(series,wc,wl,binder,filler,strength,co,man,tier,url,descr) AS (VALUES
('Original Handmade', 'United States', 'Connecticut Broadleaf', 'United States', ARRAY['Dominican Republic','Honduras','Nicaragua'], 3, 'Dominican Republic', 'Topper Cigar Co.', 'retailer', 'https://www.cigaraficionado.com/article/toppers-handmade-once-again-17195', 'Toppers gjeninnførte håndrullede klassiker med mørk Connecticut Broadleaf-dekkblad og en medium, jordaktig firelands-blanding.'),
('1894', 'United States', 'Pennsylvania Habano', 'Dominican Republic', ARRAY['Dominican Republic'], 3, 'Dominican Republic', 'Topper Cigar Co.', 'retailer', 'https://cigar-coop.com/2026/05/pca-2026-topper-cigars.html', 'Jubileumslinjen med sjeldent Habano-frø-dekkblad fra Pennsylvania og dominikansk tobakk, med lær, sedertre og naturlig sødme.'),
('Danli', 'United States', 'Connecticut Broadleaf', 'United States', ARRAY['Honduras','Dominican Republic','United States'], 4, 'Honduras', 'Topper Cigar Co.', 'retailer', 'https://www.famous-smoke.com/brand/topper-danli', 'En fyldig, honduransk-produsert linje med Connecticut Broadleaf-dekkblad og smaker av tre, pepper og sjokolade.')
),
v(series,vitola,shape,len,ring) AS (VALUES
('Original Handmade', 'Breva', 'Parejo', 5.5, 46),
('Original Handmade', 'Grande Corona', 'Parejo', 6.0, 47),
('Original Handmade', 'Ebony', 'Parejo', 5.5, 47),
('Original Handmade', 'Old Fashioned Perfecto', 'Figurado', 4.88, 48),
('1894', 'Shorty', 'Parejo', 4.0, 43),
('1894', 'Corona', 'Parejo', 6.0, 44),
('1894', 'Robusto', 'Parejo', 5.0, 50),
('1894', 'Toro', 'Parejo', 6.0, 54),
('Danli', 'Robusto', 'Parejo', 5.0, 50),
('Danli', 'Toro', 'Parejo', 6.0, 50),
('Danli', 'Belicoso', 'Figurado', 6.0, 54),
('Danli', 'Churchill', 'Parejo', 7.0, 50)
)
INSERT INTO public.cigars
  (brand,series,vitola,wrapper_country,wrapper_leaf,binder,filler,strength,
   country_origin,manufacturer,shape,common_format,description,is_public,
   source_tier,source_url,verified_at,aliases)
SELECT 'Topper', l.series, v.vitola, l.wc, l.wl, l.binder, l.filler, l.strength,
       l.co, l.man, v.shape, v.vitola, l.descr, true,
       CASE WHEN l.tier='press' THEN 'retailer' ELSE l.tier END, l.url, now(), ARRAY['Topper']
FROM l JOIN v USING(series);

-- Falto
WITH l(series,wc,wl,binder,filler,strength,co,man,tier,url,descr) AS (VALUES
('Edición Especial ELH Hato Viejo', 'Cameroon', 'Cameroon', 'Dominican Republic', ARRAY['Dominican Republic'], NULL::numeric, 'Dominican Republic', 'Tabacalera Falto', 'manufacturer', 'https://www.faltocigars.com/en/cigarros', 'En balansert corona gorda med sjokolade-, kaffe- og fløtenoter og fyldig smak.'),
('Lonsdale', 'Ecuador', 'Sumatra', 'Dominican Republic', ARRAY['Dominican Republic'], 3, 'Dominican Republic', 'Tabacalera Falto', 'manufacturer', 'https://www.faltocigars.com/en/cigarros', 'En medium lonsdale med balansert smak og styrke.'),
('Robusto', 'Ecuador', 'Sumatra', 'Dominican Republic', ARRAY['Dominican Republic'], 4, 'Dominican Republic', 'Tabacalera Falto', 'manufacturer', 'https://www.faltocigars.com/en/cigarros', 'En medium til fyldig robusto med pepper og friskhet.'),
('Reserva Especial Tres Luises', 'Cameroon', 'Cameroon', 'Dominican Republic', ARRAY['Dominican Republic','Nicaragua'], NULL::numeric, 'Dominican Republic', 'Tabacalera Falto', 'manufacturer', 'https://www.faltocigars.com/en/cigarros', 'En elegant petit belicoso med trenoter og balansert kompleksitet.'),
('Prominente Gran Reserva Especial', 'Cameroon', 'Cameroon', 'Dominican Republic', ARRAY['Dominican Republic'], NULL::numeric, 'Dominican Republic', 'Tabacalera Falto', 'manufacturer', 'https://www.faltocigars.com/en/cigarros', 'En perfecto støpt i en form fra 1923 med espresso- og tobakksnoter.'),
('Perla Reserva Especial', 'Brazil', NULL::text, 'Dominican Republic', ARRAY['Dominican Republic','Nicaragua'], NULL::numeric, 'Dominican Republic', 'Tabacalera Falto', 'manufacturer', 'https://www.faltocigars.com/en/cigarros', 'En petit corona med undertoner av mørk sjokolade og kaffe.'),
('Selección Especial', 'Dominican Republic', NULL::text, 'Indonesia', ARRAY['Brazil','Dominican Republic'], 3, 'Dominican Republic', 'Tabacalera Falto', 'manufacturer', 'https://www.faltocigars.com/en/cigarros', 'En medium corona gorda med intensitet fra godt lagret tobakk.'),
('Legado', 'Nicaragua', NULL::text, 'Dominican Republic', ARRAY['Dominican Republic','Nicaragua'], NULL::numeric, 'Dominican Republic', 'Tabacalera Falto', 'manufacturer', 'https://www.faltocigars.com/en/cigarros', 'En tiårs-jubileumsblanding med noter av ristede nøtter og frisk tobakk.'),
('La Obra Azojuano', 'Nicaragua', NULL::text, 'Dominican Republic', ARRAY['Dominican Republic','Nicaragua'], NULL::numeric, 'Dominican Republic', 'Tabacalera Falto', 'manufacturer', 'https://www.faltocigars.com/en/cigarros', 'En corona gorda med nicaraguansk dekkblad og dominikansk-nicaraguansk fyll.'),
('El Falto Los Menesteres', 'Nicaragua', NULL::text, 'Dominican Republic', ARRAY['Dominican Republic','Nicaragua'], NULL::numeric, 'Dominican Republic', 'Tabacalera Falto', 'manufacturer', 'https://www.faltocigars.com/en/cigarros', 'En corona gorda med nicaraguansk dekkblad og fyll fra DR og Nicaragua.'),
('Terruño Hermanos', 'Dominican Republic', 'Corojo', 'Dominican Republic', ARRAY['Dominican Republic','Nicaragua','Cameroon'], NULL::numeric, 'Dominican Republic', 'Tabacalera Falto', 'manufacturer', 'https://www.faltocigars.com/en/cigarros-3', 'En robusto med dominikansk corojo og et bredt sammensatt fyll.'),
('Ballibo Edición Especial Abuelos', 'Nicaragua', NULL::text, 'Indonesia', ARRAY['Dominican Republic','Nicaragua'], NULL::numeric, 'Dominican Republic', 'Tabacalera Falto', 'manufacturer', 'https://www.faltocigars.com/en/cigarros-3', 'En corona med nicaraguansk dekkblad og indonesisk omblad.'),
('Dos Banderas', 'Dominican Republic', 'Corojo', 'Brazil', ARRAY['Dominican Republic','Cameroon'], NULL::numeric, 'Dominican Republic', 'Tabacalera Falto', 'manufacturer', 'https://www.faltocigars.com/en/cigarros-3', 'En lancero med dominikansk corojo-dekkblad og brasiliansk omblad.'),
('Yagüez Arawaco', 'Dominican Republic', 'Corojo Shade', NULL::text, ARRAY['Dominican Republic','Brazil','Nicaragua'], NULL::numeric, 'Dominican Republic', 'Tabacalera Falto', 'manufacturer', 'https://www.faltocigars.com/en/cigarros-3', 'En perfecto med dominikansk corojo shade og sumatra-brasiliansk omblad.'),
('El Prócer Historias', 'Dominican Republic', 'Habana 2000', 'Cameroon', ARRAY['Dominican Republic'], NULL::numeric, 'Dominican Republic', 'Tabacalera Falto', 'manufacturer', 'https://www.faltocigars.com/en/cigarros-3', 'En churchill med dominikansk Habana 2000-dekkblad og Cameroon-omblad.'),
('LJF Reserva del Fundador', 'Dominican Republic', 'Habana 92', 'Ecuador', ARRAY['Dominican Republic','Nicaragua'], NULL::numeric, 'Dominican Republic', 'Tabacalera Falto', 'manufacturer', 'https://www.faltocigars.com/en/cigarros-3', 'En box-pressed sigar med dominikansk Habana 92-dekkblad og Sumatra Ecuador-omblad.'),
('La Pureza', 'Dominican Republic', 'Corojo', 'Dominican Republic', ARRAY['Dominican Republic'], NULL::numeric, 'Dominican Republic', 'Tabacalera Falto', 'manufacturer', 'https://www.faltocigars.com/en/cigarros-3', 'En rent dominikansk lancero (puro) med corojo-dekkblad.'),
('El Surco Cosecheros', 'Cameroon', 'Cameroon', 'Dominican Republic', ARRAY['Dominican Republic'], NULL::numeric, 'Dominican Republic', 'Tabacalera Falto', 'manufacturer', 'https://www.faltocigars.com/en/cigarros-3', 'En lang corona gorda med Cameroon-dekkblad og dominikansk innhold.')
),
v(series,vitola,shape,len,ring) AS (VALUES
('Edición Especial ELH Hato Viejo', 'Corona Gorda', 'Parejo', 6.0, 47),
('Lonsdale', 'Lonsdale', 'Parejo', 6.5, 42),
('Robusto', 'Robusto', 'Parejo', 5.0, 50),
('Reserva Especial Tres Luises', 'Petit Belicoso', 'Figurado', 5.0, 52),
('Prominente Gran Reserva Especial', 'Perfecto', 'Figurado', 4.5, 47),
('Perla Reserva Especial', 'Petit Corona', 'Parejo', 4.0, 40),
('Selección Especial', 'Corona Gorda', 'Parejo', 5.75, 48),
('Legado', 'Corona Gorda', 'Parejo', 5.5, 47),
('La Obra Azojuano', 'Corona Gorda', 'Parejo', 5.5, 47),
('El Falto Los Menesteres', 'Corona Gorda', 'Parejo', 5.5, 47),
('Terruño Hermanos', 'Robusto', 'Parejo', 5.0, 50),
('Ballibo Edición Especial Abuelos', 'Corona', 'Parejo', 5.25, 43),
('Dos Banderas', 'Lancero', 'Parejo', 6.875, 40),
('Yagüez Arawaco', 'Perfecto', 'Figurado', 5.0, 54),
('El Prócer Historias', 'Churchill', 'Parejo', 6.0, 48),
('LJF Reserva del Fundador', 'Box Pressed', 'Figurado', 5.5, 52),
('La Pureza', 'Lancero', 'Parejo', 6.875, 40),
('El Surco Cosecheros', 'Corona Gorda', 'Parejo', 6.875, 47)
)
INSERT INTO public.cigars
  (brand,series,vitola,wrapper_country,wrapper_leaf,binder,filler,strength,
   country_origin,manufacturer,shape,common_format,description,is_public,
   source_tier,source_url,verified_at,aliases)
SELECT 'Falto', l.series, v.vitola, l.wc, l.wl, l.binder, l.filler, l.strength,
       l.co, l.man, v.shape, v.vitola, l.descr, true,
       CASE WHEN l.tier='press' THEN 'retailer' ELSE l.tier END, l.url, now(), ARRAY['Falto']
FROM l JOIN v USING(series);

-- Micallef
WITH l(series,wc,wl,binder,filler,strength,co,man,tier,url,descr) AS (VALUES
('Black', 'Mexico', 'San Andrés Maduro', 'Ecuadorian Habano', ARRAY['Nicaragua'], 5, 'Nicaragua', 'Micallef Cigars', 'manufacturer', 'https://www.micallefcigars.com/portfolio', 'En kraftig, fyldig sigar med meksikansk San Andrés maduro-dekkblad og nicaraguansk innmat, med kaffe, sjokolade og krydder.'),
('Blue', 'Mexico', 'San Andrés Sumatra', 'Ecuadorian Habano', ARRAY['Nicaragua','Dominican Republic'], 3, 'Nicaragua', 'Micallef Cigars', 'manufacturer', 'https://www.micallefcigars.com/portfolio', 'En balansert medium-sigar med San Andrés Sumatra-dekkblad, jevn og avrundet med nøtter og krydder.'),
('Green', 'Brazil', 'Mata Fina', 'San Andrés Negro', ARRAY['Nicaragua'], 4, 'Nicaragua', 'Micallef Cigars', 'manufacturer', 'https://www.micallefcigars.com/portfolio', 'En medium til kraftig sigar med brasiliansk Mata Fina-dekkblad, søtlige, jordaktige toner med hint av mørk frukt.'),
('Purple', 'Mexico', 'San Andrés Sumatra', 'Broadleaf', ARRAY['Nicaragua','Dominican Republic','Mexico'], 3, 'Nicaragua', 'Micallef Cigars', 'manufacturer', 'https://www.micallefcigars.com/portfolio', 'En medium sigar med San Andrés Sumatra-dekkblad og flerlands innmat, kompleks med krydder og lær.'),
('Red', 'Mexico', 'San Andrés Habano', 'Broadleaf', ARRAY['Nicaragua','Mexico'], 5, 'Nicaragua', 'Micallef Cigars', 'manufacturer', 'https://www.micallefcigars.com/portfolio', 'En kraftig sigar med San Andrés Habano-dekkblad og broadleaf-omblad, peppret og fyldig med mørke, jordaktige toner.'),
('White', NULL::text, 'Connecticut', 'Broadleaf', ARRAY['Nicaragua','Dominican Republic'], 1, 'Nicaragua', 'Micallef Cigars', 'manufacturer', 'https://www.micallefcigars.com/portfolio', 'En mild, kremete sigar med Connecticut-dekkblad, lett og myk med fløte, nøtter og bakverk.'),
('Connecticut', 'Ecuador', 'Connecticut', 'Nicaraguan Habano', ARRAY['Nicaragua','Dominican Republic'], 3, 'Nicaragua', 'Micallef Cigars', 'manufacturer', 'https://www.micallefcigars.com/portfolio', 'En medium sigar med ecuadoriansk Connecticut-dekkblad, mykere men fyldigere med nøtter, kaffe og krydder.'),
('Experiencia La Crema', 'Mexico', 'San Andrés Sumatra', 'Ecuadorian Habano', ARRAY['Honduras','Dominican Republic','Panama'], 3, 'Nicaragua', 'Micallef Cigars', 'manufacturer', 'https://www.micallefcigars.com/portfolio', 'En medium sigar med San Andrés Sumatra-dekkblad og innmat fra tre land, kremet og balansert.'),
('Herencia', 'Nicaragua', 'Habano', 'Ecuadorian Sumatra', ARRAY['Nicaragua','Honduras'], 3, 'Nicaragua', 'Micallef Cigars', 'manufacturer', 'https://www.micallefcigars.com/portfolio', 'En medium sigar i Habano- og Maduro-utgave med nicaraguansk dekkblad, fyldig med krydder, tre og søtlig sjokolade.'),
('Leyenda', 'Ecuador', 'Habano', 'Nicaraguan', ARRAY['Nicaragua','Dominican Republic','Honduras'], 4, 'Nicaragua', 'Micallef Cigars', 'manufacturer', 'https://www.micallefcigars.com/portfolio', 'En medium til kraftig sigar med ecuadoriansk Habano-dekkblad, rik og krydret med pepper, lær og mørk kakao.'),
('A/a', 'Nicaragua', 'Maduro', 'Ecuadorian Sumatra', ARRAY['Nicaragua','Dominican Republic'], 3, 'Nicaragua', 'Micallef Cigars', 'manufacturer', 'https://www.micallefcigars.com/portfolio', 'En medium sigar med nicaraguansk maduro-dekkblad, jevn og søtlig med kakao, kaffe og krydder.'),
('Migdalia', 'Mexico', 'San Andrés Habano', 'Sumatra', ARRAY['Nicaragua','Dominican Republic'], 4, 'Nicaragua', 'Micallef Cigars', 'manufacturer', 'https://www.micallefcigars.com/portfolio', 'En medium til kraftig sigar med San Andrés Habano-dekkblad, fyldig og krydret med mørk sjokolade, lær og pepper.'),
('Reata', 'Mexico', 'San Andrés Sumatra', 'Ecuadorian', ARRAY['Nicaragua'], 2, 'Nicaragua', 'Micallef Cigars', 'manufacturer', 'https://www.micallefcigars.com/portfolio', 'En mild til medium sigar med San Andrés Sumatra-dekkblad, lett tilgjengelig og jevn med nøtter, tre og lett krydder.'),
('Reserva', 'Mexico', 'San Andrés Habano', 'Nicaraguan', ARRAY['Honduras','Dominican Republic','Peru'], 3, 'Nicaragua', 'Micallef Cigars', 'manufacturer', 'https://www.micallefcigars.com/portfolio', 'En medium sigar med San Andrés Habano-dekkblad og innmat fra tre land, balansert med krydder, tre og kaffe.')
),
v(series,vitola,shape,len,ring) AS (VALUES
('Black', 'Robusto', 'Parejo', 5.0, 52),
('Black', 'Toro', 'Parejo', 6.0, 52),
('Blue', 'Robusto', 'Parejo', 5.0, 52),
('Blue', 'Toro', 'Parejo', 6.0, 52),
('Green', 'Robusto', 'Parejo', 5.0, 52),
('Green', 'Toro', 'Parejo', 6.0, 52),
('Purple', 'Robusto', 'Parejo', 5.0, 52),
('Purple', 'Toro', 'Parejo', 6.0, 52),
('Red', 'Robusto', 'Parejo', 5.0, 52),
('Red', 'Toro', 'Parejo', 6.0, 52),
('White', 'Robusto', 'Parejo', 5.0, 52),
('White', 'Toro', 'Parejo', 6.0, 52),
('Connecticut', 'Corona', 'Parejo', 5.0, 40),
('Connecticut', 'Robusto', 'Parejo', 5.0, 52),
('Experiencia La Crema', 'Corona', 'Parejo', 5.0, 40),
('Experiencia La Crema', 'Robusto Gordo', 'Parejo', 5.0, 54),
('Experiencia La Crema', 'Toro', 'Parejo', 6.0, 52),
('Experiencia La Crema', 'Churchill', 'Parejo', 7.0, 52),
('Herencia', 'Corona', 'Parejo', 5.0, 40),
('Herencia', 'Toro', 'Parejo', 6.0, 52),
('Herencia', 'Box-Pressed Torpedo', 'Figurado', 5.5, 52),
('Leyenda', 'Corona', 'Parejo', 5.0, 40),
('Leyenda', 'Robusto', 'Parejo', 5.0, 52),
('Leyenda', 'Toro', 'Parejo', 6.0, 52),
('Leyenda', 'Presidente', 'Parejo', 7.5, 54),
('A/a', 'Petit', 'Parejo', 4.0, 46),
('A/a', 'Toro Grande', 'Parejo', 6.75, 54),
('A/a', 'Gordo', 'Parejo', 6.0, 60),
('Migdalia', 'Corona', 'Parejo', 5.0, 40),
('Migdalia', 'Petit', 'Parejo', 4.0, 46),
('Migdalia', 'Corona Gorda', 'Parejo', 6.0, 46),
('Migdalia', 'Toro', 'Parejo', 6.0, 52),
('Reata', 'Corona', 'Parejo', 5.0, 40),
('Reata', 'Robusto', 'Parejo', 5.0, 52),
('Reata', 'Corona Gorda', 'Parejo', 6.0, 46),
('Reata', 'Toro', 'Parejo', 6.0, 52),
('Reserva', 'Corona', 'Parejo', 5.0, 40),
('Reserva', 'Toro', 'Parejo', 6.0, 52),
('Reserva', 'Churchill', 'Parejo', 7.0, 52)
)
INSERT INTO public.cigars
  (brand,series,vitola,wrapper_country,wrapper_leaf,binder,filler,strength,
   country_origin,manufacturer,shape,common_format,description,is_public,
   source_tier,source_url,verified_at,aliases)
SELECT 'Micallef', l.series, v.vitola, l.wc, l.wl, l.binder, l.filler, l.strength,
       l.co, l.man, v.shape, v.vitola, l.descr, true,
       CASE WHEN l.tier='press' THEN 'retailer' ELSE l.tier END, l.url, now(), ARRAY['Micallef']
FROM l JOIN v USING(series);

-- Jake Wyatt
WITH l(series,wc,wl,binder,filler,strength,co,man,tier,url,descr) AS (VALUES
('Fourth Dimension', 'Dominican Republic', 'Habano Rosado', 'Dominican Republic', ARRAY['Dominican Republic'], 3, 'Dominican Republic', 'Jake Wyatt Cigar Co.', 'retailer', 'https://halfwheel.com/jake-wyatt-cigar-co-launches/372682/', 'En medium, balansert dominikansk sigar med Habano Rosado-dekkblad, rik og jevn.'),
('Herbert Spencer', 'Mexico', 'San Andrés', 'Dominican Republic', ARRAY['Dominican Republic'], 3, 'Dominican Republic', 'Jake Wyatt Cigar Co.', 'retailer', 'https://halfwheel.com/jake-wyatt-cigar-co-launches/372682/', 'En medium sigar med meksikansk San Andrés maduro-dekkblad, jordaktige og søtlige toner.'),
('Appendix II', 'Ecuador', 'Connecticut', 'Dominican Republic', ARRAY['Dominican Republic'], 2, 'Dominican Republic', 'Jake Wyatt Cigar Co.', 'retailer', 'https://halfwheel.com/jake-wyatt-cigar-co-launches/372682/', 'En mild til medium sigar med ecuadoriansk Connecticut-dekkblad og en kremet, forfinet profil.'),
('Lucid Interval', 'Dominican Republic', 'Candela', 'Dominican Republic', ARRAY['Dominican Republic'], 2, 'Dominican Republic', 'Jake Wyatt Cigar Co.', 'retailer', 'https://halfwheel.com/jake-wyatt-cigar-co-launches/372682/', 'En mild-medium candela-sigar med grønt dekkblad og en gressaktig, urteaktig karakter.'),
('Lithium', 'Ecuador', 'Habano', 'Dominican Republic', ARRAY['Dominican Republic'], 3, 'Dominican Republic', 'Jake Wyatt Cigar Co.', 'retailer', 'https://halfwheel.com/jake-wyatt-lithium/385108/', 'En medium til fyldig sigar med ecuadoriansk Habano-dekkblad og en kremet, smaksrik profil.'),
('Icarus', 'Mexico', 'San Andrés', 'Dominican Republic', ARRAY['Dominican Republic','United States'], 3, 'Dominican Republic', 'Jake Wyatt Cigar Co.', 'retailer', 'https://halfwheel.com/jake-wyatt-icarus/440185/', 'En medium sigar der Tennessee fire-cured tobakk gir et distinkt røykpreg under meksikansk San Andrés-dekkblad.'),
('J.W. Maverick', 'Mexico', 'San Andrés', 'Corojo', ARRAY['United States'], 4, 'Dominican Republic', 'Jake Wyatt Cigar Co.', 'retailer', 'https://halfwheel.com/jake-wyatt-cigar-co-ships-full-line-of-j-w-maverick/429887/', 'Merkets fyldigste sigar med meksikansk San Andrés-dekkblad og en kraftig, men jevn smak.'),
('Titan Series', NULL::text, 'Claro/Oscuro/Rosado', 'Honduras', ARRAY['Honduras','Nicaragua'], 3, 'Honduras', 'Jake Wyatt Cigar Co.', 'manufacturer', 'https://jakewyattcigars.com/products/the-titan-series', 'En prisgunstig, medium honduransk sigar i tre dekkbladvarianter (Claro, Oscuro og Rosado).')
),
v(series,vitola,shape,len,ring) AS (VALUES
('Fourth Dimension', 'Robusto', 'Parejo', 5.0, 50),
('Fourth Dimension', 'Toro', 'Parejo', 6.0, 54),
('Fourth Dimension', 'Belicoso', 'Figurado', 6.0, 52),
('Fourth Dimension', 'Gordo', 'Parejo', 6.0, 60),
('Herbert Spencer', 'Robusto', 'Parejo', 5.0, 50),
('Herbert Spencer', 'Toro', 'Parejo', 6.0, 54),
('Herbert Spencer', 'Belicoso', 'Figurado', 6.0, 52),
('Herbert Spencer', 'Gordo', 'Parejo', 6.0, 60),
('Appendix II', 'Robusto', 'Parejo', 5.0, 50),
('Appendix II', 'Toro', 'Parejo', 6.0, 54),
('Appendix II', 'Belicoso', 'Figurado', 6.0, 52),
('Appendix II', 'Gordo', 'Parejo', 6.0, 60),
('Lucid Interval', 'Robusto', 'Parejo', 5.0, 50),
('Lucid Interval', 'Toro', 'Parejo', 6.0, 54),
('Lucid Interval', 'Belicoso', 'Figurado', 6.0, 52),
('Lucid Interval', 'Gordo', 'Parejo', 6.0, 60),
('Lithium', 'Toro', 'Parejo', 6.0, 50),
('Icarus', 'Toro Extra', 'Parejo', 6.0, 54),
('J.W. Maverick', 'Robusto', 'Parejo', 5.0, 50),
('J.W. Maverick', 'Toro', 'Parejo', 6.0, 54),
('J.W. Maverick', 'Box-Pressed Gordo', 'Figurado', 6.0, 60),
('Titan Series', 'Robusto', 'Parejo', 5.0, 50),
('Titan Series', 'Toro', 'Parejo', 6.0, 54)
)
INSERT INTO public.cigars
  (brand,series,vitola,wrapper_country,wrapper_leaf,binder,filler,strength,
   country_origin,manufacturer,shape,common_format,description,is_public,
   source_tier,source_url,verified_at,aliases)
SELECT 'Jake Wyatt', l.series, v.vitola, l.wc, l.wl, l.binder, l.filler, l.strength,
       l.co, l.man, v.shape, v.vitola, l.descr, true,
       CASE WHEN l.tier='press' THEN 'retailer' ELSE l.tier END, l.url, now(), ARRAY['Jake Wyatt']
FROM l JOIN v USING(series);

-- Nat Cicco
WITH l(series,wc,wl,binder,filler,strength,co,man,tier,url,descr) AS (VALUES
('Aniversario 1965 Liga No. 4', 'Ecuador', 'Habano', 'Nicaragua', ARRAY['Nicaragua'], 4, 'Nicaragua', 'Nat Cicco', 'manufacturer', 'https://www.natcicco.com/1965-aniversario', 'En semi-boks-presset nicaraguansk blend med ecuadoriansk Habano-dekkblad, med pepper, kakao, seder og lær.'),
('Cuban Legends', NULL::text, 'Cuban-seed Rosado', 'Nicaragua', NULL::text[], 3, 'Nicaragua', 'Nat Cicco', 'manufacturer', 'https://www.natcicco.com/cuban-legends', 'En rimelig, mild til medium daglig-sigar bygget som cubansk sandwich med cubansk-frø Rosado-dekkblad.'),
('HHB Gold', 'Nicaragua', 'Habano', 'Nicaragua', ARRAY['Nicaragua'], 3, 'Nicaragua', 'Nat Cicco', 'manufacturer', 'https://www.natcicco.com/hhb', 'En medium, kremet og smakrik nicaraguansk puro med Habano-dekkblad.'),
('HHB Classic', NULL::text, 'Connecticut', 'Nicaragua', ARRAY['Nicaragua'], 3, 'Nicaragua', 'Nat Cicco', 'retailer', 'https://www.neptunecigar.com/cigars/nat-cicco-hhb-classic-robusto', 'En mild-til-medium nicaraguansk sigar med lyst Connecticut-dekkblad for en jevn, kremet røyk.'),
('Elephant Ears', 'Nicaragua', 'Maduro', 'Nicaragua', ARRAY['Nicaragua'], 4, 'Nicaragua', 'Nat Cicco', 'manufacturer', 'https://www.natcicco.com/elephant-ears', 'En fyldig nicaraguansk puro med rødlig maduro-dekkblad og en karakteristisk åpen, utbrettet fot.'),
('Nicaraguan Long Filler', 'Nicaragua', NULL::text, 'Nicaragua', ARRAY['Nicaragua'], 4, 'Nicaragua', 'Nat Cicco', 'manufacturer', 'https://www.natcicco.com/nicaraguan-long-filler', 'En håndrullet nicaraguansk puro med langfyll og robuste, fyldige smaker.'),
('Cuban Style', NULL::text, 'Connecticut Broadleaf', NULL::text, NULL::text[], 2, 'Dominican Republic', 'Nat Cicco', 'manufacturer', 'https://www.natcicco.com/cuban-style', 'En mild, rimelig sigar fra DR med Connecticut broadleaf-dekkblad og picadura-fyll, i Natural og Maduro.')
),
v(series,vitola,shape,len,ring) AS (VALUES
('Aniversario 1965 Liga No. 4', 'Corona', 'Parejo', 5.5, 46),
('Aniversario 1965 Liga No. 4', 'Robusto', 'Parejo', 5.0, 52),
('Aniversario 1965 Liga No. 4', 'Robusto Grande', 'Parejo', 5.5, 56),
('Aniversario 1965 Liga No. 4', 'Toro', 'Parejo', 6.0, 52),
('Aniversario 1965 Liga No. 4', 'Torpedo', 'Figurado', 6.25, 52),
('Aniversario 1965 Liga No. 4', 'Double Toro', 'Parejo', 6.5, 60),
('Aniversario 1965 Liga No. 4', 'Churchill', 'Parejo', 7.0, 52),
('Cuban Legends', 'No. 4', 'Parejo', 4.0, 58),
('Cuban Legends', 'Robusto', 'Parejo', 5.0, 54),
('Cuban Legends', 'Torpedo', 'Figurado', 6.0, 54),
('Cuban Legends', 'Toro', 'Parejo', 6.0, 56),
('Cuban Legends', 'Churchill', 'Parejo', 7.5, 52),
('HHB Gold', 'Corona', 'Parejo', 5.25, 50),
('HHB Gold', 'Corona Extra', 'Parejo', 6.25, 50),
('HHB Gold', 'Robusto', 'Parejo', 5.25, 56),
('HHB Gold', 'Toro', 'Parejo', 6.75, 58),
('HHB Gold', 'Churchill', 'Parejo', 7.75, 54),
('HHB Classic', 'Robusto', 'Parejo', 5.25, 56),
('HHB Classic', 'Toro', 'Parejo', 6.75, 58),
('Elephant Ears', 'Elephant Ears', 'Parejo', 8.5, 60),
('Elephant Ears', 'Baby', 'Parejo', 7.5, 54),
('Elephant Ears', 'Juniors', 'Parejo', 7.5, 60),
('Elephant Ears', 'Baby Juniors', 'Parejo', 6.5, 54),
('Elephant Ears', 'Jumbo', 'Parejo', 6.0, 70),
('Elephant Ears', 'Jumbo Juniors', 'Parejo', 6.0, 60),
('Nicaraguan Long Filler', 'Robusto', 'Parejo', 5.0, 52),
('Nicaraguan Long Filler', 'Robusto Grande', 'Parejo', 5.5, 56),
('Nicaraguan Long Filler', 'Toro', 'Parejo', 6.0, 52),
('Nicaraguan Long Filler', 'Belicoso', 'Figurado', 6.25, 52),
('Nicaraguan Long Filler', 'Magnum', 'Parejo', 6.25, 60),
('Nicaraguan Long Filler', 'Churchill', 'Parejo', 7.0, 56),
('Cuban Style', 'Corona Grande', 'Parejo', 6.0, 42),
('Cuban Style', 'Robusto', 'Parejo', 5.75, 49),
('Cuban Style', 'Churchill', 'Parejo', 7.5, 46)
)
INSERT INTO public.cigars
  (brand,series,vitola,wrapper_country,wrapper_leaf,binder,filler,strength,
   country_origin,manufacturer,shape,common_format,description,is_public,
   source_tier,source_url,verified_at,aliases)
SELECT 'Nat Cicco', l.series, v.vitola, l.wc, l.wl, l.binder, l.filler, l.strength,
       l.co, l.man, v.shape, v.vitola, l.descr, true,
       CASE WHEN l.tier='press' THEN 'retailer' ELSE l.tier END, l.url, now(), ARRAY['Nat Cicco']
FROM l JOIN v USING(series);

-- Warfighter Tobacco
WITH l(series,wc,wl,binder,filler,strength,co,man,tier,url,descr) AS (VALUES
('5.56 Field Connecticut Shade', 'Honduras', 'Connecticut Shade', 'Nicaragua', ARRAY['Nicaragua','Colombia'], 2, 'Nicaragua', 'Warfighter Tobacco', 'manufacturer', 'https://www.warfightertobacco.com/collections/cigars/products/5-56-mm-field-reload', 'En mild til medium sigar med Connecticut Shade-dekkblad, med hint av salsa, hvit pepper, lær og fløte.'),
('7.62 Field Sumatra', 'Indonesia', 'Sumatra', 'Nicaragua', ARRAY['Nicaragua','Dominican Republic'], 3, 'Nicaragua', 'Warfighter Tobacco', 'manufacturer', 'https://www.warfightertobacco.com/collections/cigars/products/762-mm-field-sumatra-cigar', 'En medium hverdagssigar med Sumatra-dekkblad og noter av lær, treverk og ristet marshmallow.'),
('.50 Cal Field Maduro', 'Nicaragua', 'Habano Maduro', 'Nicaragua', ARRAY['Nicaragua','Colombia'], 3, 'Nicaragua', 'Warfighter Tobacco', 'manufacturer', 'https://www.warfightertobacco.com/collections/cigars/products/50-cal-field-maduro-reload', 'Den kraftigste i Field-serien, med krydder, kaffe og kakao som avslutter mildere med lær og treverk.'),
('Garrison Corojo', 'Nicaragua', 'Corojo', 'Nicaragua', ARRAY['Honduras','Nicaragua'], 3, 'Nicaragua', 'Warfighter Tobacco', 'manufacturer', 'https://www.warfightertobacco.com/collections/cigars/products/5-56-mm-garrison-corojo-cigar', 'En sigar med kremet start som går over i nicaraguansk corojo-krydder, med pepper, lær og kremet kakao.'),
('Garrison Rosado', 'Nicaragua', 'Habano Rosado', 'Nicaragua', ARRAY['Nicaragua'], 3, 'Nicaragua', 'Warfighter Tobacco', 'manufacturer', 'https://www.warfightertobacco.com/collections/cigars/products/762-mm-garrison-rosado-cigar', 'En sigar som røyker sterkere enn Field-serien med habano-krydder, ristede nøtter, eik og lyst brunt sukker.'),
('Garrison Oscuro Maduro', 'Honduras', 'Habano Oscuro Maduro', 'Honduras', ARRAY['Nicaragua'], 4, 'Nicaragua', 'Warfighter Tobacco', 'manufacturer', 'https://www.warfightertobacco.com/collections/cigars/products/50-cal-garrison-oscuro-maduro', 'En mørk og kraftig maduro med eik, bourbon, kakao og aprikos, med et mildt smøraktig innslag.'),
('Night Shift', 'Ecuador', 'Habano Oscuro', 'Indonesia', ARRAY['Nicaragua'], 3, 'Nicaragua', 'Warfighter Tobacco', 'manufacturer', 'https://www.warfightertobacco.com/collections/cigars/products/warfighter-night-shift', 'En medium sigar med ecuadoriansk Habano Oscuro-dekkblad, med pepper, lær, sitrus og frukt.'),
('10th Anniversary', 'Ecuador', 'Sumatra', 'Honduras', ARRAY['Nicaragua'], 3, 'Nicaragua', 'Warfighter Tobacco', 'manufacturer', 'https://www.warfightertobacco.com/collections/cigars/products/warfighter-10th-anniversary', 'En balansert medium sigar med ecuadoriansk Sumatra-frø-dekkblad, produsert til 10-årsjubileet.'),
('San Andres', 'Mexico', 'San Andrés', 'Nicaragua', ARRAY['Nicaragua'], 3, 'Nicaragua', 'Warfighter Tobacco', 'retailer', 'https://tobaccoreporter.com/2026/05/29/warfighter-tobacco-ships-10th-anniversary-and-san-andres-releases/', 'En medium til medium-kraftig sigar med meksikansk San Andrés-dekkblad over nicaraguansk bind og fyll.')
),
v(series,vitola,shape,len,ring) AS (VALUES
('5.56 Field Connecticut Shade', 'Minutemen', 'Parejo', 4.0, 44),
('5.56 Field Connecticut Shade', 'Corona', 'Parejo', 5.5, 46),
('5.56 Field Connecticut Shade', 'Robusto', 'Parejo', 5.0, 52),
('5.56 Field Connecticut Shade', 'Toro', 'Parejo', 6.0, 52),
('5.56 Field Connecticut Shade', 'Gordo', 'Parejo', 6.0, 60),
('5.56 Field Connecticut Shade', 'Lancero', 'Parejo', 7.0, 38),
('7.62 Field Sumatra', 'Minutemen', 'Parejo', 4.0, 44),
('7.62 Field Sumatra', 'Corona', 'Parejo', 5.5, 46),
('7.62 Field Sumatra', 'Robusto', 'Parejo', 5.0, 52),
('7.62 Field Sumatra', 'Toro', 'Parejo', 6.0, 52),
('7.62 Field Sumatra', 'Gordo', 'Parejo', 6.0, 60),
('7.62 Field Sumatra', 'Lancero', 'Parejo', 7.0, 38),
('.50 Cal Field Maduro', 'Minutemen', 'Parejo', 4.0, 44),
('.50 Cal Field Maduro', 'Corona', 'Parejo', 5.5, 46),
('.50 Cal Field Maduro', 'Robusto', 'Parejo', 5.0, 52),
('.50 Cal Field Maduro', 'Toro', 'Parejo', 6.0, 52),
('.50 Cal Field Maduro', 'Gordo', 'Parejo', 6.0, 60),
('.50 Cal Field Maduro', 'Lancero', 'Parejo', 7.0, 38),
('Garrison Corojo', 'Minutemen', 'Parejo', 4.0, 44),
('Garrison Corojo', 'Corona', 'Parejo', 5.5, 46),
('Garrison Corojo', 'Robusto', 'Parejo', 5.0, 52),
('Garrison Corojo', 'Toro', 'Parejo', 6.0, 52),
('Garrison Corojo', 'Gordo', 'Parejo', 6.0, 60),
('Garrison Corojo', 'Lancero', 'Parejo', 7.0, 38),
('Garrison Rosado', 'Minutemen', 'Parejo', 4.0, 44),
('Garrison Rosado', 'Corona', 'Parejo', 5.5, 46),
('Garrison Rosado', 'Robusto', 'Parejo', 5.0, 52),
('Garrison Rosado', 'Toro', 'Parejo', 6.0, 52),
('Garrison Rosado', 'Rocco', 'Parejo', 6.0, 60),
('Garrison Rosado', 'Lancero', 'Parejo', 7.0, 38),
('Garrison Oscuro Maduro', 'Minutemen', 'Parejo', 4.0, 44),
('Garrison Oscuro Maduro', 'Corona', 'Parejo', 5.5, 46),
('Garrison Oscuro Maduro', 'Robusto', 'Parejo', 5.0, 52),
('Garrison Oscuro Maduro', 'Toro', 'Parejo', 6.0, 52),
('Garrison Oscuro Maduro', 'Rocco', 'Parejo', 6.0, 60),
('Garrison Oscuro Maduro', 'Lancero', 'Parejo', 7.0, 38),
('Night Shift', 'Toro', 'Parejo', 6.0, 50),
('10th Anniversary', 'Toro', 'Parejo', 6.0, 52),
('San Andres', 'Toro', 'Parejo', 6.0, 52)
)
INSERT INTO public.cigars
  (brand,series,vitola,wrapper_country,wrapper_leaf,binder,filler,strength,
   country_origin,manufacturer,shape,common_format,description,is_public,
   source_tier,source_url,verified_at,aliases)
SELECT 'Warfighter Tobacco', l.series, v.vitola, l.wc, l.wl, l.binder, l.filler, l.strength,
       l.co, l.man, v.shape, v.vitola, l.descr, true,
       CASE WHEN l.tier='press' THEN 'retailer' ELSE l.tier END, l.url, now(), ARRAY['Warfighter Tobacco','Warfighter']
FROM l JOIN v USING(series);

-- La Sirena
WITH l(series,wc,wl,binder,filler,strength,co,man,tier,url,descr) AS (VALUES
('Original', 'Nicaragua', 'Habano Oscuro', 'Nicaragua', ARRAY['Nicaragua'], 3, 'Nicaragua', 'La Sirena Cigars', 'manufacturer', 'https://www.lasirenacigars.com/', 'En helnicaraguansk sigar med Habano Oscuro-dekkblad rullet ved La Zona, medium til medium-fyldig med pepper, kakao og krem.'),
('Merlion', 'Ecuador', 'Corojo', 'Brazil', ARRAY['Brazil','Dominican Republic','Nicaragua'], 4, 'Dominican Republic', 'La Sirena Cigars', 'retailer', 'https://cigar-coop.com/2012/07/cigar-review-merlion-by-la-sirena.html', 'La Sirenas dominikansk-produserte linje fra La Aurora, med ecuadoriansk Corojo-dekkblad, medium til fyldig.'),
('Oceano', 'Ecuador', 'Corojo', 'Brazil', NULL::text[], 4, 'Dominican Republic', 'La Sirena Cigars', 'manufacturer', 'https://www.lasirenacigars.com/', 'En fyldig La Sirena-linje rullet ved MATASA i DR, med vitolaer oppkalt etter verdenshavene.')
),
v(series,vitola,shape,len,ring) AS (VALUES
('Original', 'Sea Sprite', 'Parejo', 5.5, 42),
('Original', 'The Prince', 'Parejo', 5.0, 50),
('Original', 'Trident', 'Parejo', 7.0, 50),
('Original', 'Divine', 'Parejo', 5.5, 52),
('Original', 'King Poseidon', 'Parejo', 6.0, 60),
('Original', 'Lancero', 'Parejo', 7.0, 42),
('Merlion', 'Robusto', 'Parejo', 5.0, 50),
('Merlion', 'Toro', 'Parejo', 5.5, 54),
('Merlion', 'Gran Toro', 'Parejo', 6.0, 58),
('Oceano', 'Southern', 'Parejo', 5.0, 43),
('Oceano', 'Indian', 'Parejo', 5.5, 50),
('Oceano', 'Atlantic', 'Parejo', 7.0, 52),
('Oceano', 'Pacific', 'Parejo', 6.0, 65)
)
INSERT INTO public.cigars
  (brand,series,vitola,wrapper_country,wrapper_leaf,binder,filler,strength,
   country_origin,manufacturer,shape,common_format,description,is_public,
   source_tier,source_url,verified_at,aliases)
SELECT 'La Sirena', l.series, v.vitola, l.wc, l.wl, l.binder, l.filler, l.strength,
       l.co, l.man, v.shape, v.vitola, l.descr, true,
       CASE WHEN l.tier='press' THEN 'retailer' ELSE l.tier END, l.url, now(), ARRAY['La Sirena']
FROM l JOIN v USING(series);

-- JRE Tobacco
WITH l(series,wc,wl,binder,filler,strength,co,man,tier,url,descr) AS (VALUES
('Rancho Luna Habano', 'Honduras', 'Habano', 'Honduras', ARRAY['Honduras'], 3, 'Honduras', 'JRE Tobacco Co.', 'retailer', 'https://cigar-coop.com/2020/06/cigar-review-rancho-luna-grandes-70-x-7-by-jre-tobacco-co.html', 'En honduransk puro i mellomstyrke med habano-dekkblad fra Eiroa-familiens gård i Jamastran-dalen.'),
('Rancho Luna Maduro', 'Mexico', 'San Andrés', 'Honduras', ARRAY['Honduras'], 3, 'Honduras', 'JRE Tobacco Co.', 'retailer', 'https://cigar-coop.com/2017/04/cigar-review-rancho-luna-maduro-robusto-by-jre-tobacco-company.html', 'En mellomsterk maduro med meksikansk San Andrés-dekkblad over honduransk corojo- og habanotobakk.'),
('Tatascan Habano', 'Honduras', 'Habano', 'Honduras', ARRAY['Honduras'], 2, 'Honduras', 'JRE Tobacco Co.', 'retailer', 'https://cigar-coop.com/2017/10/cigar-review-tatascan-habano-toro-by-jre-tobacco-co.html', 'En mild til mellomsterk honduransk puro med habano-dekkblad og søt tupp.'),
('Tatascan Connecticut', 'Ecuador', 'Connecticut Shade', 'Honduras', ARRAY['Honduras'], 2, 'Honduras', 'JRE Tobacco Co.', 'retailer', 'https://www.jrcigars.com/cigars/handmade-cigars/tatascan-connecticut/', 'En mild honduransk sigar med gyllent ecuadoriansk Connecticut-dekkblad over honduransk corojo og habano.'),
('Tatascan Maduro', NULL::text, 'Maduro', 'Honduras', ARRAY['Honduras'], 2, 'Honduras', 'JRE Tobacco Co.', 'retailer', 'https://smokincigar.com/products/tatascan-robusto-maduro-5x50', 'En mild til mellomsterk honduransk sigar med mørkt maduro-dekkblad over corojo- og habanofyll.')
),
v(series,vitola,shape,len,ring) AS (VALUES
('Rancho Luna Habano', 'Robusto', 'Parejo', 5.0, 50),
('Rancho Luna Habano', 'Toro', 'Parejo', 6.0, 50),
('Rancho Luna Habano', 'Gordo', 'Parejo', 6.5, 60),
('Rancho Luna Habano', 'Grandes 64', 'Parejo', 7.0, 64),
('Rancho Luna Habano', 'Grandes 70', 'Parejo', 7.0, 70),
('Rancho Luna Maduro', 'Robusto', 'Parejo', 5.0, 50),
('Rancho Luna Maduro', 'Toro', 'Parejo', 6.0, 50),
('Rancho Luna Maduro', 'Gordo', 'Parejo', 6.5, 60),
('Tatascan Habano', 'Corona', 'Parejo', 5.0, 44),
('Tatascan Habano', 'Robusto', 'Parejo', 5.0, 50),
('Tatascan Habano', 'Toro', 'Parejo', 6.0, 50),
('Tatascan Habano', 'Gran Churchill', 'Parejo', 7.0, 52),
('Tatascan Habano', 'Gordo', 'Parejo', 6.5, 60),
('Tatascan Connecticut', 'Robusto', 'Parejo', 5.0, 50),
('Tatascan Connecticut', 'Toro', 'Parejo', 6.0, 50),
('Tatascan Connecticut', 'Gordo', 'Parejo', 6.5, 60),
('Tatascan Maduro', 'Robusto', 'Parejo', 5.0, 50)
)
INSERT INTO public.cigars
  (brand,series,vitola,wrapper_country,wrapper_leaf,binder,filler,strength,
   country_origin,manufacturer,shape,common_format,description,is_public,
   source_tier,source_url,verified_at,aliases)
SELECT 'JRE Tobacco', l.series, v.vitola, l.wc, l.wl, l.binder, l.filler, l.strength,
       l.co, l.man, v.shape, v.vitola, l.descr, true,
       CASE WHEN l.tier='press' THEN 'retailer' ELSE l.tier END, l.url, now(), ARRAY['JRE','Rancho Luna','Tatascan']
FROM l JOIN v USING(series);

