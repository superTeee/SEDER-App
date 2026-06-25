-- ============================================================
-- 011_jc_newman_seed.sql
--
-- Setter inn J.C. Newman Cigar Co. (Tampa, FL — grunnlagt 1895,
-- USAs eldste familieeide sigarprodusent). Selskapet eier flere
-- merker som allerede fantes i databasen som løsrevne, feilkoblede
-- rader (Brick House, Diamond Crown) — disse kobles nå korrekt til
-- manufacturer = 'J.C. Newman'. Resten av linjene er helt nye.
--
-- VIKTIG: J.C. Newman driver også USA-salgsstyrken for Arturo Fuente
-- (distribusjon), men produserer IKKE Fuente-sigarene. Arturo Fuente
-- forblir derfor egen manufacturer — ikke rørt i denne migrasjonen.
-- Budsjett-/maskinrullede bundle-linjer (Factory Throwouts, Trader
-- Jack's, Quorum) er utenfor scope for denne premium-fokuserte MVP-en.
--
-- Linjer:
--   0) Re-kobler eksisterende Brick House (3 rader) og
--      Diamond Crown (1 rad) til manufacturer = 'J.C. Newman'
--   1) Brick House          — utvider Classic/Maduro/Double Connecticut
--                              med flere vitolas (Nicaragua, PENSA-fabrikk)
--   2) Diamond Crown        — Classic-serien (4 nye str.) + Black Diamond
--                              (luksus, laget av Tabacalera A. Fuente i DR)
--   3) Perla del Mar        — Corojo, Maduro, Shade (Ecuador/Nicaragua, PENSA)
--   4) El Baton             — kraftig nicaraguansk puro
--   5) Cuesta-Rey           — historisk merke (140+ år), Centro Fino
--   6) The American         — verdens første sigar med Florida Sun Grown
--                              dekkblad, rullet i Tampa (El Reloj-fabrikken)
--   7) Yagua                — rustikk, palmebark-lagret limited release
--
-- Totalt: 4 eksisterende rader re-koblet + 35 nye rader.
-- Kilder: jcnewman.com, cigaraficionado.com, cigar-coop.com, halfwheel.com,
-- cuencacigars.com (offisielle vitola-lister og produktbeskrivelser).
-- ============================================================

-- ----------------------------------------------------------------
-- 0) Re-koble eksisterende Brick House + Diamond Crown til J.C. Newman
-- ----------------------------------------------------------------
update cigars set manufacturer = 'J.C. Newman' where brand in ('Brick House', 'Diamond Crown');

