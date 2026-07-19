-- 112_casdagli_bots_band_aliases
-- Alias-kampanje, første slice: Casdagli "Brothers of the Sabre".
-- Banderolene viser generalen hver linje hedrer (bekreftet mot casdaglicigars.com):
--   Forrader  -> Blücher (Preussen)
--   Brave     -> Ney (Frankrike)
--   Epicurist -> Lasalle (Frankrike)
--   Vater     -> Radetzky (Østerrike)
-- Alle åtte vitolae stemmer eksakt på mål mot produsentens egne produktsider,
-- så de markeres samtidig som verifisert med kilde-URL.

update cigars c set
  aliases = v.aliases,
  source_url = v.url,
  verified_at = now()
from (values
  ('db39c35d-3ed0-4ba0-bc25-536351dbbe7a'::uuid, array['Blücher','Forrader Blücher'], 'https://casdaglicigars.com/cigar/forrader-piramide/'),
  ('d637f177-adb9-4a9a-a182-9f6cde0bb9ea'::uuid, array['Blücher','Forrader Blücher'], 'https://casdaglicigars.com/cigar/forrader-robusto/'),
  ('a5d6fce2-abed-424d-a1f7-704d547913d9'::uuid, array['Ney','Brave Ney'], 'https://casdaglicigars.com/cigar/brave-piramide/'),
  ('8a59101f-27f8-4396-8258-f8d2965020ef'::uuid, array['Ney','Brave Ney'], 'https://casdaglicigars.com/cigar/brave-robusto/'),
  ('3cad297d-bff9-40fb-af1b-628756e3fe8c'::uuid, array['Lasalle','Epicurist Lasalle'], 'https://casdaglicigars.com/cigar/epicurist-figurado/'),
  ('5e2d1cc9-3af6-45bf-aabf-d81fcc3d9fb8'::uuid, array['Lasalle','Epicurist Lasalle'], 'https://casdaglicigars.com/cigar/epicurist-petit-robusto/'),
  ('e3423f47-baae-4c79-aa10-3bf43fa5da5d'::uuid, array['Radetzky','Vater Radetzky'], 'https://casdaglicigars.com/cigar/vater-figurado/'),
  ('90c9dd71-0b13-4326-a3b4-9f00a52d7ad7'::uuid, array['Radetzky','Vater Radetzky'], 'https://casdaglicigars.com/cigar/vater-petit-robusto/')
) as v(id, aliases, url)
where c.id = v.id;
