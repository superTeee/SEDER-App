-- 030_vega_fina_alias_and_vitolas_seed.sql
-- Vega Fina-båndet viser logoen "VF" i stedet for fullt merkenavn.
-- OCR leser "VF" + "Nicaragua" — men "VF" er ikke i search_vector.
-- Fix 1: alias "VF" → Vega Fina (fanges av raw_text ILIKE-oppslaget i search_cigars_ranked).
-- Fix 2: legg til manglende vitolas for Vega Fina Nicaragua og Classic.

-- Alias
insert into cigar_aliases (brand, series, alias)
values
  ('Vega Fina', null, 'VF')
on conflict do nothing;

-- Vega Fina Nicaragua — manglende vitolas (Toro finnes allerede)
insert into cigars (
  manufacturer, brand, series, vitola, common_format,
  ring_gauge, length, shape,
  body_type, head_type, foot_type,
  wrapper, binder, filler,
  country_of_origin,
  strength, price_range,
  flavor_description, flavor_notes
) values
  ('Altadis U.S.A.', 'Vega Fina', 'Nicaragua', 'Robusto', 'Robusto',
   50, 5.0, 'Parejo', null, null, null,
   'Nicaragua', 'Habano', 'Nicaragua',
   'Nicaragua',
   3, '$4-6',
   'Vega Fina Nicaragua Robusto er det korteste og kompakteste formatet i serien — full av nicaraguansk krydder og mørk sjokolade.',
   array['black pepper','dark chocolate','cedar','earth','spice']),

  ('Altadis U.S.A.', 'Vega Fina', 'Nicaragua', 'Churchill', 'Churchill',
   48, 7.0, 'Parejo', null, null, null,
   'Nicaragua', 'Habano', 'Nicaragua',
   'Nicaragua',
   3, '$4-6',
   'Vega Fina Nicaragua Churchill er det lengste formatet — en lang, behagelig røyk med nicaraguansk dybde og pepper.',
   array['black pepper','cedar','dark chocolate','leather','earth']),

  ('Altadis U.S.A.', 'Vega Fina', 'Nicaragua', 'Torpedo', 'Torpedo',
   52, 6.0, 'Torpedo', null, null, null,
   'Nicaragua', 'Habano', 'Nicaragua',
   'Nicaragua',
   3, '$4-6',
   'Torpedo-varianten av Vega Fina Nicaragua har en smalere hode som konsentrerer smakene.',
   array['black pepper','espresso','dark chocolate','cedar','earth']),

-- Vega Fina Classic — manglende vitolas (Robusto finnes allerede)
  ('Altadis U.S.A.', 'Vega Fina', 'Classic', 'Toro', 'Toro',
   52, 6.0, 'Parejo', null, null, null,
   'Ecuador', 'Connecticut', 'Dominican Republic',
   'Dominican Republic',
   2, '$4-6',
   'Vega Fina Classic Toro er mild og kremet — et lengre format av den silkeglattet Ecuador Connecticut-varianten.',
   array['cream','cedar','nuts','sweet spice','hay']),

  ('Altadis U.S.A.', 'Vega Fina', 'Classic', 'Churchill', 'Churchill',
   48, 7.0, 'Parejo', null, null, null,
   'Ecuador', 'Connecticut', 'Dominican Republic',
   'Dominican Republic',
   2, '$4-6',
   'Vega Fina Classic Churchill er den lengste og mildeste varianten i Classic-linjen.',
   array['cream','cedar','nuts','hay','sweet spice'])

on conflict do nothing;
