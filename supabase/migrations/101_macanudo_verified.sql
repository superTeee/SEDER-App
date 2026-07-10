-- 101_macanudo_verified.sql
--
-- Macanudo: 67 rader → 86, alle verifisert mot produsent.
-- Kilde: https://www.macanudo.com/cigars/<linje>/ (20 linje-sider).
--
-- Etter kjøring: 86 rader, source_tier='manufacturer', 0 uverifiserte, 20 serier.
-- Ingen testerdata på merket (humidor/logg/ønskeliste/målinger = 0, sjekket).
--
--
-- KILDEN
--
-- Macanudo publiserer rikt: dekkblad, omblad, innmat, kropp og størrelser.
-- Hver vitola står som «Navn (LENGDE x RINGMÅL)» i desimaltommer — LENGDE ×
-- RINGMÅL, som CAO/Joya/Ashton. De 67 gamle radene (0 referanser) ble
-- full-erstattet av de 20 linjenes 86 vitolaer.
--
--
-- OMFANG
--
-- Med: legacy-linjene (Café, Maduro, Gold Label, Vintage, Estate Reserve,
-- Cru Royale, 1968, Ecuadorian Shade, Sumatra) og hele Inspirado-serien.
-- Uten: «M by Macanudo» (aromatiserte/infuserte sigarer, en egen produktfamilie)
-- og Emissary (ingen størrelsesliste på siden). De kan legges til senere som
-- egne merker.
--
--
-- OPPRINNELSE STÅR TOMT — MED VILJE
--
-- Macanudos sider oppgir IKKE produksjonsland. Klassisk Macanudo lages i Den
-- dominikanske republikk, men Inspirado-linjene rulles i ulike land (Orange i
-- Honduras, Red med nicaraguansk innmat osv.). Å skrive «Dominican Republic»
-- overalt ville vært feil for Inspirado, så country_origin står tomt. Vi gjetter
-- ikke et land produsenten ikke oppgir.
--
--
-- STYRKE (Macanudo bruker «Body»)
--
-- Mellow=1, Mellow-Medium=2, Medium=3, Medium-Full=4, Full=5.
--
--
-- FORM
--
-- shape = 'Figurado' for Torpedo/Pyramid (body_type = navnet). Ellers 'Parejo'.
--

delete from cigars where brand='Macanudo';

insert into cigars
  (brand, series, vitola, ring_gauge, length_inches, shape, body_type,
   wrapper_leaf, binder, filler, strength, source_url, verified_at,
   source_tier, is_public)
