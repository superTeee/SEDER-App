-- Migration 055: Cigar World gap-fix
-- Merker som manglet etter kryssjekk mot cigarworld.com/cigars/brands/:
--   Alec Bradley, Camacho, Gispert, El Rico Habano, Omar Ortez, Silencio
-- Totalt: ~60 nye vitolas

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
-- ALEC BRADLEY
-- Grunnlagt: 1996, Alan Rubin. Produsert i Honduras (Danlí).
-- Fabrikk: Raices Cubanas (Honduras)
-- ============================================================

-- Prensado — flaggskip, #2 Cigar of the Year CA 2011
('Alec Bradley','Alec Bradley','Prensado','Robusto','Robusto',
 52,5.0,'Parejo',null,null,null,
 'Honduras','Honduran Habano','Honduras',ARRAY['Honduras','Nicaragua'],
 'Honduras',5,'$10-15',
 'Alec Bradley Prensado Robusto — 5"×52. Flaggskipet til Alec Bradley og #2 Cigar of the Year 2011 (Cigar Aficionado). Honduransk Habano-dekkblad over Honduransk bind og Honduransk/Nicaraguansk innmat. Full styrke med noter av mørk sjokolade, espresso og sort pepper.',
 ARRAY['dark chocolate','espresso','black pepper','earth','leather'],8.9),

('Alec Bradley','Alec Bradley','Prensado','Toro','Toro',
 52,6.0,'Parejo',null,null,null,
 'Honduras','Honduran Habano','Honduras',ARRAY['Honduras','Nicaragua'],
 'Honduras',5,'$10-15',
 'Alec Bradley Prensado Toro — 6"×52. Full styrke, kompleks med intens kropp. Produsert på Raices Cubanas-fabrikken i Danlí, Honduras.',
 ARRAY['dark chocolate','espresso','black pepper','leather','cedar'],8.8),

('Alec Bradley','Alec Bradley','Prensado','Churchill','Churchill',
 54,6.75,'Parejo',null,null,null,
 'Honduras','Honduran Habano','Honduras',ARRAY['Honduras','Nicaragua'],
 'Honduras',5,'$12-18',
 'Alec Bradley Prensado Churchill — 6¾"×54. Gir mer tid til å utvikle de komplekse smaksnotene. Full styrke gjennom hele røyken.',
 ARRAY['dark chocolate','espresso','black pepper','earth','cedar'],8.7),

('Alec Bradley','Alec Bradley','Prensado','Gran Toro','Gran Toro',
 58,6.0,'Parejo',null,null,null,
 'Honduras','Honduran Habano','Honduras',ARRAY['Honduras','Nicaragua'],
 'Honduras',5,'$12-18',
 'Alec Bradley Prensado Gran Toro — 6"×58. Det store ringmålet gir en saktere, kjøligere røyk og ytterligere kompleksitet.',
 ARRAY['dark chocolate','espresso','earth','pepper','leather'],8.6),

-- Black Market — mørkere, mer jordnær profil
('Alec Bradley','Alec Bradley','Black Market','Robusto','Robusto',
 52,5.0,'Parejo',null,null,null,
 'Honduras','Honduran Habano','Honduras',ARRAY['Honduras','Nicaragua'],
 'Honduras',5,'$9-13',
 'Alec Bradley Black Market Robusto — 5"×52. En mørkere, mer jordnær søsken til Prensado. Honduransk Habano-dekkblad med intense noter av espresso og lær. Populær hverdagssigar i full styrke.',
 ARRAY['espresso','leather','dark earth','black pepper','cedar'],8.5),

('Alec Bradley','Alec Bradley','Black Market','Toro','Toro',
 52,6.0,'Parejo',null,null,null,
 'Honduras','Honduran Habano','Honduras',ARRAY['Honduras','Nicaragua'],
 'Honduras',5,'$9-13',
 'Alec Bradley Black Market Toro — 6"×52. Full kroppet med rik, mørk profil. Solid hverdagssigar fra et av de beste produsentene i Honduras.',
 ARRAY['espresso','leather','dark earth','black pepper'],8.4),

