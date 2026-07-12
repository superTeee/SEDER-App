-- 103_eiroa_cuba_aliados.sql
--
-- To nye merker fra dekningshull-lista (norske butikker), verifisert mot produsent.
-- Eiroa: 23 vitolaer / 4 linjer.  Cuba Aliados: 5 vitolaer / 1 linje.
--
--
-- EIROA — C.L.E Cigar Company
--
-- Kilde: clecigars.com (produsentens egen WooCommerce-butikk). Vitolaene ligger
-- i variasjons-nedtrekket som RING × LENGDE (bekreftet mot No Smoke: «48x4»,
-- «50x5»). Alle rulles på Aladino-fabrikken i Danlí, Honduras → country='Honduras'.
--
-- CLE navngir vitolaene KUN med mål, så vi bruker standard bransjenavn
-- (Robusto = 5×50, Toro = 6×54, Gordo = 6×60 osv.) — universell nomenklatur,
-- ikke gjetning. Box-pressede størrelser markert i cross_section.
--
-- Dekkblad per linje der det er utvetydig: CBT Maduro = Connecticut Broadleaf,
-- First 20 Years = Corojo, Colorado = Corojo Colorado. Natural står tomt (usikkert).
-- Omblad/innmat oppgis kun i prosa → står tomme, vi gjetter ikke.
--
--
-- CUBA ALIADOS
--
-- Gammelt merke (Rolando Reyes Sr.), kjøpt av Oliva i 2022. Original Blend rulles
-- i Honduras av JRE Tobacco (Julio Eiroa) → country='Honduras'. Målene er fra
-- Olivas offisielle lansering (Robusto 5×50, Toro 6×50, Torpedo 6×50, Churchill
-- 7×50, ReGordo 6×60). Nettsiden (Wix) er JS-rendret og sparsom; dekkblad står
-- tomt til vi kan bekrefte det per vitola.

-- Eiroa (C.L.E Cigar Company, Aladino-fabrikken, Danlí, Honduras)
insert into cigars
  (brand, series, vitola, ring_gauge, length_inches, shape, body_type,
   cross_section, wrapper_leaf, country_origin, source_url, verified_at,
   source_tier, is_public)
