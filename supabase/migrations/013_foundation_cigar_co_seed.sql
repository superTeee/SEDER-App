-- ============================================================
-- 013_foundation_cigar_co_seed.sql
--
-- Setter inn Foundation Cigar Co — grunnlagt 2015 av Nicholas
-- "Nick" Melillo (tidligere visepresident for internasjonal
-- produksjon/master blender hos Drew Estate 2003-2014, mannen
-- bak Liga Privada No. 9, T52 og Nica Rustica). Connecticut-født,
-- hovedkvarter på en tobakksgård i Connecticut River Valley —
-- derav merkets sterke fokus på Connecticut Broadleaf/Shade-
-- dekkblad. Det meste produseres i Nicaragua hos AJ Fernandez
-- og My Father Cigars (Pepin Garcia), med innmat fra Aganorsa
-- Leaf og My Father. Filosofi: "foundation first" — small-batch,
-- historiedrevne sigarer med fokus på balanse og kompleksitet
-- fremfor rå styrke.
--
-- I databasen fra før: 1 rad (Charter Oak/Toro, Connecticut
-- Broadleaf-variant). Denne migrasjonen bygger ut med 53 nye
-- rader fordelt på 7 serier:
--
--   1) El Güegüense        — opprinnelig flaggskip (nicaraguansk puro,
--                            Corojo/Criollo), utgått, men fortsatt
--                            mye søkt etter under "Wise Man"-navnet
--   2) The Wise Man Corojo  — etterfølger til El Güegüense, nå laget
--                            hos My Father Cigars
--   3) The Wise Man Maduro  — søsterlinje med San Andrés Maduro-dekkblad
--   4) The Tabernacle       — super-premium all-maduro, Connecticut
--                            Broadleaf-dekkblad, laget hos AJ Fernandez
--   5) Charter Oak          — hyllest til Connecticut-dekkbladtradisjonen,
--                            i både Shade- og Broadleaf-utgave
--   6) Olmec Maduro          — fullkroppet, meksikansk San Andrés Negro
--   7) Highclere Castle      — inspirert av "Downton Abbey"-slottet,
--                            tre underlinjer: Edwardian, Victorian, Senetjer
--
-- Kilder: foundationcigarcompany.com, cigaraficionado.com,
-- halfwheel.com, cigar-coop.com, cigarsdaily.com, jrcigars.com,
-- cigars.com, atlanticcigar.com (offisielle vitola-lister og
-- produktbeskrivelser).
-- ============================================================