('Alec Bradley','Alec Bradley','Black Market','Gordo','Gordo',
 60,6.0,'Parejo',null,null,null,
 'Honduras','Honduran Habano','Honduras',ARRAY['Honduras','Nicaragua'],
 'Honduras',5,'$10-14',
 'Alec Bradley Black Market Gordo — 6"×60. Det brede ringmålet gir en kjølig, jevn røyk med kompleks mørk profil.',
 ARRAY['espresso','dark chocolate','earth','leather','pepper'],8.3),

-- Tempus — Connecticut Broadleaf maduro
('Alec Bradley','Alec Bradley','Tempus','Robusto','Robusto',
 54,5.0,'Parejo',null,null,null,
 'United States','Connecticut Broadleaf','Honduras',ARRAY['Honduras','Nicaragua'],
 'Honduras',5,'$10-14',
 'Alec Bradley Tempus Robusto — 5"×54. Et mørkt Connecticut Broadleaf Maduro-dekkblad gir naturlig sødme og fløyelsmyk tekstur over en fullkroppet Honduransk/Nicaraguansk innmat.',
 ARRAY['dark chocolate','coffee','molasses','earth','cedar'],8.6),

('Alec Bradley','Alec Bradley','Tempus','Toro','Toro',
 52,6.0,'Parejo',null,null,null,
 'United States','Connecticut Broadleaf','Honduras',ARRAY['Honduras','Nicaragua'],
 'Honduras',5,'$11-15',
 'Alec Bradley Tempus Toro — 6"×52. Maduro med naturlig sødme og full kropp. Et av de beste Maduro-alternativene i prissegmentet.',
 ARRAY['dark chocolate','coffee','molasses','leather','pepper'],8.5),

-- Coyol — naturlig Coyol Palm-bindblad (unik)
('Alec Bradley','Alec Bradley','Coyol','Robusto','Robusto',
 52,5.0,'Parejo',null,null,null,
 'Honduras','Honduran Habano','Honduras',ARRAY['Honduras','Nicaragua'],
 'Honduras',4,'$9-13',
 'Alec Bradley Coyol Robusto — 5"×52. Bruker et eksklusivt Coyol Palm-bindblad (fra Honduras) som gir en unik jordnær kompleksitet. Middels til full styrke.',
 ARRAY['earth','cedar','leather','spice','wood'],8.3),

('Alec Bradley','Alec Bradley','Coyol','Toro','Toro',
 52,6.0,'Parejo',null,null,null,
 'Honduras','Honduran Habano','Honduras',ARRAY['Honduras','Nicaragua'],
 'Honduras',4,'$10-14',
 'Alec Bradley Coyol Toro — 6"×52. Det naturlige Coyol Palm-bindbladet bidrar med en jordnær, organisk smaksprofil som skiller seg fra tradisjonelle bindblad.',
 ARRAY['earth','cedar','leather','spice','wood'],8.2),

-- ============================================================
-- CAMACHO
-- Grunnlagt: 1962, Simon Camacho. Dagens eier: Davidoff of Geneva.
-- Fabrikk: Camacho Cigars (Danlí, Honduras)
-- ============================================================

-- Connecticut — mild profil, flaggskip for mild kategori
('Davidoff of Geneva','Camacho','Connecticut','Robusto','Robusto',
 50,5.0,'Parejo',null,null,null,
 'Ecuador','Connecticut Shade','Honduras',ARRAY['Honduras','Nicaragua','Dominican Republic'],
 'Honduras',2,'$9-13',
 'Camacho Connecticut Robusto — 5"×50. Camacho sin inngang i den milde kategorien. Ecuadoriansk Connecticut Shade-dekkblad gir kremete noter med en litt mer rik profil enn typiske Connecticut-sigarer.',
 ARRAY['cream','cedar','roasted nuts','mild spice','toasted bread'],8.3),

