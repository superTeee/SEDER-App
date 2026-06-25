-- ============================================================
-- 012_la_flor_dominicana_seed.sql
--
-- Setter inn La Flor Dominicana (LFD) — Tamboril, Den dominikanske
-- republikk. Grunnlagt 1994 av Litto og Ines Gomez. Et av få helt
-- vertikalintegrerte boutique-merker: binder og innmat dyrkes på
-- deres egen gård, La Canela, i Cibao-dalen. Kjent for kraftige,
-- ligero-tunge blandinger og signaturformen "Chisel" (patentert
-- kileformet hode).
--
-- I databasen fra før: 1 rad (Double Ligero/Robusto). Ingen
-- re-kobling nødvendig — manufacturer var allerede korrekt satt
-- til "La Flor Dominicana". Denne migrasjonen bygger ut samme
-- merke/serie-struktur med 23 nye rader fordelt på 8 serier:
--
--   1) Double Ligero      — kraftig, dekkblad Ecuador Sumatra/Maduro
--   2) Andalusian Bull    — CA's "Cigar of the Year" 2016 (96 poeng)
--   3) Air Bender         — CA topp 10 2010, Ecuador Habano-dekkblad
--   4) Cameroon Cabinet    — sjeldent kamerunsk dekkblad
--   5) Colorado Oscuro     — mørkt nicaraguansk Habano-dekkblad
--   6) 1994                — hyllest til grunnleggelsesåret
--   7) La Nox               — merkets mørkeste, kraftigste linje
--   8) Mambises / Carajos  — naturlig dekkblad-linje + cigarrito
--
-- Kilder: laflordominicana.com, cigaraficionado.com, cigars.com,
-- cigarcountry.com, halfwheel.com (offisielle vitola-lister og
-- produktbeskrivelser).
-- ============================================================

-- ----------------------------------------------------------------
-- 1) Double Ligero — flere vitolas (eksisterende rad: Robusto)
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('La Flor Dominicana','La Flor Dominicana','Double Ligero','No. 600','Robusto',52,5.25,'Parejo',null,null,null,'Ecuador','Sumatra (EMS)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Double Ligero er LFDs flaggskip for styrke — bygget rundt rikelig med ligero-blader fra deres egen gård La Canela. Fullkroppet med kraftig krydder, jord og espresso. No. 600 er en kortere, tykk robusto-variant.'),
('La Flor Dominicana','La Flor Dominicana','Double Ligero','No. 654','Toro',54,6.0,'Parejo',null,null,null,'Ecuador','Sumatra (EMS)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Double Ligero er LFDs flaggskip for styrke — bygget rundt rikelig med ligero-blader fra deres egen gård La Canela. Fullkroppet med kraftig krydder, jord og espresso. No. 654 er en av de mest populære vitolaene i serien.'),
('La Flor Dominicana','La Flor Dominicana','Double Ligero','No. 660','Gordito',60,4.62,'Parejo',null,null,null,'Ecuador','Maduro','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Double Ligero Maduro-utgaven bruker et mørkere, søtere dekkblad enn standard EMS-versjonen. No. 660 er en kort, tykk vitola (60 ring gauge) med konsentrert, intens smak.'),
('La Flor Dominicana','La Flor Dominicana','Double Ligero','No. 700','Gordo',60,6.5,'Parejo',null,null,null,'Ecuador','Maduro','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Double Ligero Maduro-utgaven bruker et mørkere, søtere dekkblad enn standard EMS-versjonen. No. 700 er en stor, tykk vitola med lang røyketid og fyldig, søtlig finish.'),
('La Flor Dominicana','La Flor Dominicana','Double Ligero','Chisel','Chisel',54,6.0,'Figurado','Chisel','Wedge','Closed','Ecuador','Sumatra (EMS)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Chisel er Litto Gomez'' patenterte, kileformede hode — designet for å gi et lettere trekk og en jevnere forbrenning. Denne Double Ligero-utgaven er fullkroppet med samme intense profil som resten av serien.'),
('La Flor Dominicana','La Flor Dominicana','Double Ligero','The Digger','Gordo',60,8.5,'Parejo',null,null,null,'Ecuador','Maduro','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'The Digger er en av de største vitolaene LFD lager — 8,5 tommer lang med 60 ring gauge. Maduro-dekkblad gir en søtlig, fyldig opplevelse over svært lang røyketid.');

-- ----------------------------------------------------------------
-- 2) Andalusian Bull — Cigar Aficionado's "Cigar of the Year" 2016 (96 poeng)
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('La Flor Dominicana','La Flor Dominicana','Andalusian Bull','Toro Especial','Perfecto',64,6.5,'Figurado','Perfecto','Pointed','Closed','Ecuador','Sumatra (EMS)','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Andalusian Bull ble kåret til Cigar Aficionados "Cigar of the Year" i 2016 med 96 poeng. Den store, perfecto-formede sigaren er rullet i en gammel belgisk form Litto Gomez fant, og er navngitt etter Andalusias tyrefektere som en hyllest til hans spanske røtter. Middels til fullkroppet med kompleks, krydret smak.');