values
  ('Macanudo','1968','Robusto',50,5,'Parejo',NULL,'Honduran Olancho San Agustin','Connecticut Habano',ARRAY['Dominican','Nicaraguan Esteli','Nicaraguan Ometepe']::text[],4,'https://www.macanudo.com/cigars/legacy/macanudo-1968/',now(),'manufacturer',true),
  ('Macanudo','1968','Toro',54,6,'Parejo',NULL,'Honduran Olancho San Agustin','Connecticut Habano',ARRAY['Dominican','Nicaraguan Esteli','Nicaraguan Ometepe']::text[],4,'https://www.macanudo.com/cigars/legacy/macanudo-1968/',now(),'manufacturer',true),
  ('Macanudo','1968','Gigante',60,6,'Parejo',NULL,'Honduran Olancho San Agustin','Connecticut Habano',ARRAY['Dominican','Nicaraguan Esteli','Nicaraguan Ometepe']::text[],4,'https://www.macanudo.com/cigars/legacy/macanudo-1968/',now(),'manufacturer',true),
  ('Macanudo','1968','Churchill',49,7,'Parejo',NULL,'Honduran Olancho San Agustin','Connecticut Habano',ARRAY['Dominican','Nicaraguan Esteli','Nicaraguan Ometepe']::text[],4,'https://www.macanudo.com/cigars/legacy/macanudo-1968/',now(),'manufacturer',true),
  ('Macanudo','Café','Miniatures',24,3.75,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-cafe/',now(),'manufacturer',true),
  ('Macanudo','Café','Caviar',36,4,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-cafe/',now(),'manufacturer',true),
  ('Macanudo','Café','Ascots',32,4.1875,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-cafe/',now(),'manufacturer',true),
  ('Macanudo','Café','Diplomat',60,4.5,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-cafe/',now(),'manufacturer',true),
  ('Macanudo','Café','Lords',49,4.75,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-cafe/',now(),'manufacturer',true),
  ('Macanudo','Café','Petit Corona',38,5,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-cafe/',now(),'manufacturer',true),
  ('Macanudo','Café','Duke of York',54,5.25,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-cafe/',now(),'manufacturer',true),
  ('Macanudo','Café','Duke of Devon',42,5.5,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-cafe/',now(),'manufacturer',true),
  ('Macanudo','Café','Hampton Court',42,5.5,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-cafe/',now(),'manufacturer',true),
  ('Macanudo','Café','Hyde Park',49,5.5,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-cafe/',now(),'manufacturer',true),
  ('Macanudo','Café','Claybourne',31,6,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-cafe/',now(),'manufacturer',true),
  ('Macanudo','Café','Duke of Windsor',50,6,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-cafe/',now(),'manufacturer',true),
  ('Macanudo','Café','Thames',50,6,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-cafe/',now(),'manufacturer',true),
  ('Macanudo','Café','Tudor',52,6,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-cafe/',now(),'manufacturer',true),
  ('Macanudo','Café','Gigante',60,6,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-cafe/',now(),'manufacturer',true),
  ('Macanudo','Café','Baron de Rothschild',42,6.5,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-cafe/',now(),'manufacturer',true),
  ('Macanudo','Café','Prince Philip',49,7.5,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-cafe/',now(),'manufacturer',true),
  ('Macanudo','Café','Prince of Wales',52,8,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-cafe/',now(),'manufacturer',true),
  ('Macanudo','Ecuadorian Shade','Robusto',50,5,'Parejo',NULL,'Ecuadorian Shade','U.S. Broadleaf',ARRAY['Dominican Piloto','Nicaraguan Condega','Nicaraguan Esteli','Dominican Olor']::text[],2,'https://www.macanudo.com/cigars/legacy/macanudo-ecuadorian-shade/',now(),'manufacturer',true),
  ('Macanudo','Ecuadorian Shade','Toro',50,6,'Parejo',NULL,'Ecuadorian Shade','U.S. Broadleaf',ARRAY['Dominican Piloto','Nicaraguan Condega','Nicaraguan Esteli','Dominican Olor']::text[],2,'https://www.macanudo.com/cigars/legacy/macanudo-ecuadorian-shade/',now(),'manufacturer',true),
  ('Macanudo','Ecuadorian Shade','Gigante',60,6,'Parejo',NULL,'Ecuadorian Shade','U.S. Broadleaf',ARRAY['Dominican Piloto','Nicaraguan Condega','Nicaraguan Esteli','Dominican Olor']::text[],2,'https://www.macanudo.com/cigars/legacy/macanudo-ecuadorian-shade/',now(),'manufacturer',true),
  ('Macanudo','Sumatra','Robusto',50,5,'Parejo',NULL,'Ecuadorian Sumatra','U.S. Broadleaf',ARRAY['Dominican Piloto','Nicaraguan Condega','Nicaraguan Esteli','Dominican Olor']::text[],3,'https://www.macanudo.com/cigars/legacy/macanudo-sumatra/',now(),'manufacturer',true),
  ('Macanudo','Sumatra','Toro',50,6,'Parejo',NULL,'Ecuadorian Sumatra','U.S. Broadleaf',ARRAY['Dominican Piloto','Nicaraguan Condega','Nicaraguan Esteli','Dominican Olor']::text[],3,'https://www.macanudo.com/cigars/legacy/macanudo-sumatra/',now(),'manufacturer',true),
  ('Macanudo','Sumatra','Gigante',60,6,'Parejo',NULL,'Ecuadorian Sumatra','U.S. Broadleaf',ARRAY['Dominican Piloto','Nicaraguan Condega','Nicaraguan Esteli','Dominican Olor']::text[],3,'https://www.macanudo.com/cigars/legacy/macanudo-sumatra/',now(),'manufacturer',true),
  ('Macanudo','Maduro','Ascots',32,4.1875,'Parejo',NULL,'Connecticut Broadleaf','Connecticut',ARRAY['Mexican','Dominican Piloto Cubano']::text[],2,'https://www.macanudo.com/cigars/legacy/macanudo-maduro/',now(),'manufacturer',true),
  ('Macanudo','Maduro','Diplomat',60,4.5,'Parejo',NULL,'Connecticut Broadleaf','Connecticut',ARRAY['Mexican','Dominican Piloto Cubano']::text[],2,'https://www.macanudo.com/cigars/legacy/macanudo-maduro/',now(),'manufacturer',true),
  ('Macanudo','Maduro','Duke of Devon',42,5.5,'Parejo',NULL,'Connecticut Broadleaf','Connecticut',ARRAY['Mexican','Dominican Piloto Cubano']::text[],2,'https://www.macanudo.com/cigars/legacy/macanudo-maduro/',now(),'manufacturer',true),
  ('Macanudo','Maduro','Hampton Court',42,5.5,'Parejo',NULL,'Connecticut Broadleaf','Connecticut',ARRAY['Mexican','Dominican Piloto Cubano']::text[],2,'https://www.macanudo.com/cigars/legacy/macanudo-maduro/',now(),'manufacturer',true),
  ('Macanudo','Maduro','Hyde Park',49,5.5,'Parejo',NULL,'Connecticut Broadleaf','Connecticut',ARRAY['Mexican','Dominican Piloto Cubano']::text[],2,'https://www.macanudo.com/cigars/legacy/macanudo-maduro/',now(),'manufacturer',true),
  ('Macanudo','Maduro','Crystal',50,5.5,'Parejo',NULL,'Connecticut Broadleaf','Connecticut',ARRAY['Mexican','Dominican Piloto Cubano']::text[],2,'https://www.macanudo.com/cigars/legacy/macanudo-maduro/',now(),'manufacturer',true),
  ('Macanudo','Maduro','Gigante',60,6,'Parejo',NULL,'Connecticut Broadleaf','Connecticut',ARRAY['Mexican','Dominican Piloto Cubano']::text[],2,'https://www.macanudo.com/cigars/legacy/macanudo-maduro/',now(),'manufacturer',true),
  ('Macanudo','Maduro','Baron de Rothschild',42,6.5,'Parejo',NULL,'Connecticut Broadleaf','Connecticut',ARRAY['Mexican','Dominican Piloto Cubano']::text[],2,'https://www.macanudo.com/cigars/legacy/macanudo-maduro/',now(),'manufacturer',true),
  ('Macanudo','Maduro','Prince Philip',49,7.5,'Parejo',NULL,'Connecticut Broadleaf','Connecticut',ARRAY['Mexican','Dominican Piloto Cubano']::text[],2,'https://www.macanudo.com/cigars/legacy/macanudo-maduro/',now(),'manufacturer',true),
  ('Macanudo','Gold Label','Ascots',32,4.1875,'Parejo',NULL,'Connecticut Golden Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-gold-label/',now(),'manufacturer',true),
  ('Macanudo','Gold Label','Gold Pyramid',54,5,'Figurado','Pyramid','Connecticut Golden Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-gold-label/',now(),'manufacturer',true),
  ('Macanudo','Gold Label','Duke of York',54,5.25,'Parejo',NULL,'Connecticut Golden Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-gold-label/',now(),'manufacturer',true),
  ('Macanudo','Gold Label','Tudor',52,6,'Parejo',NULL,'Connecticut Golden Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-gold-label/',now(),'manufacturer',true),
  ('Macanudo','Gold Label','Gold Bullion',54,6,'Parejo',NULL,'Connecticut Golden Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-gold-label/',now(),'manufacturer',true),
  ('Macanudo','Gold Label','Shakespeare',45,6.5,'Parejo',NULL,'Connecticut Golden Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-gold-label/',now(),'manufacturer',true),
  ('Macanudo','Gold Label','Lord Nelson',49,7,'Parejo',NULL,'Connecticut Golden Shade','Mexican San Andrean',ARRAY['Mexican','Dominican Piloto Cubano']::text[],1,'https://www.macanudo.com/cigars/legacy/macanudo-gold-label/',now(),'manufacturer',true),
  ('Macanudo','Vintage 2010','Torpedo',52,6.25,'Figurado','Torpedo','Connecticut Shade Vintage 2010','Honduran',ARRAY['Honduran','Nicaraguan','Piloto Cubano 94']::text[],2,'https://www.macanudo.com/cigars/legacy/macanudo-vintage-2010/',now(),'manufacturer',true),
  ('Macanudo','Vintage 2010','Toro Grande',54,6.625,'Parejo',NULL,'Connecticut Shade Vintage 2010','Honduran',ARRAY['Honduran','Nicaraguan','Piloto Cubano 94']::text[],2,'https://www.macanudo.com/cigars/legacy/macanudo-vintage-2010/',now(),'manufacturer',true),
  ('Macanudo','Vintage 2010','Churchill',48,7.25,'Parejo',NULL,'Connecticut Shade Vintage 2010','Honduran',ARRAY['Honduran','Nicaraguan','Piloto Cubano 94']::text[],2,'https://www.macanudo.com/cigars/legacy/macanudo-vintage-2010/',now(),'manufacturer',true),
  ('Macanudo','Vintage Maduro 2013','Robusto',50,5,'Parejo',NULL,'Connecticut Broadleaf Maduro','Honduran Olancho San Agustin',ARRAY['Brazilian Mata Fina','Nicaraguan Jalapa','Piloto Cubano Seco','Piloto Cubano Ligero']::text[],3,'https://www.macanudo.com/cigars/legacy/macanudo-vintage-maduro-2013/',now(),'manufacturer',true),
  ('Macanudo','Vintage Maduro 2013','Toro Grande',54,6,'Parejo',NULL,'Connecticut Broadleaf Maduro','Honduran Olancho San Agustin',ARRAY['Brazilian Mata Fina','Nicaraguan Jalapa','Piloto Cubano Seco','Piloto Cubano Ligero']::text[],3,'https://www.macanudo.com/cigars/legacy/macanudo-vintage-maduro-2013/',now(),'manufacturer',true),
  ('Macanudo','Vintage Maduro 2013','Churchill',49,7,'Parejo',NULL,'Connecticut Broadleaf Maduro','Honduran Olancho San Agustin',ARRAY['Brazilian Mata Fina','Nicaraguan Jalapa','Piloto Cubano Seco','Piloto Cubano Ligero']::text[],3,'https://www.macanudo.com/cigars/legacy/macanudo-vintage-maduro-2013/',now(),'manufacturer',true),
  ('Macanudo','Estate Reserve No. 1','Toro',54,6,'Parejo',NULL,'Ecuadorian Connecticut Shade','Connecticut Broadleaf',NULL,3,'https://www.macanudo.com/cigars/legacy/macanudo-estate-reserve-release-no-1/',now(),'manufacturer',true),
  ('Macanudo','Estate Reserve No. 1','Churchill',52,7,'Parejo',NULL,'Ecuadorian Connecticut Shade','Connecticut Broadleaf',NULL,3,'https://www.macanudo.com/cigars/legacy/macanudo-estate-reserve-release-no-1/',now(),'manufacturer',true),
  ('Macanudo','Estate Reserve No. 2','Toro',54,6,'Parejo',NULL,'Ecuadorian Connecticut Shade','Connecticut Broadleaf',NULL,3,'https://www.macanudo.com/cigars/legacy/macanudo-estate-reserve-release-no-2/',now(),'manufacturer',true),
  ('Macanudo','Estate Reserve No. 2','Churchill',52,7,'Parejo',NULL,'Ecuadorian Connecticut Shade','Connecticut Broadleaf',NULL,3,'https://www.macanudo.com/cigars/legacy/macanudo-estate-reserve-release-no-2/',now(),'manufacturer',true),
  ('Macanudo','Estate Reserve No. 3','Churchill',52,7,'Parejo',NULL,'Ecuadorian Connecticut Shade','Connecticut Broadleaf',NULL,3,'https://www.macanudo.com/cigars/legacy/macanudo-estate-reserve-release-no-3/',now(),'manufacturer',true),
  ('Macanudo','Cru Royale','Poco Gordo',60,4,'Parejo',NULL,'Ecuadorian Habano','Dominican La Vega Especial',ARRAY['Brazilian','Dominican','Nicaraguan']::text[],3,'https://www.macanudo.com/cigars/legacy/macanudo-cru-royale/',now(),'manufacturer',true),
  ('Macanudo','Cru Royale','Robusto',50,5,'Parejo',NULL,'Ecuadorian Habano','Dominican La Vega Especial',ARRAY['Brazilian','Dominican','Nicaraguan']::text[],3,'https://www.macanudo.com/cigars/legacy/macanudo-cru-royale/',now(),'manufacturer',true),
  ('Macanudo','Cru Royale','Toro',54,6,'Parejo',NULL,'Ecuadorian Habano','Dominican La Vega Especial',ARRAY['Brazilian','Dominican','Nicaraguan']::text[],3,'https://www.macanudo.com/cigars/legacy/macanudo-cru-royale/',now(),'manufacturer',true),
  ('Macanudo','Cru Royale','Gigante',60,6,'Parejo',NULL,'Ecuadorian Habano','Dominican La Vega Especial',ARRAY['Brazilian','Dominican','Nicaraguan']::text[],3,'https://www.macanudo.com/cigars/legacy/macanudo-cru-royale/',now(),'manufacturer',true),
  ('Macanudo','Inspirado White','Robusto',50,5,'Parejo',NULL,'Ecuadorian Connecticut','Indonesian',NULL,2,'https://www.macanudo.com/cigars/inspirado/white/',now(),'manufacturer',true),
  ('Macanudo','Inspirado White','Tubo',50,5,'Parejo',NULL,'Ecuadorian Connecticut','Indonesian',NULL,2,'https://www.macanudo.com/cigars/inspirado/white/',now(),'manufacturer',true),
  ('Macanudo','Inspirado White','Gigante',60,6,'Parejo',NULL,'Ecuadorian Connecticut','Indonesian',NULL,2,'https://www.macanudo.com/cigars/inspirado/white/',now(),'manufacturer',true),
  ('Macanudo','Inspirado White','Toro',50,6.5,'Parejo',NULL,'Ecuadorian Connecticut','Indonesian',NULL,2,'https://www.macanudo.com/cigars/inspirado/white/',now(),'manufacturer',true),
  ('Macanudo','Inspirado White','Churchill',48,7,'Parejo',NULL,'Ecuadorian Connecticut','Indonesian',NULL,2,'https://www.macanudo.com/cigars/inspirado/white/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Orange','Robusto',50,5,'Parejo',NULL,'Honduran','Honduran',ARRAY['Dominican','Honduran','Nicaraguan']::text[],3,'https://www.macanudo.com/cigars/inspirado/orange/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Orange','Tubo',50,5,'Parejo',NULL,'Honduran','Honduran',ARRAY['Dominican','Honduran','Nicaraguan']::text[],3,'https://www.macanudo.com/cigars/inspirado/orange/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Orange','Toro',52,5.75,'Parejo',NULL,'Honduran','Honduran',ARRAY['Dominican','Honduran','Nicaraguan']::text[],3,'https://www.macanudo.com/cigars/inspirado/orange/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Orange','Gigante',60,6,'Parejo',NULL,'Honduran','Honduran',ARRAY['Dominican','Honduran','Nicaraguan']::text[],3,'https://www.macanudo.com/cigars/inspirado/orange/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Orange','Churchill',50,7,'Parejo',NULL,'Honduran','Honduran',ARRAY['Dominican','Honduran','Nicaraguan']::text[],3,'https://www.macanudo.com/cigars/inspirado/orange/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Black','Robusto',50,4.875,'Parejo',NULL,'Connecticut Broadleaf','Ecuadorian Sumatra',ARRAY['Nicaraguan Esteli']::text[],3,'https://www.macanudo.com/cigars/inspirado/black/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Black','Tubo',50,4.875,'Parejo',NULL,'Connecticut Broadleaf','Ecuadorian Sumatra',ARRAY['Nicaraguan Esteli']::text[],3,'https://www.macanudo.com/cigars/inspirado/black/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Black','Toro',54,5.5,'Parejo',NULL,'Connecticut Broadleaf','Ecuadorian Sumatra',ARRAY['Nicaraguan Esteli']::text[],3,'https://www.macanudo.com/cigars/inspirado/black/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Black','Churchill',48,7,'Parejo',NULL,'Connecticut Broadleaf','Ecuadorian Sumatra',ARRAY['Nicaraguan Esteli']::text[],3,'https://www.macanudo.com/cigars/inspirado/black/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Green','Robusto',52,5,'Parejo',NULL,'Brazilian Arapiraca','Indonesian',ARRAY['Colombian','Dominican']::text[],3,'https://www.macanudo.com/cigars/inspirado/green/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Green','Toro',50,6,'Parejo',NULL,'Brazilian Arapiraca','Indonesian',ARRAY['Colombian','Dominican']::text[],3,'https://www.macanudo.com/cigars/inspirado/green/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Green','Gigante',60,6,'Parejo',NULL,'Brazilian Arapiraca','Indonesian',ARRAY['Colombian','Dominican']::text[],3,'https://www.macanudo.com/cigars/inspirado/green/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Green','Churchill',48,7,'Parejo',NULL,'Brazilian Arapiraca','Indonesian',ARRAY['Colombian','Dominican']::text[],3,'https://www.macanudo.com/cigars/inspirado/green/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Red','Toro',50,6,'Parejo',NULL,'Ecuadorian Habano','Nicaraguan Jalapa',ARRAY['Honduran Jamastran','Nicaraguan Esteli','Nicaraguan Ometepe']::text[],4,'https://www.macanudo.com/cigars/inspirado/red/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Red','Gigante',60,6,'Parejo',NULL,'Ecuadorian Habano','Nicaraguan Jalapa',ARRAY['Honduran Jamastran','Nicaraguan Esteli','Nicaraguan Ometepe']::text[],4,'https://www.macanudo.com/cigars/inspirado/red/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Jamao','Toro',52,5.75,'Parejo',NULL,'Jamao Dominican','Honduran',ARRAY['Honduran','Nicaraguan','Dominican']::text[],3,'https://www.macanudo.com/cigars/inspirado/jamao/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Jamao','Churchill',49,7,'Parejo',NULL,'Jamao Dominican','Honduran',ARRAY['Honduran','Nicaraguan','Dominican']::text[],3,'https://www.macanudo.com/cigars/inspirado/jamao/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Tercio Aged','Toro',54,6,'Parejo',NULL,'Mexican San Andrés','Indonesian Bezuki',ARRAY['Piloto Cubano Seco','Piloto Cubano Ligero','Colombian Seco']::text[],3,'https://www.macanudo.com/cigars/inspirado/tercio-aged/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Tercio Aged','Churchill',49,7,'Parejo',NULL,'Mexican San Andrés','Indonesian Bezuki',ARRAY['Piloto Cubano Seco','Piloto Cubano Ligero','Colombian Seco']::text[],3,'https://www.macanudo.com/cigars/inspirado/tercio-aged/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Brazilian Shade','Torpedo',52,6.25,'Figurado','Torpedo','Connecticut Shade','Mexican San Andrean',ARRAY['Brazilian','Nicaraguan Jalapa','Dominican Piloto Cubano','Dominican Cubita Mao']::text[],3,'https://www.macanudo.com/cigars/inspirado/inspirado-brazilian-shade/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Brazilian Shade','Toro',52,6.5,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Brazilian','Nicaraguan Jalapa','Dominican Piloto Cubano','Dominican Cubita Mao']::text[],3,'https://www.macanudo.com/cigars/inspirado/inspirado-brazilian-shade/',now(),'manufacturer',true),
  ('Macanudo','Inspirado Brazilian Shade','Churchill',48,7,'Parejo',NULL,'Connecticut Shade','Mexican San Andrean',ARRAY['Brazilian','Nicaraguan Jalapa','Dominican Piloto Cubano','Dominican Cubita Mao']::text[],3,'https://www.macanudo.com/cigars/inspirado/inspirado-brazilian-shade/',now(),'manufacturer',true);
