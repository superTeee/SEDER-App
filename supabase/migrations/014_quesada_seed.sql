-- ============================================================
-- 014_quesada_seed.sql
--
-- Setter inn Quesada Cigars — grunnlagt 1974 av Manuel Quesada,
-- hans far og bror som MATASA (Manufactura de Tabacos S.A.) i
-- Santiago, Dominikanske republikk. Familieeid fabrikk som i
-- 2014 endret navn til Quesada Cigars (samme år som 40th
-- Anniversary-sigaren ble lansert). Quesada produserer både
-- egne merker og kjente tredjepartsmerker (bl.a. Romeo y Julieta
-- non-Cuban, Fonseca, Cubita).
--
-- I databasen fra før: 1 rad (Quesada/España, Toro). Denne
-- migrasjonen bygger ut med 23 nye rader fordelt på 6 serier:
--
--   1) Casa Magna Colorado     — flaggskip, nicaraguansk Corojo-
--                                dekkblad, laget av Plasencia-
--                                familien i Nicaragua
--   2) Casa Magna Connecticut  — mildere variant, Ecuador
--                                Connecticut Shade-dekkblad
--   3) Casa Magna Maduro       — meksikansk San Andrés-dekkblad
--   4) Casa Magna Oscuro       — mørk honduransk Oscuro-dekkblad,
--                                fullkroppet
--   5) Quesada 1974            — hyllest til grunnleggelsesåret,
--                                Ecuador Cameroon-frø-dekkblad
--   6) Quesada Tributo         — hyllest til fire familiemedlemmer
--                                omkommet i flyulykke, eksklusiv
--                                "HCHS"-hybriddekkblad
--   7) Quesada Oktoberfest     — sesongbasert, meksikansk San
--                                Andrés-dekkblad, laget for å
--                                pares med Oktoberfest-øl
--
-- Kilder: quesadacigars.com, cigaraficionado.com, halfwheel.com,
-- cigar-coop.com, neptunecigar.com, en.wikipedia.org/wiki/Quesada_Cigars
-- (offisielle vitola-lister og produktbeskrivelser).
-- ============================================================

-- ----------------------------------------------------------------
-- 1) Casa Magna Colorado — flaggskiplinjen. Samarbeid mellom
--    Manuel Quesada og Nestor Plasencia Sr., produsert i Nicaragua.
--    Nicaraguansk Corojo-dekkblad, nicaraguansk bind og innmat.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Quesada','Casa Magna','Colorado','Robusto','Robusto',52,5.5,'Parejo',null,null,null,'Nicaragua','Corojo','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Casa Magna Colorado er Quesadas prisbelønte flaggskip — et samarbeid mellom Manuel Quesada og Nestor Plasencia Sr., produsert i Nicaragua. Nicaraguansk Corojo-dekkblad gir krydder, jord og en mørk sødme.'),
('Quesada','Casa Magna','Colorado','Belicoso','Belicoso',54,6.25,'Figurado','Belicoso','Pointed','Closed','Nicaragua','Corojo','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Casa Magna Colorado er Quesadas prisbelønte flaggskip, laget av familien Plasencia i Nicaragua. Belicoso-formen konsentrerer trekket mot en spiss ende.'),
('Quesada','Casa Magna','Colorado','Churchill','Churchill',49,6.875,'Parejo',null,null,null,'Nicaragua','Corojo','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Casa Magna Colorado er Quesadas prisbelønte flaggskip, laget av familien Plasencia i Nicaragua. Churchill er den lengste klassiske vitolaen i serien.'),
('Quesada','Casa Magna','Colorado','Gran Toro','Toro',58,6.0,'Parejo',null,null,null,'Nicaragua','Corojo','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Casa Magna Colorado er Quesadas prisbelønte flaggskip, laget av familien Plasencia i Nicaragua. Gran Toro er en bredere, kraftigere utgave av den klassiske Toro-formen.'),
('Quesada','Casa Magna','Colorado','Pikito','Petit Corona',42,4.75,'Parejo',null,null,null,'Nicaragua','Corojo','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Casa Magna Colorado er Quesadas prisbelønte flaggskip, laget av familien Plasencia i Nicaragua. Pikito er en liten, rask vitola for kortere røyketid.'),
('Quesada','Casa Magna','Colorado','Torito','Robusto',60,4.75,'Parejo',null,null,null,'Nicaragua','Corojo','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Casa Magna Colorado er Quesadas prisbelønte flaggskip, laget av familien Plasencia i Nicaragua. Torito er en kort, tykk vitola med konsentrert smak.');

