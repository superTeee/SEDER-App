-- Migration 009: Normaliser bulk-importert sigardata (REST API)
--
-- Bakgrunn: Et bulk-datasett med 596 sigarer fra 50 merker ble importert
-- 2026-06-20 med manufacturer = NULL for alle rader. Dette overlappet
-- fullstendig (og med bedre dekning) med de manuelt seedede Padron- og
-- Arturo Fuente-migrasjonene (007 og 008). Beslutning: bulk-datasettet er
-- hovedkilde for disse to merkene fremover. De manuelle radene fjernes,
-- og manufacturer-feltet normaliseres for alle bulk-rader slik at det
-- følger samme mønster som resten av databasen (manufacturer = brand).

-- 1. Fjern manuelt seedede Padron-rader (migrasjon 007) - dekket og erstattet av bulk-data
delete from cigars where manufacturer = 'Padron';

-- 2. Fjern manuelt seedede Arturo Fuente-rader (migrasjon 008) - dekket og erstattet av bulk-data
delete from cigars where manufacturer = 'Arturo Fuente';

-- 3. Normaliser aksent: 'Padrón' -> 'Padron' for konsistens med resten av databasen
--    og for at OCR/alias-basert søk (som typisk ikke inkluderer aksenter) skal fungere
update cigars
set brand = 'Padron'
where manufacturer is null and brand = 'Padrón';

-- 4. Fyll manufacturer-feltet på alle resterende bulk-rader (manufacturer = brand)
update cigars
set manufacturer = brand
where manufacturer is null;

-- Sanity check
do $
declare
  null_cnt int;
  padron_cnt int;
  fuente_cnt int;
  total_cnt int;
begin
  select count(*) into null_cnt from cigars where manufacturer is null;
  if null_cnt <> 0 then
    raise exception 'Forventet 0 rader med manufacturer = NULL, fant %', null_cnt;
  end if;

  select count(*) into padron_cnt from cigars where manufacturer = 'Padron';
  if padron_cnt <> 102 then
    raise exception 'Forventet 102 Padron-rader (bulk), fant %', padron_cnt;
  end if;

  select count(*) into fuente_cnt from cigars where manufacturer = 'Arturo Fuente';
  if fuente_cnt <> 85 then
    raise exception 'Forventet 85 Arturo Fuente-rader (bulk), fant %', fuente_cnt;
  end if;

  select count(*) into total_cnt from cigars;
  raise notice 'Normalisering fullført. Totalt antall sigarer i databasen: %', total_cnt;
end $;
