-- ============================================================
-- 018_joya_de_nicaragua_seed.sql
--
-- Setter inn Joya de Nicaragua — Nicaraguas eldste premium-
-- sigarmerke, grunnlagt 1968 av J.F. Bermejo og Simón Camacho i
-- Estelí. Fabrikken ble brent ned under borgerkrigen, men Alejandro
-- Martínez-Cuenca kjøpte merket i 1994 og bygde det opp igjen.
-- Lanseringen av Antaño 1970 i 2001 — en kraftig, ren nicaraguansk
-- puro — gjenopplivet merkets rykte. Produseres fortsatt på egen
-- fabrikk i Estelí.
--
-- 10 nye rader fordelt på 4 serier/produktlinjer:
--   1) Antaño 1970          — flaggskipet, full-bodied Nicaragua-puro
--   2) Cuatro Cinco Reserva Especial — rom-tønnelagret ligero,
--                              feiret 45 år med sigarproduksjon
--   3) Joya Red             — mildere Habano rosado-dekkblad
--   4) Joya Black           — mørkere, søtere San Andrés Negro-dekkblad
--
-- Smaksnoter satt direkte ved innsetting, samme konvensjon som
-- migrasjon 016 (Acid) og 017 (Viaje).
--
-- Kilder: cigaraficionado.com, halfwheel.com, cigar-coop.com,
-- leafenthusiast.com, blindmanspuff.com, neptunecigar.com,
-- casasfumando.com, joyacigars.com
-- ============================================================

-- ----------------------------------------------------------------
-- 1) Antaño 1970 — Joya de Nicaraguas flaggskip, lansert 2001.
--    100% nicaraguansk puro (dekkblad, bind og innmat alle fra
--    Jalapa/Condega/Estelí). Navnet betyr "i gamle dager" og er en
--    hyllest til den klassiske, kraftige nicaraguanske smaken.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Joya de Nicaragua','Joya de Nicaragua','Antaño 1970','Robusto Grande','Robusto',52,5.5,'Parejo',null,null,null,'Nicaragua','Habano Criollo','Nicaraguan',array['Nicaragua'],'Nicaragua',5,null,'Antaño 1970 Robusto Grande er Joya de Nicaraguas flaggskip — en fullkraftig, ren nicaraguansk puro som gjenopplivet merkets rykte da den ble lansert i 2001.',array['espresso','black pepper','dark chocolate','leather','earth']),
('Joya de Nicaragua','Joya de Nicaragua','Antaño 1970','Consul','Petit Corona',52,4.5,'Parejo',null,null,null,'Nicaragua','Habano Criollo','Nicaraguan',array['Nicaragua'],'Nicaragua',5,null,'Consul er en kortere Antaño 1970-vitola med samme intense, ren nicaraguanske profil i et raskere format.',array['espresso','black pepper','cedar','dark chocolate','earth']);

-- ----------------------------------------------------------------
-- 2) Cuatro Cinco Reserva Especial — lansert for å feire 45 år med
--    sigarproduksjon. Mørkt Habano-dekkblad, dominikansk bind, og
--    nicaraguansk ligero-innmat lagret fem år på fat som tidligere
--    har inneholdt rom.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Joya de Nicaragua','Joya de Nicaragua','Cuatro Cinco','Reserva Especial Toro','Toro',50,6.25,'Parejo',null,null,null,'Nicaragua','Habano','Dominican',array['Nicaragua'],'Nicaragua',4,null,'Cuatro Cinco Reserva Especial feirer 45 år med sigarproduksjon — nicaraguansk ligero-innmat lagret fem år på gamle romtønner gir en rik, søtlig kompleksitet.',array['rum','vanilla','cedar','sweet spice','wood']),
('Joya de Nicaragua','Joya de Nicaragua','Cuatro Cinco','Reserva Especial Torpedo','Torpedo',52,6.0,'Figurado',null,'Pointed','Closed','Nicaragua','Habano','Dominican',array['Nicaragua'],'Nicaragua',4,null,'Torpedo-vitolaen av Cuatro Cinco Reserva Especial pakker den rom-tønnelagrede ligero-innmaten inn i en spiss figurado-form.',array['rum','vanilla','wood','sweet spice','cocoa']),
('Joya de Nicaragua','Joya de Nicaragua','Cuatro Cinco','Reserva Especial Doble Robusto','Robusto',56,5.0,'Parejo',null,null,null,'Nicaragua','Habano','Dominican',array['Nicaragua'],'Nicaragua',4,null,'Doble Robusto er den bredeste Cuatro Cinco-vitolaen, med en fyldigere, mer konsentrert versjon av den søtlige rom-tønne-profilen.',array['rum','wood','vanilla','sweet spice','velvety finish']);

-- ----------------------------------------------------------------
-- 3) Joya Red — mildere all-nicaraguansk puro med et lavere-
--    priming Habano-dekkblad i rosado-/kanelfarge.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Joya de Nicaragua','Joya de Nicaragua','Joya Red','Robusto','Robusto',50,5.25,'Parejo',null,null,null,'Nicaragua','Habano Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Joya Red Robusto er en mildere, all-nicaraguansk puro med et rosadofarget Habano-dekkblad og en balansert, kremet profil.',array['cedar','cream','honey','nutmeg','light pepper']),
('Joya de Nicaragua','Joya de Nicaragua','Joya Red','Toro','Toro',52,6.0,'Parejo',null,null,null,'Nicaragua','Habano Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Toro-utgaven av Joya Red gir samme rosado-søtlige, kremete profil i et lengre format.',array['cedar','cream','honey','mild spice','almond']);

-- ----------------------------------------------------------------
-- 4) Joya Black — Joya de Nicaraguas første sigar med meksikansk
--    San Andrés Negro-dekkblad, mørkere og søtere enn Joya Red.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Joya de Nicaragua','Joya de Nicaragua','Joya Black','Robusto','Robusto',50,5.25,'Parejo',null,null,null,'Mexico','San Andrés Negro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Joya Black Robusto var Joya de Nicaraguas første sigar med meksikansk San Andrés Negro-dekkblad — mørkere og søtere enn Joya Red.',array['dark chocolate','coffee','molasses','black pepper','earth']),
('Joya de Nicaragua','Joya de Nicaragua','Joya Black','Toro','Toro',52,6.0,'Parejo',null,null,null,'Mexico','San Andrés Negro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Toro-utgaven av Joya Black gir samme mørke, søtlige San Andrés-profil i et lengre format.',array['dark chocolate','espresso','molasses','earth','sweet spice']),
('Joya de Nicaragua','Joya de Nicaragua','Joya Black','Nocturno','Corona Gorda',46,6.25,'Parejo',null,null,null,'Mexico','San Andrés Negro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Nocturno er en slankere, lengre Joya Black-vitola med samme mørke San Andrés-dekkblad og søtlige kompleksitet.',array['dark chocolate','coffee','black pepper','earth','molasses']);
