-- ============================================================
-- 021_avo_cain_epcarrillo_nub_sancristobal_southerndraw_seed.sql
--
-- Oppfølging av Holt's "Top Brands"-gap-analysen (migrasjon 020).
-- Disse 6 merkene fantes med kun 1 rad hver i databasen (kun
-- én serie/vitola representert). Denne migrasjonen legger til
-- 3 nye serier/vitolas per merke for bedre dekning — 18 rader
-- totalt. Eksisterende rad for hvert merke er IKKE rørt.
--
-- Eksisterende rad pr. merke (uendret):
--   - Avo: Classic, Toro
--   - Cain: Cain F, Robusto
--   - E.P. Carrillo: Pledge, Toro
--   - Nub: Connecticut, Nub 460
--   - San Cristobal: Elegancia, Toro
--   - Southern Draw: Firethorn, Toro
--
-- Nye serier lagt til:
--   1) Avo (Davidoff, Den. Rep.) — XO Intermezzo, Syncro Nicaragua,
--      Syncro Fogata
--   2) Cain (Oliva, Nicaragua) — Daytona, Habano, Maduro
--   3) E.P. Carrillo (Den. Rep.) — Encore, La Historia, Inch
--   4) Nub (Oliva/Studio Tobac, Nicaragua) — Habano, Maduro, Cameroon
--   5) San Cristobal (My Father, Estelí) — Revelation, Quintessence,
--      Ovation
--   6) Southern Draw (boutique, Nicaragua) — Rose of Sharon, Cedrus,
--      Kudzu
--
-- Smaksnoter og beskrivelser satt direkte ved innsetting, samme
-- konvensjon som migrasjon 016-020.
--
-- Kilder: holts.com, cuencacigars.com, famous-smoke.com,
-- cigarsinternational.com, neptunecigar.com, cigarworld.com,
-- casasfumando.com, davidoffgeneva.com, cigarcountry.com,
-- gothamcigars.com, elementvape.com, sancristobalcigar.com,
-- cigaraficionado.com, finckcigarcompany.com, halfwheel.com,
-- cigars.com
-- ============================================================

-- ----------------------------------------------------------------
-- 1) Avo — grunnlagt av Avo Uvezian, eies av Davidoff, produsert i
--    Den. Rep. XO er medium-fyldig med ecuadoriansk Connecticut-
--    dekkblad. Syncro-serien kombinerer tobakk fra flere land —
--    Nicaragua-utgaven er medium-fyldig, Fogata er kraftigere.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Davidoff','Avo','XO','Intermezzo','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Connecticut','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'AVO XO Intermezzo er medium-fyldig med et lyst, silkeaktig ecuadoriansk Connecticut-dekkblad over alt-dominikansk bind og innmat.',array['cream','cedar','vanilla','light spice']),
('Davidoff','Avo','Syncro Nicaragua','Toro','Toro',52,6.0,'Parejo',null,null,null,'Ecuador','Connecticut','Dominican',array['Nicaragua','Dominican Republic'],'Dominican Republic',3,null,'Syncro Nicaragua kombinerer nicaraguansk innmat med et glatt ecuadoriansk Connecticut-dekkblad — en medium-fyldig, balansert profil.',array['cocoa','cedar','coffee','cream']),
('Davidoff','Avo','Syncro Fogata','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Syncro Fogata er den kraftigste Syncro-utgivelsen, med et nicaraguansk habano-dekkblad og en ristet, krydret karakter.',array['toasted wood','black pepper','cocoa','earth']);

