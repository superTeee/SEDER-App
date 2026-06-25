-- ============================================================
-- 020_argyle_baccarat_donlino_granhabano_kristoff_laaromadecuba_
--     lagloriacubana_oldhenry_mulligans_villiger_seed.sql
--
-- Tom ba om å sjekke databasen mot Holt's Cigar Company sin
-- "Top Brands"-liste (40 merker). Av disse var 10 merker helt
-- fraværende fra databasen (0 rader hver). Denne migrasjonen
-- legger inn disse 10 merkene, slik Tom ba om: "begynn med de
-- 10 helt fraværende".
--
-- De 10 nye merkene (3 vitolas hver, 30 rader totalt):
--   1) Argyle          — Holt's-merke, Fumas (Sumatra) + Dark Corojo
--   2) Baccarat        — klassisk honduransk bundlemerke, Candela
--   3) Don Lino         — opprinnelig Honduras, nå Dominikansk Rep.
--   4) Gran Habano      — Honduras, Corojo #5 og Connecticut #1
--   5) Kristoff         — Den. Rep., nicaraguansk og criollo-linje
--   6) La Aroma de Cuba — General Cigar/Dominikansk Rep.
--   7) La Gloria Cubana — General Cigar, Serie R / Serie R Estelí
--   8) Old Henry        — blandet av Pepin Garcia, Nicaragua
--   9) Rocky Patel Mulligans — golf-tema, Honduras
--  10) Villiger          — sveitsisk merke, Export + San'Doro
--
-- Smaksnoter og beskrivelser satt direkte ved innsetting, samme
-- konvensjon som migrasjon 016-019.
--
-- Kilder: holts.com (brand-sider + staff reviews), cigar.com,
-- neptunecigar.com, cigarsdaily.com, halfwheel.com,
-- cigarobsession.com, bestcigarprices.com, thecigarstore.com,
-- casasfumando.com, stogieguys.com
-- ============================================================

-- ----------------------------------------------------------------
-- 1) Argyle — Holt's-eksklusivt merke produsert i Honduras/Den.
--    Rep. Fumas-linjen bruker et oljete Sumatra-dekkblad over et
--    "Cuban-sandwich"-innmat (kort + lang fyll) fra Nicaragua —
--    mild til medium. Dark Corojo er den kraftigste i sortimentet.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Argyle','Argyle','Fumas','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Indonesia','Sumatra','Nicaraguan',array['Nicaragua'],'Nicaragua',2,null,'Argyle Fumas Robusto er en mild til medium-fyldig "Cuban-sandwich"-sigar med et oljete, ingefærbrunt Sumatra-dekkblad.',array['coffee bean','cream','baking spice','nuts']),
('Argyle','Argyle','Fumas','Toro','Toro',52,6.0,'Parejo',null,null,null,'Indonesia','Sumatra','Nicaraguan',array['Nicaragua'],'Nicaragua',2,null,'Toro-utgaven av Argyle Fumas gir samme kremede, lett kryddrede profil i et lengre format.',array['coffee bean','cream','cedar','nuts']),
('Argyle','Argyle','Dark Corojo','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Honduras','Corojo','Honduran',array['Honduras'],'Honduras',3,null,'Dark Corojo er en av de kraftigste utgivelsene i Argyle-sortimentet, med et mørkt corojo-dekkblad og medium styrke.',array['black pepper','cedar','earth','toasted nuts']);

-- ----------------------------------------------------------------
-- 2) Baccarat — klassisk honduransk bundlemerke kjent for sitt
--    søte munnstykke ("sweet tip") og lyse Candela-dekkblad. Den
--    nyere Nicaragua-linjen bruker nicaraguansk puro-tobakk og er
--    en god del kraftigere enn originalen.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Baccarat','Baccarat','Original','Rothschild','Robusto',50,4.5,'Parejo',null,null,null,'Honduras','Candela','Honduran',array['Honduras'],'Honduras',1,null,'Baccarat Rothschild er en klassisk mild bundlesigar med et lyst Candela-dekkblad og det signaturmessige søte munnstykket.',array['sweet tip','hay','mild cedar','cream']),
('Baccarat','Baccarat','Original','Churchill','Churchill',48,7.0,'Parejo',null,null,null,'Honduras','Candela','Honduran',array['Honduras'],'Honduras',1,null,'Churchill-formatet av Baccarat gir samme milde, søte profil i et lengre format — en avslappet, rolig røyk.',array['sweet tip','hay','cream','mild cedar']),
('Baccarat','Baccarat','Nicaragua','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Baccarat Nicaragua er en nyere, kraftigere linje bygget på 100% nicaraguansk puro-tobakk — en god del fyldigere enn det klassiske Candela-merket.',array['leather','cedar','black pepper','dried fruit']);

