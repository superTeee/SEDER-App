-- 134: La Barba «Siempre» (Tamboril) — siste linje fra produsentens lineup, manglet i basen.
-- Blend/smak fra produsentens egen side (labarbacigars.com/the-lineup): Ecuador Connecticut-
-- dekkblad med Corojo Ligero + HVA Secco, light+. Rulles hos Tabacalera William Ventura (DR).
-- Produsenten publiserer ikke mål, så størrelser er hentet fra presse (halfwheel, IPCPR 2016)
-- og markeres source_tier='retailer':
--   Perla 4×42 · Robusto 5×50 · Toro 6×50 · Double Toro 6×60
-- Alias 'Siempre'/'La Barba Siempre'/'Siempre Tamboril' så det skannede båndet matcher.
INSERT INTO public.cigars
  (brand, series, vitola, wrapper_country, wrapper_leaf, country_origin, strength, ring_gauge,
   length_inches, shape, manufacturer, common_format, description, is_public, source_tier,
   source_url, verified_at, aliases)
VALUES
('La Barba','Siempre','Perla','Ecuador','Connecticut','Dominican Republic',1.5,42,4.0,
 'Parejo','La Barba Cigars','Perla',
 'Ecuador Connecticut-dekkblad med Corojo Ligero og HVA Secco. Lett og upåklagelig — espresso, vanilje, fløte, salt og jord. Light+.',
 true,'retailer','https://halfwheel.com/ipcpr-2016-la-barba-cigar-co/126021/',now(),
 ARRAY['Siempre','La Barba Siempre','Siempre Tamboril']),
('La Barba','Siempre','Robusto','Ecuador','Connecticut','Dominican Republic',1.5,50,5.0,
 'Parejo','La Barba Cigars','Robusto',
 'Ecuador Connecticut-dekkblad med Corojo Ligero og HVA Secco. Lett og upåklagelig — espresso, vanilje, fløte, salt og jord. Light+.',
 true,'retailer','https://halfwheel.com/ipcpr-2016-la-barba-cigar-co/126021/',now(),
 ARRAY['Siempre','La Barba Siempre','Siempre Tamboril']),
('La Barba','Siempre','Toro','Ecuador','Connecticut','Dominican Republic',1.5,50,6.0,
 'Parejo','La Barba Cigars','Toro',
 'Ecuador Connecticut-dekkblad med Corojo Ligero og HVA Secco. Lett og upåklagelig — espresso, vanilje, fløte, salt og jord. Light+.',
 true,'retailer','https://halfwheel.com/ipcpr-2016-la-barba-cigar-co/126021/',now(),
 ARRAY['Siempre','La Barba Siempre','Siempre Tamboril']),
('La Barba','Siempre','Double Toro','Ecuador','Connecticut','Dominican Republic',1.5,60,6.0,
 'Parejo','La Barba Cigars','Double Toro',
 'Ecuador Connecticut-dekkblad med Corojo Ligero og HVA Secco. Lett og upåklagelig — espresso, vanilje, fløte, salt og jord. Light+.',
 true,'retailer','https://halfwheel.com/ipcpr-2016-la-barba-cigar-co/126021/',now(),
 ARRAY['Siempre','La Barba Siempre','Siempre Tamboril']);
