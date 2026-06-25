-- ============================================================
-- 019_new_world_aurora_plasencia_oscar_valladares_seed.sql
--
-- Tom ba om å sjekke 5 merker: New World, Aurora ADN,
-- Oscar Valladares, Partagas, Alma del Campo.
--
-- Funn i databasen før denne migrasjonen:
--   - AJ Fernandez / "New World": fantes med 1 rad (kun Oscuro-
--     linjen). Mangler Connecticut- og Puro Especial-linjene.
--   - La Aurora: fantes med 4 rader (107, 1903, 1903 Cameroon,
--     Preferidos). Manglet ADN Dominicano-serien helt.
--   - Plasencia: fantes med 20 rader (Alma Fuerte, Cosecha 146,
--     Cosecha 149, Reserva Original). Manglet Alma del Campo helt.
--   - Oscar Valladares: fantes IKKE i databasen — nytt merke.
--   - Partagas: fantes allerede med 9 rader og god dekning
--     (1845, 8-9-8, Black Label, Heritage, Lusitania, Serie D
--     No.4/No.5, Serie E No.2) — ingen endring nødvendig.
--
-- 18 nye rader fordelt på 4 merker/serier:
--   1) AJ Fernandez — New World Connecticut (3 vitolas)
--   2) AJ Fernandez — New World Puro Especial (3 vitolas)
--   3) La Aurora — ADN Dominicano (4 vitolas)
--   4) Plasencia — Alma del Campo (5 vitolas)
--   5) Oscar Valladares — Leaf by Oscar, 2012 Series, Super Fly
--      (nytt merke, 8 rader)
--
-- Smaksnoter satt direkte ved innsetting, samme konvensjon som
-- migrasjon 016-018.
--
-- Kilder: ajfcigars.com, gothamcigars.com, leafenthusiast.com,
-- cigar-coop.com, halfwheel.com, jrcigars.com, cigarcountry.com,
-- plasenciacigars.com, cigaraficionado.com, blindmanspuff.com
-- ============================================================

-- ----------------------------------------------------------------
-- 1) New World Connecticut — rundere form enn original-linjen
--    (som er boxpresset). Connecticut Shade-dekkblad, San Andrés-
--    bind fra Mexico, innmat fra Nicaragua og Brasil.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('AJ Fernandez','AJ Fernandez','New World Connecticut','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'United States','Connecticut Shade','San Andres',array['Nicaragua','Brazil'],'Nicaragua',2,null,'New World Connecticut Robusto er en mild, rund variant av New World med Connecticut Shade-dekkblad — motsatt av originalens boxpressede form.',array['cream','cedar','honey','light pepper']),
('AJ Fernandez','AJ Fernandez','New World Connecticut','Toro','Toro',52,6.0,'Parejo',null,null,null,'United States','Connecticut Shade','San Andres',array['Nicaragua','Brazil'],'Nicaragua',2,null,'Toro-utgaven av New World Connecticut gir samme kremede, milde profil i et lengre format.',array['cream','cedar','almond','sweet hay']),
('AJ Fernandez','AJ Fernandez','New World Connecticut','Churchill','Churchill',50,7.0,'Parejo',null,null,null,'United States','Connecticut Shade','San Andres',array['Nicaragua','Brazil'],'Nicaragua',2,null,'Churchill-formatet av New World Connecticut er den lengste vitolaen i serien, med en jevn og rolig røykeopplevelse.',array['cream','cedar','honey','vanilla']);

-- ----------------------------------------------------------------
-- 2) New World Puro Especial — 100% nicaraguansk puro, motsatt av
--    den milde Connecticut-linjen. Habano Criollo '98-dekkblad fra
--    San José-gården, innmat lagret 3-5 år fra Estelí.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('AJ Fernandez','AJ Fernandez','New World Puro Especial','Robusto','Robusto',52,5.5,'Parejo',null,null,null,'Nicaragua','Habano Criollo ''98','Nicaraguan Habano',array['Nicaragua'],'Nicaragua',4,null,'New World Puro Especial Robusto er en fullkraftig, 100% nicaraguansk puro med dekkblad fra Fernandez'' egen San José-gård.',array['leather','earth','cedar','coffee','black pepper']),
('AJ Fernandez','AJ Fernandez','New World Puro Especial','Toro','Toro',52,6.5,'Parejo',null,null,null,'Nicaragua','Habano Criollo ''98','Nicaraguan Habano',array['Nicaragua'],'Nicaragua',4,null,'Toro-utgaven av Puro Especial gir samme intense nicaraguanske profil med noter av lær og kaffe i et lengre format.',array['leather','coffee','cocoa','almond','cedar']),
('AJ Fernandez','AJ Fernandez','New World Puro Especial','Gordo','Gordo',60,6.0,'Parejo',null,null,null,'Nicaragua','Habano Criollo ''98','Nicaraguan Habano',array['Nicaragua'],'Nicaragua',4,null,'Gordo-formatet av Puro Especial er den bredeste vitolaen, med en konsentrert versjon av merkets jordnære, fyldige smaksprofil.',array['leather','earth','hickory','cocoa','black pepper']);

