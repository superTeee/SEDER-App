-- Migration 053: J.C. Newman Cigar Co. — full ekspansjon
-- Dekker: MAXIMUS, Julius Caeser, Black Diamond, La Unica (Dominican Republic)
--         Diamond Crown Maduro (tillegg til eksisterende Classic)
--         Alcazar, Don Jose, Havana Q, Jose Gaspar, Sarzedas (Nicaragua)
--         Brick House Maduro + Double Connecticut (tillegg til eksisterende Classic)
--         El Reloj Cigars, Factory Throwouts (United States)
-- Totalt: ~64 nye vitolas

INSERT INTO cigars (
  manufacturer, brand, series, vitola, common_format,
  ring_gauge, length_inches, shape,
  body_type, head_type, foot_type,
  wrapper_country, wrapper_leaf, binder, filler,
  country_origin, strength, price_range,
  description, flavor_notes, avg_rating
)
VALUES

-- ============================================================
-- DIAMOND CROWN MAXIMUS (Dominican Republic)
-- Samarbeid: Fuente, Newman og Oliva-familiene — 2002
-- Wrapper: Ecuadoriansk El Bajo Sungrown (sjelden dalbund i Ecuador)
-- ============================================================
(
  'J.C. Newman Cigar Co.','Diamond Crown MAXIMUS',NULL,'Toro','Toro',
  50,6.0,'Parejo',
  null,null,null,
  'Ecuador','El Bajo Sungrown','Dominican',ARRAY['Dominican'],
  'Dominican Republic',4,'$18-25',
  'Diamond Crown MAXIMUS Toro — 6"×50. Skapt av et historisk samarbeid mellom Carlos Fuente Jr., Stanford J. Newman og John Oliva Sr. til J.C. Newmans 105-årsdag i 2002. Ecuadoriansk El Bajo Sungrown wrapper fra en sjelden dal med vulkansk jord. 5 år lagret Dominican filler. Kraftfull og kompleks, topp 25 Cigar Aficionado 2009.',
  ARRAY['dark chocolate','espresso','earth','leather','black pepper','cedar'],8.6
),

-- ============================================================
-- JULIUS CAESER (Dominican Republic)
-- Wrapper: Ecuadorian Havana, Binder: Dominican, Filler: Caribbean + Central American
-- Factory: Tabacalera A. Fuente — 5 år lagret
-- ============================================================
(
  'J.C. Newman Cigar Co.','Julius Caeser',NULL,'Churchill','Churchill',
  52,7.25,'Parejo',
  null,null,null,
  'Ecuador','Ecuadorian Havana','Dominican',ARRAY['Caribbean','Central American'],
  'Dominican Republic',4,'$15-22',
  'Julius Caeser Churchill — 7¼"×52. Ecuadoriansk Havana-seed wrapper, 5 år lagret Dominican binder og Caribbean/Central American filler, rullet i små partier av Tabacalera A. Fuente. Oppkalt etter gründerens fullstendige navn — Julius Caeser Newman — der "Caeser" var en skrivefeil av innvandringsoffiseren i 1888.',
  ARRAY['cedar','dark chocolate','espresso','leather','earth','spice'],8.5
),
(
  'J.C. Newman Cigar Co.','Julius Caeser',NULL,'Pyramid','Pyramid',
  52,6.5,'Figurado',
  null,null,null,
  'Ecuador','Ecuadorian Havana','Dominican',ARRAY['Caribbean','Central American'],
  'Dominican Republic',4,'$15-22',
  'Julius Caeser Pyramid — 6½"×52 figurado med smal hette. Ecuadoriansk Havana wrapper, 5 år lagret. Pyramideformen konsentrerer smaken i åpningen og åpner jevnt.',
  ARRAY['cedar','dark chocolate','espresso','leather','earth','spice'],8.5
),
(
  'J.C. Newman Cigar Co.','Julius Caeser',NULL,'Hail Caeser','Gordo',
  60,6.0,'Parejo',
  null,null,null,
  'Ecuador','Ecuadorian Havana','Dominican',ARRAY['Caribbean','Central American'],
  'Dominican Republic',4,'$15-22',
  'Julius Caeser Hail Caeser — 6"×60 Gordo, den bredeste i linjen. Ecuadoriansk Havana wrapper, stor ringmål gir ekstra røykevolum og dypere smak.',
  ARRAY['cedar','dark chocolate','espresso','leather','earth','cocoa'],8.5
),
(
  'J.C. Newman Cigar Co.','Julius Caeser',NULL,'Toro','Toro',
  52,6.0,'Parejo',
  null,null,null,
  'Ecuador','Ecuadorian Havana','Dominican',ARRAY['Caribbean','Central American'],
  'Dominican Republic',4,'$13-20',
  'Julius Caeser Toro — 6"×52 klassisk Toro. Ecuadoriansk Havana-seed wrapper, 5-årig lagret filler fra Karibia og Sentral-Amerika. Cigar & Spirits kåret Julius Caeser til Årets Sigar 2017.',
  ARRAY['cedar','dark chocolate','espresso','leather','earth','spice'],8.5
),
(
  'J.C. Newman Cigar Co.','Julius Caeser',NULL,'Corona','Lonsdale',
  43,5.5,'Parejo',
  null,null,null,
  'Ecuador','Ecuadorian Havana','Dominican',ARRAY['Caribbean','Central American'],
  'Dominican Republic',3,'$12-18',
  'Julius Caeser Corona — 5½"×43, smal og elegant. Ecuadoriansk Havana wrapper, Tabacalera A. Fuente. Kåret til topp 25-sigar av Cigar Aficionado i 2011 og 2014.',
  ARRAY['cedar','cream','coffee','leather','mild spice'],8.4
),
(
  'J.C. Newman Cigar Co.','Julius Caeser',NULL,'Robusto','Robusto',
  52,4.7,'Parejo',
  null,null,null,
  'Ecuador','Ecuadorian Havana','Dominican',ARRAY['Caribbean','Central American'],
  'Dominican Republic',4,'$12-18',
  'Julius Caeser Robusto — 4 7/10"×52, kompakt og kraftfull. Ecuadoriansk Havana-seed wrapper, Tabacalera A. Fuente.',
  ARRAY['cedar','espresso','earth','leather','black pepper'],8.5
),
(
  'J.C. Newman Cigar Co.','Julius Caeser',NULL,'1895','Robusto',
  52,5.0,'Parejo',
  null,null,null,
  'Ecuador','Ecuadorian Havana','Dominican',ARRAY['Caribbean','Central American'],
  'Dominican Republic',4,'$14-20',
  'Julius Caeser 1895 — 5"×52, eksklusivt tilgjengelig på Diamond Crown Lounges. Oppkalt etter J.C. Newman Cigar Co.s grunnleggelsesår. Ecuadoriansk Havana wrapper, 5-årig lagret blend fra Tabacalera A. Fuente.',
  ARRAY['cedar','espresso','dark chocolate','leather','earth'],8.6
),
(
  'J.C. Newman Cigar Co.','Julius Caeser',NULL,'Troublemaker','Robusto Grande',
  52,5.75,'Parejo',
  null,null,null,
  'Ecuador','Ecuadorian Havana','Dominican',ARRAY['Caribbean','Central American'],
  'Dominican Republic',4,'$13-19',
  'Julius Caeser Troublemaker — 5¾"×52, ny vitola. Ecuadoriansk Havana wrapper, Tabacalera A. Fuente. Mellomformat mellom Corona og Toro med rik, full smaksprofil.',
  ARRAY['cedar','dark chocolate','espresso','leather','earth'],8.5
),

