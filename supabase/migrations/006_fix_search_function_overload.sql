-- ============================================================
-- 006_fix_search_function_overload.sql
--
-- BUG: "Søket feilet" i appen ("Legg til manuelt" / scan-søk).
--
-- Årsak: 004_brand_hierarchy.sql brukte
--   create or replace function search_cigars_ranked(search_query text, raw_text text default null)
-- for å utvide søkefunksjonen fra 002_ranked_search.sql, som hadde
-- signaturen search_cigars_ranked(search_query text) — KUN ett argument.
--
-- I Postgres erstatter "create or replace function" kun en funksjon med
-- NØYAKTIG samme argumentliste (type og antall). Siden 004 la til et nytt
-- argument (selv med default-verdi), ble dette en ny, overlappende
-- funksjon i stedet for en erstatning. Resultat: TO funksjoner med samme
-- navn lå i databasen samtidig:
--   1) search_cigars_ranked(search_query text)
--   2) search_cigars_ranked(search_query text, raw_text text default null)
--
-- PostgREST (som app-koden bruker via .rpc()) kan ikke skille disse når
-- den kalles med kun "search_query" (siden raw_text har en default-verdi,
-- matcher kallet BÅDE funksjon 1 og funksjon 2) — den returnerer feilen
-- PGRST203 "Could not choose the best candidate function". Dette er det
-- som vises i appen som "Søket feilet. Sjekk internettforbindelsen og
-- prøv igjen." (selv om internett fungerer helt fint).
--
-- Bekreftet empirisk 2026-06-20: kall med {search_query, raw_text} -> 200 OK,
-- kall med kun {search_query} -> 300 PGRST203.
--
-- FIX: dropp den gamle 1-argument-funksjonen. Kun 2-argument-versjonen
-- (med raw_text default null, alias-søk) skal eksistere fremover.
-- ============================================================

drop function if exists public.search_cigars_ranked(text);

-- Sikkerhetsnett: bekreft at det nå kun finnes ÉN funksjon med dette navnet.
do $$
declare
  cnt int;
begin
  select count(*) into cnt
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'search_cigars_ranked';

  if cnt <> 1 then
    raise exception 'Forventet nøyaktig 1 search_cigars_ranked-funksjon, fant %', cnt;
  end if;
end $$;