-- ----------------------------------------------------------------
-- 3) Don Lino — opprinnelig produsert i Honduras, senere flyttet
--    til Den. Rep. Casa Verde bruker et grønt Candela-dekkblad og
--    er mild og all-dominikansk. Fumas bruker Sumatra-dekkblad og
--    er medium-fyldig. Millennium er den mer premium Connecticut-
--    linjen.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Don Lino','Don Lino','Casa Verde','Toro','Toro',54,6.0,'Parejo',null,null,null,'Dominican Republic','Candela','Dominican',array['Dominican Republic'],'Dominican Republic',1,null,'Don Lino Casa Verde har et grønt Candela-dekkblad over en mild, all-dominikansk innmat — friske noter av grønn te og høy.',array['green tea','hay','buttered toast','fennel']),
('Don Lino','Don Lino','Fumas','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Indonesia','Sumatra','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Don Lino Fumas er en medium-fyldig "Cuban-sandwich"-sigar med karamellbrunt Sumatra-dekkblad over nicaraguansk innmat.',array['wood','nougat','cedar','earth']),
('Don Lino','Don Lino','Millennium','Toro','Toro',52,6.0,'Parejo',null,null,null,'Ecuador','Connecticut','Dominican',array['Dominican Republic'],'Dominican Republic',2,null,'Millennium er den mer premium Connecticut-linjen fra Don Lino — mild til medium-fyldig med et kremet, dominikansk innmat.',array['cream','cedar','honey','light spice']);

-- ----------------------------------------------------------------
-- 4) Gran Habano — håndrullet i Honduras. Corojo #5 er den
--    kraftigste blandingen i sortimentet (nicaraguansk corojo-
--    dekkblad), mens Connecticut #1 (ecuadoriansk Connecticut) er
--    den mildeste. Habano #3 ligger midt mellom de to.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Gran Habano','Gran Habano','Corojo #5','Gran Robusto','Robusto',54,6.0,'Parejo',null,null,null,'Nicaragua','Corojo','Nicaraguan Cuban-seed',array['Nicaragua','Costa Rica'],'Honduras',5,null,'Gran Habano Corojo #5 er den kraftigste blandingen i sortimentet — et oljete nicaraguansk corojo-dekkblad over nicaraguansk/costaricansk innmat.',array['charcoal','anise','black cherry','spice']),
('Gran Habano','Gran Habano','Connecticut #1','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Connecticut','Nicaraguan',array['Nicaragua'],'Honduras',2,null,'Connecticut #1 er den mildeste og mest budsjettvennlige linjen fra Gran Habano, med et lyst ecuadoriansk Connecticut-dekkblad.',array['nuts','coffee bean','leather','cream']),
('Gran Habano','Gran Habano','Habano #3','Toro','Toro',52,6.0,'Parejo',null,null,null,'Honduras','Habano','Nicaraguan',array['Nicaragua'],'Honduras',3,null,'Habano #3 ligger mellom Corojo #5 og Connecticut #1 i styrke — en balansert, medium-fyldig profil.',array['cedar','earth','toasted bread','light pepper']);