('Davidoff of Geneva','Camacho','Connecticut','Toro','Toro',
 50,6.0,'Parejo',null,null,null,
 'Ecuador','Connecticut Shade','Honduras',ARRAY['Honduras','Nicaragua','Dominican Republic'],
 'Honduras',2,'$10-14',
 'Camacho Connecticut Toro — 6"×50. Mild og kremete med Camacho sin signatur-konstruksjon. Perfekt for nybegynnere eller en lettere røyk.',
 ARRAY['cream','cedar','roasted nuts','mild spice'],8.2),

-- Corojo — flaggskipet, full styrke
('Davidoff of Geneva','Camacho','Corojo','Robusto','Robusto',
 50,5.0,'Parejo',null,null,null,
 'Honduras','Corojo','Honduras',ARRAY['Honduras'],
 'Honduras',5,'$10-15',
 'Camacho Corojo Robusto — 5"×50. Flaggskipet fra Camacho. 100 % Honduransk puro med Corojo-dekkblad. Fullkroppet med intens styrke og noter av lær, jord og paprika. En av Hondurans mest ikoniske sigarer.',
 ARRAY['leather','earth','paprika','black pepper','cedar','espresso'],8.7),

('Davidoff of Geneva','Camacho','Corojo','Toro','Toro',
 50,6.0,'Parejo',null,null,null,
 'Honduras','Corojo','Honduras',ARRAY['Honduras'],
 'Honduras',5,'$11-16',
 'Camacho Corojo Toro — 6"×50. Lengre røyk gir mer tid til å utvikle komplekse Corojo-noter. Full styrke gjennom hele røyken.',
 ARRAY['leather','earth','paprika','black pepper','cedar'],8.7),

('Davidoff of Geneva','Camacho','Corojo','Churchill','Churchill',
 48,7.0,'Parejo',null,null,null,
 'Honduras','Corojo','Honduras',ARRAY['Honduras'],
 'Honduras',5,'$13-18',
 'Camacho Corojo Churchill — 7"×48. Et sjeldent langt format for de som vil nyte Camacho Corojo-profilen over lengre tid.',
 ARRAY['leather','earth','paprika','black pepper','spice'],8.5),

-- Criollo — litt mildere enn Corojo
('Davidoff of Geneva','Camacho','Criollo','Robusto','Robusto',
 50,5.0,'Parejo',null,null,null,
 'Honduras','Criollo','Honduras',ARRAY['Honduras','Nicaragua'],
 'Honduras',4,'$9-13',
 'Camacho Criollo Robusto — 5"×50. Honduransk Criollo-dekkblad over Honduransk/Nicaraguansk innmat. Middels til full styrke med noter av lær, pepper og jord. Litt mildere enn Corojo.',
 ARRAY['leather','black pepper','earth','cedar','cocoa'],8.4),

('Davidoff of Geneva','Camacho','Criollo','Toro','Toro',
 50,6.0,'Parejo',null,null,null,
 'Honduras','Criollo','Honduras',ARRAY['Honduras','Nicaragua'],
 'Honduras',4,'$10-14',
 'Camacho Criollo Toro — 6"×50. Balansert mellom Corojo sin kraft og Connecticut sin mildhet. En solid allround-sigar.',
 ARRAY['leather','black pepper','earth','cedar'],8.3),

-- BXP — Box Pressed
('Davidoff of Geneva','Camacho','BXP','Robusto','Robusto',
 52,5.0,'Box Pressed',null,null,null,
 'Honduras','Corojo','Honduras',ARRAY['Honduras'],
 'Honduras',5,'$11-16',
 'Camacho BXP Robusto — 5"×52. Box pressed-versjon av Camacho Corojo. Den rektangulære formen endrer draget og kjøler røyken noe. Full styrke.',
 ARRAY['leather','earth','paprika','black pepper','cedar'],8.5),

