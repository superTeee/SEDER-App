-- 133: La Barba — fyll inn faktiske størrelser per linje.
-- Produsenten (labarbacigars.com) publiserer IKKE mål, så størrelsene er hentet fra
-- presse-/forhandlerkilder og markeres source_tier='retailer' (jf. regel: forhandler
-- tillatt når merket eksplisitt godkjennes). Alle linjer rulles hos Tabacalera William
-- Ventura i Den dominikanske republikk.
--   Red      (cigars.com):  Corona 5¾×46, Toro 6×54, Petite Lancero 6½×40
--   Purple   (cigar-coop):  Robusto 5×50, Corona Gorda 5¾×46, Toro 6×54, Magnum 6×60, Lancero 7×40
--   One&Only (halfwheel):   Toro 6×50 (limited, 500 esker)
-- Placeholder-radene fra 132 (vitola NULL) oppgraderes til flaggskip-vitolaen (beholder
-- id + evt. skann-referanser), resten legges inn som nye rader. Red «Rothschild» utelatt
-- fordi mål ikke lot seg verifisere — tomt slår gjetning. Blend/dekkblad uendret fra 132.

-- RED: placeholder -> Toro 6×54, + Corona + Petite Lancero
UPDATE public.cigars
SET vitola='Toro', length_inches=6.0, ring_gauge=54, shape='Parejo', common_format='Toro',
    country_origin='Dominican Republic', source_tier='retailer',
    source_url='https://www.cigars.com/embers-insights/article/la-barba-red-cigar-review/',
    verified_at=now()
WHERE brand='La Barba' AND series='Red' AND vitola IS NULL;

INSERT INTO public.cigars
  (brand, series, vitola, wrapper_country, wrapper_leaf, country_origin, strength, ring_gauge,
   length_inches, shape, manufacturer, common_format, description, is_public, source_tier,
   source_url, verified_at, aliases)
VALUES
('La Barba','Red','Corona','Dominican Republic','Corojo','Dominican Republic',3.5,46,5.75,
 'Parejo','La Barba Cigars','Corona',
 'Dominikansk puro med Corojo-dekkblad. Krydret og søtt — graham crackers, sjokolade og ristet marshmallow. Medium+.',
 true,'retailer','https://www.cigars.com/embers-insights/article/la-barba-red-cigar-review/',now(),
 ARRAY['La Barba','Barba','Th Barba']),
('La Barba','Red','Petite Lancero','Dominican Republic','Corojo','Dominican Republic',3.5,40,6.5,
 'Parejo','La Barba Cigars','Petite Lancero',
 'Dominikansk puro med Corojo-dekkblad. Krydret og søtt — graham crackers, sjokolade og ristet marshmallow. Medium+.',
 true,'retailer','https://www.cigars.com/embers-insights/article/la-barba-red-cigar-review/',now(),
 ARRAY['La Barba','Barba','Th Barba']);

-- PURPLE: placeholder -> Robusto 5×50, + Corona Gorda + Toro + Magnum + Lancero
UPDATE public.cigars
SET vitola='Robusto', length_inches=5.0, ring_gauge=50, shape='Parejo', common_format='Robusto',
    country_origin='Dominican Republic', source_tier='retailer',
    source_url='https://cigar-coop.com/2017/10/cigar-review-la-barba-purple-robusto.html',
    verified_at=now()
WHERE brand='La Barba' AND series='Purple' AND vitola IS NULL;

INSERT INTO public.cigars
  (brand, series, vitola, wrapper_country, wrapper_leaf, country_origin, strength, ring_gauge,
   length_inches, shape, manufacturer, common_format, description, is_public, source_tier,
   source_url, verified_at, aliases)
VALUES
('La Barba','Purple','Corona Gorda','Ecuador','Habano','Dominican Republic',2.5,46,5.75,
 'Parejo','La Barba Cigars','Corona Gorda',
 'Ecuadoriansk Habano-dekkblad. Søt, med hvit og sort pepper, floral og elegant. Medium−.',
 true,'retailer','https://cigar-coop.com/2017/10/cigar-review-la-barba-purple-robusto.html',now(),
 ARRAY['La Barba','Barba','Th Barba']),
('La Barba','Purple','Toro','Ecuador','Habano','Dominican Republic',2.5,54,6.0,
 'Parejo','La Barba Cigars','Toro',
 'Ecuadoriansk Habano-dekkblad. Søt, med hvit og sort pepper, floral og elegant. Medium−.',
 true,'retailer','https://cigar-coop.com/2017/10/cigar-review-la-barba-purple-robusto.html',now(),
 ARRAY['La Barba','Barba','Th Barba']),
('La Barba','Purple','Magnum','Ecuador','Habano','Dominican Republic',2.5,60,6.0,
 'Parejo','La Barba Cigars','Magnum',
 'Ecuadoriansk Habano-dekkblad. Søt, med hvit og sort pepper, floral og elegant. Medium−.',
 true,'retailer','https://cigar-coop.com/2017/10/cigar-review-la-barba-purple-robusto.html',now(),
 ARRAY['La Barba','Barba','Th Barba']),
('La Barba','Purple','Lancero','Ecuador','Habano','Dominican Republic',2.5,40,7.0,
 'Parejo','La Barba Cigars','Lancero',
 'Ecuadoriansk Habano-dekkblad. Søt, med hvit og sort pepper, floral og elegant. Medium−.',
 true,'retailer','https://cigar-coop.com/2017/10/cigar-review-la-barba-purple-robusto.html',now(),
 ARRAY['La Barba','Barba','Th Barba']);

-- ONE & ONLY: placeholder -> Toro 6×50 (eneste størrelse, limited)
UPDATE public.cigars
SET vitola='Toro', length_inches=6.0, ring_gauge=50, shape='Parejo', common_format='Toro',
    country_origin='Dominican Republic', source_tier='retailer',
    source_url='https://halfwheel.com/la-barba-one/141960/',
    verified_at=now()
WHERE brand='La Barba' AND series='One & Only' AND vitola IS NULL;
