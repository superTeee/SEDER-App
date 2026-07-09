-- 083_gec_mint_note.sql
-- «mint» har nå eget ikon i appen (FlavorIcons/mint.imageset), så vi kan legge
-- den tilbake på de GEC-blendene der produsenten faktisk beskriver mynte:
--   RVGN            — mynte i røyken og i kald trekk
--   RVGN Extrem     — honning og mynte i dekkbladet, mynte i kald trekk
--   Weltschmerz     — «and some mint» i kald trekk
--   Kraftwerk       — «a minty freshness on the retrohale»
-- Raumzeit har ingen mynte og røres ikke.
-- Idempotent: array_append kun der noten mangler.

update cigars
set flavor_notes = array_append(flavor_notes, 'mint')
where brand = 'German Engineered Cigars'
  and series in ('RVGN Rauchvergnügen', 'RVGN Extrem', 'Weltschmerz', 'Kraftwerk')
  and not ('mint' = any(flavor_notes));
