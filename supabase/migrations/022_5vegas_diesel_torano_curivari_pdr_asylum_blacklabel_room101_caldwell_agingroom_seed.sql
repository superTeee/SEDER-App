-- ============================================================
-- 022_5vegas_diesel_torano_curivari_pdr_asylum_blacklabel_room101_caldwell_agingroom_seed.sql
--
-- Oppfølging av "hvilke sigar brands mangler?"-gjennomgangen.
-- Etter migrasjon 020-021 dekket databasen alle 40 Holt's
-- "Top Brands". Denne migrasjonen legger til 10 kjente merker
-- som fortsatt manglet helt fra den bredere referanselisten —
-- 30 nye rader totalt (3 vitolas pr. merke). Drew Estates
-- undermerker (Liga Privada, Undercrown, Herrera Estelí,
-- Nica Rustica) var allerede dekket som serier og er IKKE
-- berørt av denne migrasjonen.
--
-- Nye merker (alle helt nye i databasen):
--   1) 5 Vegas (General Cigar, Nicaragua/blandet)
--   2) Diesel (General Cigar/AJ Fernandez, Nicaragua)
--   3) Torano / Carlos Torano (Honduras/Nicaragua/Den. Rep.)
--   4) Curivari (Nicaragua)
--   5) PDR Cigars (Den. Rep.)
--   6) Asylum (Christian Eiroa, Nicaragua/Honduras)
--   7) Black Label Trading Co. (Nicaragua/Honduras)
--   8) Room101 (Matt Booth / General Cigar, Nicaragua/Honduras)
--   9) Caldwell Cigar Co. (Robert Caldwell, Den. Rep./Honduras)
--  10) Aging Room (Boutique Blends, Rafael Nodal, Den. Rep.)
--
-- Smaksnoter og beskrivelser satt direkte ved innsetting, samme
-- konvensjon som migrasjon 016-021.
--
-- Kilder: cigar.com, holts.com, 5vegas.com, cigarsinternational.com,
-- elementvape.com, dieselcigars.com, klarocigars.com, famous-smoke.com,
-- cigarsinternational.com, nhcigars.com, cigarmonthclub.com,
-- privadacigarclub.com, leafenthusiast.com, havanahouse.co.uk,
-- pdrcigars.com, cigarcountry.com, bnbtobacco.com, neptunecigar.com,
-- casasfumando.com, cigarpage.com, halfwheel.com, room101cigars.com,
-- developingpalates.com, cigar-coop.com, mikescigars.com, hilandscigars.com
-- ============================================================

-- ----------------------------------------------------------------
-- 1) 5 Vegas — General Cigar-merke. Gold er mildest (Connecticut),
--    Classic medium (Sumatra), Series 'A' fyldigst (Costa Rica Maduro).
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('General Cigar Co.','5 Vegas','Gold','Toro','Toro',52,6.0,'Parejo',null,null,null,'United States','Connecticut','Honduran',array['Nicaragua','Honduras'],'Nicaragua',2,null,'5 Vegas Gold er den mildeste linjen i sortimentet, laget av 5 år lagret tobakk med et lyst Connecticut-dekkblad.',array['cream','cedar','honey','light spice']),
('General Cigar Co.','5 Vegas','Classic','Toro','Toro',52,6.0,'Parejo',null,null,null,'Nicaragua','Sumatra','Dominican',array['Nicaragua','Dominican Republic'],'Nicaragua',3,null,'5 Vegas Classic bruker et mørkt Sumatra-dekkblad over cubansk-frø-tobakk fra Nicaragua og Den. Rep. — medium-fyldig.',array['cedar','earth','light pepper','toasted nuts']),
('General Cigar Co.','5 Vegas','Series A','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Costa Rica','Maduro','Honduran',array['Nicaragua','Honduras','Dominican Republic'],'Nicaragua',5,null,'Series A er den fyldigste 5 Vegas-linjen, med et mørkt, oljete Costa Rica Maduro-dekkblad og 4 år lagret innmat.',array['coffee','earth','sweet spice','dark chocolate']);