values
  ('Eiroa','The First 20 Years','Petit Corona',40,4,'Parejo',NULL,'Box Pressed','Corojo','Honduras','https://clecigars.com/shop/eiroa-the-first-20-years-2/',now(),'manufacturer',true),
  ('Eiroa','The First 20 Years','Corona Gorda',46,6,'Parejo',NULL,'Box Pressed','Corojo','Honduras','https://clecigars.com/shop/eiroa-the-first-20-years-2/',now(),'manufacturer',true),
  ('Eiroa','The First 20 Years','Robusto',50,5,'Parejo',NULL,'Box Pressed','Corojo','Honduras','https://clecigars.com/shop/eiroa-the-first-20-years-2/',now(),'manufacturer',true),
  ('Eiroa','The First 20 Years','Toro',54,6,'Parejo',NULL,'Box Pressed','Corojo','Honduras','https://clecigars.com/shop/eiroa-the-first-20-years-2/',now(),'manufacturer',true),
  ('Eiroa','The First 20 Years','Gordo',60,6,'Parejo',NULL,'Box Pressed','Corojo','Honduras','https://clecigars.com/shop/eiroa-the-first-20-years-2/',now(),'manufacturer',true),
  ('Eiroa','The First 20 Years','Diadema',NULL,NULL,'Figurado','Diadema',NULL,'Corojo','Honduras','https://clecigars.com/shop/eiroa-the-first-20-years-2/',now(),'manufacturer',true),
  ('Eiroa','The First 20 Years Colorado','Petit Corona',40,4,'Parejo',NULL,'Box Pressed','Corojo Colorado','Honduras','https://clecigars.com/shop/eiroa-the-first-20-years-colorado/',now(),'manufacturer',true),
  ('Eiroa','The First 20 Years Colorado','Corona Gorda',46,6,'Parejo',NULL,'Box Pressed','Corojo Colorado','Honduras','https://clecigars.com/shop/eiroa-the-first-20-years-colorado/',now(),'manufacturer',true),
  ('Eiroa','The First 20 Years Colorado','Robusto',50,5,'Parejo',NULL,'Box Pressed','Corojo Colorado','Honduras','https://clecigars.com/shop/eiroa-the-first-20-years-colorado/',now(),'manufacturer',true),
  ('Eiroa','The First 20 Years Colorado','Toro',54,6,'Parejo',NULL,'Box Pressed','Corojo Colorado','Honduras','https://clecigars.com/shop/eiroa-the-first-20-years-colorado/',now(),'manufacturer',true),
  ('Eiroa','The First 20 Years Colorado','Gordo',60,6,'Parejo',NULL,'Box Pressed','Corojo Colorado','Honduras','https://clecigars.com/shop/eiroa-the-first-20-years-colorado/',now(),'manufacturer',true),
  ('Eiroa','CBT Maduro','Petit Corona',40,4,'Parejo',NULL,NULL,'Connecticut Broadleaf','Honduras','https://clecigars.com/shop/eiroa-cbt-maduro-2/',now(),'manufacturer',true),
  ('Eiroa','CBT Maduro','Corona Prensado',48,4,'Parejo',NULL,'Box Pressed','Connecticut Broadleaf','Honduras','https://clecigars.com/shop/eiroa-cbt-maduro-2/',now(),'manufacturer',true),
  ('Eiroa','CBT Maduro','Robusto',50,5,'Parejo',NULL,NULL,'Connecticut Broadleaf','Honduras','https://clecigars.com/shop/eiroa-cbt-maduro-2/',now(),'manufacturer',true),
  ('Eiroa','CBT Maduro','Toro',54,6,'Parejo',NULL,NULL,'Connecticut Broadleaf','Honduras','https://clecigars.com/shop/eiroa-cbt-maduro-2/',now(),'manufacturer',true),
  ('Eiroa','CBT Maduro','Gordo',60,6,'Parejo',NULL,NULL,'Connecticut Broadleaf','Honduras','https://clecigars.com/shop/eiroa-cbt-maduro-2/',now(),'manufacturer',true),
  ('Eiroa','CBT Maduro','Lancero',38,7,'Parejo',NULL,NULL,'Connecticut Broadleaf','Honduras','https://clecigars.com/shop/eiroa-cbt-maduro-2/',now(),'manufacturer',true),
  ('Eiroa','Natural','Toro',54,6,'Parejo',NULL,NULL,NULL,'Honduras','https://clecigars.com/shop/eiroa-natural-2/',now(),'manufacturer',true),
  ('Eiroa','Natural','Petit Corona',40,4,'Parejo',NULL,NULL,NULL,'Honduras','https://clecigars.com/shop/eiroa-natural-2/',now(),'manufacturer',true),
  ('Eiroa','Natural','Corona Prensado',48,4,'Parejo',NULL,'Box Pressed',NULL,'Honduras','https://clecigars.com/shop/eiroa-natural-2/',now(),'manufacturer',true),
  ('Eiroa','Natural','Robusto',50,5,'Parejo',NULL,NULL,NULL,'Honduras','https://clecigars.com/shop/eiroa-natural-2/',now(),'manufacturer',true),
  ('Eiroa','Natural','Gordo',60,6,'Parejo',NULL,NULL,NULL,'Honduras','https://clecigars.com/shop/eiroa-natural-2/',now(),'manufacturer',true),
  ('Eiroa','Natural','Lancero',38,7,'Parejo',NULL,NULL,NULL,'Honduras','https://clecigars.com/shop/eiroa-natural-2/',now(),'manufacturer',true);

-- Cuba Aliados Original Blend (JRE Tobacco / Julio Eiroa, Honduras)
insert into cigars
  (brand, series, vitola, ring_gauge, length_inches, shape, body_type,
   country_origin, source_url, verified_at, source_tier, is_public)
values
  ('Cuba Aliados','Original Blend','Robusto',50,5,'Parejo',NULL,NULL,'Honduras','https://www.original-aliados.com/',now(),'manufacturer',true),
  ('Cuba Aliados','Original Blend','Toro',50,6,'Parejo',NULL,NULL,'Honduras','https://www.original-aliados.com/',now(),'manufacturer',true),
  ('Cuba Aliados','Original Blend','Torpedo',50,6,'Figurado','Torpedo',NULL,'Honduras','https://www.original-aliados.com/',now(),'manufacturer',true),
  ('Cuba Aliados','Original Blend','Churchill',50,7,'Parejo',NULL,NULL,'Honduras','https://www.original-aliados.com/',now(),'manufacturer',true),
  ('Cuba Aliados','Original Blend','ReGordo',60,6,'Parejo',NULL,NULL,'Honduras','https://www.original-aliados.com/',now(),'manufacturer',true);
