-- Migration 052: Madrigal Picador — full lineup (4 bekreftet vitolas)
-- Produsent: Santa Clara Puros (Ortiz-Alvarez-familien, 5 generasjoner)
-- Opprinnelse: San Andres, Veracruz, Mexico
-- Blanding: Capa Fina Rosada San Andres wrapper (2 år), Morron Limpio binder (2 år), long filler (3 år)
-- Styrke: Medium (3/5) | Pris: budsjett

INSERT INTO cigars (
  manufacturer, brand, series, vitola, common_format,
  ring_gauge, length_inches, shape,
  body_type, head_type, foot_type,
  wrapper_country, wrapper_leaf, binder, filler,
  country_origin, strength, price_range,
  description, flavor_notes, avg_rating
)
VALUES
(
  'Santa Clara Puros','Madrigal Picador',NULL,'Short Robusto','Petit Robusto',
  50,3.35,'Parejo',
  null,null,null,
  'Mexico','Capa Fina Rosada San Andres','San Andres Morron Limpio',ARRAY['San Andres'],
  'Mexico',3,'$3-5',
  'Madrigal Picador Short Robusto — den korteste varianten i linjen, ca. 3½"×50. Kompakt og konsentrert dagligsigar fra San Andres-dalen i Veracruz. Ristede kaffetoner og tre i åpningen, lett pepper mot midten. Perfekt for en rask røyk.',
  ARRAY['roasted coffee','cedar','wood','black pepper','earth'],8.0
),
(
  'Santa Clara Puros','Madrigal Picador',NULL,'Robusto','Robusto',
  50,4.5,'Parejo',
  null,null,null,
  'Mexico','Capa Fina Rosada San Andres','San Andres Morron Limpio',ARRAY['San Andres'],
  'Mexico',3,'$3-5',
  'Madrigal Picador Robusto — 4½"×50, flaggskipformatet i Picador-linjen. Håndlaget av tabaquero-mestere i San Andres med 3 år modnet long filler og 2 år modnet dekkblad. Balansert og jevn røyk med kremet tre og kaffe. Eksepsjonell verdi for pengene.',
  ARRAY['cedar','coffee','earth','black pepper','mild cream'],8.1
),
(
  'Santa Clara Puros','Madrigal Picador',NULL,'Corona','Corona',
  50,5.0,'Parejo',
  null,null,null,
  'Mexico','Capa Fina Rosada San Andres','San Andres Morron Limpio',ARRAY['San Andres'],
  'Mexico',3,'$3-5',
  'Madrigal Picador Corona — 5"×50, en romslig Corona med San Andres-tobakk fra Veracruz. Gir litt mer røyketid og bredere smaksutvikling enn Robusto-formen. Kremet treprofil med god kaffedybde og pepper i avslutningen.',
  ARRAY['cedar','coffee','earth','black pepper','wood'],8.1
),
(
  'Santa Clara Puros','Madrigal Picador',NULL,'Churchill','Churchill',
  50,6.0,'Parejo',
  null,null,null,
  'Mexico','Capa Fina Rosada San Andres','San Andres Morron Limpio',ARRAY['San Andres'],
  'Mexico',3,'$4-6',
  'Madrigal Picador Churchill — 6"×50, den lengste varianten med rikelig røyketid. San Andres long filler modnet i 3 år gir gradvis smaksutvikling fra kremet tre mot mer intense kaffe- og peppertoner. Imponerende kvalitet til prisen.',
  ARRAY['cedar','coffee','earth','black pepper','mild spice'],8.2
)
ON CONFLICT DO NOTHING;