-- ============================================================
-- BLACK DIAMOND (Dominican Republic)
-- Wrapper: Connecticut Havana Seed sun-grown (eksklusive åkre)
-- Binder + Filler: Dominican (5 år lagret) — small batch
-- ============================================================
(
  'J.C. Newman Cigar Co.','Black Diamond',NULL,'Emerald','Toro',
  52,6.0,'Parejo',
  null,null,null,
  'Dominican Republic','Connecticut Havana Seed','Dominican',ARRAY['Dominican'],
  'Dominican Republic',4,'$22-30',
  'Black Diamond Emerald — 6"×52 Toro. Connecticut Havana Seed sun-grown wrapper med 5-årig lagret Dominican filler fra Fuente-familiens eksklusive åkre. Small batch, ekstremt streng kvalitetskontroll. Cigar and Spirits: 95, Cigar Snob: 92.',
  ARRAY['dark chocolate','espresso','cedar','cream','leather','earth'],8.7
),
(
  'J.C. Newman Cigar Co.','Black Diamond',NULL,'Marquise','Robusto Extra',
  56,5.25,'Parejo',
  null,null,null,
  'Dominican Republic','Connecticut Havana Seed','Dominican',ARRAY['Dominican'],
  'Dominican Republic',4,'$22-30',
  'Black Diamond Marquise — 5¼"×56, bredeste format. Connecticut Havana Seed wrapper, 5 år lagret eksklusive Dominican filler. En luksussigar i svært begrenset produksjon.',
  ARRAY['dark chocolate','espresso','cedar','cream','leather','cocoa'],8.7
),
(
  'J.C. Newman Cigar Co.','Black Diamond',NULL,'Radiant','Petit Robusto',
  54,4.5,'Parejo',
  null,null,null,
  'Dominican Republic','Connecticut Havana Seed','Dominican',ARRAY['Dominican'],
  'Dominican Republic',4,'$18-26',
  'Black Diamond Radiant — 4½"×54, korteste format. Connecticut Havana Seed wrapper, konsentrert og kraftfull smaksopplevelse på kort røyketid.',
  ARRAY['dark chocolate','espresso','cedar','cream','leather'],8.7
),

