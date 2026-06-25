-- ============================================================
-- 017_viaje_seed.sql
--
-- Setter inn Viaje — grunnlagt 2008 av Andre Farkas. Startet med
-- to faste linjer (Platino, Oro), men siden 2012 har Viaje vært
-- et rendyrket limited-edition/small-batch-merke. Produseres i
-- stor grad hos Aganorsa Leaf i Nicaragua, med noen linjer fra
-- Raíces Cubanas i Honduras. Kjent for et stort, kultlignende
-- fellesskap, hyppige utsalgte slipp og en gjennomgående
-- "skrekk/krig"-tematikk i navngivningen (Skull and Bones,
-- Zombie, WMD, Honey & Hand Grenades). Nr. 13 på Atlantic Cigars
-- salgsliste for 2026.
--
-- 12 nye rader fordelt på 6 serier/produktlinjer:
--   1) Platino              — fast linje, Nicaraguan Corojo '99
--   2) Oro                  — fast linje, brakte Viaje #2 på CA
--                              Top 25 i 2010
--   3) Skull and Bones      — limited, "WMD"-tema, full styrke
--   4) Zombie               — limited, post-apokalyptisk tema
--   5) Honey & Hand Grenades — limited, perfecto-formater
--   6) Black and White Connecticut / Exclusivo Nicaragua
--      — mildere Connecticut-variant + Nicaragua-puro
--
-- Smaksnoter satt direkte ved innsetting, samme konvensjon som
-- migrasjon 016 (Acid).
--
-- Kilder: cigaraficionado.com, halfwheel.com, cigar-coop.com,
-- kohnhed.com, atlanticcigar.com, smokingpipes.com
-- ============================================================

-- ----------------------------------------------------------------
-- 1) Platino — Viajes opprinnelige faste linje. Nicaraguan
--    Corojo '99-dekkblad over nicaraguansk bind/innmat, en rolig,
--    nyansert røyk for den erfarne røykeren.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Viaje','Viaje','Platino','Corona Gorda','Corona Gorda',46,5.625,'Parejo',null,null,null,'Nicaragua','Corojo 99','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Platino er Viajes opprinnelige faste linje — en rolig, nyansert røyk med Nicaraguan Corojo 99-dekkblad, bygget for den erfarne røykeren.',array['cedar','leather','dark chocolate','espresso','black pepper']),
('Viaje','Viaje','Platino','Five Fifty Eight','Gordo',58,5.0,'Parejo',null,null,null,'Nicaragua','Corojo 99','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Five Fifty Eight er en bredere, kortere Platino-vitola med samme rolige, jordnære Corojo-profil.',array['cedar','leather','cocoa','black pepper','toasted nuts']);

-- ----------------------------------------------------------------
-- 2) Oro — Viajes andre faste lanseringslinje. Cuban-seed
--    nicaraguansk Criollo-dekkblad; Oro Reserva VOR No. 5 tok
--    andreplassen på Cigar Aficionados Top 25 i 2010 og satte
--    Viaje på kartet.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Viaje','Viaje','Oro','Original','Robusto',44,5.5,'Parejo',null,null,null,'Nicaragua','Criollo','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Oro var Viajes andre faste linje og brakte merket internasjonal oppmerksomhet da Oro Reserva VOR No. 5 tok andreplassen på Cigar Aficionados Top 25 i 2010.',array['cedar','cinnamon','dried fruit','espresso','leather']),
('Viaje','Viaje','Oro','Koa','Corona Gorda',46,5.625,'Parejo',null,null,null,'Nicaragua','Criollo','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Oro Koa er en corona gorda-vitola av Oro-linjen med samme komplekse, Cuban-seed nicaraguanske blanding.',array['leather','cedar','cocoa','dried fruit','spice']);

