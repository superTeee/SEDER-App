-- 128: Avstemming av J.C. Newman-linjer med navne-/mål-drift mot jcnewman.com (aug 2026)
--   * El Baton: "Gordo"→"Double Toro", rett Robusto-ring 52→54, fjern spøkelses-"Toro",
--     legg til Double Torpedo + Belicoso (produsentens 4 størrelser).
--   * Cuesta-Rey: bygget om fra 6 eldre, avvikende rader til produsentens tre serier:
--     Centro Fino (3), Centenario (6), Cabinet Selection (No. 898, No. 95).
--   * Yagua: rett mål fra 5x50 til 6x54 (Connecticut Broadleaf).
-- Ingen av de endrede/fjernede radene var referert av humidor/journal/ønskeliste/favoritt/skann.

-- El Baton
UPDATE public.cigars SET vitola='Double Toro', common_format='Gordo', ring_gauge=60, length_inches=6.0,
  wrapper_country='Ecuador', wrapper_leaf='Havana', binder='Nicaraguan', filler=ARRAY['Nicaragua'],
  country_origin='Nicaragua', shape='Parejo', manufacturer='J.C. Newman Cigar Co.',
  source_url='https://www.jcnewman.com/company/el-baton-cigars/', source_tier='manufacturer', verified_at=now()
WHERE id='cddcbe8e-068d-4f5d-8d89-44158d63d3c7';

UPDATE public.cigars SET ring_gauge=54, length_inches=5.0, common_format='Robusto',
  wrapper_country='Ecuador', wrapper_leaf='Havana', binder='Nicaraguan', filler=ARRAY['Nicaragua'],
  country_origin='Nicaragua', shape='Parejo', manufacturer='J.C. Newman Cigar Co.',
  source_url='https://www.jcnewman.com/company/el-baton-cigars/', source_tier='manufacturer', verified_at=now()
WHERE id='452fa895-097e-446b-992f-7545f605a27d';

DELETE FROM public.cigars WHERE id='16106180-4735-48e0-8c5b-77623a31d317';

INSERT INTO public.cigars
  (brand, series, vitola, wrapper_country, wrapper_leaf, binder, filler, country_origin,
   ring_gauge, length_inches, shape, manufacturer, common_format, is_public, source_url, source_tier, verified_at)
VALUES
('El Baton',NULL,'Double Torpedo','Ecuador','Havana','Nicaraguan',ARRAY['Nicaragua'],'Nicaragua',56,6.25,'Figurado','J.C. Newman Cigar Co.','Torpedo',true,'https://www.jcnewman.com/company/el-baton-cigars/','manufacturer',now()),
('El Baton',NULL,'Belicoso','Ecuador','Havana','Nicaraguan',ARRAY['Nicaragua'],'Nicaragua',56,5.0,'Figurado','J.C. Newman Cigar Co.','Belicoso',true,'https://www.jcnewman.com/company/el-baton-cigars/','manufacturer',now());

-- Cuesta-Rey
DELETE FROM public.cigars WHERE id IN (
 'cbf8983b-adb4-47dc-9bdf-75021883196f','673d7d78-3891-4172-8758-a091ab1356ec',
 'fee6581a-9340-413a-a9ae-8d1cccb59e93','01030387-33b3-440f-8323-9dac281181ae',
 '2842adf2-4061-4c11-8c5c-f6baafc3b899','fc97feb4-39f4-4d6b-b200-5c0594463de4');

INSERT INTO public.cigars
  (brand, series, vitola, wrapper_country, wrapper_leaf, binder, filler, country_origin,
   ring_gauge, length_inches, shape, manufacturer, common_format, is_public, source_url, source_tier, verified_at)