-- ----------------------------------------------------------------
-- 2) Diesel — General Cigar/AJ Fernandez-samarbeid, kjent for
--    kraftige, industrielt navngitte blends. Whiskey Row er
--    bourbon-tønne-lagret bind, Estelí Puro er 100% nicaraguansk.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('AJ Fernandez','Diesel','Whiskey Row','Toro','Toro',52,6.0,'Parejo',null,null,null,'Ecuador','Habano','Mexican San Andres',array['Nicaragua'],'Nicaragua',3,null,'Diesel Whiskey Row har et 5 år lagret ecuadoriansk Habano-dekkblad over et bourbon-tønne-lagret meksikansk San Andrés-bind.',array['oak','bourbon','sweet spice','floral']),
('AJ Fernandez','Diesel','Estelí Puro','Robusto','Robusto',52,5.0,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Estelí Puro er laget 100% av nicaraguansk tobakk fra Estelí-regionen — en av de kraftigste Diesel-utgivelsene.',array['earth','espresso','leather','white pepper']),
('AJ Fernandez','Diesel','Unlimited Maduro','Robusto','Robusto',54,5.0,'Parejo',null,null,null,'Mexico','San Andres Maduro','Nicaraguan',array['Nicaragua'],'Nicaragua',5,null,'Unlimited Maduro er den fyldigste Diesel-linjen, med et søtladent meksikansk San Andrés-dekkblad og en intens, kompleks profil.',array['dark chocolate','espresso','black pepper','earth']);

-- ----------------------------------------------------------------
-- 3) Torano / Carlos Torano — kubansk familiemerke som flyktet til
--    USA i 1959 (derav Exodus 1959). Gold bruker Habano H-2000-
--    dekkblad, 50 Years brasiliansk Arapiraca, Casa Torano er det
--    mildeste — opprinnelig et "house blend" til arrangementer.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Carlos Torano','Torano','Casa Torano','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Connecticut Shade','Nicaraguan',array['Dominican Republic','Honduras','Nicaragua'],'Nicaragua',2,null,'Casa Torano var opprinnelig et eksklusivt "house blend" delt ut på arrangementer — mild-medium med gyllent ecuadoriansk Connecticut-dekkblad.',array['cream','sweet spice','light pepper','earth']),
('Carlos Torano','Torano','Exodus 1959 50 Years','Robusto','Robusto',50,5.5,'Parejo',null,null,null,'Brazil','Arapiraca','Honduran',array['Dominican Republic','Honduras','Nicaragua'],'Honduras',3,null,'Exodus 1959 50 Years feirer familiens 50-årsjubileum med et solgrodd brasiliansk Arapiraca-dekkblad — medium styrke.',array['cedar','dark fruit','cocoa','light spice']),
('Carlos Torano','Torano','Exodus 1959 Gold','Toro','Toro',52,6.0,'Parejo',null,null,null,'Nicaragua','Habano H-2000','Honduran',array['Dominican Republic','Honduras','Nicaragua','Costa Rica'],'Honduras',4,null,'Exodus Gold bruker et Habano H-2000-dekkblad og en kompleks fem-lands-blend — medium til full styrke.',array['leather','espresso','cedar','black pepper']);