-- ----------------------------------------------------------------
-- 1) El Güegüense ("The Wise Man") — opprinnelig flaggskip, utgått
--    Nicaraguansk puro: Corojo/Criollo-dekkblad fra 2011/2012-avlingen,
--    samme jord til bind og innmat.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Foundation Cigar Co','Foundation Cigar Co','El Güegüense','Robusto','Robusto',50,5.5,'Parejo',null,null,null,'Nicaragua','Corojo','Nicaraguan Criollo',array['Nicaragua'],'Nicaragua',4,null,'El Güegüense var Foundations opprinnelige flaggskip — en nicaraguansk puro bygget på sjeldne Corojo- og Criollo-blader fra 2011/2012-avlingen. Fullkroppet med krydder, seder og naturlig sødme. Linjen er utgått, men lever videre under navnet "The Wise Man".'),
('Foundation Cigar Co','Foundation Cigar Co','El Güegüense','Corona Gorda','Corona Gorda',46,5.625,'Parejo',null,null,null,'Nicaragua','Corojo','Nicaraguan Criollo',array['Nicaragua'],'Nicaragua',4,null,'El Güegüense var Foundations opprinnelige flaggskip — en nicaraguansk puro bygget på sjeldne Corojo- og Criollo-blader fra 2011/2012-avlingen. Corona Gorda er den slankeste vitolaen i serien.'),
('Foundation Cigar Co','Foundation Cigar Co','El Güegüense','Toro Huaco','Gordo',56,6.0,'Parejo',null,null,null,'Nicaragua','Corojo','Nicaraguan Criollo',array['Nicaragua'],'Nicaragua',4,null,'El Güegüense var Foundations opprinnelige flaggskip — en nicaraguansk puro bygget på sjeldne Corojo- og Criollo-blader fra 2011/2012-avlingen. Toro Huaco er en tykk, kort vitola med konsentrert smak.'),
('Foundation Cigar Co','Foundation Cigar Co','El Güegüense','Torpedo','Torpedo',52,6.25,'Figurado','Torpedo','Pointed','Closed','Nicaragua','Corojo','Nicaraguan Criollo',array['Nicaragua'],'Nicaragua',4,null,'El Güegüense var Foundations opprinnelige flaggskip — en nicaraguansk puro bygget på sjeldne Corojo- og Criollo-blader fra 2011/2012-avlingen. Torpedo-formen gir et konsentrert trekk mot enden.'),
('Foundation Cigar Co','Foundation Cigar Co','El Güegüense','Churchill','Churchill',48,7.0,'Parejo',null,null,null,'Nicaragua','Corojo','Nicaraguan Criollo',array['Nicaragua'],'Nicaragua',4,null,'El Güegüense var Foundations opprinnelige flaggskip — en nicaraguansk puro bygget på sjeldne Corojo- og Criollo-blader fra 2011/2012-avlingen. Churchill er den lengste klassiske vitolaen i serien.'),
('Foundation Cigar Co','Foundation Cigar Co','El Güegüense','Lancero','Lancero',40,7.5,'Parejo',null,null,null,'Nicaragua','Corojo','Nicaraguan Criollo',array['Nicaragua'],'Nicaragua',4,null,'El Güegüense var Foundations opprinnelige flaggskip — en nicaraguansk puro bygget på sjeldne Corojo- og Criollo-blader fra 2011/2012-avlingen. Lancero er den slankeste og lengste vitolaen, populær blant entusiaster.');