-- ============================================================
-- DIAMOND CROWN MADURO (tillegg — 4 manglende vitolas)
-- Wrapper: Connecticut Broadleaf — Binder/Filler: Dominican
-- Factory: Tabacalera A. Fuente — 5 år lagret
-- ============================================================
(
  'J.C. Newman Cigar Co.','Diamond Crown','Maduro','No. 3','Toro Grande',
  54,6.5,'Parejo',
  null,null,null,
  'United States','Connecticut Broadleaf','Dominican',ARRAY['Dominican'],
  'Dominican Republic',4,'$18-26',
  'Diamond Crown Maduro No. 3 — 6½"×54. Connecticut Broadleaf maduro wrapper over 5-årig lagret Dominican filler, rullet av Tabacalera A. Fuente. Rik sjokolade og espresso-profil over den klassiske Diamond Crown-basen.',
  ARRAY['dark chocolate','espresso','cedar','cream','leather','earth'],8.6
),
(
  'J.C. Newman Cigar Co.','Diamond Crown','Maduro','No. 6','Gordo',
  64,6.0,'Parejo',
  null,null,null,
  'United States','Connecticut Broadleaf','Dominican',ARRAY['Dominican'],
  'Dominican Republic',4,'$20-28',
  'Diamond Crown Maduro No. 6 — 6"×64 Gordo, bredeste format i Diamond Crown-linjen. Connecticut Broadleaf maduro wrapper, 5-årig Dominican filler. Stor ringmål gir ekstremt rik og kompleks røyk.',
  ARRAY['dark chocolate','espresso','cedar','cream','leather','cocoa'],8.7
),
(
  'J.C. Newman Cigar Co.','Diamond Crown','Maduro','No. 4','Robusto Grande',
  54,5.5,'Parejo',
  null,null,null,
  'United States','Connecticut Broadleaf','Dominican',ARRAY['Dominican'],
  'Dominican Republic',4,'$16-24',
  'Diamond Crown Maduro No. 4 — 5½"×54. Connecticut Broadleaf maduro wrapper, 5-årig Dominican filler fra Tabacalera A. Fuente. Balansert mellom lengde og ringmål.',
  ARRAY['dark chocolate','espresso','cedar','cream','leather'],8.6
),
(
  'J.C. Newman Cigar Co.','Diamond Crown','Maduro','No. 5','Petit Robusto',
  54,4.5,'Parejo',
  null,null,null,
  'United States','Connecticut Broadleaf','Dominican',ARRAY['Dominican'],
  'Dominican Republic',4,'$14-20',
  'Diamond Crown Maduro No. 5 — 4½"×54, korteste maduro-format. Connecticut Broadleaf wrapper, konsentrert sjokolade og espresso på kompakt røyketid.',
  ARRAY['dark chocolate','espresso','cedar','cream','leather'],8.5
),

