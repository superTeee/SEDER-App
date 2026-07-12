-- 104_condega_nicarao.sql
--
-- To nye merker fra dekningshull-lista, verifisert mot produsent.
-- Condega: 17 vitolaer / 3 serier.  Nicarao: 17 vitolaer / 3 linjer.
--
--
-- CONDEGA — condegacigar.com (Casa Fernández / Aganorsa, Estelí)
--
-- Serverrendret WordPress. Målene står som LENGDE × RINGMÅL, med full blend per
-- serie (dekkblad/omblad/innmat). Nicaraguansk puro. Siden er geo-blokkert i
-- nettleseren (403), men tilgjengelig via server-fetch.
-- Serie F rommer også Arsenio Edición Especial og en Maduro med egne blends.
--
--
-- NICARAO — nicaraocigars.com (Nicaraguansk puro)
--
-- Serverrendret. Hver vitola oppgitt både i mm og tommer «[5 x 42]» =
-- LENGDE × RINGMÅL. Tre linjer med økende bladlagring: Clasico (Habano Rosado),
-- Especial (Rosado Oscuro), Exclusivo (Maduro Natural). Omblad/innmat er
-- «Nicaraguansk puro» men ikke tallfestet per blad → binder/filler står tomme.
--
--
-- REPOSADO 96 (utelatt)
--
-- Var med i puljen, men er et rent Cigars International-husmerke (AJ Fernández)
-- uten egen produsentkatalog. Kan ikke verifiseres mot produsent — hoppet over.

-- Condega (Casa Fernández / Aganorsa, Estelí, Nicaragua)
insert into cigars
  (brand, series, vitola, ring_gauge, length_inches, shape, body_type,
   cross_section, wrapper_leaf, binder, filler, country_origin, source_url,
   verified_at, source_tier, is_public)
values
  ('Condega','Serie F','Perla',40,4,'Parejo',NULL,NULL,'Corojo 99','Corojo 99',ARRAY['Criollo 98','Corojo 99']::text[],'Nicaragua','https://condegacigar.com/serie-f/',now(),'manufacturer',true),
  ('Condega','Serie F','Juanito',46,4.5,'Parejo',NULL,NULL,'Corojo 99','Corojo 99',ARRAY['Criollo 98','Corojo 99']::text[],'Nicaragua','https://condegacigar.com/serie-f/',now(),'manufacturer',true),
  ('Condega','Serie F','Mini Robusto',50,4.5,'Parejo',NULL,NULL,'Corojo 99','Corojo 99',ARRAY['Criollo 98','Corojo 99']::text[],'Nicaragua','https://condegacigar.com/serie-f/',now(),'manufacturer',true),
  ('Condega','Serie F','Mini Titán',60,4.5,'Parejo',NULL,NULL,'Corojo 99','Corojo 99',ARRAY['Criollo 98','Corojo 99']::text[],'Nicaragua','https://condegacigar.com/serie-f/',now(),'manufacturer',true),
  ('Condega','Serie F','Mareva',42,5,'Parejo',NULL,NULL,'Corojo 99','Corojo 99',ARRAY['Criollo 98','Corojo 99']::text[],'Nicaragua','https://condegacigar.com/serie-f/',now(),'manufacturer',true),
  ('Condega','Serie F','Robusto',50,5.5,'Parejo',NULL,NULL,'Corojo 99','Corojo 99',ARRAY['Criollo 98','Corojo 99']::text[],'Nicaragua','https://condegacigar.com/serie-f/',now(),'manufacturer',true),
  ('Condega','Serie F','Gran Titán',60,6,'Parejo',NULL,NULL,'Corojo 99','Corojo 99',ARRAY['Criollo 98','Corojo 99']::text[],'Nicaragua','https://condegacigar.com/serie-f/',now(),'manufacturer',true),
  ('Condega','Serie F','Magnum',52,6,'Parejo',NULL,NULL,'Corojo 99','Corojo 99',ARRAY['Criollo 98','Corojo 99']::text[],'Nicaragua','https://condegacigar.com/serie-f/',now(),'manufacturer',true),
  ('Condega','Serie F','Pirámide',52,6.25,'Figurado','Pirámide',NULL,'Corojo 99','Corojo 99',ARRAY['Criollo 98','Corojo 99']::text[],'Nicaragua','https://condegacigar.com/serie-f/',now(),'manufacturer',true),
  ('Condega','Serie F','Lancero',40,7,'Parejo',NULL,NULL,'Corojo 99','Corojo 99',ARRAY['Criollo 98','Corojo 99']::text[],'Nicaragua','https://condegacigar.com/serie-f/',now(),'manufacturer',true),
  ('Condega','Serie F','Arsenio Edición Especial',50,5.5,'Parejo',NULL,NULL,'Corojo 99','Nicaragua',ARRAY['Nicaragua']::text[],'Nicaragua','https://condegacigar.com/serie-f/',now(),'manufacturer',true),
  ('Condega','Serie F','Maduro',50,5,'Parejo',NULL,NULL,'San Andrés Maduro','Aganorsa',ARRAY['Aganorsa']::text[],'Nicaragua','https://condegacigar.com/serie-f/',now(),'manufacturer',true),
  ('Condega','Serie S','Half Corona',44,4,'Parejo',NULL,NULL,'Corojo','Seco Jalapa',ARRAY['Corojo Condega Estelí']::text[],'Nicaragua','https://condegacigar.com/serie-s/',now(),'manufacturer',true),
  ('Condega','Serie S','Short Robusto',52,4,'Parejo',NULL,NULL,'Corojo','Seco Jalapa',ARRAY['Corojo Condega Estelí']::text[],'Nicaragua','https://condegacigar.com/serie-s/',now(),'manufacturer',true),
  ('Condega','Serie S','Robusto',52,5,'Parejo',NULL,NULL,'Corojo','Seco Jalapa',ARRAY['Corojo Condega Estelí']::text[],'Nicaragua','https://condegacigar.com/serie-s/',now(),'manufacturer',true),
  ('Condega','Serie S','Magnum 52',52,6,'Parejo',NULL,NULL,'Corojo','Seco Jalapa',ARRAY['Corojo Condega Estelí']::text[],'Nicaragua','https://condegacigar.com/serie-s/',now(),'manufacturer',true),
  ('Condega','Volcanes','Cerro Negro',52,6.75,'Figurado','Doble Figurado','Box Pressed','Sungrown','Nicaragua',ARRAY['Nicaragua']::text[],'Nicaragua','https://condegacigar.com/volcanes/',now(),'manufacturer',true);