-- ----------------------------------------------------------------
-- 3) La Aurora ADN Dominicano — kjennetegnes av andullo-tobakk,
--    en tradisjonell dominikansk innmatstype rullet i palmeblad
--    (yaguas) og lagret i jorden under fermentering. Dominikansk
--    dekkblad fra Cibao-dalen, Cameroon-bind.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('La Aurora','La Aurora','ADN Dominicano','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Dominican Republic','Cibao Valley','Cameroon',array['Dominican Republic','Nicaragua','United States'],'Dominican Republic',3,null,'ADN Dominicano Robusto bruker tradisjonell andullo-tobakk i innmaten — en gammel dominikansk fermenteringsmetode som gir en rik, jordnær karakter.',array['earth','dark fruit','cedar','molasses','leather']),
('La Aurora','La Aurora','ADN Dominicano','Toro','Toro',54,5.75,'Parejo',null,null,null,'Dominican Republic','Cibao Valley','Cameroon',array['Dominican Republic','Nicaragua','United States'],'Dominican Republic',3,null,'Toro-utgaven av ADN Dominicano gir samme andullo-pregede, jordnære profil i et lengre, bredere format.',array['earth','dark fruit','cocoa','cedar','spice']),
('La Aurora','La Aurora','ADN Dominicano','Churchill','Churchill',47,7.0,'Parejo',null,null,null,'Dominican Republic','Cibao Valley','Cameroon',array['Dominican Republic','Nicaragua','United States'],'Dominican Republic',3,null,'Churchill-formatet av ADN Dominicano er den lengste, slankeste vitolaen — en rolig røykeopplevelse med andullo-tobakkens karakteristiske dybde.',array['earth','leather','dark fruit','cedar','nutmeg']),
('La Aurora','La Aurora','ADN Dominicano','Gran Toro','Gran Toro',58,6.0,'Parejo',null,null,null,'Dominican Republic','Cibao Valley','Cameroon',array['Dominican Republic','Nicaragua','United States'],'Dominican Republic',3,null,'Gran Toro er den bredeste ADN Dominicano-vitolaen, med en fyldigere, mer konsentrert andullo-profil.',array['earth','molasses','dark fruit','cocoa','leather']);

-- ----------------------------------------------------------------
-- 4) Plasencia Alma del Campo — andre utgivelse i Alma-serien,
--    lansert 2017 som en hyllest til "jordens sjel" i Nicaragua.
--    Naturlig nicaraguansk dekkblad, nicaraguansk bind og innmat.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Plasencia','Plasencia','Alma del Campo','Tribu','Robusto',52,5.0,'Parejo',null,null,null,'Nicaragua','Natural Nicaraguan','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Alma del Campo Tribu er den kortligste vitolaen i serien — en nicaraguansk puro skapt av tre generasjoner Plasencia som hyllest til "jordens sjel".',array['cocoa','leather','dark fruit','coffee','sweet cedar']),
('Plasencia','Plasencia','Alma del Campo','Guajiro','Robusto',52,5.5,'Parejo',null,null,null,'Nicaragua','Natural Nicaraguan','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Guajiro gir samme balanserte, medium-fyldige Alma del Campo-profil i et litt lengre robusto-format.',array['cocoa','coffee','dark fruit','cedar','cream']),
('Plasencia','Plasencia','Alma del Campo','Travesía','Toro',54,6.5,'Parejo',null,null,null,'Nicaragua','Natural Nicaraguan','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Travesía er en av de mer populære Alma del Campo-vitolaene, med kakao- og kaffenoter balansert av søt sedertre.',array['cocoa','coffee','sweet cedar','dark fruit','leather']),
('Plasencia','Plasencia','Alma del Campo','Sendero','Toro',56,6.0,'Parejo',null,null,null,'Nicaragua','Natural Nicaraguan','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Sendero har et bredere ringmål enn Travesía, noe som gir en fyldigere, mer konsentrert versjon av Alma del Campo-profilen.',array['cocoa','dark fruit','coffee','earth','sweet cedar']),
('Plasencia','Plasencia','Alma del Campo','Madroño','Gordo',58,6.5,'Parejo',null,null,null,'Nicaragua','Natural Nicaraguan','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Madroño er den bredeste Alma del Campo-vitolaen — en lang, rolig røyk med samme kakao- og kaffepregede karakter.',array['cocoa','coffee','dark fruit','cream','cedar']);