-- ============================================================
-- LA UNICA (Dominican Republic) — Natural (Ecuador Shade wrapper)
-- Siden 1986 — #1 premium bundle-sigar i Amerika
-- Factory: Tabacalera A. Fuente — 5 år lagret
-- ============================================================
(
  'J.C. Newman Cigar Co.','La Unica','Natural','No. 100','Double Corona',
  52,8.5,'Parejo',
  null,null,null,
  'Ecuador','Ecuador Shade','Dominican',ARRAY['Dominican'],
  'Dominican Republic',2,'$5-9',
  'La Unica Natural No. 100 — 8½"×52, lengste format. Ecuador Shade wrapper, 5-årig Dominican long filler. Siden 1986 den #1-selgende premium bundle-sigaren i Amerika. Silkemyk og kremet profil med sødme og nøtter. Cigar Insider: 98.',
  ARRAY['cream','nuts','cedar','fruit','mild earth'],8.2
),
(
  'J.C. Newman Cigar Co.','La Unica','Natural','No. 200','Churchill',
  49,7.0,'Parejo',
  null,null,null,
  'Ecuador','Ecuador Shade','Dominican',ARRAY['Dominican'],
  'Dominican Republic',2,'$4-8',
  'La Unica Natural No. 200 — 7"×49 Churchill. Ecuador Shade wrapper, 5-årig lagret Dominican filler. Kremet og glatt med nøtter og mild sødme.',
  ARRAY['cream','nuts','cedar','mild spice','fruit'],8.1
),
(
  'J.C. Newman Cigar Co.','La Unica','Natural','No. 300','Lonsdale',
  44,6.7,'Parejo',
  null,null,null,
  'Ecuador','Ecuador Shade','Dominican',ARRAY['Dominican'],
  'Dominican Republic',2,'$4-7',
  'La Unica Natural No. 300 — 6 7/10"×44 Lonsdale. Ecuador Shade wrapper, smal ring gauge gir lengre og kjøligere røyk. Kremet og nøtteaktig.',
  ARRAY['cream','nuts','cedar','mild spice'],8.0
),
(
  'J.C. Newman Cigar Co.','La Unica','Natural','No. 600','Toro',
  50,6.0,'Parejo',
  null,null,null,
  'Ecuador','Ecuador Shade','Dominican',ARRAY['Dominican'],
  'Dominican Republic',2,'$4-7',
  'La Unica Natural No. 600 — 6"×50 Toro. Ecuador Shade wrapper, balansert format. Kremet og glatt Dominican long filler.',
  ARRAY['cream','nuts','cedar','fruit','mild earth'],8.1
),
(
  'J.C. Newman Cigar Co.','La Unica','Natural','No. 500','Corona',
  42,5.5,'Parejo',
  null,null,null,
  'Ecuador','Ecuador Shade','Dominican',ARRAY['Dominican'],
  'Dominican Republic',2,'$4-7',
  'La Unica Natural No. 500 — 5½"×42 Corona. Ecuador Shade wrapper, smal og elegant. Kremet Dominican long filler lagret for maks smak.',
  ARRAY['cream','nuts','cedar','mild spice'],8.0
),
(
  'J.C. Newman Cigar Co.','La Unica','Natural','No. 400','Petit Robusto',
  50,4.5,'Parejo',
  null,null,null,
  'Ecuador','Ecuador Shade','Dominican',ARRAY['Dominican'],
  'Dominican Republic',2,'$3-6',
  'La Unica Natural No. 400 — 4½"×50, korteste format. Ecuador Shade wrapper, konsentrert kremet smak på kort røyketid.',
  ARRAY['cream','nuts','cedar','mild earth'],8.0
),
-- La Unica Maduro — Connecticut Broadleaf wrapper
(
  'J.C. Newman Cigar Co.','La Unica','Maduro','No. 100','Double Corona',
  52,8.5,'Parejo',
  null,null,null,
  'United States','Connecticut Broadleaf','Dominican',ARRAY['Dominican'],
  'Dominican Republic',3,'$5-9',
  'La Unica Maduro No. 100 — 8½"×52. Connecticut Broadleaf maduro wrapper, 5-årig Dominican long filler. Rik sjokolade og espresso over kremet Dominican-base. Cigar Aficionado: 90.',
  ARRAY['dark chocolate','espresso','cream','cedar','nuts','earth'],8.2
),
(
  'J.C. Newman Cigar Co.','La Unica','Maduro','No. 200','Churchill',
  49,7.0,'Parejo',
  null,null,null,
  'United States','Connecticut Broadleaf','Dominican',ARRAY['Dominican'],
  'Dominican Republic',3,'$4-8',
  'La Unica Maduro No. 200 — 7"×49 Churchill. Connecticut Broadleaf maduro wrapper med sjokoladeprofil over kremet Dominican filler.',
  ARRAY['dark chocolate','espresso','cream','cedar','nuts'],8.2
),
(
  'J.C. Newman Cigar Co.','La Unica','Maduro','No. 300','Lonsdale',
  44,6.7,'Parejo',
  null,null,null,
  'United States','Connecticut Broadleaf','Dominican',ARRAY['Dominican'],
  'Dominican Republic',3,'$4-7',
  'La Unica Maduro No. 300 — 6 7/10"×44 Lonsdale. Connecticut Broadleaf wrapper, smal og elegant med rik maduro-profil.',
  ARRAY['dark chocolate','cream','cedar','nuts','mild spice'],8.1
),
(
  'J.C. Newman Cigar Co.','La Unica','Maduro','No. 600','Toro',
  50,6.0,'Parejo',
  null,null,null,
  'United States','Connecticut Broadleaf','Dominican',ARRAY['Dominican'],
  'Dominican Republic',3,'$4-7',
  'La Unica Maduro No. 600 — 6"×50 Toro. Connecticut Broadleaf maduro, rik og rund smaksprofil.',
  ARRAY['dark chocolate','espresso','cream','cedar','earth'],8.2
),
(
  'J.C. Newman Cigar Co.','La Unica','Maduro','No. 500','Corona',
  42,5.5,'Parejo',
  null,null,null,
  'United States','Connecticut Broadleaf','Dominican',ARRAY['Dominican'],
  'Dominican Republic',3,'$4-7',
  'La Unica Maduro No. 500 — 5½"×42 Corona. Connecticut Broadleaf wrapper, konsentrert maduro-profil.',
  ARRAY['dark chocolate','cream','cedar','nuts'],8.1
),
(
  'J.C. Newman Cigar Co.','La Unica','Maduro','No. 400','Petit Robusto',
  50,4.5,'Parejo',
  null,null,null,
  'United States','Connecticut Broadleaf','Dominican',ARRAY['Dominican'],
  'Dominican Republic',3,'$3-6',
  'La Unica Maduro No. 400 — 4½"×50. Connecticut Broadleaf maduro wrapper, korteste format med konsentrert sjokolade og kremet profil.',
  ARRAY['dark chocolate','cream','cedar','nuts','mild earth'],8.1
),

