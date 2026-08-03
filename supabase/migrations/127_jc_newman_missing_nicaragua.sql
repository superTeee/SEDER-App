-- 127: Manglende J.C. Newman Nicaragua-størrelser, verifisert mot jcnewman.com (aug 2026)
--   * Brick House Classic – Mighty Mighty, The Traveler (tube), Short Torp, Corona, The Teaser
--   * Perla del Mar Shade – Double Toro, Corona Gorda, Short Robusto
-- Bekreftet komplette fra før: Brick House Maduro + Double Connecticut, Perla del Mar Corojo + Maduro,
-- Quorum (Classic/Maduro/Shade). El Baton og Cuesta-Rey har navne-/mål-drift og håndteres separat.

INSERT INTO public.cigars
  (brand, series, vitola, wrapper_country, wrapper_leaf, binder, filler, country_origin,
   ring_gauge, length_inches, shape, manufacturer, common_format, is_public, source_url, source_tier, verified_at)
VALUES
('Brick House','Classic','Mighty Mighty','Ecuador','Havana','Nicaraguan',ARRAY['Nicaragua'],'Nicaragua',60,6.25,'Parejo','J.C. Newman Cigar Co.','Gordo',true,'https://www.jcnewman.com/company/brick-house-cigars/','manufacturer',now()),
('Brick House','Classic','The Traveler','Ecuador','Havana','Nicaraguan',ARRAY['Nicaragua'],'Nicaragua',48,6.125,'Parejo','J.C. Newman Cigar Co.','Toro',true,'https://www.jcnewman.com/company/brick-house-cigars/','manufacturer',now()),
('Brick House','Classic','Short Torp','Ecuador','Havana','Nicaraguan',ARRAY['Nicaragua'],'Nicaragua',52,5.5,'Figurado','J.C. Newman Cigar Co.','Torpedo',true,'https://www.jcnewman.com/company/brick-house-cigars/','manufacturer',now()),
('Brick House','Classic','Corona','Ecuador','Havana','Nicaraguan',ARRAY['Nicaragua'],'Nicaragua',42,5.0,'Parejo','J.C. Newman Cigar Co.','Corona',true,'https://www.jcnewman.com/company/brick-house-cigars/','manufacturer',now()),
('Brick House','Classic','The Teaser','Ecuador','Havana','Nicaraguan',ARRAY['Nicaragua'],'Nicaragua',56,3.5,'Parejo','J.C. Newman Cigar Co.','Petit Robusto',true,'https://www.jcnewman.com/company/brick-house-cigars/','manufacturer',now()),
('Perla del Mar','Shade','Double Toro','Ecuador','Connecticut Shade','Nicaraguan',ARRAY['Nicaragua'],'Nicaragua',60,6.0,'Parejo','J.C. Newman Cigar Co.','Gordo',true,'https://www.jcnewman.com/company/perla-del-mar-cigars/','manufacturer',now()),
('Perla del Mar','Shade','Corona Gorda','Ecuador','Connecticut Shade','Nicaraguan',ARRAY['Nicaragua'],'Nicaragua',46,5.5,'Parejo','J.C. Newman Cigar Co.','Corona Gorda',true,'https://www.jcnewman.com/company/perla-del-mar-cigars/','manufacturer',now()),
('Perla del Mar','Shade','Short Robusto','Ecuador','Connecticut Shade','Nicaraguan',ARRAY['Nicaragua'],'Nicaragua',56,3.75,'Parejo','J.C. Newman Cigar Co.','Petit Robusto',true,'https://www.jcnewman.com/company/perla-del-mar-cigars/','manufacturer',now());