VALUES
('Cuesta-Rey','Centro Fino','Pyramid No. 9','Ecuador','Sungrown','Dominican',ARRAY['Dominican Republic'],'Dominican Republic',52,6.25,'Figurado','J.C. Newman Cigar Co.','Pyramid',true,'https://www.jcnewman.com/company/cuesta-rey-cigars/','manufacturer',now()),
('Cuesta-Rey','Centro Fino','No. 60','Ecuador','Sungrown','Dominican',ARRAY['Dominican Republic'],'Dominican Republic',50,6.0,'Parejo','J.C. Newman Cigar Co.','Toro',true,'https://www.jcnewman.com/company/cuesta-rey-cigars/','manufacturer',now()),
('Cuesta-Rey','Centro Fino','Robusto No. 7','Ecuador','Sungrown','Dominican',ARRAY['Dominican Republic'],'Dominican Republic',50,4.5,'Parejo','J.C. Newman Cigar Co.','Robusto',true,'https://www.jcnewman.com/company/cuesta-rey-cigars/','manufacturer',now()),
('Cuesta-Rey','Centenario','Aristocrat','United States','Connecticut Shade','Dominican',ARRAY['Dominican Republic'],'Dominican Republic',48,7.25,'Parejo','J.C. Newman Cigar Co.','Churchill',true,'https://www.jcnewman.com/company/cuesta-rey-cigars/','manufacturer',now()),
('Cuesta-Rey','Centenario','Pyramid No. 9','United States','Connecticut Shade','Dominican',ARRAY['Dominican Republic'],'Dominican Republic',52,6.25,'Figurado','J.C. Newman Cigar Co.','Pyramid',true,'https://www.jcnewman.com/company/cuesta-rey-cigars/','manufacturer',now()),
('Cuesta-Rey','Centenario','Dominican No. 60','United States','Connecticut Shade','Dominican',ARRAY['Dominican Republic'],'Dominican Republic',50,6.0,'Parejo','J.C. Newman Cigar Co.','Toro',true,'https://www.jcnewman.com/company/cuesta-rey-cigars/','manufacturer',now()),
('Cuesta-Rey','Centenario','Dominican No. 5','United States','Connecticut Shade','Dominican',ARRAY['Dominican Republic'],'Dominican Republic',43,5.5,'Parejo','J.C. Newman Cigar Co.','Corona',true,'https://www.jcnewman.com/company/cuesta-rey-cigars/','manufacturer',now()),
('Cuesta-Rey','Centenario','Tuscany','United States','Connecticut Shade','Dominican',ARRAY['Dominican Republic'],'Dominican Republic',50,5.0,'Parejo','J.C. Newman Cigar Co.','Robusto',true,'https://www.jcnewman.com/company/cuesta-rey-cigars/','manufacturer',now()),
('Cuesta-Rey','Centenario','Robusto No. 7','United States','Connecticut Shade','Dominican',ARRAY['Dominican Republic'],'Dominican Republic',50,4.5,'Parejo','J.C. Newman Cigar Co.','Robusto',true,'https://www.jcnewman.com/company/cuesta-rey-cigars/','manufacturer',now()),
('Cuesta-Rey','Cabinet Selection','No. 898','United States','Connecticut Shade','Dominican',ARRAY['Dominican Republic','Brazil'],'Dominican Republic',49,7.0,'Parejo','J.C. Newman Cigar Co.','Churchill',true,'https://www.jcnewman.com/company/cuesta-rey-cigars/','manufacturer',now()),
('Cuesta-Rey','Cabinet Selection','No. 95','Cameroon','African Cameroon','Dominican',ARRAY['Dominican Republic','Brazil'],'Dominican Republic',42,6.25,'Parejo','J.C. Newman Cigar Co.','Lonsdale',true,'https://www.jcnewman.com/company/cuesta-rey-cigars/','manufacturer',now());

-- Yagua
UPDATE public.cigars SET ring_gauge=54, length_inches=6.0, wrapper_country='United States',
  wrapper_leaf='Connecticut Broadleaf', binder='Nicaraguan', filler=ARRAY['Nicaragua'],
  country_origin='Nicaragua', shape='Parejo', common_format='Toro', manufacturer='J.C. Newman Cigar Co.',
  source_url='https://www.jcnewman.com/company/yagua-cigars/', source_tier='manufacturer', verified_at=now()
WHERE id='6d072582-b356-48d0-a554-b7e8869cf0c2';
