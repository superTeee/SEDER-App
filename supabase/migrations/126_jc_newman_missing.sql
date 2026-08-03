-- 126: Manglende J.C. Newman-sigarer, verifisert mot jcnewman.com (aug 2026)
--   * Diamond Crown Classic – manglende størrelser No. 2/7/8/9 (No.9 = standard 6x50 parejo)
--   * Angel Cuesta – nytt merke (Tampa, USA), linjene Rosado + Shade, 3 størrelser hver
-- Kilde: produsentens egen side. Maximus (kun Toro etter 2026-relansering),
-- Black Diamond, Diamond Crown Maduro og Julius Caeser er alle bekreftet komplette.
-- La Unica fantes allerede (series Natural + Maduro) og ble derfor ikke lagt inn.

INSERT INTO public.cigars
  (brand, series, vitola, wrapper_country, wrapper_leaf, binder, filler, country_origin,
   ring_gauge, length_inches, shape, manufacturer, common_format, is_public, source_url, source_tier, verified_at)
VALUES
-- Diamond Crown Classic – manglende størrelser
('Diamond Crown','Classic','No. 2','United States','Connecticut Shade','Dominican',ARRAY['Dominican Republic'],'Dominican Republic',54,7.5,'Parejo','J.C. Newman Cigar Co.','Churchill',true,'https://www.jcnewman.com/company/diamond-crown-cigars/','manufacturer',now()),
('Diamond Crown','Classic','No. 7','United States','Connecticut Shade','Dominican',ARRAY['Dominican Republic'],'Dominican Republic',54,6.75,'Parejo','J.C. Newman Cigar Co.','Toro',true,'https://www.jcnewman.com/company/diamond-crown-cigars/','manufacturer',now()),
('Diamond Crown','Classic','No. 8','United States','Connecticut Shade','Dominican',ARRAY['Dominican Republic'],'Dominican Republic',58,5.0,'Parejo','J.C. Newman Cigar Co.','Robusto',true,'https://www.jcnewman.com/company/diamond-crown-cigars/','manufacturer',now()),
('Diamond Crown','Classic','No. 9','United States','Connecticut Shade','Dominican',ARRAY['Dominican Republic'],'Dominican Republic',50,6.0,'Parejo','J.C. Newman Cigar Co.','Toro',true,'https://www.jcnewman.com/company/diamond-crown-cigars/','manufacturer',now()),
-- Angel Cuesta (El Reloj, Tampa USA) – nytt merke, Rosado + Shade
('Angel Cuesta','Rosado','Doble Robusto','Ecuador','Havana Rosado',NULL,NULL,'United States',56,5.5,'Parejo','J.C. Newman Cigar Co.','Robusto',true,'https://www.jcnewman.com/company/angel-cuesta/','manufacturer',now()),
('Angel Cuesta','Rosado','Toro','Ecuador','Havana Rosado',NULL,NULL,'United States',52,6.25,'Parejo','J.C. Newman Cigar Co.','Toro',true,'https://www.jcnewman.com/company/angel-cuesta/','manufacturer',now()),
('Angel Cuesta','Rosado','Salomones','Ecuador','Havana Rosado',NULL,NULL,'United States',57,7.25,'Figurado','J.C. Newman Cigar Co.','Salomon',true,'https://www.jcnewman.com/company/angel-cuesta/','manufacturer',now()),
('Angel Cuesta','Shade','Doble Robusto','Nicaragua','Shade',NULL,NULL,'United States',56,5.5,'Parejo','J.C. Newman Cigar Co.','Robusto',true,'https://www.jcnewman.com/company/angel-cuesta/','manufacturer',now()),
('Angel Cuesta','Shade','Toro','Nicaragua','Shade',NULL,NULL,'United States',52,6.25,'Parejo','J.C. Newman Cigar Co.','Toro',true,'https://www.jcnewman.com/company/angel-cuesta/','manufacturer',now()),
('Angel Cuesta','Shade','Salomones','Nicaragua','Shade',NULL,NULL,'United States',57,7.25,'Figurado','J.C. Newman Cigar Co.','Salomon',true,'https://www.jcnewman.com/company/angel-cuesta/','manufacturer',now());