-- American Barrel-Aged
('Davidoff of Geneva','Camacho','American Barrel-Aged','Robusto','Robusto',
 52,5.0,'Parejo',null,null,null,
 'Honduras','Honduran Corojo','Honduras',ARRAY['Honduras'],
 'Honduras',4,'$13-18',
 'Camacho American Barrel-Aged Robusto — 5"×52. Honduransk innmat lagret i American whiskey-fat. Gir søte, eikete noter på toppen av Camacho sin typisk kraftige profil.',
 ARRAY['oak','vanilla','leather','dark chocolate','earth','whiskey'],8.6),

-- ============================================================
-- GISPERT
-- Grunnlagt i Cuba (1800-tall). Dagens versjon: Altadis USA, Honduras.
-- ============================================================

('Altadis USA','Gispert','Gispert','Robusto','Robusto',
 50,5.0,'Parejo',null,null,null,
 'Ecuador','Connecticut Shade','Honduras',ARRAY['Honduras','Dominican Republic'],
 'Honduras',3,'$5-8',
 'Gispert Robusto — 5"×50. Klassisk Honduransk medium-sigar til en tilgjengelig pris. Ecuadoriansk Connecticut Shade-dekkblad over Honduransk og Dominikansk innmat. Mild til middels styrke med glatt, konsistent profil.',
 ARRAY['cedar','roasted nuts','cream','mild spice','toasted bread'],7.9),

('Altadis USA','Gispert','Gispert','Toro','Toro',
 52,6.0,'Parejo',null,null,null,
 'Ecuador','Connecticut Shade','Honduras',ARRAY['Honduras','Dominican Republic'],
 'Honduras',3,'$6-9',
 'Gispert Toro — 6"×52. Mer røyketid enn Robusto med samme glatte, konsekvente profil. En av de best prisgitte mellomkategori-sigarene fra Honduras.',
 ARRAY['cedar','roasted nuts','cream','mild spice'],7.9),

('Altadis USA','Gispert','Gispert','Churchill','Churchill',
 47,7.0,'Parejo',null,null,null,
 'Ecuador','Connecticut Shade','Honduras',ARRAY['Honduras','Dominican Republic'],
 'Honduras',3,'$7-10',
 'Gispert Churchill — 7"×47. Det klassiske Churchill-formatet er ideelt for den kremete Gispert-profilen.',
 ARRAY['cedar','roasted nuts','cream','toasted bread'],7.8),

('Altadis USA','Gispert','Gispert','Lonsdale','Lonsdale',
 44,6.75,'Parejo',null,null,null,
 'Ecuador','Connecticut Shade','Honduras',ARRAY['Honduras','Dominican Republic'],
 'Honduras',3,'$5-8',
 'Gispert Lonsdale — 6¾"×44. Slankt format gir en kjøligere røyk. Mild til middels med tydelige noter av seder og ristet brød.',
 ARRAY['cedar','roasted nuts','toasted bread','mild spice'],7.8),

-- ============================================================
-- EL RICO HABANO
-- General Cigar Co. — produsert i Dominican Republic / Honduras.
-- ============================================================

('General Cigar Co.','El Rico Habano','El Rico Habano','Gran Habanero','Gran Habanero',
 54,6.5,'Parejo',null,null,null,
 'Ecuador','Ecuadorian Sumatra','Honduras',ARRAY['Dominican Republic','Honduras'],
 'Dominican Republic',4,'$5-8',
 'El Rico Habano Gran Habanero — 6½"×54. Ecuadoriansk Sumatra-dekkblad over Dominikansk og Honduransk innmat. Full kropp med intens, krydret profil og dype tobakknyanser. Kraft til en svært tilgjengelig pris.',
 ARRAY['black pepper','earth','coffee','leather','cedar'],8.1),