-- ----------------------------------------------------------------
-- 4) Curivari — nicaraguansk merke kjent for lagret tobakk. Achilles
--    er den kraftigste linjen, Buenaventura finnes i tre dekkblad-
--    varianter med stigende styrke (Connecticut → Natural → Maduro).
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Curivari','Curivari','Buenaventura Connecticut','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Connecticut','Nicaraguan',array['Nicaragua'],'Nicaragua',2,null,'Buenaventura Connecticut er den mildeste varianten i Favoritos-linjen, med et lyst ecuadoriansk dekkblad.',array['cream','cedar','honey','light spice']),
('Curivari','Curivari','Buenaventura Natural','Toro','Toro',52,6.0,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Buenaventura Natural bruker et nicaraguansk Habano-dekkblad — medium styrke med en balansert, jordnær profil.',array['cedar','earth','cocoa','light pepper']),
('Curivari','Curivari','Achilles Mirmidones','Robusto','Robusto',54,5.0,'Parejo',null,null,null,'Mexico','San Andres Maduro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Achilles Mirmidones er den kraftigste Curivari-linjen, med et søtladent meksikansk San Andrés Maduro-dekkblad.',array['sweet pepper','cedar','caramel','dark chocolate']);

-- ----------------------------------------------------------------
-- 5) PDR Cigars — dominikansk merke grunnlagt 2004 av master blender
--    Abe Flores i Tamboril. AFR-75 er den kraftigste, El Trovador
--    medium med Rosado-dekkblad, 1878 Natural Roast Café mildest.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('PDR Cigars','PDR','1878 Natural Roast Café','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Connecticut','Dominican',array['Dominican Republic'],'Dominican Republic',2,null,'1878 Natural Roast Café er en mild, kremet sigar med ecuadoriansk Connecticut-dekkblad — laget av master blender Abe Flores.',array['cream','coffee','cedar','vanilla']),
('PDR Cigars','PDR','El Trovador','Toro','Toro',52,6.0,'Parejo',null,null,null,'Ecuador','Rosado','Dominican',array['Dominican Republic','Nicaragua'],'Dominican Republic',3,null,'El Trovador bruker et ecuadoriansk Rosado-dekkblad og gir en medium-fyldig, balansert profil.',array['cedar','dried fruit','cocoa','light spice']),
('PDR Cigars','PDR','AFR-75','Robusto','Robusto',52,5.0,'Parejo',null,null,null,'Mexico','San Andres Maduro','Nicaraguan',array['Nicaragua','Dominican Republic'],'Dominican Republic',4,null,'AFR-75 er den kraftigste PDR-linjen, med et mørkt meksikansk San Andrés-dekkblad og en rik, krydret profil.',array['dark chocolate','espresso','black pepper','earth']);

-- ----------------------------------------------------------------
-- 6) Asylum — grunnlagt av Christian Eiroa. Medulla bruker honduransk
--    Corojo (medium), Insidious var første med Connecticut-dekkblad
--    (medium), Ogre er en barber pole-sigar med dobbelt dekkblad
--    (medium-full).
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Christian Eiroa','Asylum','13 Medulla','Robusto','Robusto',52,6.0,'Parejo',null,null,null,'Honduras','Corojo','Honduran',array['Honduras'],'Honduras',3,null,'Asylum 13 Medulla bruker 100% honduransk Corojo-tobakk — medium styrke med en fyldig, jordnær karakter.',array['earth','cocoa','dark tobacco spice','leather']),
('Christian Eiroa','Asylum','Insidious','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Connecticut','Honduran',array['Honduras'],'Honduras',3,null,'Insidious var den første Asylum-sigaren med ecuadoriansk Connecticut-dekkblad — medium og ultra-glatt.',array['cream','cedar','sweet spice','honey']),
('Christian Eiroa','Asylum','13 Ogre','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Nicaragua','Candela/Habano','Honduran',array['Honduras'],'Honduras',4,null,'Ogre er en "barber pole"-sigar med dobbelt Candela- og Habano-dekkblad fra Nicaragua — medium til full styrke.',array['grass','wood','mild spice','cocoa']);

-- ----------------------------------------------------------------
-- 7) Black Label Trading Co. — boutique-merke grunnlagt 2013, kjent
--    for nicaraguansk/honduransk tobakk i små, limiterte partier.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Black Label Trading Co.','Black Label Trading Co.','Deliverance Porcelain','Robusto','Robusto',50,5.5,'Parejo',null,null,null,'Nicaragua','Natural Nicaraguan','Nicaraguan',array['Nicaragua','United States'],'Nicaragua',4,null,'Deliverance Porcelain starter medium og bygger seg opp i styrke og fylde — nicaraguansk bind og innmat med litt Pennsylvania-tobakk.',array['cedar','earth','light pepper','cream']),
('Black Label Trading Co.','Black Label Trading Co.','Salvation','Toro','Toro',52,6.0,'Parejo',null,null,null,'Ecuador','Sun Grown','Honduran',array['Nicaragua'],'Honduras',4,null,'Salvation bruker et Ecuador Sun Grown-dekkblad over honduransk bind og nicaraguansk innmat — medium til full styrke.',array['earth','black pepper','toasted cedar','cocoa']),
('Black Label Trading Co.','Black Label Trading Co.','Last Rites','Robusto','Robusto',54,5.0,'Parejo',null,null,null,'Ecuador','Maduro','Honduran',array['Honduras','Nicaragua'],'Honduras',4,null,'Last Rites har et ecuadoriansk Maduro-dekkblad og gir en sirupsaktig, medium-full profil.',array['earth','black pepper','dark coffee','dark chocolate']);