-- ----------------------------------------------------------------
-- 5) Kristoff — grunnlagt av Glen Case, produsert i Den. Rep.
--    Nicaragua-linjen er en 100% nicaraguansk puro med habano-
--    dekkblad — merkets opprinnelige og mest kjente blanding.
--    Criollo-linjen bruker et ecuadoriansk criollo-dekkblad over
--    dominikansk bind/innmat og er noe mildere.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Kristoff','Kristoff','Nicaragua','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Nicaragua','Habano','Corojo',array['Nicaragua'],'Nicaragua',4,null,'Kristoff Nicaragua er merkets opprinnelige og mest kjente blanding — en 100% nicaraguansk puro med habano-dekkblad og corojo-bind, medium-plus til full styrke.',array['leather','espresso','cedar','black pepper']),
('Kristoff','Kristoff','Nicaragua','Toro','Toro',54,6.25,'Parejo',null,null,null,'Nicaragua','Habano','Corojo',array['Nicaragua'],'Nicaragua',4,null,'Toro-utgaven (6.25x54) av Kristoff Nicaragua gir samme kraftige, lærpregede profil i et lengre format.',array['leather','espresso','dark chocolate','spice']),
('Kristoff','Kristoff','Criollo','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Criollo','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Kristoff Criollo er noe mildere enn Nicaragua-linjen, med et ecuadoriansk criollo-dekkblad over dominikansk bind og innmat.',array['cedar','cocoa','dried fruit','mild pepper']);

-- ----------------------------------------------------------------
-- 6) La Aroma de Cuba — General Cigar, produsert i Den. Rep.
--    Originalen bruker et Connecticut Habano-dekkblad og er
--    medium-fyldig. Mi Amor er kraftigere med ecuadoriansk habano-
--    dekkblad. Noblesse er en nyere, litt mildere variant.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('General Cigar Co.','La Aroma de Cuba','Original','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'United States','Connecticut Habano','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'La Aroma de Cuba Original er en medium-fyldig dominikansk sigar med et Connecticut Habano-dekkblad — en hyllest til det opprinnelige kubanske merkenavnet.',array['cedar','cocoa','dried fruit','espresso']),
('General Cigar Co.','La Aroma de Cuba','Mi Amor','Toro','Toro',54,6.0,'Parejo',null,null,null,'Ecuador','Habano','Dominican',array['Dominican Republic','Nicaragua'],'Dominican Republic',4,null,'Mi Amor er den kraftigste linjen i La Aroma de Cuba-sortimentet, med et ecuadoriansk habano-dekkblad og medium-full styrke.',array['leather','dark chocolate','black pepper','cedar']),
('General Cigar Co.','La Aroma de Cuba','Noblesse','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Habano','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Noblesse er en nyere, litt rundere og tilgjengelig variant i La Aroma de Cuba-sortimentet med medium styrke.',array['cream','cedar','cocoa','light spice']);

-- ----------------------------------------------------------------
-- 7) La Gloria Cubana — grunnlagt av Ernesto Perez-Carrillo, nå
--    General Cigar. Originalen bruker Connecticut Shade-dekkblad.
--    Serie R bruker et ecuadoriansk Sumatra-dekkblad og er
--    kraftigere. Serie R Estelí er en 100% nicaraguansk puro —
--    den mest fullkraftige utgivelsen i merkets historie.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('General Cigar Co.','La Gloria Cubana','Original','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'United States','Connecticut Shade','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'La Gloria Cubana Original er merkets klassiske dominikanske blanding med Connecticut Shade-dekkblad — medium styrke.',array['cedar','cream','nuts','light spice']),
('General Cigar Co.','La Gloria Cubana','Serie R','No. 5','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Sumatra','Dominican',array['Dominican Republic','Nicaragua'],'Dominican Republic',4,null,'Serie R er en kraftigere linje enn originalen, med et mørkere ecuadoriansk Sumatra-dekkblad og medium-full styrke.',array['leather','earth','dark chocolate','black pepper']),
('General Cigar Co.','La Gloria Cubana','Serie R Estelí','Toro','Toro',54,6.0,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',5,null,'Serie R Estelí er en 100% nicaraguansk puro fra Estelí-regionen — den mest fullkraftige La Gloria Cubana-utgivelsen til dags dato.',array['espresso','black pepper','leather','dark cocoa']);

-- ----------------------------------------------------------------
-- 8) Old Henry — blandet av José "Pepin" Garcia, produsert i
--    Nicaragua, solgt av Holt's. Gold Label er den mildeste, med
--    ecuadoriansk Connecticut-dekkblad. Pure Breed bruker et
--    Oscuro-gradert ecuadoriansk Sumatra-dekkblad og er kraftigere.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Old Henry','Old Henry','Gold Label','Toro','Toro',52,6.0,'Parejo',null,null,null,'Ecuador','Connecticut','Nicaraguan',array['Nicaragua'],'Nicaragua',2,null,'Old Henry Gold Label er tilgjengelig og medium-fyldig — mild nok for morgenrøyk, men rik nok til kvelden, blandet av Pepin Garcia.',array['caramel','nuts','cream','light spice']),
('Old Henry','Old Henry','Pure Breed','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Sumatra Oscuro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Pure Breed bruker et Oscuro-gradert ecuadoriansk Sumatra-dekkblad — medium til full styrke med Pepins signaturkrydder.',array['caramel','butter','black pepper','nuts']),
('Old Henry','Old Henry','Maduro','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Nicaragua','Maduro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Old Henry Maduro er den mørkeste og søteste linjen i sortimentet, med en fyldig nicaraguansk profil.',array['dark chocolate','molasses','espresso','earth']);