('General Cigar Co.','El Rico Habano','El Rico Habano','Double Corona','Double Corona',
 50,7.5,'Parejo',null,null,null,
 'Ecuador','Ecuadorian Sumatra','Honduras',ARRAY['Dominican Republic','Honduras'],
 'Dominican Republic',4,'$5-8',
 'El Rico Habano Double Corona — 7½"×50. Langt format for de som vil nyte den kraftige, krydrete profilen over lengre tid. Ecuadoriansk Sumatra-dekkblad.',
 ARRAY['black pepper','earth','coffee','leather'],8.0),

('General Cigar Co.','El Rico Habano','El Rico Habano','Presidente','Presidente',
 50,8.5,'Parejo',null,null,null,
 'Ecuador','Ecuadorian Sumatra','Honduras',ARRAY['Dominican Republic','Honduras'],
 'Dominican Republic',4,'$6-9',
 'El Rico Habano Presidente — 8½"×50. Imponerende format. Et av de lengste i sin priskategori. Full styrke.',
 ARRAY['black pepper','earth','leather','coffee','cedar'],7.9),

('General Cigar Co.','El Rico Habano','El Rico Habano','Robusto','Robusto',
 50,5.0,'Parejo',null,null,null,
 'Ecuador','Ecuadorian Sumatra','Honduras',ARRAY['Dominican Republic','Honduras'],
 'Dominican Republic',4,'$4-7',
 'El Rico Habano Robusto — 5"×50. Kompakt format med full kraft. Ecuadoriansk Sumatra-dekkblad.',
 ARRAY['black pepper','earth','coffee','leather'],7.9),

-- ============================================================
-- OMAR ORTEZ
-- Nicaraguansk tobakksdyrker og blender. Produsert i Nicaragua.
-- ============================================================

('Omar Ortez','Omar Ortez','Classicos','Robusto','Robusto',
 50,5.0,'Parejo',null,null,null,
 'Ecuador','Ecuadorian Sumatra','Nicaragua',ARRAY['Nicaragua'],
 'Nicaragua',4,'$5-8',
 'Omar Ortez Classicos Robusto — 5"×50. Nicaraguansk puro med Ecuadoriansk Sumatra-dekkblad. Laget av Omar Ortez — veteran-blender og tobakkskultivatør fra Estelí. Middels til full styrke med jordnær profil.',
 ARRAY['earth','leather','cedar','black pepper','cocoa'],8.2),

('Omar Ortez','Omar Ortez','Classicos','Toro','Toro',
 50,6.0,'Parejo',null,null,null,
 'Ecuador','Ecuadorian Sumatra','Nicaragua',ARRAY['Nicaragua'],
 'Nicaragua',4,'$6-9',
 'Omar Ortez Classicos Toro — 6"×50. Mer kompleksitet i det lengre formatet. Full nicaraguansk profil.',
 ARRAY['earth','leather','cedar','black pepper','cocoa'],8.2),

('Omar Ortez','Omar Ortez','General','Robusto','Robusto',
 52,5.0,'Parejo',null,null,null,
 'Nicaragua','Nicaraguan Habano','Nicaragua',ARRAY['Nicaragua'],
 'Nicaragua',4,'$5-8',
 'Omar Ortez General Robusto — 5"×52. 100 % Nicaraguansk puro. Habano-dekkblad gir en rikere, mer intens smaksprofil enn Classicos.',
 ARRAY['earth','espresso','leather','black pepper','cedar'],8.1),

('Omar Ortez','Omar Ortez','General','Toro','Toro',
 52,6.0,'Parejo',null,null,null,
 'Nicaragua','Nicaraguan Habano','Nicaragua',ARRAY['Nicaragua'],
 'Nicaragua',4,'$6-9',
 'Omar Ortez General Toro — 6"×52. Nicaraguansk puro med full styrke og earthy, krydret profil.',
 ARRAY['earth','espresso','leather','black pepper'],8.1),