-- ----------------------------------------------------------------
-- 2) Cain — laget av Oliva Cigar Company i Nicaragua, kjent for
--    trippel-fermentert ligero-tobakk. Daytona er den mildeste
--    (kun ligero fra Jalapa), Habano ligger i midten, Maduro er
--    fyldigst med søtladen San Andrés-dekkblad.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Oliva','Cain','Daytona','Toro','Toro',52,6.0,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Cain Daytona er den mest tilgjengelige linjen i Cain-sortimentet, og bruker kun ligero-tobakk fra Jalapa for en jevnere, medium-fyldig profil.',array['cedar','cocoa','light pepper','toasted nuts']),
('Oliva','Cain','Habano','Robusto','Robusto',52,5.0,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Cain Habano ligger mellom Daytona og Cain F i styrke — en medium-full, krydret profil med samme trippel-fermenterte ligero-innmat.',array['leather','black pepper','espresso','cedar']),
('Oliva','Cain','Maduro','Robusto','Robusto',52,5.0,'Parejo',null,null,null,'Mexico','San Andres Maduro','Nicaraguan',array['Nicaragua'],'Nicaragua',5,null,'Cain Maduro er den fyldigste linjen, med et søtladent, sjokoladefarget San Andrés-dekkblad over rett ligero-innmat.',array['dark chocolate','espresso','black pepper','earth']);

-- ----------------------------------------------------------------
-- 3) E.P. Carrillo — Ernesto Perez-Carrillo, produsert i Den. Rep.
--    Encore bruker et ecuadoriansk Sumatra-dekkblad og er medium-
--    full. La Historia er den kraftigste, med nicaraguansk habano-
--    dekkblad. Inch-serien er kjent for sine store ringmål.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('E.P. Carrillo','E.P. Carrillo','Encore','Toro','Toro',52,6.0,'Parejo',null,null,null,'Ecuador','Sumatra','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'E.P. Carrillo Encore bruker et ecuadoriansk Sumatra-dekkblad over dominikansk bind og innmat — medium-full styrke med rik smak.',array['leather','cocoa','espresso','cedar']),
('E.P. Carrillo','E.P. Carrillo','La Historia','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Nicaragua','Habano','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'La Historia er den kraftigste linjen fra E.P. Carrillo, med et nicaraguansk habano-dekkblad og en fyldig, kompleks profil.',array['black pepper','dark chocolate','leather','dried fruit']),
('E.P. Carrillo','E.P. Carrillo','Inch','No. 60','Gordo',60,5.5,'Parejo',null,null,null,'Ecuador','Habano','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Inch-serien er kjent for sine uvanlig store ringmål — No. 60 bruker et ecuadoriansk habano-dekkblad og gir en lang, rolig røykeopplevelse.',array['cedar','toasted nuts','cocoa','light spice']);

-- ----------------------------------------------------------------
-- 4) Nub — designet av Sam Leccia, produsert hos Oliva/Studio Tobac
--    i Nicaragua. Kort og fyldig "short and fat"-format. Habano er
--    medium-full, Maduro er fyldigst med Connecticut Broadleaf-
--    dekkblad, Cameroon er den mildeste varianten.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Studio Tobac','Nub','Habano','Nub 358','Robusto',58,3.75,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Nub Habano 358 er en kort, bred "short and fat"-sigar med nicaraguansk habano-dekkblad og medium-full styrke.',array['black pepper','cedar','espresso','earth']),
('Studio Tobac','Nub','Maduro','Nub 464','Robusto',64,4.0,'Parejo',null,null,null,'United States','Connecticut Broadleaf','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Nub Maduro 464 har et mørkt Connecticut Broadleaf-dekkblad — den fyldigste varianten i Nub-sortimentet, med søte, jordnære noter.',array['dark chocolate','molasses','earth','espresso']),
('Studio Tobac','Nub','Cameroon','Nub 354','Robusto',54,3.75,'Parejo',null,null,null,'Cameroon','Cameroon','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Nub Cameroon 354 er den mildeste varianten, med et karakteristisk grynet Cameroon-dekkblad og en kortere, kompakt røyketid.',array['cedar','nuts','light spice','cream']);

-- ----------------------------------------------------------------
-- 5) San Cristobal — laget av Garcia-familien på My Father-
--    fabrikken i Estelí, Nicaragua. Revelation bruker Ecuador
--    Sumatra-dekkblad (medium), Quintessence Ecuador Habano
--    (medium-full), Ovation et mørkt meksikansk San Andrés-
--    dekkblad (fyldigst, ultra-limited).
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('My Father Cigars','San Cristobal','Revelation','Toro','Toro',54,6.0,'Parejo',null,null,null,'Ecuador','Sumatra','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'San Cristobal Revelation har et melkesjokoladefarget ecuadoriansk Sumatra-dekkblad over eldre nicaraguansk bind og innmat — medium styrke.',array['cream','cocoa','cedar','light spice']),
('My Father Cigars','San Cristobal','Quintessence','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Quintessence er medium-full med ecuadoriansk habano-dekkblad — kjent for noter av kaffe, krydder og en rik, unik sødme.',array['coffee','spice','sweet cedar','cocoa']),
('My Father Cigars','San Cristobal','Ovation','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Mexico','San Andres','Nicaraguan',array['Nicaragua'],'Nicaragua',5,null,'Ovation er en ultra-limitert utgivelse med et mørkt meksikansk San Andrés-dekkblad — den fyldigste og mest luksuriøse San Cristobal-utgivelsen.',array['dark chocolate','leather','espresso','dried fruit']);

-- ----------------------------------------------------------------
-- 6) Southern Draw — boutique-merke grunnlagt av Robert Holt,
--    produsert i Nicaragua. Rose of Sharon bruker et ecuadoriansk
--    Connecticut Shade-dekkblad (medium). Cedrus har et indonesisk
--    dekkblad (medium-full). Kudzu bruker et dobbelt-fermentert
--    ecuadoriansk habano-dekkblad (fyldigst).
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Southern Draw','Southern Draw','Rose of Sharon','Robusto','Robusto',54,5.5,'Parejo',null,null,null,'Ecuador','Connecticut Shade','Nicaraguan',array['Dominican Republic','Nicaragua'],'Nicaragua',3,null,'Rose of Sharon har et ecuadoriansk Connecticut Shade-dekkblad over nicaraguansk bind og en blanding av dominikansk piloto cubano og nicaraguansk innmat — medium styrke.',array['cream','cedar','sweet spice','hay']),
('Southern Draw','Southern Draw','Cedrus','Toro','Toro',52,6.0,'Parejo',null,null,null,'Indonesia','Sumatra','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Cedrus bruker et indonesisk dekkblad og gir en medium til full-fyldig profil med tydelige noter av pepper, sedertre og urter.',array['black pepper','cedar','herbal','earth']),
('Southern Draw','Southern Draw','Kudzu','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',5,null,'Kudzu er den fyldigste Southern Draw-linjen, med et dobbelt-fermentert ecuadoriansk habano-dekkblad og en rik profil av kakao og krydder.',array['cedar','cocoa','spice','dark coffee']);