-- ----------------------------------------------------------------
-- 9) Rocky Patel Mulligans — golf-tema, produsert i Honduras.
--    Originalen og Bogey Club er milde, tilgjengelige hverdags-
--    sigarer. Crown Jewel er den mer premium, kraftigere linjen.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Rocky Patel','Rocky Patel Mulligans','Original','Toro','Toro',52,6.0,'Parejo',null,null,null,'Ecuador','Connecticut','Honduran',array['Honduras','Nicaragua'],'Honduras',2,null,'Rocky Patel Mulligans Original er en mild til medium-fyldig golf-tema-sigar med ecuadoriansk Connecticut-dekkblad — en tilgjengelig hverdagsrøyk.',array['cream','cedar','honey','mild nuts']),
('Rocky Patel','Rocky Patel Mulligans','Bogey Club','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Connecticut','Honduran',array['Honduras'],'Honduras',1,null,'Bogey Club er den mildeste linjen i Mulligans-sortimentet — en lett, avslappet sigar for en rolig runde golf.',array['cream','hay','mild cedar','light spice']),
('Rocky Patel','Rocky Patel Mulligans','Crown Jewel','Toro','Toro',52,6.0,'Parejo',null,null,null,'Ecuador','Habano','Honduran',array['Honduras','Nicaragua'],'Honduras',3,null,'Crown Jewel er den mer premium og kraftigere linjen i Mulligans-sortimentet, med et ecuadoriansk habano-dekkblad.',array['cedar','black pepper','leather','toasted nuts']);

-- ----------------------------------------------------------------
-- 10) Villiger — sveitsisk merke (etablert 1888). Export-linjen er
--     korte, kuban-sandwich-stil sigarer produsert i Honduras med
--     brasiliansk Arapiraca-dekkblad — mild til medium. San'Doro er
--     merkets håndrullede, premium nicaraguanske puro-flaggskip.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Villiger','Villiger','Export Maduro','Cigarillo','Cigarillo',37,4.0,'Parejo',null,null,null,'Brazil','Arapiraca Maduro','Cuban-seed blend',array['Dominican Republic','Nicaragua','Honduras'],'Switzerland',2,null,'Villiger Export Maduro er en kort, boxpresset 4x37-sigarillo med brasiliansk Arapiraca maduro-dekkblad — mild til medium med søte noter.',array['earth','cocoa','coffee','mild spice']),
('Villiger','Villiger','Export Natural','Cigarillo','Cigarillo',37,4.0,'Parejo',null,null,null,'Indonesia','Sumatra','Cuban-seed blend',array['Dominican Republic','Nicaragua','Honduras'],'Switzerland',1,null,'Export Natural er den lysere, mildere varianten av Villigers signatur-cigarillo, med et Sumatra-dekkblad.',array['hay','cedar','cream','light spice']),
('Villiger','Villiger','San''Doro','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'San''Doro er Villigers håndrullede, premium nicaraguanske puro-flaggskip — medium til full styrke, langt fra de enklere Export-sigarillosene.',array['leather','cedar','espresso','black pepper']);