-- ----------------------------------------------------------------
-- 2) Casa Magna Connecticut — mildere søsterlinje, Ecuador
--    Connecticut Shade-dekkblad over nicaraguansk bind og
--    dominikansk/nicaraguansk innmat.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Quesada','Casa Magna','Connecticut','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Connecticut Shade','Nicaraguan',array['Dominican Republic','Nicaragua'],'Nicaragua',2,null,'Casa Magna Connecticut er den mildeste utgaven i serien — et silkeaktig Ecuador Connecticut Shade-dekkblad over nicaraguansk bind og innmat fra Den dominikanske republikk og Nicaragua.'),
('Quesada','Casa Magna','Connecticut','Toro','Toro',52,6.5,'Parejo',null,null,null,'Ecuador','Connecticut Shade','Nicaraguan',array['Dominican Republic','Nicaragua'],'Nicaragua',2,null,'Casa Magna Connecticut er den mildeste utgaven i serien — et silkeaktig Ecuador Connecticut Shade-dekkblad over nicaraguansk bind og innmat fra Den dominikanske republikk og Nicaragua.'),
('Quesada','Casa Magna','Connecticut','Toro Gordo','Gordo',56,6.0,'Parejo',null,null,null,'Ecuador','Connecticut Shade','Nicaraguan',array['Dominican Republic','Nicaragua'],'Nicaragua',2,null,'Casa Magna Connecticut er den mildeste utgaven i serien. Toro Gordo er den bredeste vitolaen — en time med jevn, mild røyking.');

-- ----------------------------------------------------------------
-- 3) Casa Magna Maduro — meksikansk San Andrés-dekkblad over
--    nicaraguansk bind, innmat fra DR/Nicaragua/USA.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Quesada','Casa Magna','Maduro','Robusto','Robusto',54,5.0,'Parejo',null,null,null,'Mexico','San Andrés','Nicaraguan',array['Dominican Republic','Nicaragua','United States'],'Nicaragua',4,null,'Casa Magna Maduro bruker et meksikansk San Andrés-dekkblad over nicaraguansk bind og innmat fra Den dominikanske republikk, Nicaragua og USA. Mørk sjokolade og krydder.'),
('Quesada','Casa Magna','Maduro','Toro','Toro',52,6.5,'Parejo',null,null,null,'Mexico','San Andrés','Nicaraguan',array['Dominican Republic','Nicaragua','United States'],'Nicaragua',4,null,'Casa Magna Maduro bruker et meksikansk San Andrés-dekkblad. Mørk sjokolade, krydder og en jevn sødme.'),
('Quesada','Casa Magna','Maduro','Belicoso','Belicoso',52,5.5,'Figurado','Belicoso','Pointed','Closed','Mexico','San Andrés','Nicaraguan',array['Dominican Republic','Nicaragua','United States'],'Nicaragua',4,null,'Casa Magna Maduro Belicoso er boxpresset, med et meksikansk San Andrés-dekkblad og konsentrert trekk mot den spisse enden.'),
('Quesada','Casa Magna','Maduro','Toro TAA','Toro',54,6.0,'Parejo',null,null,null,'Mexico','San Andrés','Nicaraguan',array['Dominican Republic','Nicaragua','United States'],'Nicaragua',4,null,'Casa Magna Maduro Toro TAA er en boxpresset, TAA-eksklusiv vitola med meksikansk San Andrés-dekkblad.'),
('Quesada','Casa Magna','Maduro','Lancero','Lancero',40,7.0,'Parejo',null,null,null,'Mexico','San Andrés','Nicaraguan',array['Dominican Republic','Nicaragua','United States'],'Nicaragua',4,null,'Casa Magna Maduro Lancero er en limited-utgave — slank og lang, med meksikansk San Andrés-dekkblad.');