-- ----------------------------------------------------------------
-- 3) Skull and Bones — limited-edition-serie med bombe-/
--    krigstema. WMD ("Weapon of Mass Destruction") er en
--    fullkraftig nicaraguansk puro med Criollo-dekkblad.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Viaje','Viaje','Skull and Bones','WMD','Petit Robusto',54,3.75,'Parejo',null,null,null,'Nicaragua','Criollo','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Skull and Bones WMD er en kort, kraftig nicaraguansk puro — en av Viajes mest intense og kultstatuspregede slipp.',array['black pepper','char','earth','dark chocolate','leather']);

-- ----------------------------------------------------------------
-- 4) Zombie — post-apokalyptisk-tematisk serie som bygger videre
--    på Skull and Bones-historien. Criollo '98-dekkblad,
--    nicaraguansk puro, kjent for full styrke og kompleksitet.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Viaje','Viaje','Zombie','Original','Toro',52,6.25,'Parejo',null,null,null,'Nicaragua','Criollo 98','Nicaraguan',array['Nicaragua'],'Nicaragua',5,null,'Zombie er en fullkraftig nicaraguansk puro med Criollo 98-dekkblad, første gang lansert i 2011 som en oppfølger til Skull and Bones-historien.',array['dark chocolate','maple','earth','black pepper','char']),
('Viaje','Viaje','Zombie','Super Shot','Petit Robusto',54,3.5,'Parejo',null,null,null,'Nicaragua','Criollo 98','Nicaraguan',array['Nicaragua'],'Nicaragua',5,null,'Zombie Super Shot pakker samme fullkraftige Zombie-blanding inn i et kort "10 Gauge"-format.',array['maple sweetness','dark chocolate','char','black pepper','leather']);

-- ----------------------------------------------------------------
-- 5) Honey & Hand Grenades — limited-batch-serie i perfecto-
--    formater, oppkalt etter granat-/våpentema. Nicaraguansk
--    Criollo-dekkblad, med en mexicansk San Andrés-maduro-variant.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Viaje','Viaje','Honey & Hand Grenades','The Rapier','Perfecto',44,6.5,'Figurado',null,'Pointed','Closed','Nicaragua','Criollo','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'The Rapier er en slank perfecto-vitola i Honey & Hand Grenades-serien, kjent for sin elegante form og balanserte styrke.',array['cedar','black pepper','leather','dried fruit','earth']),
('Viaje','Viaje','Honey & Hand Grenades','The Shiv','Perfecto',50,6.25,'Figurado',null,'Pointed','Closed','Nicaragua','Criollo','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'The Shiv er en bredere, kraftigere perfecto i samme serie, med mer krydder og dybde enn The Rapier.',array['cedar','spice','leather','cocoa','earth']),
('Viaje','Viaje','Honey & Hand Grenades','The Katana Maduro','Perfecto',48,7.0,'Figurado',null,'Pointed','Closed','Mexico','San Andrés','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'The Katana Maduro bruker et mexicansk San Andrés-dekkblad for en søtere, mørkere variant av Honey & Hand Grenades.',array['dark chocolate','espresso','molasses','black pepper','earth']);

-- ----------------------------------------------------------------
-- 6) Andre kjente enkeltlinjer — Black and White Connecticut
--    (Viajes mildeste, hemmelighetsfulle blanding) og Exclusivo
--    Nicaragua (ren nicaraguansk puro med sitrus/krydder-profil).
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Viaje','Viaje','Black and White','Connecticut','Perfecto',52,6.75,'Figurado',null,'Pointed','Closed','Ecuador','Connecticut Shade','Nicaraguan',array['Nicaragua'],'Nicaragua',2,null,'Black and White Connecticut er Viajes mildeste slipp — som vanlig hos merket holdes bind og innmat hemmelig, men dekkbladet er bekreftet Connecticut Shade.',array['cream','hay','toasted nuts','mild pepper','sweet cedar']),
('Viaje','Viaje','Exclusivo','Nicaragua Toro','Toro',52,6.0,'Parejo',null,null,null,'Nicaragua','Nicaraguan','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Exclusivo Nicaragua er en ren nicaraguansk puro med en distinkt profil av sedertre, nøtter og sitrus.',array['cedar','toasted nuts','citrus','red pepper','natural tobacco']);
