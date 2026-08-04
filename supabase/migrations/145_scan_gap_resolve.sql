-- 145: Fjern bom fra arbeidslista UTEN å slette skann-historikken.
-- Bug: «Slett»/«Publisert» kalte admin_delete_scan_gap som slettet scan_events-rader,
-- slik at treffrate/skann/bom (admin_scan_hitrate teller ALLE hendelser) endret seg.
-- Nå markerer vi bommen som «resolved» i stedet: den forsvinner fra bom-lista, men
-- historikken (og dermed statistikken) står urørt. Nye skann av samme tekst dukker
-- opp igjen automatisk (de får resolved_at = null).

-- 1) Nytt felt.
ALTER TABLE public.scan_events
  ADD COLUMN IF NOT EXISTS resolved_at timestamptz;

-- 2) Bom-lista utelater nå «resolved» hendelser.
CREATE OR REPLACE FUNCTION public.admin_scan_gaps(p_days integer DEFAULT 30, p_limit integer DEFAULT 50)
 RETURNS TABLE(norm_text text, sample_ocr text, misses bigint, last_seen timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
      and e.resolved_at is null
      and e.created_at > now() - make_interval(days => p_days)
    group by e.norm_text
    order by misses desc, last_seen desc
    limit p_limit;
end
$function$;

-- 3) Ny «løs opp»-funksjon: skjuler bommen fra lista uten å slette noe.
CREATE OR REPLACE FUNCTION public.admin_resolve_scan_gap(p_norm_text text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  n integer;
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;
  update public.scan_events
     set resolved_at = now()
   where norm_text = p_norm_text
     and hit = false
     and resolved_at is null;
  get diagnostics n = row_count;
  return n;
end
$function$;
