-- 142: Én liten RPC til gamification-baren i admin. Gir totalt antall offentlige
-- sigarer og hvor mange som fortsatt har hull — i én spørring, uten søkefilter,
-- så framdriftsbaren viser reell total-framgang uansett hva som er søkt på.
CREATE OR REPLACE FUNCTION public.admin_gap_stats()
 RETURNS TABLE(total_public integer, gap_count integer, complete integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  t integer;
  g integer;
begin
  if not is_admin() then
    raise exception 'ikke autorisert';
  end if;

  select count(*)::int into t
  from cigars c
  where coalesce(c.is_public, true) = true;

  select count(*)::int into g
  from cigars c
  where coalesce(c.is_public, true) = true
    and (
      c.ring_gauge is null or c.length_inches is null
      or c.country_origin is null or length(trim(c.country_origin)) = 0
      or c.wrapper_leaf is null or length(trim(c.wrapper_leaf)) = 0
      or c.strength is null
      or c.flavor_notes is null or array_length(c.flavor_notes, 1) is null
      or c.description is null or length(trim(c.description)) = 0
    );

  total_public := t;
  gap_count := g;
  complete := t - g;
  return next;
end;
$function$;