-- ----------------------------------------------------------------
-- 5) Oscar Valladares — nytt merke. Grunnlagt 2012 i Danlí,
--    Honduras av Oscar og Hector Valladares sammen med Bayron
--    Duarte (tidligere General Cigar). Sterk honduransk profil i
--    både tobakk og merkevarebygging.
--    - Leaf by Oscar: dekkblad-emballasje av ekte tobakksblad,
--      honduransk bind/innmat, fire dekkbladvarianter.
--    - 2012 Series: lansert for å feire 5-årsjubileet i 2017.
--    - Super Fly: meksikansk San Andrés-dekkblad, disco-inspirert.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Oscar Valladares','Oscar Valladares','Leaf by Oscar','Connecticut Toro','Toro',50,6.0,'Parejo',null,null,null,'Honduras','Connecticut','Honduran',array['Honduras'],'Honduras',2,null,'Leaf by Oscar Connecticut er pakket i et ekte tobakksblad i stedet for cellofan — en mild, kremet honduransk sigar.',array['cream','cedar','honey','mild spice']),
('Oscar Valladares','Oscar Valladares','Leaf by Oscar','Maduro Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Mexico','San Andres Maduro','Honduran',array['Honduras'],'Honduras',4,null,'Maduro-utgaven av Leaf by Oscar gir en søtere, mørkere profil med San Andrés-dekkblad over honduransk bind og innmat.',array['dark chocolate','molasses','espresso','earth']),
('Oscar Valladares','Oscar Valladares','Leaf by Oscar','Corojo Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Honduras','Corojo','Honduran',array['Honduras'],'Honduras',3,null,'Corojo-varianten av Leaf by Oscar gir en krydret, medium-fyldig honduransk profil med karakteristisk corojo-pepper.',array['black pepper','cedar','earth','sweet spice']),
('Oscar Valladares','Oscar Valladares','2012 Series','Connecticut Robusto','Robusto',50,5.0,'Parejo',null,null,null,'United States','Connecticut Shade','Honduran',array['Honduras'],'Honduras',2,null,'2012 Series Connecticut ble lansert for å feire 5-årsjubileet til Oscar Valladares Cigars i 2017 — mild og kremet.',array['cream','cedar','honey','light pepper']),
('Oscar Valladares','Oscar Valladares','2012 Series','Corojo Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Honduras','Corojo','Honduran',array['Honduras'],'Honduras',3,null,'2012 Series Corojo gir en krydret, medium-fyldig profil som del av jubileumstrioen.',array['black pepper','cedar','earth','toasted nuts']),
('Oscar Valladares','Oscar Valladares','2012 Series','Maduro Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Mexico','San Andres Maduro','Honduran',array['Honduras'],'Honduras',4,null,'2012 Series Maduro er den fyldigste av jubileumstrioen, med en søtlig, mørk San Andrés-profil.',array['dark chocolate','espresso','molasses','earth']),
('Oscar Valladares','Oscar Valladares','Super Fly','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Mexico','San Andres','Honduran',array['Honduras'],'Honduras',4,null,'Super Fly er en av de mest særegne Oscar Valladares-utgivelsene, med et disco-inspirert 1970-talls banddesign og et fyldig San Andrés-dekkblad.',array['sweet spice','cream','dark chocolate','earth']),
('Oscar Valladares','Oscar Valladares','Super Fly','Toro','Toro',52,6.0,'Parejo',null,null,null,'Mexico','San Andres','Honduran',array['Honduras'],'Honduras',4,null,'Toro-utgaven av Super Fly gir samme fyldige, søtlige San Andrés-profil i et lengre format.',array['sweet spice','dark chocolate','cream','molasses']);