-- ----------------------------------------------------------------
-- 1) Brick House — flere vitolas (Classic, Maduro, Double Connecticut)
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('J.C. Newman','Brick House','Classic','Toro','Toro',52,6.0,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Brick House Classic er J.C. Newmans mest solgte håndlagde sigar — mørkt, oljeholdig nicaraguansk Habano-dekkblad over nicaraguansk innmat. Middels styrke med rik, balansert smak av jord, krydder og lett sødme. Laget på PENSA-fabrikken i Nicaragua.'),
('J.C. Newman','Brick House','Classic','Churchill','Churchill',47,7.0,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Brick House Classic er J.C. Newmans mest solgte håndlagde sigar — mørkt, oljeholdig nicaraguansk Habano-dekkblad over nicaraguansk innmat. Middels styrke med rik, balansert smak av jord, krydder og lett sødme. Laget på PENSA-fabrikken i Nicaragua.'),
('J.C. Newman','Brick House','Classic','Corona Larga','Corona Larga',44,6.5,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Brick House Classic er J.C. Newmans mest solgte håndlagde sigar — mørkt, oljeholdig nicaraguansk Habano-dekkblad over nicaraguansk innmat. Middels styrke med rik, balansert smak av jord, krydder og lett sødme. Laget på PENSA-fabrikken i Nicaragua.'),
('J.C. Newman','Brick House','Maduro','Toro','Toro',52,6.0,'Parejo',null,null,null,'Nicaragua','Nicaraguan Maduro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Brick House Maduro bruker et mørkere, søtere nicaraguansk Maduro-dekkblad enn Classic-utgaven — gir mer fylde og en søtlig, kakao-aktig finish. Middels til fullkroppet.'),
('J.C. Newman','Brick House','Maduro','Mighty Mighty','Gordo',60,6.25,'Parejo',null,null,null,'Nicaragua','Nicaraguan Maduro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Brick House Maduro bruker et mørkere, søtere nicaraguansk Maduro-dekkblad enn Classic-utgaven — gir mer fylde og en søtlig, kakao-aktig finish. Mighty Mighty er en kort, svært tykk (60 ring gauge) vitola med lang røyketid.'),
('J.C. Newman','Brick House','Double Connecticut','Toro','Toro',52,6.0,'Parejo',null,null,null,'United States','Connecticut Shade','Connecticut',array['Nicaragua'],'Nicaragua',2,null,'Double Connecticut bruker et lysere Connecticut Shade-dekkblad over Connecticut-bundet og nicaraguansk innmat — mildere og kremete enn Classic/Maduro-utgavene, med nøtteaktig sødme.');

-- ----------------------------------------------------------------
-- 2) Diamond Crown — Classic-serien + Black Diamond
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('J.C. Newman','Diamond Crown','Classic','No. 3','Toro',54,6.5,'Parejo',null,null,null,'United States','Connecticut Shade','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Diamond Crown Classic er J.C. Newmans flaggskip-luksuslinje, håndlaget av Tabacalera A. Fuente i Den dominikanske republikk. Connecticut Shade-dekkblad over dominikansk innmat lagret i flere år — middels til fullkroppet med kompleks, jevn smak.'),
('J.C. Newman','Diamond Crown','Classic','No. 4','Robusto',54,5.5,'Parejo',null,null,null,'United States','Connecticut Shade','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Diamond Crown Classic er J.C. Newmans flaggskip-luksuslinje, håndlaget av Tabacalera A. Fuente i Den dominikanske republikk. Connecticut Shade-dekkblad over dominikansk innmat lagret i flere år — middels til fullkroppet med kompleks, jevn smak. No. 4 er en «Double Robusto»-vitola og en av de mest populære i serien.'),
('J.C. Newman','Diamond Crown','Classic','No. 5','Robusto',54,4.5,'Parejo',null,null,null,'United States','Connecticut Shade','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Diamond Crown Classic er J.C. Newmans flaggskip-luksuslinje, håndlaget av Tabacalera A. Fuente i Den dominikanske republikk. Connecticut Shade-dekkblad over dominikansk innmat lagret i flere år — middels til fullkroppet med kompleks, jevn smak. No. 5 er den kortest vitolaen i serien.'),
('J.C. Newman','Diamond Crown','Classic','No. 6','Corona Gorda',46,6.0,'Parejo',null,null,null,'United States','Connecticut Shade','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Diamond Crown Classic er J.C. Newmans flaggskip-luksuslinje, håndlaget av Tabacalera A. Fuente i Den dominikanske republikk. Connecticut Shade-dekkblad over dominikansk innmat lagret i flere år — middels til fullkroppet med kompleks, jevn smak. No. 6 er den tynneste vitolaen i serien.'),
('J.C. Newman','Diamond Crown','Black Diamond','Robusto','Robusto',54,5.0,'Parejo',null,null,null,'United States','Connecticut Habano (Maduro)','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Black Diamond er den mørkere, kraftigere varianten i Diamond Crown-familien — Connecticut Habano Maduro-dekkblad over dominikansk innmat. Fyldigere og søtere enn Classic-utgaven, fortsatt håndlaget av Tabacalera A. Fuente.'),
('J.C. Newman','Diamond Crown','Black Diamond','Toro','Toro',54,6.0,'Parejo',null,null,null,'United States','Connecticut Habano (Maduro)','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Black Diamond er den mørkere, kraftigere varianten i Diamond Crown-familien — Connecticut Habano Maduro-dekkblad over dominikansk innmat. Fyldigere og søtere enn Classic-utgaven, fortsatt håndlaget av Tabacalera A. Fuente.'),
('J.C. Newman','Diamond Crown','Black Diamond','Churchill','Churchill',54,7.0,'Parejo',null,null,null,'United States','Connecticut Habano (Maduro)','Dominican',array['Dominican Republic'],'Dominican Republic',4,null,'Black Diamond er den mørkere, kraftigere varianten i Diamond Crown-familien — Connecticut Habano Maduro-dekkblad over dominikansk innmat. Fyldigere og søtere enn Classic-utgaven, fortsatt håndlaget av Tabacalera A. Fuente.');

-- ----------------------------------------------------------------
-- 3) Perla del Mar — Corojo, Maduro, Shade
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('J.C. Newman','Perla del Mar','Corojo','Robusto','Robusto',52,4.75,'Parejo',null,null,null,'Ecuador','Corojo','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Perla del Mar Corojo har et ecuadoriansk Corojo-dekkblad over nicaraguansk bind og innmat fra fire ulike distrikter (Pueblo Nuevo, La Reina, Condega, Jalapa). Tampa-style press gir en mer rektangulær form. Middels styrke. Laget på PENSA-fabrikken i Nicaragua.'),
('J.C. Newman','Perla del Mar','Corojo','Corona Gorda','Corona Gorda',46,5.5,'Parejo',null,null,null,'Ecuador','Corojo','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Perla del Mar Corojo har et ecuadoriansk Corojo-dekkblad over nicaraguansk bind og innmat fra fire ulike distrikter (Pueblo Nuevo, La Reina, Condega, Jalapa). Tampa-style press gir en mer rektangulær form. Middels styrke. Laget på PENSA-fabrikken i Nicaragua.'),
('J.C. Newman','Perla del Mar','Corojo','Toro','Toro',54,6.25,'Parejo',null,null,null,'Ecuador','Corojo','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Perla del Mar Corojo har et ecuadoriansk Corojo-dekkblad over nicaraguansk bind og innmat fra fire ulike distrikter (Pueblo Nuevo, La Reina, Condega, Jalapa). Tampa-style press gir en mer rektangulær form. Middels styrke. Laget på PENSA-fabrikken i Nicaragua.'),
('J.C. Newman','Perla del Mar','Corojo','Double Toro','Gordo',60,6.0,'Parejo',null,null,null,'Ecuador','Corojo','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Perla del Mar Corojo har et ecuadoriansk Corojo-dekkblad over nicaraguansk bind og innmat fra fire ulike distrikter (Pueblo Nuevo, La Reina, Condega, Jalapa). Tampa-style press gir en mer rektangulær form. Middels styrke. Laget på PENSA-fabrikken i Nicaragua.'),
('J.C. Newman','Perla del Mar','Maduro','Robusto','Robusto',52,4.75,'Parejo',null,null,null,'Nicaragua','Nicaraguan Maduro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Perla del Mar Maduro bruker et mørkt, søtt nicaraguansk Maduro-dekkblad over samme nicaraguanske bind/innmat-base som Corojo-utgaven. Fyldigere og søtere, middels til fullkroppet.'),
('J.C. Newman','Perla del Mar','Maduro','Corona Gorda','Corona Gorda',46,5.5,'Parejo',null,null,null,'Nicaragua','Nicaraguan Maduro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Perla del Mar Maduro bruker et mørkt, søtt nicaraguansk Maduro-dekkblad over samme nicaraguanske bind/innmat-base som Corojo-utgaven. Fyldigere og søtere, middels til fullkroppet.'),
('J.C. Newman','Perla del Mar','Maduro','Toro','Toro',54,6.25,'Parejo',null,null,null,'Nicaragua','Nicaraguan Maduro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Perla del Mar Maduro bruker et mørkt, søtt nicaraguansk Maduro-dekkblad over samme nicaraguanske bind/innmat-base som Corojo-utgaven. Fyldigere og søtere, middels til fullkroppet.'),
('J.C. Newman','Perla del Mar','Maduro','Double Toro','Gordo',60,6.0,'Parejo',null,null,null,'Nicaragua','Nicaraguan Maduro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Perla del Mar Maduro bruker et mørkt, søtt nicaraguansk Maduro-dekkblad over samme nicaraguanske bind/innmat-base som Corojo-utgaven. Fyldigere og søtere, middels til fullkroppet.'),
('J.C. Newman','Perla del Mar','Shade','Robusto','Robusto',52,4.75,'Parejo',null,null,null,'United States','Connecticut Shade','Nicaraguan',array['Nicaragua'],'Nicaragua',2,null,'Perla del Mar Shade har et lyst, kremet Connecticut Shade-dekkblad — den mildeste og mest tilgjengelige utgaven i Perla del Mar-familien, med en cubansk-inspirert, smooth profil.'),
('J.C. Newman','Perla del Mar','Shade','Toro','Toro',54,6.25,'Parejo',null,null,null,'United States','Connecticut Shade','Nicaraguan',array['Nicaragua'],'Nicaragua',2,null,'Perla del Mar Shade har et lyst, kremet Connecticut Shade-dekkblad — den mildeste og mest tilgjengelige utgaven i Perla del Mar-familien, med en cubansk-inspirert, smooth profil.');

-- ----------------------------------------------------------------
-- 4) El Baton — kraftig nicaraguansk puro
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('J.C. Newman','El Baton',null,'Robusto','Robusto',52,5.0,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'El Baton er J.C. Newmans kraftigste håndlagde linje — en ren nicaraguansk puro med mørkt Habano-dekkblad. Fullere kropp med dypere krydder og jordtoner enn Brick House. For røykere som vil ha mer styrke.'),
('J.C. Newman','El Baton',null,'Toro','Toro',54,6.0,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'El Baton er J.C. Newmans kraftigste håndlagde linje — en ren nicaraguansk puro med mørkt Habano-dekkblad. Fullere kropp med dypere krydder og jordtoner enn Brick House. For røykere som vil ha mer styrke.'),
('J.C. Newman','El Baton',null,'Gordo','Gordo',60,6.0,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'El Baton er J.C. Newmans kraftigste håndlagde linje — en ren nicaraguansk puro med mørkt Habano-dekkblad. Fullere kropp med dypere krydder og jordtoner enn Brick House. For røykere som vil ha mer styrke.');