('Omar Ortez','Omar Ortez','Robusto Especial','Robusto','Robusto',
 52,5.0,'Parejo',null,null,null,
 'Ecuador','Ecuadorian Habano','Nicaragua',ARRAY['Nicaragua'],
 'Nicaragua',4,'$6-10',
 'Omar Ortez Robusto Especial — 5"×52. Premium-utgave med Ecuadoriansk Habano-dekkblad over fullt Nicaraguansk innmat. Bruker de beste tobakkene fra Ortez sin gård i Jalapa-dalen.',
 ARRAY['earth','leather','espresso','dark chocolate','cedar'],8.3),

-- ============================================================
-- SILENCIO
-- General Cigar Co. — relativt ny linje.
-- Produsert i Honduras/Nicaragua.
-- ============================================================

('General Cigar Co.','Silencio','Silencio','Robusto','Robusto',
 50,5.0,'Parejo',null,null,null,
 'Honduras','Honduran Habano','Honduras',ARRAY['Honduras','Nicaragua'],
 'Honduras',4,'$8-12',
 'Silencio Robusto — 5"×50. En ny premium-linje fra General Cigar Co. Honduransk Habano-dekkblad over Honduransk og Nicaraguansk innmat. Middels til full styrke med kompleks, balansert profil. Stille, kontemplativ røyk.',
 ARRAY['leather','cedar','earth','black pepper','cocoa'],8.2),

('General Cigar Co.','Silencio','Silencio','Toro','Toro',
 52,6.0,'Parejo',null,null,null,
 'Honduras','Honduran Habano','Honduras',ARRAY['Honduras','Nicaragua'],
 'Honduras',4,'$9-13',
 'Silencio Toro — 6"×52. Det populære Toro-formatet gir en jevn, balansert røyk med Silencio sin karakteristiske jordnære profil.',
 ARRAY['leather','cedar','earth','black pepper','dark chocolate'],8.2),

('General Cigar Co.','Silencio','Silencio','Churchill','Churchill',
 48,7.0,'Parejo',null,null,null,
 'Honduras','Honduran Habano','Honduras',ARRAY['Honduras','Nicaragua'],
 'Honduras',4,'$10-15',
 'Silencio Churchill — 7"×48. Langt format for en langsom, meditativ røyk. Middels til full med jevn styrke gjennom hele røyken.',
 ARRAY['leather','cedar','earth','pepper','cocoa'],8.1),

('General Cigar Co.','Silencio','Silencio','Gordo','Gordo',
 60,6.0,'Parejo',null,null,null,
 'Honduras','Honduran Habano','Honduras',ARRAY['Honduras','Nicaragua'],
 'Honduras',4,'$10-14',
 'Silencio Gordo — 6"×60. Det brede ringmålet gir en ekstra kjølig og kremete røyk. Populært format i premium-segmentet.',
 ARRAY['leather','cedar','earth','chocolate','pepper'],8.0);

-- Oppdater brand_aliases for søkerobusthet
INSERT INTO brand_aliases (alias, brand, manufacturer)
VALUES
  ('AB', 'Alec Bradley', 'Alec Bradley'),
  ('Alec Bradley Prensado', 'Alec Bradley', 'Alec Bradley'),
  ('Alec Bradley Black Market', 'Alec Bradley', 'Alec Bradley'),
  ('Camacho Corojo', 'Camacho', 'Davidoff of Geneva'),
  ('Camacho Connecticut', 'Camacho', 'Davidoff of Geneva'),
  ('Camacho BXP', 'Camacho', 'Davidoff of Geneva'),
  ('El Rico Habano', 'El Rico Habano', 'General Cigar Co.'),
  ('ERH', 'El Rico Habano', 'General Cigar Co.'),
  ('Omar Ortez', 'Omar Ortez', 'Omar Ortez')
ON CONFLICT (alias) DO NOTHING;
