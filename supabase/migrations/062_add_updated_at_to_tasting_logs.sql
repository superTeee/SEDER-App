-- ============================================================
-- 062_add_updated_at_to_tasting_logs.sql
--
-- FIKS: "column updated_at of relation tasting_logs does not exist" (42703)
-- ved redigering av en journal-logg.
--
-- Rotårsak: RPC-en update_own_tasting_log (migrasjon 060) setter
-- updated_at = NOW(), men kolonnen ble aldri lagt til på tasting_logs.
--
-- Løsning: legg til updated_at-kolonnen (default now() så eksisterende
-- rader får en verdi).
-- ============================================================

alter table tasting_logs
  add column if not exists updated_at timestamptz default now();