-- ============================================================
-- ALCAZAR (Nicaragua) — Maduro only
-- Wrapper: Connecticut Broadleaf, Binder/Filler: Nicaraguan
-- Factory: J.C. Newman PENSA — historisk merkevare fra 1898
-- ============================================================
(
  'J.C. Newman Cigar Co.','Alcazar','Maduro','No. 1','Double Corona',
  52,8.0,'Parejo',
  null,null,null,
  'United States','Connecticut Broadleaf','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$4-7',
  'Alcazar Maduro No. 1 — 8"×52, lengste format. Connecticut Broadleaf wrapper over nikaraguan filler, rullet ved J.C. Newman PENSA i Estelí. Historisk merkevare fra 1898, opprinnelig oppkalt etter et prisbelønnet veddeløpshest. Pakket i rimelige bunter — en ekte klassiker.',
  ARRAY['dark chocolate','earth','cedar','leather','mild pepper'],7.9
),
(
  'J.C. Newman Cigar Co.','Alcazar','Maduro','No. 2','Churchill',
  50,7.0,'Parejo',
  null,null,null,
  'United States','Connecticut Broadleaf','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$4-7',
  'Alcazar Maduro No. 2 — 7"×50 Churchill. Connecticut Broadleaf maduro wrapper, nikaraguan filler. Jevn og jordaktig profil med mørke toner.',
  ARRAY['dark chocolate','earth','cedar','leather'],7.9
),
(
  'J.C. Newman Cigar Co.','Alcazar','Maduro','No. 5','Toro Grande',
  52,6.5,'Figurado',
  null,null,null,
  'United States','Connecticut Broadleaf','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$4-7',
  'Alcazar Maduro No. 5 — 6½"×52 Torpedo. Connecticut Broadleaf wrapper, nikaraguan filler. Torpedo-formen konsentrerer smaken mot hetten.',
  ARRAY['dark chocolate','earth','cedar','leather','mild pepper'],8.0
),
(
  'J.C. Newman Cigar Co.','Alcazar','Maduro','No. 3','Toro',
  50,6.0,'Parejo',
  null,null,null,
  'United States','Connecticut Broadleaf','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$3-6',
  'Alcazar Maduro No. 3 — 6"×50 Toro. Connecticut Broadleaf maduro, nikaraguan filler fra PENSA-fabrikken.',
  ARRAY['dark chocolate','earth','cedar','leather'],7.9
),
(
  'J.C. Newman Cigar Co.','Alcazar','Maduro','No. 4','Robusto',
  52,5.0,'Parejo',
  null,null,null,
  'United States','Connecticut Broadleaf','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$3-5',
  'Alcazar Maduro No. 4 — 5"×52 Robusto. Connecticut Broadleaf maduro, konsentrert og jevn nikaraguan profil.',
  ARRAY['dark chocolate','earth','cedar','leather'],7.9
),

-- ============================================================
-- DON JOSE (Nicaragua) — Natural
-- Wrapper: Sumatra Sungrown, Binder/Filler: Nicaraguan
-- Factory: J.C. Newman PENSA — cubanske frøsorter
-- Også tilgjengelig i Maduro (separat blending ikke spesifisert)
-- ============================================================
(
  'J.C. Newman Cigar Co.','Don Jose','Natural','El Grandee','Double Corona',
  52,8.5,'Parejo',
  null,null,null,
  'Indonesia','Sumatra Sungrown','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$3-6',
  'Don Jose Natural El Grandee — 8½"×52, største format. Sumatra Sungrown wrapper, nikaraguan filler med cubanske frøsorter fra vulkansk Honduransk jord. Håndlaget ved PENSA med conquistador-teknikker. Medium til full kropp med krem og kaffetoner.',
  ARRAY['cream','coffee','cedar','earth','mild pepper'],7.8
),
(
  'J.C. Newman Cigar Co.','Don Jose','Natural','San Marco','Churchill',
  50,7.0,'Parejo',
  null,null,null,
  'Indonesia','Sumatra Sungrown','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$3-6',
  'Don Jose Natural San Marco — 7"×50 Churchill. Sumatra Sungrown wrapper, nikaraguan filler med cubanske frøsorter. Kremet og jevn kaffeprofil.',
  ARRAY['cream','coffee','cedar','earth'],7.8
),
(
  'J.C. Newman Cigar Co.','Don Jose','Natural','Torpedo','Toro Grande',
  52,6.5,'Figurado',
  null,null,null,
  'Indonesia','Sumatra Sungrown','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$3-5',
  'Don Jose Natural Torpedo — 6½"×52 Torpedo. Sumatra Sungrown wrapper, nikaraguan filler. Torpedo-form konsentrerer Sumatra-smaken mot hetten.',
  ARRAY['cream','coffee','cedar','earth','mild pepper'],7.8
),
(
  'J.C. Newman Cigar Co.','Don Jose','Natural','Granada','Corona Larga',
  43,6.0,'Parejo',
  null,null,null,
  'Indonesia','Sumatra Sungrown','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$3-5',
  'Don Jose Natural Granada — 6"×43 smal og elegant. Sumatra Sungrown wrapper, nikaraguan filler. Lengre og kjøligere røyk.',
  ARRAY['cream','coffee','cedar','mild spice'],7.7
),
(
  'J.C. Newman Cigar Co.','Don Jose','Natural','Turbo','Toro',
  50,6.0,'Parejo',
  null,null,null,
  'Indonesia','Sumatra Sungrown','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$3-5',
  'Don Jose Natural Turbo — 6"×50 Toro. Sumatra Sungrown wrapper, nikaraguan filler. Balansert medium-full profil.',
  ARRAY['cream','coffee','cedar','earth'],7.8
),
(
  'J.C. Newman Cigar Co.','Don Jose','Natural','Valrico','Petit Robusto',
  50,4.5,'Parejo',
  null,null,null,
  'Indonesia','Sumatra Sungrown','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$2-4',
  'Don Jose Natural Valrico — 4½"×50, korteste format. Oppkalt etter Valrico, FL. Sumatra Sungrown wrapper, konsentrert kremet profil.',
  ARRAY['cream','coffee','cedar','mild earth'],7.7
),