-- ----------------------------------------------------------------
-- 2) The Wise Man Corojo — etterfølger til El Güegüense, nå laget
--    hos My Father Cigars. Corojo 99-dekkblad, nicaraguansk puro.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Foundation Cigar Co','Foundation Cigar Co','The Wise Man Corojo','Robusto','Robusto',50,5.5,'Parejo',null,null,null,'Nicaragua','Corojo 99','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'The Wise Man Corojo er etterfølgeren til El Güegüense, nå produsert hos My Father Cigars. Nicaraguansk puro med Corojo 99-dekkblad og innmat fra Estelí og Jalapa — krydder, seder og en raffinert naturlig sødme.'),
('Foundation Cigar Co','Foundation Cigar Co','The Wise Man Corojo','Corona Gorda','Corona Gorda',46,5.625,'Parejo',null,null,null,'Nicaragua','Corojo 99','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'The Wise Man Corojo er etterfølgeren til El Güegüense, nå produsert hos My Father Cigars. Nicaraguansk puro med Corojo 99-dekkblad og innmat fra Estelí og Jalapa.'),
('Foundation Cigar Co','Foundation Cigar Co','The Wise Man Corojo','Toro Huaco','Gordo',56,6.0,'Parejo',null,null,null,'Nicaragua','Corojo 99','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'The Wise Man Corojo er etterfølgeren til El Güegüense, nå produsert hos My Father Cigars. Toro Huaco er en tykk, kort vitola med konsentrert smak.'),
('Foundation Cigar Co','Foundation Cigar Co','The Wise Man Corojo','Torpedo','Torpedo',52,6.25,'Figurado','Torpedo','Pointed','Closed','Nicaragua','Corojo 99','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'The Wise Man Corojo er etterfølgeren til El Güegüense, nå produsert hos My Father Cigars. Torpedo-formen gir et konsentrert trekk mot enden.'),
('Foundation Cigar Co','Foundation Cigar Co','The Wise Man Corojo','Churchill','Churchill',48,7.0,'Parejo',null,null,null,'Nicaragua','Corojo 99','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'The Wise Man Corojo er etterfølgeren til El Güegüense, nå produsert hos My Father Cigars. Churchill er den lengste klassiske vitolaen i serien.'),
('Foundation Cigar Co','Foundation Cigar Co','The Wise Man Corojo','Lancero','Lancero',40,7.0,'Parejo',null,null,null,'Nicaragua','Corojo 99','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'The Wise Man Corojo Lancero ble lansert i 2025 som en utvidelse av serien — 7x40, krydder, seder og en raffinert naturlig sødme fra Estelí- og Jalapa-innmaten.');

-- ----------------------------------------------------------------
-- 3) The Wise Man Maduro — San Andrés Maduro-dekkblad fra Mexico
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Foundation Cigar Co','Foundation Cigar Co','The Wise Man Maduro','Robusto','Robusto',50,5.5,'Parejo',null,null,null,'Mexico','San Andres Maduro','Nicaraguan Corojo 99',array['Nicaragua'],'Nicaragua',4,null,'The Wise Man Maduro bruker et San Andrés Maduro-dekkblad fra Mexico over en vintage nicaraguansk Corojo 99-bind fra Jalapa og aldret innmat fra Estelí og Condega. Kakao, espresso og jord.'),
('Foundation Cigar Co','Foundation Cigar Co','The Wise Man Maduro','Corona Gorda','Corona Gorda',46,5.6,'Parejo',null,null,null,'Mexico','San Andres Maduro','Nicaraguan Corojo 99',array['Nicaragua'],'Nicaragua',4,null,'The Wise Man Maduro bruker et San Andrés Maduro-dekkblad fra Mexico over en vintage nicaraguansk Corojo 99-bind fra Jalapa og aldret innmat fra Estelí og Condega.'),
('Foundation Cigar Co','Foundation Cigar Co','The Wise Man Maduro','Toro Huaco','Gordo',56,6.0,'Parejo',null,null,null,'Mexico','San Andres Maduro','Nicaraguan Corojo 99',array['Nicaragua'],'Nicaragua',4,null,'The Wise Man Maduro bruker et San Andrés Maduro-dekkblad fra Mexico over en vintage nicaraguansk Corojo 99-bind. Toro Huaco er en tykk, kort vitola med konsentrert smak.'),
('Foundation Cigar Co','Foundation Cigar Co','The Wise Man Maduro','Torpedo','Torpedo',52,6.25,'Figurado','Torpedo','Pointed','Closed','Mexico','San Andres Maduro','Nicaraguan Corojo 99',array['Nicaragua'],'Nicaragua',4,null,'The Wise Man Maduro bruker et San Andrés Maduro-dekkblad fra Mexico over en vintage nicaraguansk Corojo 99-bind. Torpedo-formen gir et konsentrert trekk mot enden.'),
('Foundation Cigar Co','Foundation Cigar Co','The Wise Man Maduro','Churchill','Churchill',48,7.0,'Parejo',null,null,null,'Mexico','San Andres Maduro','Nicaraguan Corojo 99',array['Nicaragua'],'Nicaragua',4,null,'The Wise Man Maduro bruker et San Andrés Maduro-dekkblad fra Mexico over en vintage nicaraguansk Corojo 99-bind. Churchill er den lengste klassiske vitolaen i serien.'),
('Foundation Cigar Co','Foundation Cigar Co','The Wise Man Maduro','Lancero','Lancero',40,7.0,'Parejo',null,null,null,'Mexico','San Andres Maduro','Nicaraguan Corojo 99',array['Nicaragua'],'Nicaragua',4,null,'The Wise Man Maduro Lancero ble lansert i 2025 som en utvidelse av serien — 7x40, kakao, espresso og jord fra San Andrés-dekkbladet.');

-- ----------------------------------------------------------------
-- 4) The Tabernacle — super-premium all-maduro, Connecticut
--    Broadleaf-dekkblad, laget hos AJ Fernandez i Nicaragua
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Foundation Cigar Co','Foundation Cigar Co','The Tabernacle','Torpedo','Torpedo',52,4.5,'Figurado','Torpedo','Pointed','Closed','United States','Connecticut Broadleaf','Mexican San Andres',array['Nicaragua','Honduras'],'Nicaragua',4,null,'The Tabernacle er en super-premium all-maduro-linje med et mørkt, oljeaktig Connecticut Broadleaf-dekkblad — en hyllest til Nick Melillos hjemstat. Meksikansk San Andrés-bind og innmat fra Estelí, Jalapa og Jamastran. Kakao, lær og sort pepper.'),
('Foundation Cigar Co','Foundation Cigar Co','The Tabernacle','Corona','Corona',46,5.25,'Parejo',null,null,null,'United States','Connecticut Broadleaf','Mexican San Andres',array['Nicaragua','Honduras'],'Nicaragua',4,null,'The Tabernacle er en super-premium all-maduro-linje med et mørkt, oljeaktig Connecticut Broadleaf-dekkblad. Meksikansk San Andrés-bind og innmat fra Estelí, Jalapa og Jamastran.'),
('Foundation Cigar Co','Foundation Cigar Co','The Tabernacle','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'United States','Connecticut Broadleaf','Mexican San Andres',array['Nicaragua','Honduras'],'Nicaragua',4,null,'The Tabernacle er en super-premium all-maduro-linje med et mørkt, oljeaktig Connecticut Broadleaf-dekkblad. Meksikansk San Andrés-bind og innmat fra Estelí, Jalapa og Jamastran.'),
('Foundation Cigar Co','Foundation Cigar Co','The Tabernacle','Toro','Toro',52,6.0,'Parejo',null,null,null,'United States','Connecticut Broadleaf','Mexican San Andres',array['Nicaragua','Honduras'],'Nicaragua',4,null,'The Tabernacle er en super-premium all-maduro-linje med et mørkt, oljeaktig Connecticut Broadleaf-dekkblad. Meksikansk San Andrés-bind og innmat fra Estelí, Jalapa og Jamastran.'),
('Foundation Cigar Co','Foundation Cigar Co','The Tabernacle','Double Corona','Double Corona',54,7.0,'Parejo',null,null,null,'United States','Connecticut Broadleaf','Mexican San Andres',array['Nicaragua','Honduras'],'Nicaragua',4,null,'The Tabernacle er en super-premium all-maduro-linje med et mørkt, oljeaktig Connecticut Broadleaf-dekkblad. Double Corona er den lengste klassiske vitolaen, med lang røyketid og full smaksutvikling.'),
('Foundation Cigar Co','Foundation Cigar Co','The Tabernacle','Lancero','Lancero',40,7.0,'Parejo',null,null,null,'United States','Connecticut Broadleaf','Mexican San Andres',array['Nicaragua','Honduras'],'Nicaragua',4,null,'The Tabernacle er en super-premium all-maduro-linje med et mørkt, oljeaktig Connecticut Broadleaf-dekkblad. Lancero gir en raffinert, balansert opplevelse av maduro-profilen.'),
('Foundation Cigar Co','Foundation Cigar Co','The Tabernacle','David','Perfecto',54,5.0,'Figurado','Perfecto','Tapered','Closed','United States','Connecticut Broadleaf','Mexican San Andres',array['Nicaragua','Honduras'],'Nicaragua',4,null,'David er en perfecto-vitola i Tabernacle-linjen — kortere og smalere enn Goliath, men med samme mørke Connecticut Broadleaf-dekkblad og rike maduro-profil.'),
('Foundation Cigar Co','Foundation Cigar Co','The Tabernacle','Goliath','Perfecto',58,5.0,'Figurado','Perfecto','Tapered','Closed','United States','Connecticut Broadleaf','Mexican San Andres',array['Nicaragua','Honduras'],'Nicaragua',4,null,'Goliath er den tykkeste perfecto-vitolaen i Tabernacle-linjen — 58 ring gauge med samme mørke Connecticut Broadleaf-dekkblad og rike maduro-profil som resten av serien.');

-- ----------------------------------------------------------------
-- 5) Charter Oak — hyllest til Connecticut-dekkbladtradisjonen.
--    Finnes i to dekkbladvarianter: Connecticut Shade (mild/medium)
--    og Connecticut Broadleaf (medium). Eksisterende rad: Toro
--    (Broadleaf) — beholdes, ny Toro (Shade) får eget navn for å
--    unngå duplikat.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Foundation Cigar Co','Foundation Cigar Co','Charter Oak','Petite Corona (CT Shade)','Petit Corona',42,5.25,'Parejo',null,null,null,'United States','Connecticut Shade','Nicaraguan',array['Nicaragua'],'Nicaragua',2,null,'Charter Oak Connecticut Shade er en mild til medium hyllest til Connecticut-dekkbladtradisjonen, over aldret nicaraguansk innmat. Petite Corona er den slankeste vitolaen.'),
('Foundation Cigar Co','Foundation Cigar Co','Charter Oak','Rothschild (CT Shade)','Rothschild',50,4.5,'Parejo',null,null,null,'United States','Connecticut Shade','Nicaraguan',array['Nicaragua'],'Nicaragua',2,null,'Charter Oak Connecticut Shade er en mild til medium hyllest til Connecticut-dekkbladtradisjonen, over aldret nicaraguansk innmat. Rothschild er en kort, tykk vitola.'),
('Foundation Cigar Co','Foundation Cigar Co','Charter Oak','Lonsdale (CT Shade)','Lonsdale',46,6.25,'Parejo',null,null,null,'United States','Connecticut Shade','Nicaraguan',array['Nicaragua'],'Nicaragua',2,null,'Charter Oak Connecticut Shade er en mild til medium hyllest til Connecticut-dekkbladtradisjonen, over aldret nicaraguansk innmat. Lonsdale er en klassisk, slank vitola.'),
('Foundation Cigar Co','Foundation Cigar Co','Charter Oak','Toro (CT Shade)','Toro',52,6.0,'Parejo',null,null,null,'United States','Connecticut Shade','Nicaraguan',array['Nicaragua'],'Nicaragua',2,null,'Charter Oak Connecticut Shade er en mild til medium hyllest til Connecticut-dekkbladtradisjonen, over aldret nicaraguansk innmat. Toro er den mest populære vitolaen i serien.'),
('Foundation Cigar Co','Foundation Cigar Co','Charter Oak','Grande (CT Shade)','Gordo',60,6.0,'Parejo',null,null,null,'United States','Connecticut Shade','Nicaraguan',array['Nicaragua'],'Nicaragua',2,null,'Charter Oak Connecticut Shade er en mild til medium hyllest til Connecticut-dekkbladtradisjonen, over aldret nicaraguansk innmat. Grande er den tykkeste vitolaen, 60 ring gauge.'),
('Foundation Cigar Co','Foundation Cigar Co','Charter Oak','Petite Corona','Petit Corona',42,5.25,'Parejo',null,null,null,'United States','Connecticut Broadleaf','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Charter Oak Connecticut Broadleaf gir mer kropp og mørkere smak enn Shade-utgaven, fortsatt over aldret nicaraguansk innmat. Petite Corona er den slankeste vitolaen.'),
('Foundation Cigar Co','Foundation Cigar Co','Charter Oak','Rothschild','Rothschild',50,4.5,'Parejo',null,null,null,'United States','Connecticut Broadleaf','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Charter Oak Connecticut Broadleaf gir mer kropp og mørkere smak enn Shade-utgaven, fortsatt over aldret nicaraguansk innmat. Rothschild er en kort, tykk vitola.'),
('Foundation Cigar Co','Foundation Cigar Co','Charter Oak','Lonsdale','Lonsdale',46,6.25,'Parejo',null,null,null,'United States','Connecticut Broadleaf','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Charter Oak Connecticut Broadleaf gir mer kropp og mørkere smak enn Shade-utgaven, fortsatt over aldret nicaraguansk innmat. Lonsdale er en klassisk, slank vitola.'),
('Foundation Cigar Co','Foundation Cigar Co','Charter Oak','Grande','Gordo',60,6.0,'Parejo',null,null,null,'United States','Connecticut Broadleaf','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Charter Oak Connecticut Broadleaf gir mer kropp og mørkere smak enn Shade-utgaven, fortsatt over aldret nicaraguansk innmat. Grande er den tykkeste vitolaen, 60 ring gauge.'),
('Foundation Cigar Co','Foundation Cigar Co','Charter Oak','Pegnataro','Robusto',48,5.5,'Parejo',null,null,null,'United States','Connecticut Shade','Nicaraguan',array['Nicaragua'],'Nicaragua',2,null,'Charter Oak Especiales Pegnataro er en myk boks-presset Connecticut Shade-vitola, 5½×48 — en eksklusiv tilføyelse til Charter Oak-serien.'),
('Foundation Cigar Co','Foundation Cigar Co','Charter Oak','Pasquale','Robusto',48,5.5,'Parejo',null,null,null,'United States','Connecticut Broadleaf','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Charter Oak Especiales Pasquale er en myk boks-presset Connecticut Broadleaf-vitola, 5½×48 — en eksklusiv tilføyelse til Charter Oak-serien.');

-- ----------------------------------------------------------------
-- 6) Olmec Maduro — fullkroppet, meksikansk San Andrés Negro-dekkblad,
--    laget hos AJ Fernandez
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Foundation Cigar Co','Foundation Cigar Co','Olmec Maduro','Corona Gorda','Corona Gorda',48,5.5,'Parejo',null,null,null,'Mexico','San Andres Negro Maduro','Nicaraguan',array['Nicaragua'],'Nicaragua',5,null,'Olmec Maduro bruker et San Andrés Negro-dekkblad fra Mexico — en av verdens eldste tobakksfrøvarianter — over nicaraguansk bind og innmat fra Estelí og Jalapa, aldret minst tre år. Fullkroppet med kakao, kanel og espresso.'),
('Foundation Cigar Co','Foundation Cigar Co','Olmec Maduro','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Mexico','San Andres Negro Maduro','Nicaraguan',array['Nicaragua'],'Nicaragua',5,null,'Olmec Maduro bruker et San Andrés Negro-dekkblad fra Mexico over nicaraguansk bind og innmat fra Estelí og Jalapa, aldret minst tre år. Fullkroppet med kakao, kanel og espresso.'),
('Foundation Cigar Co','Foundation Cigar Co','Olmec Maduro','Toro','Toro',52,6.0,'Parejo',null,null,null,'Mexico','San Andres Negro Maduro','Nicaraguan',array['Nicaragua'],'Nicaragua',5,null,'Olmec Maduro bruker et San Andrés Negro-dekkblad fra Mexico over nicaraguansk bind og innmat fra Estelí og Jalapa, aldret minst tre år. Fullkroppet med kakao, kanel og espresso.'),
('Foundation Cigar Co','Foundation Cigar Co','Olmec Maduro','Grande','Gordo',60,6.0,'Parejo',null,null,null,'Mexico','San Andres Negro Maduro','Nicaraguan',array['Nicaragua'],'Nicaragua',5,null,'Olmec Maduro bruker et San Andrés Negro-dekkblad fra Mexico over nicaraguansk bind og innmat fra Estelí og Jalapa, aldret minst tre år. Grande er den tykkeste vitolaen.'),
('Foundation Cigar Co','Foundation Cigar Co','Olmec Maduro','Double Corona','Double Corona',52,7.0,'Parejo',null,null,null,'Mexico','San Andres Negro Maduro','Nicaraguan',array['Nicaragua'],'Nicaragua',5,null,'Olmec Maduro bruker et San Andrés Negro-dekkblad fra Mexico over nicaraguansk bind og innmat fra Estelí og Jalapa, aldret minst tre år. Double Corona er den lengste vitolaen, med lang røyketid.');

-- ----------------------------------------------------------------
-- 7) Highclere Castle — inspirert av slottet fra "Downton Abbey".
--    Tre underlinjer: Edwardian (mild/medium, CT Shade), Victorian
--    (medium, Ecuador Habano), Senetjer (limited, Ecuador Habano
--    7. priming, perfecto-form).
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Foundation Cigar Co','Foundation Cigar Co','Highclere Castle Edwardian','Petite Corona','Petit Corona',42,5.0,'Parejo',null,null,null,'United States','Connecticut Shade','Brazilian Mata Fina',array['Nicaragua'],'Nicaragua',2,null,'Highclere Castle Edwardian er inspirert av slottet fra TV-serien "Downton Abbey". Silkeaktig Connecticut Shade-dekkblad, brasiliansk Mata Fina-bind og en eksklusiv Criollo/Corojo-hybridinnmat ("Nicadan") fra Jalapa og Ometepe. Mild til medium, raffinert og rolig.'),
('Foundation Cigar Co','Foundation Cigar Co','Highclere Castle Edwardian','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'United States','Connecticut Shade','Brazilian Mata Fina',array['Nicaragua'],'Nicaragua',2,null,'Highclere Castle Edwardian er inspirert av slottet fra TV-serien "Downton Abbey". Silkeaktig Connecticut Shade-dekkblad, brasiliansk Mata Fina-bind og en eksklusiv Criollo/Corojo-hybridinnmat ("Nicadan") fra Jalapa og Ometepe.'),
('Foundation Cigar Co','Foundation Cigar Co','Highclere Castle Edwardian','Corona','Corona',46,5.5,'Parejo',null,null,null,'United States','Connecticut Shade','Brazilian Mata Fina',array['Nicaragua'],'Nicaragua',2,null,'Highclere Castle Edwardian er inspirert av slottet fra TV-serien "Downton Abbey". Silkeaktig Connecticut Shade-dekkblad, brasiliansk Mata Fina-bind og en eksklusiv Criollo/Corojo-hybridinnmat ("Nicadan") fra Jalapa og Ometepe.'),
('Foundation Cigar Co','Foundation Cigar Co','Highclere Castle Edwardian','Toro','Toro',52,6.0,'Parejo',null,null,null,'United States','Connecticut Shade','Brazilian Mata Fina',array['Nicaragua'],'Nicaragua',2,null,'Highclere Castle Edwardian er inspirert av slottet fra TV-serien "Downton Abbey". Silkeaktig Connecticut Shade-dekkblad, brasiliansk Mata Fina-bind og en eksklusiv Criollo/Corojo-hybridinnmat ("Nicadan") fra Jalapa og Ometepe.'),
('Foundation Cigar Co','Foundation Cigar Co','Highclere Castle Edwardian','Churchill','Churchill',48,7.0,'Parejo',null,null,null,'United States','Connecticut Shade','Brazilian Mata Fina',array['Nicaragua'],'Nicaragua',2,null,'Highclere Castle Edwardian er inspirert av slottet fra TV-serien "Downton Abbey". Silkeaktig Connecticut Shade-dekkblad, brasiliansk Mata Fina-bind og en eksklusiv Criollo/Corojo-hybridinnmat ("Nicadan") fra Jalapa og Ometepe. Churchill er den lengste vitolaen.'),
('Foundation Cigar Co','Foundation Cigar Co','Highclere Castle Victorian','Petit Corona','Petit Corona',42,5.0,'Parejo',null,null,null,'Ecuador','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Highclere Castle Victorian er håndrullet i Estelí, Nicaragua, med et luksuriøst Habano Ecuador-dekkblad fra øvre priming, over en kuratert Criollo/Corojo-innmat fra Estelí, Jalapa og Ometepe. Medium styrke, mer krydder og kropp enn Edwardian.'),
('Foundation Cigar Co','Foundation Cigar Co','Highclere Castle Victorian','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Highclere Castle Victorian er håndrullet i Estelí, Nicaragua, med et luksuriøst Habano Ecuador-dekkblad fra øvre priming, over en kuratert Criollo/Corojo-innmat fra Estelí, Jalapa og Ometepe.'),
('Foundation Cigar Co','Foundation Cigar Co','Highclere Castle Victorian','Corona','Corona',46,5.5,'Parejo',null,null,null,'Ecuador','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Highclere Castle Victorian er håndrullet i Estelí, Nicaragua, med et luksuriøst Habano Ecuador-dekkblad fra øvre priming, over en kuratert Criollo/Corojo-innmat fra Estelí, Jalapa og Ometepe.'),
('Foundation Cigar Co','Foundation Cigar Co','Highclere Castle Victorian','Toro','Toro',52,6.0,'Parejo',null,null,null,'Ecuador','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Highclere Castle Victorian er håndrullet i Estelí, Nicaragua, med et luksuriøst Habano Ecuador-dekkblad fra øvre priming, over en kuratert Criollo/Corojo-innmat fra Estelí, Jalapa og Ometepe.'),
('Foundation Cigar Co','Foundation Cigar Co','Highclere Castle Victorian','Churchill','Churchill',48,7.0,'Parejo',null,null,null,'Ecuador','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Highclere Castle Victorian er håndrullet i Estelí, Nicaragua, med et luksuriøst Habano Ecuador-dekkblad fra øvre priming, over en kuratert Criollo/Corojo-innmat fra Estelí, Jalapa og Ometepe. Churchill er den lengste vitolaen.'),
('Foundation Cigar Co','Foundation Cigar Co','Highclere Castle Senetjer','Senetjer','Perfecto',52,6.75,'Figurado','Perfecto','Tapered','Closed','Ecuador','Habano (7th priming)','Brazilian Mata Fina',array['Nicaragua'],'Nicaragua',4,null,'Highclere Castle Senetjer er en limited-utgave, kun i én perfecto-vitola (6¾×52). Ecuadoriansk Habano-dekkblad fra 7. priming, brasiliansk Mata Fina-bind og en udisclosed innmat aldret minst 3 år.');

-- ----------------------------------------------------------------
-- 8) ALIAS — vanlige skrivemåter/forkortelser for OCR/søk-treff
-- ----------------------------------------------------------------
insert into cigar_aliases (alias, manufacturer, brand, series) values
('Foundation', 'Foundation Cigar Co', 'Foundation Cigar Co', null),
('El Gueguense', 'Foundation Cigar Co', 'Foundation Cigar Co', 'El Güegüense'),
('El Güegüense', 'Foundation Cigar Co', 'Foundation Cigar Co', 'El Güegüense'),
('Wise Man', 'Foundation Cigar Co', 'Foundation Cigar Co', null),
('The Wise Man Corojo', 'Foundation Cigar Co', 'Foundation Cigar Co', 'The Wise Man Corojo'),
('The Wise Man Maduro', 'Foundation Cigar Co', 'Foundation Cigar Co', 'The Wise Man Maduro'),
('Tabernacle', 'Foundation Cigar Co', 'Foundation Cigar Co', 'The Tabernacle'),
('Charter Oak', 'Foundation Cigar Co', 'Foundation Cigar Co', 'Charter Oak'),
('Olmec', 'Foundation Cigar Co', 'Foundation Cigar Co', 'Olmec Maduro'),
('Highclere Castle', 'Foundation Cigar Co', 'Foundation Cigar Co', null);