-- ----------------------------------------------------------------
-- 5) Cuesta-Rey — historisk merke, Centro Fino Sungrown
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('J.C. Newman','Cuesta-Rey','Centro Fino','No. 1','Lonsdale',42,6.5,'Parejo',null,null,null,'Dominican Republic','Dominican Sungrown','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Cuesta-Rey er et av de eldste amerikanske sigarnavnene (etablert 1884, kjøpt av J.C. Newman i 1958). Centro Fino-linjen har et soldyrket dominikansk dekkblad og lages delvis hos Arturo Fuente-fabrikken i Den dominikanske republikk. Klassisk, middels styrke.'),
('J.C. Newman','Cuesta-Rey','Centro Fino','No. 95','Robusto',50,5.0,'Parejo',null,null,null,'Dominican Republic','Dominican Sungrown','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Cuesta-Rey er et av de eldste amerikanske sigarnavnene (etablert 1884, kjøpt av J.C. Newman i 1958). Centro Fino-linjen har et soldyrket dominikansk dekkblad og lages delvis hos Arturo Fuente-fabrikken i Den dominikanske republikk. Klassisk, middels styrke.'),
('J.C. Newman','Cuesta-Rey','Centro Fino','Dominicain','Churchill',48,7.0,'Parejo',null,null,null,'Dominican Republic','Dominican Sungrown','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'Cuesta-Rey er et av de eldste amerikanske sigarnavnene (etablert 1884, kjøpt av J.C. Newman i 1958). Centro Fino-linjen har et soldyrket dominikansk dekkblad og lages delvis hos Arturo Fuente-fabrikken i Den dominikanske republikk. Klassisk, middels styrke.');

-- ----------------------------------------------------------------
-- 6) The American — Florida Sun Grown dekkblad, rullet i Tampa
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('J.C. Newman','The American',null,'Robusto','Robusto',50,4.5,'Parejo',null,null,null,'United States','Florida Sun Grown','Connecticut Broadleaf',array['United States'],'United States',3,null,'The American var verdens første sigar med Florida Sun Grown-dekkblad — dyrket i Florida, kombinert med Connecticut Broadleaf-bind og innmat av Connecticut Havana og Amish-dyrket Pennsylvania-tobakk. Hver del av sigaren, fra blad til bånd, er amerikanskprodusert. Håndrullet på El Reloj-fabrikken i Tampas Ybor City.'),
('J.C. Newman','The American',null,'Double Robusto','Robusto',56,5.5,'Parejo',null,null,null,'United States','Florida Sun Grown','Connecticut Broadleaf',array['United States'],'United States',3,null,'The American var verdens første sigar med Florida Sun Grown-dekkblad — dyrket i Florida, kombinert med Connecticut Broadleaf-bind og innmat av Connecticut Havana og Amish-dyrket Pennsylvania-tobakk. Hver del av sigaren, fra blad til bånd, er amerikanskprodusert. Håndrullet på El Reloj-fabrikken i Tampas Ybor City.'),
('J.C. Newman','The American',null,'Torpedo','Torpedo',52,6.125,'Figurado','Torpedo','Pointed','Closed','United States','Florida Sun Grown','Connecticut Broadleaf',array['United States'],'United States',3,null,'The American var verdens første sigar med Florida Sun Grown-dekkblad — dyrket i Florida, kombinert med Connecticut Broadleaf-bind og innmat av Connecticut Havana og Amish-dyrket Pennsylvania-tobakk. Hver del av sigaren, fra blad til bånd, er amerikanskprodusert. Håndrullet på El Reloj-fabrikken i Tampas Ybor City.'),
('J.C. Newman','The American',null,'Toro','Toro',54,6.0,'Parejo',null,null,null,'United States','Florida Sun Grown','Connecticut Broadleaf',array['United States'],'United States',3,null,'The American var verdens første sigar med Florida Sun Grown-dekkblad — dyrket i Florida, kombinert med Connecticut Broadleaf-bind og innmat av Connecticut Havana og Amish-dyrket Pennsylvania-tobakk. Hver del av sigaren, fra blad til bånd, er amerikanskprodusert. Håndrullet på El Reloj-fabrikken i Tampas Ybor City.'),
('J.C. Newman','The American',null,'Churchill','Churchill',47,7.0,'Parejo',null,null,null,'United States','Florida Sun Grown','Connecticut Broadleaf',array['United States'],'United States',3,null,'The American var verdens første sigar med Florida Sun Grown-dekkblad — dyrket i Florida, kombinert med Connecticut Broadleaf-bind og innmat av Connecticut Havana og Amish-dyrket Pennsylvania-tobakk. Hver del av sigaren, fra blad til bånd, er amerikanskprodusert. Håndrullet på El Reloj-fabrikken i Tampas Ybor City.');