-- ----------------------------------------------------------------
-- 3) Air Bender — Cigar Aficionados Topp 10 2010, Ecuador Habano-dekkblad
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('La Flor Dominicana','La Flor Dominicana','Air Bender','Poderoso','Corona',44,5.5,'Parejo',null,null,null,'Ecuador','Habano','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Air Bender landet på Cigar Aficionados Topp 10-liste i 2010 med 94 poeng. Ecuadoriansk Habano-dekkblad over dominikansk bind og innmat fra La Canela-gården. Middels til fullkroppet med espresso, mørk sjokolade og krydder.'),
('La Flor Dominicana','La Flor Dominicana','Air Bender','Valiente Maduro','Gordo',60,6.25,'Parejo',null,null,null,'Ecuador','Habano Maduro','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Air Bender landet på Cigar Aficionados Topp 10-liste i 2010 med 94 poeng. Valiente Maduro-utgaven bruker et mørkere Habano Maduro-dekkblad for ekstra søtlighet og fylde. Middels til fullkroppet.');

-- ----------------------------------------------------------------
-- 4) Cameroon Cabinet — sjeldent kamerunsk dekkblad, lagret i kabinett
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('La Flor Dominicana','La Flor Dominicana','Cameroon Cabinet','No. 1','Lonsdale',44,6.5,'Parejo',null,null,null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Cameroon Cabinet bruker et sjeldent, tradisjonelt kamerunsk dekkblad — kjent for sin lett krydrede, nøtteaktige smak. Lagres i kabinett (cabinet-stil kasser) før salg. Middels styrke.'),
('La Flor Dominicana','La Flor Dominicana','Cameroon Cabinet','No. 3','Petit Corona',40,4.75,'Parejo',null,null,null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Cameroon Cabinet bruker et sjeldent, tradisjonelt kamerunsk dekkblad — kjent for sin lett krydrede, nøtteaktige smak. No. 3 er den kortere petit corona-vitolaen i serien.'),
('La Flor Dominicana','La Flor Dominicana','Cameroon Cabinet','No. 4','Toro',54,6.25,'Parejo',null,null,null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Cameroon Cabinet bruker et sjeldent, tradisjonelt kamerunsk dekkblad — kjent for sin lett krydrede, nøtteaktige smak. No. 4 er en toro-vitola med god balanse mellom styrke og røyketid.'),
('La Flor Dominicana','La Flor Dominicana','Cameroon Cabinet','No. 5','Robusto',50,5.0,'Parejo',null,null,null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Cameroon Cabinet bruker et sjeldent, tradisjonelt kamerunsk dekkblad — kjent for sin lett krydrede, nøtteaktige smak. No. 5 er serien''s robusto-format.'),
('La Flor Dominicana','La Flor Dominicana','Cameroon Cabinet','Chisel','Chisel',54,6.0,'Figurado','Chisel','Wedge','Closed','Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Cameroon Cabinet Chisel kombinerer det kamerunske dekkbladet med LFDs patenterte kileformede hode for et lettere trekk og jevnere forbrenning.');

-- ----------------------------------------------------------------
-- 5) Colorado Oscuro — mørkt nicaraguansk Habano-dekkblad
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('La Flor Dominicana','La Flor Dominicana','Colorado Oscuro','No. 3','Robusto',50,5.0,'Parejo',null,null,null,'Nicaragua','Habano Oscuro','Dominican',array['Dominican Republic','Nicaragua'],'Dominican Republic',3,null,'Colorado Oscuro bruker en mørk nicaraguansk Habano-frøvariant som dekkblad, kombinert med dominikansk bind og innmat av dominikansk og nicaraguansk tobakk. Middels styrke med rik, jevn smak.'),
('La Flor Dominicana','La Flor Dominicana','Colorado Oscuro','No. 4','Corona Gorda',54,5.25,'Parejo',null,null,null,'Nicaragua','Habano Oscuro','Dominican',array['Dominican Republic','Nicaragua'],'Dominican Republic',3,null,'Colorado Oscuro bruker en mørk nicaraguansk Habano-frøvariant som dekkblad, kombinert med dominikansk bind og innmat av dominikansk og nicaraguansk tobakk. Middels styrke med rik, jevn smak.'),
('La Flor Dominicana','La Flor Dominicana','Colorado Oscuro','No. 5','Gordo',60,5.75,'Parejo',null,null,null,'Nicaragua','Habano Oscuro','Dominican',array['Dominican Republic','Nicaragua'],'Dominican Republic',3,null,'Colorado Oscuro bruker en mørk nicaraguansk Habano-frøvariant som dekkblad, kombinert med dominikansk bind og innmat av dominikansk og nicaraguansk tobakk. Middels styrke med rik, jevn smak.'),
('La Flor Dominicana','La Flor Dominicana','Colorado Oscuro','Churchill Oscuro','Churchill',48,7.0,'Parejo',null,null,null,'Nicaragua','Habano Oscuro','Dominican',array['Dominican Republic','Nicaragua'],'Dominican Republic',4,null,'Churchill Oscuro er den lengste vitolaen i Colorado Oscuro-serien — samme mørke nicaraguanske Habano-dekkblad, men med mer fylde og styrke enn de kortere formatene.');

-- ----------------------------------------------------------------
-- 6) 1994 — hyllest til grunnleggelsesåret til La Flor Dominicana
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('La Flor Dominicana','La Flor Dominicana','1994','Tango','Petit Corona',48,4.5,'Parejo',null,null,null,'Ecuador','Sumatra (EMS)','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'1994-serien hedrer året Litto og Ines Gomez grunnla La Flor Dominicana. Tango er en kort, kraftig petit corona-vitola med middels til fullkroppet smaksprofil.'),
('La Flor Dominicana','La Flor Dominicana','1994','Rumba','Toro',52,6.5,'Parejo',null,null,null,'Ecuador','Sumatra (EMS)','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'1994-serien hedrer året Litto og Ines Gomez grunnla La Flor Dominicana. Rumba er en lengre toro-vitola med samme middels til fullkroppede profil som Tango.');

-- ----------------------------------------------------------------
-- 7) La Nox — merkets mørkeste og kraftigste linje ("natten")
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('La Flor Dominicana','La Flor Dominicana','La Nox','Petite La Nox','Petit Corona',40,5.0,'Parejo',null,null,null,'Mexico','San Andres Maduro','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'La Nox ("natten" på latin) er LFDs mørkeste og kraftigste linje — et nesten svart San Andrés Maduro-dekkblad fra Mexico over dominikansk bind og innmat. Svært fullkroppet med dyp sødme og krydder.');

-- ----------------------------------------------------------------
-- 8) Mambises (naturlig dekkblad) + Carajos (cigarrito)
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('La Flor Dominicana','La Flor Dominicana','Mambises',null,'Churchill',48,6.88,'Parejo',null,null,null,'Dominican Republic','Dominican Sungrown','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Mambises bruker et naturlig, soldyrket dominikansk dekkblad — lysere og mildere enn LFDs typiske ligero-tunge profil. Middels styrke med jevn, balansert smak.'),
('La Flor Dominicana','La Flor Dominicana','Carajos',null,'Cigarrito',34,4.0,'Parejo',null,null,null,'Nicaragua','Nicaraguan Maduro','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Carajos Maduro er en liten, tynn cigarrito-format — rask å røyke, men med konsentrert, kraftig smak fra det mørke nicaraguanske dekkbladet.');

-- ----------------------------------------------------------------
-- 9) ALIAS — vanlige skrivemåter/forkortelser for OCR/søk-treff
-- ----------------------------------------------------------------
insert into cigar_aliases (alias, manufacturer, brand, series) values
('LFD', 'La Flor Dominicana', 'La Flor Dominicana', null),
('La Flor', 'La Flor Dominicana', 'La Flor Dominicana', null),
('Air Bender', 'La Flor Dominicana', 'La Flor Dominicana', 'Air Bender'),
('Andalusian Bull', 'La Flor Dominicana', 'La Flor Dominicana', 'Andalusian Bull'),
('Cameroon Cabinet', 'La Flor Dominicana', 'La Flor Dominicana', 'Cameroon Cabinet'),
('Colorado Oscuro', 'La Flor Dominicana', 'La Flor Dominicana', 'Colorado Oscuro'),
('Double Ligero', 'La Flor Dominicana', 'La Flor Dominicana', 'Double Ligero'),
('La Nox', 'La Flor Dominicana', 'La Flor Dominicana', 'La Nox');

-- ----------------------------------------------------------------
-- 10) Sanity check — skal være nøyaktig 24 La Flor Dominicana-rader
--     (1 eksisterende Double Ligero/Robusto + 23 nye)
-- ----------------------------------------------------------------
do $$
declare
  cnt int;
begin
  select count(*) into cnt from cigars where manufacturer = 'La Flor Dominicana';
  if cnt <> 24 then
    raise exception 'Forventet 24 La Flor Dominicana-rader, fant %', cnt;
  end if;
end $$;
