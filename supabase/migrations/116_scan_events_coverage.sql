-- 116_scan_events_coverage
-- Steg 1 i dekning-datahjulet: logg HVERT bånd-skann (treff + bom) fra appen,
-- så vi kan måle treffrate og se hvilke sigarer folk skanner som vi IKKE har.
--
-- Utfyller 113_scan_misses (som kun fanger de hardeste bommene via edge-
-- funksjonen). scan_events logges fra appen på ALLE skann → gir treffrate.
-- Applied to prod via MCP apply_migration (scan_events_coverage).

create table if not exists public.scan_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  ocr_text text not null default '',
  norm_text text not null default '',
  hit boolean not null default false,
  matched_cigar_id uuid,
  confidence real,
  created_at timestamptz not null default now()
);

create index if not exists scan_events_norm_idx on public.scan_events (norm_text);
create index if not exists scan_events_created_idx on public.scan_events (created_at desc);

alter table public.scan_events enable row level security;
-- Ingen direkte policies: all skriving går via security-definer RPC under.

-- Normaliserer OCR-tekst til en grupperbar nøkkel (aksent-fri, kun a–z0–9 + mellomrom)
create or replace function public.norm_scan_text(t text)
returns text
language sql
immutable
set search_path = public, extensions
as $$
  select btrim(
    regexp_replace(
      regexp_replace(lower(unaccent(coalesce(t, ''))), '[^a-z0-9 ]', ' ', 'g'),
      '\s+', ' ', 'g'
    )
  )
$$;

-- Loggekall fra appen (fyrer og glemmer). Trygg for alle innloggede.
create or replace function public.log_scan_event(
  p_ocr_text text,
  p_hit boolean,
  p_matched_cigar_id uuid default null,
  p_confidence real default null
)
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.scan_events (user_id, ocr_text, norm_text, hit, matched_cigar_id, confidence)
  values (
    auth.uid(),
    left(coalesce(p_ocr_text, ''), 300),
    public.norm_scan_text(p_ocr_text),
    coalesce(p_hit, false),
    p_matched_cigar_id,
    p_confidence
  );
$$;

grant execute on function public.log_scan_event(text, boolean, uuid, real) to authenticated;

-- Treffrate siste N dager (kun admin)
create or replace function public.admin_scan_hitrate(p_days int default 30)
returns table(total bigint, hits bigint, rate numeric)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;
  return query
    select
      count(*)::bigint,
      count(*) filter (where hit)::bigint,
      round((count(*) filter (where hit))::numeric / nullif(count(*), 0) * 100, 1)
    from public.scan_events
    where created_at > now() - make_interval(days => p_days);
end
$$;

grant execute on function public.admin_scan_hitrate(int) to authenticated;

-- Mest skannede BOM (sigarer vi ikke traff) gruppert på normalisert tekst (kun admin)
create or replace function public.admin_scan_gaps(p_days int default 30, p_limit int default 50)
returns table(norm_text text, sample_ocr text, misses bigint, last_seen timestamptz)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;
  return query
    select
      e.norm_text,
      (array_agg(e.ocr_text order by e.created_at desc))[1] as sample_ocr,
      count(*)::bigint as misses,
      max(e.created_at) as last_seen
    from public.scan_events e
    where e.hit = false
      and e.norm_text <> ''
      and e.created_at > now() - make_interval(days => p_days)
    group by e.norm_text
    order by misses desc, last_seen desc
    limit p_limit;
end
$$;

grant execute on function public.admin_scan_gaps(int, int) to authenticated;