-- Nicarao (Nicaraguansk puro; mål oppgitt i tommer [L x R])
insert into cigars
  (brand, series, vitola, ring_gauge, length_inches, shape, body_type,
   wrapper_leaf, country_origin, source_url, verified_at, source_tier, is_public)
values
  ('Nicarao','Clasico','Minuto',42,5,'Parejo',NULL,'Habano Rosado','Nicaragua','https://nicaraocigars.com/en/nicarao-clasico.php',now(),'manufacturer',true),
  ('Nicarao','Clasico','Juanito',46,4.5,'Parejo',NULL,'Habano Rosado','Nicaragua','https://nicaraocigars.com/en/nicarao-clasico.php',now(),'manufacturer',true),
  ('Nicarao','Clasico','Gordito',50,4.125,'Parejo',NULL,'Habano Rosado','Nicaragua','https://nicaraocigars.com/en/nicarao-clasico.php',now(),'manufacturer',true),
  ('Nicarao','Clasico','Robusto',52,5,'Parejo',NULL,'Habano Rosado','Nicaragua','https://nicaraocigars.com/en/nicarao-clasico.php',now(),'manufacturer',true),
  ('Nicarao','Clasico','Pirámide',52,6,'Figurado','Pirámide','Habano Rosado','Nicaragua','https://nicaraocigars.com/en/nicarao-clasico.php',now(),'manufacturer',true),
  ('Nicarao','Clasico','Julieta',50,7,'Parejo',NULL,'Habano Rosado','Nicaragua','https://nicaraocigars.com/en/nicarao-clasico.php',now(),'manufacturer',true),
  ('Nicarao','Especial','Hermoso',48,5.5,'Parejo',NULL,'Habano Rosado Oscuro','Nicaragua','https://nicaraocigars.com/en/nicarao-especial.php',now(),'manufacturer',true),
  ('Nicarao','Especial','Torito',54,4.5,'Parejo',NULL,'Habano Rosado Oscuro','Nicaragua','https://nicaraocigars.com/en/nicarao-especial.php',now(),'manufacturer',true),
  ('Nicarao','Especial','Gordo',56,5,'Parejo',NULL,'Habano Rosado Oscuro','Nicaragua','https://nicaraocigars.com/en/nicarao-especial.php',now(),'manufacturer',true),
  ('Nicarao','Especial','Toro',52,6,'Parejo',NULL,'Habano Rosado Oscuro','Nicaragua','https://nicaraocigars.com/en/nicarao-especial.php',now(),'manufacturer',true),
  ('Nicarao','Especial','Toro Doble',58,5.5,'Parejo',NULL,'Habano Rosado Oscuro','Nicaragua','https://nicaraocigars.com/en/nicarao-especial.php',now(),'manufacturer',true),
  ('Nicarao','Exclusivo','Romeo',54,5,'Parejo',NULL,'Habano Maduro Natural','Nicaragua','https://nicaraocigars.com/en/nicarao-exclusivo.php',now(),'manufacturer',true),
  ('Nicarao','Exclusivo','Robusto',58,5.5,'Parejo',NULL,'Habano Maduro Natural','Nicaragua','https://nicaraocigars.com/en/nicarao-exclusivo.php',now(),'manufacturer',true),
  ('Nicarao','Exclusivo','Don Rafa',54,7,'Parejo',NULL,'Habano Maduro Natural','Nicaragua','https://nicaraocigars.com/en/nicarao-exclusivo.php',now(),'manufacturer',true),
  ('Nicarao','Exclusivo','Rodolfo',54,7,'Parejo',NULL,'Habano Maduro Natural','Nicaragua','https://nicaraocigars.com/en/nicarao-exclusivo.php',now(),'manufacturer',true),
  ('Nicarao','Exclusivo','Salomón',58,7.125,'Figurado','Salomón','Habano Maduro Natural','Nicaragua','https://nicaraocigars.com/en/nicarao-exclusivo.php',now(),'manufacturer',true),
  ('Nicarao','Exclusivo','Diadema',55,9.2,'Figurado','Diadema','Habano Maduro Natural','Nicaragua','https://nicaraocigars.com/en/nicarao-exclusivo.php',now(),'manufacturer',true);