-- ----------------------------------------------------------------
-- 7) Yagua — rustikk, palmebark-lagret limited release
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('J.C. Newman','Yagua',null,'Yagua','Robusto',50,5.0,'Parejo',null,null,null,'Nicaragua','Nicaraguan','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Yagua hedrer en gammel cubansk tradisjon: sigarene bunches og bindes inn i fuktig palmebark (yagua) under lagring, som gjør at hver sigar tørker til en unik, ujevn form — ingen er like. Rustikk, jordnær og fullkroppet smaksprofil. Begrenset produksjon, mer et samleobjekt enn en standardsigar.');

-- ----------------------------------------------------------------
-- 8) ALIAS — vanlige skrivemåter/forkortelser for OCR/søk-treff
-- ----------------------------------------------------------------
insert into cigar_aliases (alias, manufacturer, brand, series) values
('JC Newman', 'J.C. Newman', 'Brick House', null),
('J C Newman', 'J.C. Newman', 'Brick House', null),
('Newman', 'J.C. Newman', 'Brick House', null),
('Perla Del Mar', 'J.C. Newman', 'Perla del Mar', null),
('El Baton', 'J.C. Newman', 'El Baton', null),
('Cuesta Rey', 'J.C. Newman', 'Cuesta-Rey', null),
('CuestaRey', 'J.C. Newman', 'Cuesta-Rey', null),
('Diamond Crown', 'J.C. Newman', 'Diamond Crown', null);

-- ----------------------------------------------------------------
-- 9) Sanity check — skal være nøyaktig 39 J.C. Newman-rader
--    (4 re-koblet: 3 Brick House + 1 Diamond Crown, pluss 35 nye)
-- ----------------------------------------------------------------
do $$
declare
  cnt int;
begin
  select count(*) into cnt from cigars where manufacturer = 'J.C. Newman';
  if cnt <> 39 then
    raise exception 'Forventet 39 J.C. Newman-rader, fant %', cnt;
  end if;
end $$;