-- ============================================================
-- HAVANA Q (Nicaragua)
-- Wrapper: Ecuador Havana Seed (Guayas-regionen), Binder/Filler: Nicaraguan
-- Factory: J.C. Newman PENSA — cubansk smaksprofil
-- ============================================================
(
  'J.C. Newman Cigar Co.','Havana Q',NULL,'Double Robusto','Robusto Extra',
  56,5.0,'Parejo',
  null,null,null,
  'Ecuador','Ecuador Havana Seed','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$6-10',
  'Havana Q Double Robusto — 5"×56. Ecuadoriansk Havana-seed wrapper dyrket i Guayas-regionen ved foten av Cotuguay-fjellene — jord lik Cubas berømte Pinar del Rio. Nikaraguan binder og filler fra PENSA-fabrikken i Estelí.',
  ARRAY['cedar','cream','earth','mild coffee','tobacco'],7.9
),
(
  'J.C. Newman Cigar Co.','Havana Q',NULL,'Double Toro','Toro Gordo',
  54,6.0,'Parejo',
  null,null,null,
  'Ecuador','Ecuador Havana Seed','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$6-10',
  'Havana Q Double Toro — 6"×54. Ecuadoriansk Havana-seed wrapper fra Guayas-dalen. Kremete med kubansk smaksprofil og nikaraguan filler.',
  ARRAY['cedar','cream','earth','mild coffee','tobacco'],7.9
),
(
  'J.C. Newman Cigar Co.','Havana Q',NULL,'Double Grande','Gordo',
  60,6.0,'Parejo',
  null,null,null,
  'Ecuador','Ecuador Havana Seed','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$7-11',
  'Havana Q Double Grande — 6"×60 Gordo, største format. Ecuadoriansk Havana-seed wrapper, rik og voluminøs røyk med Havana-karakter.',
  ARRAY['cedar','cream','earth','tobacco','mild spice'],8.0
),
(
  'J.C. Newman Cigar Co.','Havana Q',NULL,'Double Churchill','Churchill',
  52,7.0,'Parejo',
  null,null,null,
  'Ecuador','Ecuador Havana Seed','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$7-11',
  'Havana Q Double Churchill — 7"×52, lengste format. Ecuadoriansk Havana-seed wrapper, lang og jevn røyk med kremet Cuba-inspirert profil.',
  ARRAY['cedar','cream','earth','tobacco','mild coffee'],8.0
),

-- ============================================================
-- JOSE GASPAR (Nicaragua) — Annual limited Tampa edition
-- Kun 10 000 stk produsert pr. år, kun tilgjengelig i Tampa i januar
-- Wrapper: Ecuador Havana Sungrown, Binder/Filler: Nicaraguan — PENSA
-- ============================================================
(
  'J.C. Newman Cigar Co.','Jose Gaspar',NULL,'Toro','Toro',
  54,6.0,'Parejo',
  null,null,null,
  'Ecuador','Ecuador Havana Sungrown','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$10-15',
  'Jose Gaspar Toro — 6"×54. Den offisielle sigaren for Gasparilla-paraden i Tampa, FL. Kun 10 000 stk produsert hvert år, eksklusivt tilgjengelig ved utvalgte Tampa-utsalg i januar. Oppkalt etter den beryktede piraten José Gaspar (1776–1821). Ecuadoriansk Havana Sungrown wrapper, nikaraguan binder og filler fra PENSA.',
  ARRAY['cedar','earth','cream','mild coffee','tobacco'],8.0
),

-- ============================================================
-- SARZEDAS (Nicaragua)
-- Gjenintrodusert 2025 — opprinnelig J.C. Newman-sigar fra 1900
-- Kjent som "The Aromatic Cigar" i tidlig 1900-tall
-- Wrapper: Ecuadorian Shade, Binder+Filler: Dominican & Nicaraguan — PENSA Estelí
-- ============================================================
(
  'J.C. Newman Cigar Co.','Sarzedas',NULL,'Churchill','Churchill',
  48,7.0,'Parejo',
  null,null,null,
  'Ecuador','Ecuadorian Shade','Dominican and Nicaraguan',ARRAY['Dominican','Nicaraguan'],
  'Nicaragua',3,'$8-13',
  'Sarzedas Churchill — 7"×48. Gjenintrodusert i 2025 etter 125 år — J.C. Newman rullet de første Sarzedas-sigarene i 1900, og de ble kjent som "The Aromatic Cigar". Ecuadoriansk Shade wrapper, Dominican og Nicaraguan binder/filler. Blandet av Rich Dolak. "Den mest smaksrike sigaren vi noensinne har laget" (Drew Newman).',
  ARRAY['cedar','cream','floral','mild coffee','sweet spice','earth'],8.1
),
(
  'J.C. Newman Cigar Co.','Sarzedas',NULL,'Toro','Toro',
  50,6.0,'Parejo',
  null,null,null,
  'Ecuador','Ecuadorian Shade','Dominican and Nicaraguan',ARRAY['Dominican','Nicaraguan'],
  'Nicaragua',3,'$7-12',
  'Sarzedas Toro — 6"×50. Ecuador Shade wrapper, Dominican og Nicaraguan binder/filler fra PENSA Estelí. Aromatisk og leken sigar med kremet kompleksitet.',
  ARRAY['cedar','cream','floral','mild coffee','sweet spice'],8.1
),
(
  'J.C. Newman Cigar Co.','Sarzedas',NULL,'Corona','Corona',
  43,5.5,'Parejo',
  null,null,null,
  'Ecuador','Ecuadorian Shade','Dominican and Nicaraguan',ARRAY['Dominican','Nicaraguan'],
  'Nicaragua',3,'$6-10',
  'Sarzedas Corona — 5.5"×43. Ecuador Shade wrapper, smal og aromatisk. Kremet og jevn profil.',
  ARRAY['cedar','cream','floral','mild coffee','sweet spice'],8.0
),
(
  'J.C. Newman Cigar Co.','Sarzedas',NULL,'Robusto','Robusto',
  52,4.75,'Parejo',
  null,null,null,
  'Ecuador','Ecuadorian Shade','Dominican and Nicaraguan',ARRAY['Dominican','Nicaraguan'],
  'Nicaragua',3,'$6-10',
  'Sarzedas Robusto — 4.75"×52. Ecuador Shade wrapper, kompakt og konsentrert. Dominican og Nicaraguan filler blandet for maksimal aroma og smak.',
  ARRAY['cedar','cream','floral','mild coffee','earth'],8.1
),