-- ----------------------------------------------------------------
-- 4) Casa Magna Oscuro — mørkt, oljeaktig honduransk Oscuro-
--    dekkblad, fullkroppet.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Quesada','Casa Magna','Oscuro','Robusto','Robusto',54,5.0,'Parejo',null,null,null,'Honduras','Oscuro','Honduran',array['Nicaragua','Honduras'],'Nicaragua',5,null,'Casa Magna Oscuro har et mørkt, oljeaktig honduransk Oscuro-dekkblad over honduransk bind og kraftig nicaraguansk/honduransk innmat. Mørk sjokolade, espresso, jord og sort pepper.'),
('Quesada','Casa Magna','Oscuro','Toro','Toro',52,6.0,'Parejo',null,null,null,'Honduras','Oscuro','Honduran',array['Nicaragua','Honduras'],'Nicaragua',5,null,'Casa Magna Oscuro har et mørkt, oljeaktig honduransk Oscuro-dekkblad. Fullkroppet med mørk sjokolade, espresso, jord og sort pepper.');

-- ----------------------------------------------------------------
-- 5) Quesada 1974 — hyllest til året familien Quesada åpnet sin
--    første fabrikk (MATASA). Ecuador Cameroon-frø-dekkblad.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Quesada','Quesada','1974','Toro','Toro',52,6.0,'Parejo',null,null,null,'Ecuador','Cameroon-seed','Dominican',array['Dominican Republic','Nicaragua'],'Dominican Republic',3,null,'Quesada 1974 hyller året familien Quesada åpnet sin første fabrikk, MATASA. Ecuador Cameroon-frø-dekkblad over dominikansk bind og innmat fra Den dominikanske republikk og Nicaragua. Pepper, seder og frukt med underliggende sødme.'),
('Quesada','Quesada','1974','Short Robusto','Robusto',50,4.0,'Parejo',null,null,null,'Ecuador','Cameroon-seed','Dominican',array['Dominican Republic','Nicaragua'],'Dominican Republic',3,null,'Quesada 1974 hyller året familien Quesada åpnet sin første fabrikk, MATASA. Short Robusto gir samme profil i en kortere, raskere røyk.'),
('Quesada','Quesada','1974','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Cameroon-seed','Dominican',array['Dominican Republic','Nicaragua'],'Dominican Republic',3,null,'Quesada 1974 hyller året familien Quesada åpnet sin første fabrikk, MATASA. Pepper, seder og frukt med underliggende sødme.'),
('Quesada','Quesada','1974','Corona','Corona',43,6.0,'Parejo',null,null,null,'Ecuador','Cameroon-seed','Dominican',array['Dominican Republic','Nicaragua'],'Dominican Republic',3,null,'Quesada 1974 hyller året familien Quesada åpnet sin første fabrikk, MATASA. Corona er en slank, klassisk vitola.'),
('Quesada','Quesada','1974','Lancero','Lancero',38,7.0,'Parejo',null,null,null,'Ecuador','Cameroon-seed','Dominican',array['Dominican Republic','Nicaragua'],'Dominican Republic',3,null,'Quesada 1974 hyller året familien Quesada åpnet sin første fabrikk, MATASA. Lancero er den slankeste og lengste vitolaen i serien.');

-- ----------------------------------------------------------------
-- 6) Quesada Tributo (2010) — hyllest til fire familiemedlemmer
--    omkommet i en flyulykke. Eksklusiv "HCHS"-hybriddekkblad
--    (Habano 2000 x Corojo x Habano Vuelta Arriba x Sumatra).
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Quesada','Quesada','Tributo','Alvarito','Petit Corona',40,4.5,'Parejo',null,null,null,'Ecuador','HCHS Hybrid','Honduran Criollo 98',array['Dominican Republic','Nicaragua'],'Dominican Republic',4,null,'Quesada Tributo (2010) hyller fire familiemedlemmer som omkom i en flyulykke. Eksklusivt "HCHS"-hybriddekkblad (Habano 2000 x Corojo x Habano Vuelta Arriba x Sumatra), honduransk Criollo 98-bind og kraftig dominikansk/nicaraguansk Ligero-innmat. Alvarito er den minste vitolaen.'),
('Quesada','Quesada','Tributo','Julio','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','HCHS Hybrid','Honduran Criollo 98',array['Dominican Republic','Nicaragua'],'Dominican Republic',4,null,'Quesada Tributo (2010) hyller fire familiemedlemmer som omkom i en flyulykke. Eksklusivt "HCHS"-hybriddekkblad, honduransk Criollo 98-bind og kraftig Ligero-innmat fra DR og Nicaragua.'),
('Quesada','Quesada','Tributo','Alvaro','Torpedo',48,5.5,'Figurado','Torpedo','Pointed','Closed','Ecuador','HCHS Hybrid','Honduran Criollo 98',array['Dominican Republic','Nicaragua'],'Dominican Republic',4,null,'Quesada Tributo (2010) hyller fire familiemedlemmer som omkom i en flyulykke. Alvaro er torpedo-formen i serien, med konsentrert trekk mot den spisse enden.'),
('Quesada','Quesada','Tributo','Manolin','Gordo',60,6.0,'Parejo',null,null,null,'Ecuador','HCHS Hybrid','Honduran Criollo 98',array['Dominican Republic','Nicaragua'],'Dominican Republic',4,null,'Quesada Tributo (2010) hyller fire familiemedlemmer som omkom i en flyulykke. Manolin er den bredeste vitolaen i serien.');

