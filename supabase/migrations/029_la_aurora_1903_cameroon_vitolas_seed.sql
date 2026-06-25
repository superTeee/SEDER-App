-- ============================================================
-- 029_la_aurora_1903_cameroon_vitolas_seed.sql
--
-- La Aurora 1903 Cameroon fantes allerede med én rad (Robusto).
-- Serien mangler dekning for resten av vitolaene i linjen.
-- Legger til Churchill, Toro, Corona og Petit Robusto.
--
-- 1903 Cameroon: Cameroon-dekkblad, dominikansk bind og innmat.
-- Medium-full styrke, kjent for nøtter, lær, krydder og seder.
--
-- Kilde: cigaraficionado.com, halfwheel.com, gothamcigars.com
-- ============================================================

insert into cigars (
  manufacturer, brand, series, vitola, common_format,
  ring_gauge, length_inches, shape,
  body_type, head_type, foot_type,
  wrapper_country, wrapper_leaf, binder, filler,
  country_origin, strength, price_range,
  description, flavor_notes
) values
(
  'La Aurora','La Aurora','1903 Cameroon','Churchill','Churchill',
  48,7.0,'Parejo',
  'Parejo','Round','Open',
  'Cameroon','Cameroon','Dominican Republic',array['Dominican Republic'],
  'Dominican Republic',3,null,
  'La Aurora 1903 Cameroon Churchill er den lengste varianten i serien — et langsamt, komplekst røyk med Cameroon-dekkbladets karakteristiske krydder og nøttemyk karakter.',
  array['cedar','leather','nuts','cinnamon','earth']
),
(
  'La Aurora','La Aurora','1903 Cameroon','Toro','Toro',
  52,6.0,'Parejo',
  'Parejo','Round','Open',
  'Cameroon','Cameroon','Dominican Republic',array['Dominican Republic'],
  'Dominican Republic',3,null,
  'La Aurora 1903 Cameroon Toro er det mellomstore formatet i serien — et balansert og tilgjengelig røyk med Cameroon-dekkbladets nøttete, jordnære profil.',
  array['nuts','cedar','earth','leather','pepper']
),
(
  'La Aurora','La Aurora','1903 Cameroon','Corona','Corona',
  42,5.5,'Parejo',
  'Parejo','Round','Open',
  'Cameroon','Cameroon','Dominican Republic',array['Dominican Republic'],
  'Dominican Republic',3,null,
  'La Aurora 1903 Cameroon Corona er den slankeste varianten — en konsentrert, aromatisk røyk med Cameroon-dekkbladets typiske krydder og sedernotater.',
  array['cedar','cinnamon','nuts','earth','leather']
),
(
  'La Aurora','La Aurora','1903 Cameroon','Petit Robusto','Petit Robusto',
  50,4.0,'Parejo',
  'Parejo','Round','Open',
  'Cameroon','Cameroon','Dominican Republic',array['Dominican Republic'],
  'Dominican Republic',3,null,
  'La Aurora 1903 Cameroon Petit Robusto er den korteste og kompakteste varianten — rask røyk med full Cameroon-karakter konsentrert i et lite format.',
  array['nuts','earth','leather','cedar','spice']
);