-- ============================================================
-- BRICK HOUSE MADURO — 4 vitolas (nye, mangler i DB)
-- Wrapper: Brazilian Arapiraca, Binder/Filler: Nicaraguan — Nicaragua
-- ============================================================
(
  'J.C. Newman Cigar Co.','Brick House','Maduro','Commodore','Gordo',
  70,5.5,'Parejo',
  null,null,null,
  'Brazil','Brazilian Arapiraca','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$9-14',
  'Brick House Maduro Commodore — NY 2026! 5.5"×70, den bredeste Brick House-vitola noensinne. Brasiliansk Arapiraca maduro wrapper over nikaraguan filler. Massiv ringmål gir ekstremt rik og fyldig røyk.',
  ARRAY['dark chocolate','espresso','cedar','earth','leather','caramel'],8.2
),
(
  'J.C. Newman Cigar Co.','Brick House','Maduro','Mighty Mighty','Gordo',
  60,6.25,'Parejo',
  null,null,null,
  'Brazil','Brazilian Arapiraca','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$8-12',
  'Brick House Maduro Mighty Mighty — 6¼"×60. Brasiliansk Arapiraca maduro wrapper over nikaraguan filler. Kraftfull og rik maduro-profil.',
  ARRAY['dark chocolate','espresso','cedar','earth','leather'],8.2
),
(
  'J.C. Newman Cigar Co.','Brick House','Maduro','Toro','Toro',
  52,6.0,'Parejo',
  null,null,null,
  'Brazil','Brazilian Arapiraca','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$7-11',
  'Brick House Maduro Toro — 6"×52. Brasiliansk Arapiraca maduro wrapper, nikaraguan filler. Rik sjokolade og espresso-profil i klassisk Toro-format.',
  ARRAY['dark chocolate','espresso','cedar','earth','leather'],8.2
),
(
  'J.C. Newman Cigar Co.','Brick House','Maduro','Robusto','Robusto',
  54,5.0,'Parejo',
  null,null,null,
  'Brazil','Brazilian Arapiraca','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',3,'$7-11',
  'Brick House Maduro Robusto — 5"×54. Brasiliansk Arapiraca maduro wrapper, konsentrert og rik maduro-profil over nikaraguan filler.',
  ARRAY['dark chocolate','espresso','cedar','earth','leather'],8.2
),

-- ============================================================
-- BRICK HOUSE DOUBLE CONNECTICUT — 6 vitolas (nye, mangler i DB)
-- Wrapper: Connecticut Shade, Binder: Connecticut Broadleaf, Filler: Nicaraguan
-- ============================================================
(
  'J.C. Newman Cigar Co.','Brick House','Double Connecticut','Churchill','Churchill',
  50,7.25,'Parejo',
  null,null,null,
  'United States','Connecticut Shade','Connecticut Broadleaf',ARRAY['Nicaraguan'],
  'Nicaragua',2,'$8-13',
  'Brick House Double Connecticut Churchill — 7¼"×50. Connecticut Shade wrapper + Connecticut Broadleaf binder, en unik "dobbel Connecticut"-kombinasjon over nikaraguan filler. Kremete, mild og raffinert profil.',
  ARRAY['cream','cedar','mild coffee','floral','vanilla','nuts'],8.3
),
(
  'J.C. Newman Cigar Co.','Brick House','Double Connecticut','Mighty Mighty','Gordo',
  60,6.25,'Parejo',
  null,null,null,
  'United States','Connecticut Shade','Connecticut Broadleaf',ARRAY['Nicaraguan'],
  'Nicaragua',2,'$8-13',
  'Brick House Double Connecticut Mighty Mighty — 6¼"×60 Gordo. Connecticut Shade wrapper + Broadleaf binder, kremet og mild med stor ringmål.',
  ARRAY['cream','cedar','mild coffee','floral','vanilla'],8.3
),
(
  'J.C. Newman Cigar Co.','Brick House','Double Connecticut','Corona Larga','Corona Larga',
  46,6.25,'Parejo',
  null,null,null,
  'United States','Connecticut Shade','Connecticut Broadleaf',ARRAY['Nicaraguan'],
  'Nicaragua',2,'$7-11',
  'Brick House Double Connecticut Corona Larga — 6¼"×46. Connecticut Shade + Broadleaf binder, smal og kjølig med kremete dobbel-Connecticut-profil.',
  ARRAY['cream','cedar','mild coffee','floral','vanilla'],8.2
),
(
  'J.C. Newman Cigar Co.','Brick House','Double Connecticut','Toro','Toro',
  52,6.0,'Parejo',
  null,null,null,
  'United States','Connecticut Shade','Connecticut Broadleaf',ARRAY['Nicaraguan'],
  'Nicaragua',2,'$7-11',
  'Brick House Double Connecticut Toro — 6"×52. Connecticut Shade wrapper + Broadleaf binder, nikaraguan filler. Kremet og balansert.',
  ARRAY['cream','cedar','mild coffee','floral','nuts'],8.2
),
(
  'J.C. Newman Cigar Co.','Brick House','Double Connecticut','Short Torp','Robusto Grande',
  52,5.5,'Parejo',
  null,null,null,
  'United States','Connecticut Shade','Connecticut Broadleaf',ARRAY['Nicaraguan'],
  'Nicaragua',2,'$6-10',
  'Brick House Double Connecticut Short Torp — 5½"×52. Connecticut Shade wrapper + Broadleaf binder, konsentrert kremet profil i kortere format.',
  ARRAY['cream','cedar','mild coffee','floral','vanilla'],8.2
),
(
  'J.C. Newman Cigar Co.','Brick House','Double Connecticut','Robusto','Robusto',
  54,5.0,'Parejo',
  null,null,null,
  'United States','Connecticut Shade','Connecticut Broadleaf',ARRAY['Nicaraguan'],
  'Nicaragua',2,'$6-10',
  'Brick House Double Connecticut Robusto — 5"×54. Connecticut Shade wrapper + Broadleaf binder, nikaraguan filler. Kremete og mild i kompakt robusto-format.',
  ARRAY['cream','cedar','mild coffee','floral','nuts'],8.2
),