-- ----------------------------------------------------------------
-- 8) Room101 — grunnlagt av smykkedesigner Matt Booth, nå eid av
--    General Cigar. Daruma er produsert hos Camacho/i Nicaragua,
--    Farce finnes i flere dekkbladvarianter.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Room101','Room101','Farce Connecticut','Toro','Toro',52,6.0,'Parejo',null,null,null,'Ecuador','Connecticut','Indonesian',array['Dominican Republic','Nicaragua','United States'],'Nicaragua',3,null,'Farce Connecticut er den mildeste varianten i Farce-linjen, med et lyst ecuadoriansk dekkblad.',array['cream','cedar','sweet hay','light spice']),
('Room101','Room101','Farce','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Habano','Indonesian',array['Dominican Republic','Nicaragua','United States'],'Nicaragua',4,null,'Farce bruker et ecuadoriansk Habano-dekkblad over indonesisk bind og innmat fra tre land — medium til full styrke.',array['leather','cedar','black pepper','cocoa']),
('Room101','Room101','Daruma','Toro','Toro',52,6.0,'Parejo',null,null,null,'Ecuador','Habano','Brazilian',array['Dominican Republic','Honduras'],'Nicaragua',4,null,'Daruma har et gyllenbrunt, toothy ecuadoriansk Habano-dekkblad over et brasiliansk bind — medium til full styrke.',array['coffee bean','cedar','spice','cocoa']);

-- ----------------------------------------------------------------
-- 9) Caldwell Cigar Co. — grunnlagt av Robert Caldwell. Long Live
--    the King er full styrke med dominikansk Corojo, Blind Man's
--    Bluff er mer tilgjengelig med ecuadoriansk Habano, Lost and
--    Found gir gamle/obskure blends et nytt liv under Caldwell-navn.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Caldwell Cigar Co.','Caldwell','Lost and Found Almirante','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Lost and Found-serien gir sjeldne restpartier fra andre fabrikker nytt liv under Caldwell-merket — Almirante er medium styrke.',array['cedar','cocoa','light pepper','dried fruit']),
('Caldwell Cigar Co.','Caldwell','Blind Man''s Bluff','Toro','Toro',52,6.0,'Parejo',null,null,null,'Ecuador','Habano','Honduran',array['Dominican Republic','Honduras'],'Honduras',4,null,'Blind Man''s Bluff starter medium og bygger seg opp mot full styrke, med et oljete ecuadoriansk Habano-dekkblad.',array['cedar','bread','sweet spice','dried fruit']),
('Caldwell Cigar Co.','Caldwell','Long Live the King','Robusto','Robusto',54,5.75,'Parejo',null,null,null,'Dominican Republic','Corojo','Dominican',array['Dominican Republic','Peru','Nicaragua'],'Dominican Republic',5,null,'Long Live the King er Corojo "all the way through" — dekkblad, bind og deler av innmaten — og er full styrke fra første trekk.',array['black pepper','leather','earth','dark spice']);

-- ----------------------------------------------------------------
-- 10) Aging Room — Boutique Blends Cigars, blendet av Rafael Nodal
--     i Den. Rep. Quattro F55 er den mest prisbelønte (sjeldent
--     indonesisk Sumatra-dekkblad), Small Batch og Core er medium-
--     full med Habano-dekkblad.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Boutique Blends Cigars','Aging Room','Core','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Dominican Republic','Habano','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Aging Room Core bruker et dominikansk Habano-dekkblad — medium til full styrke med noter av kanel og krydder.',array['cinnamon','vanilla','spice','leather']),
('Boutique Blends Cigars','Aging Room','Small Batch','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Habano','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Small Batch var den opprinnelige Aging Room-linjen, blendet av Rafael Nodal med et ecuadoriansk Habano-dekkblad.',array['leather','cedar','dark spice','cocoa']),
('Boutique Blends Cigars','Aging Room','Quattro F55','Toro','Toro',50,7.0,'Parejo',null,null,null,'Indonesia','Sumatra','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Quattro F55 er boxpresset med et sjeldent, 2003-lagret indonesisk Sumatra-dekkblad — kåret til en av verdens topp-25-sigarer.',array['sweet cedar','spice','cream','dark coffee']);
