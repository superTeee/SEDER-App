-- ============================================================
-- 008_arturo_fuente_seed.sql
--
-- Setter inn hele Arturo Fuente-katalogen (helt nytt merke i databasen).
-- Hierarki: manufacturer -> brand -> series -> vitola.
-- Kilde: arturofuente.com / etablerte sigarforhandlere (offisielle
-- vitola-lister, ring gauge/lengde, dekkblad/innmat/styrke).
--
-- Serier:
--   1) Hemingway          (8 vitolas  — Cameroon, flere Perfecto-formede)
--   2) Don Carlos         (5 vitolas  — Cameroon, medium-full)
--   3) Fuente Fuente OpusX (10 vitolas — første Dominikanske puro, full styrke)
--   4) Añejo              (8 vitolas  — Connecticut Broadleaf maduro, cognac-fatlagret)
--   5) Gran Reserva        (8 vitolas — Cameroon, klassisk 8-5-8-linje, medium)
--   6) Curly Head Deluxe   (2 vitolas — Cameroon/Connecticut, mild-medium, budsjettklassiker)
--
-- Totalt 41 nye rader. Ingen eksisterende rader berøres.
-- ============================================================

-- ----------------------------------------------------------------
-- 1) Hemingway
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Arturo Fuente','Arturo Fuente','Hemingway','Short Story','Perfecto',49,4.0,'Figurado','Perfecto','Tapered','Tapered','Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Hemingway-serien er oppkalt etter Ernest Hemingway og kjent for sin Perfecto-form — tapret i begge ender. Cameroon-dekkblad, dominikansk innmat, middels til fullkroppet. Short Story er den minste vitolaen i serien, populær som «etter middag»-sigar.'),
('Arturo Fuente','Arturo Fuente','Hemingway','Best Seller','Perfecto',55,4.5,'Figurado','Perfecto','Tapered','Tapered','Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Hemingway-serien er oppkalt etter Ernest Hemingway og kjent for sin Perfecto-form — tapret i begge ender. Cameroon-dekkblad, dominikansk innmat, middels til fullkroppet. Best Seller er serien''s mest solgte vitola, en kort robust perfecto.'),
('Arturo Fuente','Arturo Fuente','Hemingway','Between the Lines','Perfecto',54,4.5,'Figurado','Perfecto','Tapered','Tapered','Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Hemingway-serien er oppkalt etter Ernest Hemingway og kjent for sin Perfecto-form — tapret i begge ender. Cameroon-dekkblad, dominikansk innmat, middels til fullkroppet.'),
('Arturo Fuente','Arturo Fuente','Hemingway','Work of Art','Perfecto',60,4.875,'Figurado','Perfecto','Tapered','Tapered','Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Hemingway-serien er oppkalt etter Ernest Hemingway og kjent for sin Perfecto-form — tapret i begge ender. Cameroon-dekkblad, dominikansk innmat, middels til fullkroppet. Work of Art er en av de bredere perfecto-vitolaene i serien.'),
('Arturo Fuente','Arturo Fuente','Hemingway','Signature','Churchill',46,6.0,'Parejo',null,null,null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Hemingway-serien er oppkalt etter Ernest Hemingway og kjent for sin Perfecto-form — tapret i begge ender. Cameroon-dekkblad, dominikansk innmat, middels til fullkroppet. Signature er en rett (parejo) Churchill-vitola i serien.'),
('Arturo Fuente','Arturo Fuente','Hemingway','Classic','Lonsdale',46,7.0,'Parejo',null,null,null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Hemingway-serien er oppkalt etter Ernest Hemingway og kjent for sin Perfecto-form — tapret i begge ender. Cameroon-dekkblad, dominikansk innmat, middels til fullkroppet. Classic er en lang, rett (parejo) Lonsdale-vitola.'),
('Arturo Fuente','Arturo Fuente','Hemingway','Untold Story','Churchill',54,7.5,'Parejo',null,null,null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Hemingway-serien er oppkalt etter Ernest Hemingway og kjent for sin Perfecto-form — tapret i begge ender. Cameroon-dekkblad, dominikansk innmat, middels til fullkroppet.'),
('Arturo Fuente','Arturo Fuente','Hemingway','Masterpiece','Double Corona',52,9.0,'Parejo',null,null,null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Hemingway-serien er oppkalt etter Ernest Hemingway og kjent for sin Perfecto-form — tapret i begge ender. Cameroon-dekkblad, dominikansk innmat, middels til fullkroppet. Masterpiece er serien''s lengste, mest imponerende vitola.');

-- ----------------------------------------------------------------
-- 2) Don Carlos
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Arturo Fuente','Arturo Fuente','Don Carlos','Robusto','Robusto',50,5.25,'Parejo',null,null,null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Don Carlos er oppkalt etter familiepatriarken Carlos Fuente Sr. og regnes som et av merkets mest prestisjetunge linjer. Cameroon-dekkblad, dominikansk innmat eldet i flere år, middels til fullkroppet med kompleks, balansert smak.'),
('Arturo Fuente','Arturo Fuente','Don Carlos','Double Robusto','Robusto',52,5.75,'Parejo',null,null,null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Don Carlos er oppkalt etter familiepatriarken Carlos Fuente Sr. og regnes som et av merkets mest prestisjetunge linjer. Cameroon-dekkblad, dominikansk innmat eldet i flere år, middels til fullkroppet med kompleks, balansert smak.'),
('Arturo Fuente','Arturo Fuente','Don Carlos','No 3','Corona',44,5.5,'Parejo',null,null,null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Don Carlos er oppkalt etter familiepatriarken Carlos Fuente Sr. og regnes som et av merkets mest prestisjetunge linjer. Cameroon-dekkblad, dominikansk innmat eldet i flere år, middels til fullkroppet med kompleks, balansert smak.'),
('Arturo Fuente','Arturo Fuente','Don Carlos','No 2','Belicoso',55,6.0,'Figurado','Belicoso','Pointed','Closed','Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Don Carlos er oppkalt etter familiepatriarken Carlos Fuente Sr. og regnes som et av merkets mest prestisjetunge linjer. Cameroon-dekkblad, dominikansk innmat eldet i flere år, middels til fullkroppet med kompleks, balansert smak.'),
('Arturo Fuente','Arturo Fuente','Don Carlos','90 Anos','Toro',47,5.75,'Parejo',null,null,null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'90 Años ble lansert for å feire merkets 90-årsjubileum. Cameroon-dekkblad, dominikansk innmat eldet i flere år, middels til fullkroppet med kompleks, balansert smak — del av den prestisjetunge Don Carlos-linjen.');

-- ----------------------------------------------------------------
-- 3) Fuente Fuente OpusX
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Arturo Fuente','Arturo Fuente','Fuente Fuente OpusX','Double Corona','Double Corona',49,7.625,'Parejo',null,null,null,'Dominican Republic','Cuban-Seed Corojo (Rosado)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Lansert i 1995 — verdens første Dominikanske puro med mørkt, cubansk-frø Corojo-dekkblad dyrket på Fuente-familiens egen Chateau de la Fuente-gård. Fullkroppet med tydelig pepper og lær. Svært begrenset produksjon.'),
('Arturo Fuente','Arturo Fuente','Fuente Fuente OpusX','Fuente Fuente','Corona Gorda',46,5.625,'Parejo',null,null,null,'Dominican Republic','Cuban-Seed Corojo (Rosado)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Lansert i 1995 — verdens første Dominikanske puro med mørkt, cubansk-frø Corojo-dekkblad dyrket på Fuente-familiens egen Chateau de la Fuente-gård. Fullkroppet med tydelig pepper og lær. Svært begrenset produksjon.'),
('Arturo Fuente','Arturo Fuente','Fuente Fuente OpusX','Perfecxion X','Torpedo',48,6.25,'Figurado','Torpedo','Pointed','Open','Dominican Republic','Cuban-Seed Corojo (Rosado)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Lansert i 1995 — verdens første Dominikanske puro med mørkt, cubansk-frø Corojo-dekkblad dyrket på Fuente-familiens egen Chateau de la Fuente-gård. Fullkroppet med tydelig pepper og lær. Svært begrenset produksjon.'),
('Arturo Fuente','Arturo Fuente','Fuente Fuente OpusX','Perfecxion 888','Torpedo',44,6.875,'Figurado','Torpedo','Pointed','Open','Dominican Republic','Cuban-Seed Corojo (Rosado)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Lansert i 1995 — verdens første Dominikanske puro med mørkt, cubansk-frø Corojo-dekkblad dyrket på Fuente-familiens egen Chateau de la Fuente-gård. Fullkroppet med tydelig pepper og lær. Svært begrenset produksjon.'),
('Arturo Fuente','Arturo Fuente','Fuente Fuente OpusX','Perfecxion A','Torpedo',47,9.25,'Figurado','Torpedo','Pointed','Open','Dominican Republic','Cuban-Seed Corojo (Rosado)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Lansert i 1995 — verdens første Dominikanske puro med mørkt, cubansk-frø Corojo-dekkblad dyrket på Fuente-familiens egen Chateau de la Fuente-gård. Fullkroppet med tydelig pepper og lær. Svært begrenset produksjon.'),
('Arturo Fuente','Arturo Fuente','Fuente Fuente OpusX','Robusto','Robusto',50,5.25,'Parejo',null,null,null,'Dominican Republic','Cuban-Seed Corojo (Rosado)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Lansert i 1995 — verdens første Dominikanske puro med mørkt, cubansk-frø Corojo-dekkblad dyrket på Fuente-familiens egen Chateau de la Fuente-gård. Fullkroppet med tydelig pepper og lær. Svært begrenset produksjon.'),
('Arturo Fuente','Arturo Fuente','Fuente Fuente OpusX','Petit Lancero','Lancero',39,6.25,'Parejo',null,null,null,'Dominican Republic','Cuban-Seed Corojo (Rosado)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Lansert i 1995 — verdens første Dominikanske puro med mørkt, cubansk-frø Corojo-dekkblad dyrket på Fuente-familiens egen Chateau de la Fuente-gård. Fullkroppet med tydelig pepper og lær. Svært begrenset produksjon.'),
('Arturo Fuente','Arturo Fuente','Fuente Fuente OpusX','Super Belicoso','Belicoso',52,5.5,'Figurado','Belicoso','Pointed','Closed','Dominican Republic','Cuban-Seed Corojo (Rosado)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Lansert i 1995 — verdens første Dominikanske puro med mørkt, cubansk-frø Corojo-dekkblad dyrket på Fuente-familiens egen Chateau de la Fuente-gård. Fullkroppet med tydelig pepper og lær. Svært begrenset produksjon.'),
('Arturo Fuente','Arturo Fuente','Fuente Fuente OpusX','Shark','Perfecto',54,5.625,'Figurado','Perfecto','Pointed','Closed','Dominican Republic','Cuban-Seed Corojo (Rosado)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Lansert i 1995 — verdens første Dominikanske puro med mørkt, cubansk-frø Corojo-dekkblad dyrket på Fuente-familiens egen Chateau de la Fuente-gård. Fullkroppet med tydelig pepper og lær. Shark er boxpresset med tilspisset hode. Svært begrenset produksjon.'),
('Arturo Fuente','Arturo Fuente','Fuente Fuente OpusX','Reserva d''Chateau','Toro',48,7.0,'Parejo',null,null,null,'Dominican Republic','Cuban-Seed Corojo (Rosado)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Lansert i 1995 — verdens første Dominikanske puro med mørkt, cubansk-frø Corojo-dekkblad dyrket på Fuente-familiens egen Chateau de la Fuente-gård. Fullkroppet med tydelig pepper og lær. Svært begrenset produksjon.');

-- ----------------------------------------------------------------
-- 4) Añejo
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Arturo Fuente','Arturo Fuente','Añejo','No 46','Corona Gorda',46,5.625,'Parejo',null,null,null,'United States','Connecticut Broadleaf (Maduro)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Añejo bruker mørkt Connecticut Broadleaf-dekkblad lagret i tomme cognac-fat før bruk — gir søtlig, krydret fylde. Begrenset, sesongbasert produksjon, kun solgt i sorte serier-bånd. Fullkroppet.'),
('Arturo Fuente','Arturo Fuente','Añejo','No 48','Churchill',48,7.0,'Parejo',null,null,null,'United States','Connecticut Broadleaf (Maduro)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Añejo bruker mørkt Connecticut Broadleaf-dekkblad lagret i tomme cognac-fat før bruk — gir søtlig, krydret fylde. Begrenset, sesongbasert produksjon, kun solgt i sorte serier-bånd. Fullkroppet.'),
('Arturo Fuente','Arturo Fuente','Añejo','No 49','Double Corona',49,7.625,'Parejo',null,null,null,'United States','Connecticut Broadleaf (Maduro)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Añejo bruker mørkt Connecticut Broadleaf-dekkblad lagret i tomme cognac-fat før bruk — gir søtlig, krydret fylde. Begrenset, sesongbasert produksjon, kun solgt i sorte serier-bånd. Fullkroppet.'),
('Arturo Fuente','Arturo Fuente','Añejo','No 55','Torpedo',55,6.0,'Figurado','Torpedo','Pointed','Closed','United States','Connecticut Broadleaf (Maduro)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Añejo bruker mørkt Connecticut Broadleaf-dekkblad lagret i tomme cognac-fat før bruk — gir søtlig, krydret fylde. Begrenset, sesongbasert produksjon, kun solgt i sorte serier-bånd. Fullkroppet.'),
('Arturo Fuente','Arturo Fuente','Añejo','No 60','Gordo',60,6.0,'Parejo',null,null,null,'United States','Connecticut Broadleaf (Maduro)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Añejo bruker mørkt Connecticut Broadleaf-dekkblad lagret i tomme cognac-fat før bruk — gir søtlig, krydret fylde. Begrenset, sesongbasert produksjon, kun solgt i sorte serier-bånd. Fullkroppet.'),
('Arturo Fuente','Arturo Fuente','Añejo','No 66','Gordo',66,6.625,'Parejo',null,null,null,'United States','Connecticut Broadleaf (Maduro)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Añejo bruker mørkt Connecticut Broadleaf-dekkblad lagret i tomme cognac-fat før bruk — gir søtlig, krydret fylde. Begrenset, sesongbasert produksjon, kun solgt i sorte serier-bånd. Fullkroppet.'),
('Arturo Fuente','Arturo Fuente','Añejo','No 888','Lonsdale',44,6.875,'Parejo',null,null,null,'United States','Connecticut Broadleaf (Maduro)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Añejo bruker mørkt Connecticut Broadleaf-dekkblad lagret i tomme cognac-fat før bruk — gir søtlig, krydret fylde. Begrenset, sesongbasert produksjon, kun solgt i sorte serier-bånd. Fullkroppet.'),
('Arturo Fuente','Arturo Fuente','Añejo','Shark No 77','Perfecto',54,5.625,'Figurado','Perfecto','Pointed','Closed','United States','Connecticut Broadleaf (Maduro)','Dominican',array['Dominican Republic'],'Dominican Republic',5,null,'Añejo bruker mørkt Connecticut Broadleaf-dekkblad lagret i tomme cognac-fat før bruk — gir søtlig, krydret fylde. Shark er boxpresset med tilspisset hode. Begrenset, sesongbasert produksjon, kun solgt i sorte serier-bånd. Fullkroppet.');

-- ----------------------------------------------------------------
-- 5) Gran Reserva (Flor Fina 8-5-8 / Chateau Fuente-linjen)
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Arturo Fuente','Arturo Fuente','Gran Reserva','Flor Fina 8-5-8','Corona',47,6.0,'Parejo',null,null,null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Gran Reserva er Arturo Fuentes klassiske, anerkjente linje med Cameroon-dekkblad og dominikansk innmat — mild til middels styrke med jevn, balansert smak. Flor Fina 8-5-8 er flaggskipvitolaen og en av merkets mest solgte sigarer gjennom tidene.'),
('Arturo Fuente','Arturo Fuente','Gran Reserva','Chateau Fuente (Robusto)','Robusto',50,4.5,'Parejo',null,null,null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Gran Reserva er Arturo Fuentes klassiske, anerkjente linje med Cameroon-dekkblad og dominikansk innmat — mild til middels styrke med jevn, balansert smak. Del av Chateau Fuente-undersortimentet.'),
('Arturo Fuente','Arturo Fuente','Gran Reserva','Cuban Belicoso','Belicoso',50,5.75,'Figurado','Belicoso','Pointed','Closed','Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Gran Reserva er Arturo Fuentes klassiske, anerkjente linje med Cameroon-dekkblad og dominikansk innmat — mild til middels styrke med jevn, balansert smak. Del av Chateau Fuente-undersortimentet.'),
('Arturo Fuente','Arturo Fuente','Gran Reserva','Double Chateau (Toro)','Toro',50,6.75,'Parejo',null,null,null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Gran Reserva er Arturo Fuentes klassiske, anerkjente linje med Cameroon-dekkblad og dominikansk innmat — mild til middels styrke med jevn, balansert smak. Del av Chateau Fuente-undersortimentet.'),
('Arturo Fuente','Arturo Fuente','Gran Reserva','King B (Belicoso)','Belicoso',49,7.0,'Figurado','Belicoso','Pointed','Closed','Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Gran Reserva er Arturo Fuentes klassiske, anerkjente linje med Cameroon-dekkblad og dominikansk innmat — mild til middels styrke med jevn, balansert smak. Del av Chateau Fuente-undersortimentet.'),
('Arturo Fuente','Arturo Fuente','Gran Reserva','King T Tubes (Churchill)','Churchill',49,7.0,'Parejo',null,null,null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Gran Reserva er Arturo Fuentes klassiske, anerkjente linje med Cameroon-dekkblad og dominikansk innmat — mild til middels styrke med jevn, balansert smak. Selges i individuelle aluminiumsrør. Del av Chateau Fuente-undersortimentet.'),
('Arturo Fuente','Arturo Fuente','Gran Reserva','Queen B (Figurado)','Figurado',52,5.5,'Figurado','Belicoso','Pointed','Closed','Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Gran Reserva er Arturo Fuentes klassiske, anerkjente linje med Cameroon-dekkblad og dominikansk innmat — mild til middels styrke med jevn, balansert smak. Del av Chateau Fuente-undersortimentet.'),
('Arturo Fuente','Arturo Fuente','Gran Reserva','Royal Salute (Churchill)','Churchill',54,7.5,'Parejo',null,null,null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Gran Reserva er Arturo Fuentes klassiske, anerkjente linje med Cameroon-dekkblad og dominikansk innmat — mild til middels styrke med jevn, balansert smak. Royal Salute er serien''s lengste, mest staselige vitola.');

-- ----------------------------------------------------------------
-- 6) Curly Head Deluxe
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Arturo Fuente','Arturo Fuente','Curly Head Deluxe','Natural','Lonsdale',43,6.5,'Parejo',null,null,null,'United States','Connecticut Shade','Dominican',array['Dominican Republic'],'Dominican Republic',2,null,'Curly Head Deluxe er en av Arturo Fuentes eldste, mest tilgjengelige linjer — en mild til middels rimelig klassiker laget av kortere/«krøllete» tobakksblader. Godt innførings-alternativ for nye sigarrøykere.'),
('Arturo Fuente','Arturo Fuente','Curly Head Deluxe','Maduro','Lonsdale',43,6.5,'Parejo',null,null,null,'United States','Connecticut Broadleaf (Maduro)','Dominican',array['Dominican Republic'],'Dominican Republic',2,null,'Curly Head Deluxe er en av Arturo Fuentes eldste, mest tilgjengelige linjer — en mild til middels rimelig klassiker laget av kortere/«krøllete» tobakksblader. Maduro-varianten har et søtere, mørkere dekkblad. Godt innførings-alternativ for nye sigarrøykere.');

-- ----------------------------------------------------------------
-- 7) ALIAS — vanlige skrivemåter/forkortelser for OCR/søk-treff
-- ----------------------------------------------------------------
insert into cigar_aliases (alias, manufacturer, brand, series) values
('Fuente', 'Arturo Fuente', 'Arturo Fuente', null),
('A. Fuente', 'Arturo Fuente', 'Arturo Fuente', null),
('AFuente', 'Arturo Fuente', 'Arturo Fuente', null),
('Hemingway', 'Arturo Fuente', 'Arturo Fuente', 'Hemingway'),
('Don Carlos', 'Arturo Fuente', 'Arturo Fuente', 'Don Carlos'),
('OpusX', 'Arturo Fuente', 'Arturo Fuente', 'Fuente Fuente OpusX'),
('Opus X', 'Arturo Fuente', 'Arturo Fuente', 'Fuente Fuente OpusX'),
('Fuente Fuente Opus X', 'Arturo Fuente', 'Arturo Fuente', 'Fuente Fuente OpusX'),
('Anejo', 'Arturo Fuente', 'Arturo Fuente', 'Añejo'),
('Añejo Reserva', 'Arturo Fuente', 'Arturo Fuente', 'Añejo'),
('8-5-8', 'Arturo Fuente', 'Arturo Fuente', 'Gran Reserva'),
('858', 'Arturo Fuente', 'Arturo Fuente', 'Gran Reserva'),
('Chateau Fuente', 'Arturo Fuente', 'Arturo Fuente', 'Gran Reserva'),
('Flor Fina', 'Arturo Fuente', 'Arturo Fuente', 'Gran Reserva'),
('Curly Head', 'Arturo Fuente', 'Arturo Fuente', 'Curly Head Deluxe');

-- ----------------------------------------------------------------
-- 8) Sanity check — skal være nøyaktig 41 nye Arturo Fuente-rader
-- ----------------------------------------------------------------
do $$
declare
  cnt int;
begin
  select count(*) into cnt from cigars where manufacturer = 'Arturo Fuente';
  if cnt <> 41 then
    raise exception 'Forventet 41 Arturo Fuente-rader, fant %', cnt;
  end if;
end $$;