-- ============================================================
-- EL RELOJ CIGARS (United States — Tampa, FL)
-- Laget i det siste gjenværende sigarfabrikken i Cigar City
-- Wrapper: Ecuador Havana Seed Sungrown, Filler: Dominican + Nicaraguan
-- Factory: J.C. Newman El Reloj (Tampa, bygget 1910)
-- ============================================================
(
  'J.C. Newman Cigar Co.','El Reloj Cigars',NULL,'El Ocho','Double Corona',
  53,8.0,'Parejo',
  null,null,null,
  'Ecuador','Ecuador Havana Seed Sungrown',NULL,ARRAY['Dominican','Nicaraguan'],
  'United States',2,'$4-7',
  'El Reloj El Ocho — 8"×53. Laget i det siste fungerende sigarfabrikken i Cigar City (Tampa, FL). Oppkalt etter El Reloj ("klokketårnet"), bygget i 1910 og midtpunktet i det historiske Ybor City-distriktet. Ecuador Havana Seed Sungrown wrapper, Dominican og Nicaraguan filler — Julius Caeser Newmans originale resept fra 1954.',
  ARRAY['cedar','cream','earth','mild coffee','tobacco'],7.8
),

-- ============================================================
-- FACTORY THROWOUTS (United States — Tampa, FL)
-- Laget på håndopererte maskiner fra 1930/40-tallet i El Reloj-fabrikken
-- Wrapper: Ecuador Sungrown (lett misfarget — kjøpt rimeligere), Filler: Dominican + Nicaraguan
-- ============================================================
(
  'J.C. Newman Cigar Co.','Factory Throwouts',NULL,'No. 99','Churchill',
  52,7.25,'Parejo',
  null,null,null,
  'Ecuador','Ecuador Sungrown',NULL,ARRAY['Dominican','Nicaraguan'],
  'United States',2,'$3-5',
  'Factory Throwouts No. 99 — 7¼"×52. Laget på håndopererte maskiner fra 1930/40-tallet i det historiske El Reloj-fabrikken i Tampa. Ecuadoriansk Sungrown wrapper med lett misfarging (kjøpt rimeligere — besparingen sendes til forbrukeren). Tilgjengelig i Natural og Sweet.',
  ARRAY['cedar','tobacco','mild earth','cream'],7.5
),
(
  'J.C. Newman Cigar Co.','Factory Throwouts',NULL,'No. 59','Lonsdale',
  45,6.25,'Parejo',
  null,null,null,
  'Ecuador','Ecuador Sungrown',NULL,ARRAY['Dominican','Nicaraguan'],
  'United States',2,'$2-4',
  'Factory Throwouts No. 59 — 6¼"×45. Tampa-produsert maskinsigar med Ecuador Sungrown wrapper. Tilgjengelig i Natural, Sweet eller Claro. En ekte uendret amerikansk klassiker siden 1930-tallet.',
  ARRAY['cedar','tobacco','mild earth','cream'],7.4
),
(
  'J.C. Newman Cigar Co.','Factory Throwouts',NULL,'No. 49','Robusto',
  49,5.5,'Parejo',
  null,null,null,
  'Ecuador','Ecuador Sungrown',NULL,ARRAY['Dominican','Nicaraguan'],
  'United States',2,'$2-4',
  'Factory Throwouts No. 49 — 5½"×49. Tampa-maskinsigar, Ecuador Sungrown wrapper. Tilgjengelig i Natural og Sweet.',
  ARRAY['cedar','tobacco','mild earth','cream'],7.4
)

ON CONFLICT DO NOTHING;
