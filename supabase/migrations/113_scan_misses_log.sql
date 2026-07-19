-- 113_scan_misses_log
-- Logg over skanninger som IKKE ga treff (verken lokalt søk eller AI-fallback).
-- Driver alias-kampanjen fra reelle bommer: vi ser nøyaktig hvilke bånd som
-- feiler ute hos brukerne og legger aliaser der det faktisk trengs.
-- Lagrer kun OCR-teksten fra båndet + AI-gjetningene — ingen persondata.

create table if not exists public.scan_misses (
  id uuid primary key default gen_random_uuid(),
  ocr_text text,
  guesses jsonb,
  match_count int not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists scan_misses_created_idx on public.scan_misses (created_at desc);

-- RLS på: ingen policyer betyr at kun service_role (edge-funksjonen) kan skrive,
-- og lesing skjer utelukkende via den admin-gatede RPC-en under.
alter table public.scan_misses enable row level security;

-- Admin-liste: grupperer på normalisert OCR-tekst, teller opp, nyeste først.
create or replace function public.admin_scan_misses()
returns table (ocr_text text, antall bigint, sist timestamptz)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'ikke autorisert';
  end if;

  return query
  select lower(btrim(coalesce(sm.ocr_text, ''))) as ocr_text,
         count(*)          as antall,
         max(sm.created_at) as sist
  from public.scan_misses sm
  where coalesce(btrim(sm.ocr_text), '') <> ''
  group by lower(btrim(coalesce(sm.ocr_text, '')))
  order by count(*) desc, max(sm.created_at) desc
  limit 200;
end;
$$;

grant execute on function public.admin_scan_misses() to authenticated;