-- ----------------------------------------------------------------
-- 7) Quesada Oktoberfest — sesongbasert årlig utgivelse siden
--    2011, laget for å pares med Oktoberfest-øl. Meksikansk San
--    Andrés-dekkblad, dominikansk bind og innmat, laget hos
--    Tabacos de Exportación i Den dominikanske republikk.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('Quesada','Quesada','Oktoberfest','The Bavarian','Robusto',52,5.5,'Parejo',null,null,null,'Mexico','San Andrés','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Quesada Oktoberfest er en årlig sesongutgivelse siden 2011, laget for å pares med Oktoberfest-øl. Mørkt, oljeaktig meksikansk San Andrés-dekkblad over dominikansk bind og innmat. The Bavarian er en av de to opprinnelige kjernevitolaene.'),
('Quesada','Quesada','Oktoberfest','Das Boot','Toro',52,6.0,'Parejo',null,null,null,'Mexico','San Andrés','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Quesada Oktoberfest er en årlig sesongutgivelse siden 2011, laget for å pares med Oktoberfest-øl. Mørkt, oljeaktig meksikansk San Andrés-dekkblad over dominikansk bind og innmat.'),
('Quesada','Quesada','Oktoberfest','Über','Gordo',65,6.0,'Parejo',null,null,null,'Mexico','San Andrés','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Quesada Oktoberfest er en årlig sesongutgivelse siden 2011. Über er den massive originalvitolaen — 6×65 — med mørkt San Andrés-dekkblad.'),
('Quesada','Quesada','Oktoberfest','Kaiser Ludwig','Toro',49,6.0,'Parejo',null,null,null,'Mexico','San Andrés','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Quesada Oktoberfest er en årlig sesongutgivelse siden 2011. Kaiser Ludwig er en senere tilleggsvitola i serien, med samme mørke San Andrés-dekkblad.');

-- ----------------------------------------------------------------
-- 8) ALIAS — vanlige skrivemåter/forkortelser for OCR/søk-treff
-- ----------------------------------------------------------------
insert into cigar_aliases (alias, manufacturer, brand, series) values
('Quesada', 'Quesada', 'Quesada', null),
('Casa Magna', 'Quesada', 'Casa Magna', null),
('CasaMagna', 'Quesada', 'Casa Magna', null),
('Casa Magna Colorado', 'Quesada', 'Casa Magna', 'Colorado'),
('Casa Magna Connecticut', 'Quesada', 'Casa Magna', 'Connecticut'),
('Casa Magna Maduro', 'Quesada', 'Casa Magna', 'Maduro'),
('Casa Magna Oscuro', 'Quesada', 'Casa Magna', 'Oscuro'),
('Quesada 1974', 'Quesada', 'Quesada', '1974'),
('Tributo', 'Quesada', 'Quesada', 'Tributo'),
('Quesada Tributo', 'Quesada', 'Quesada', 'Tributo'),
('Oktoberfest', 'Quesada', 'Quesada', 'Oktoberfest'),
('Quesada Oktoberfest', 'Quesada', 'Quesada', 'Oktoberfest'),
('Uber', 'Quesada', 'Quesada', 'Oktoberfest'),
('Über', 'Quesada', 'Quesada', 'Oktoberfest'),
('Espana', 'Quesada', 'Quesada', 'Espana'),
('España', 'Quesada', 'Quesada', 'Espana');
