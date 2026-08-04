-- 140: (1) Marker alle sigarer med kildelenke som verifisert. (2) Gi admin-datahull
-- et ekte totaltall (ikke begrenset til 300) og et søk.

-- (1) Har en lenke, men mangler verified_at -> sett den. Appen viser dem da som bekreftet.
UPDATE public.cigars
SET verified_at = now()
WHERE coalesce(is_public, true) = true
  AND source_url IS NOT NULL AND length(trim(source_url)) > 0
  AND verified_at IS NULL;

-- (2) Datahull med søk. Erstatter den parameterløse funksjonen med én som tar et
-- valgfritt søk (standard null -> uendret oppførsel for gamle app-versjoner).
DROP FUNCTION IF EXISTS public.admin_data_gaps();

CREATE OR REPLACE FUNCTION public.admin_data_gaps(p_search text DEFAULT NULL)
 RETURNS TABLE(id uuid, cigar_navn text, brand text, ring_gauge integer, length_inches numeric, country_origin text, wrapper_leaf text, strength numeric, has_flavor boolean, has_description boolean, missing text[], gap_count integer, source_tier text, verified boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  q text := nullif(btrim(coalesce(p_search, '')), '');
begin
  if not is_admin() then
    raise exception 'ikke autorisert';
  end if;

  return query
  with g as (
    select
      c.id,
      nullif(trim(concat_ws(' ', c.brand, c.series, c.vitola)), '') as cigar_navn,
      c.brand,
      c.ring_gauge,
      c.length_inches,
      c.country_origin,
      c.wrapper_leaf,
      c.strength,
      (c.flavor_notes is not null and array_length(c.flavor_notes, 1) > 0) as has_flavor,
      (c.description is not null and length(trim(c.description)) > 0)       as has_description,
      array_remove(array[
        case when c.ring_gauge is null or c.length_inches is null                   then 'dimensions'  end,
        case when c.country_origin is null or length(trim(c.country_origin)) = 0     then 'origin'       end,
        case when c.wrapper_leaf is null or length(trim(c.wrapper_leaf)) = 0         then 'wrapper'      end,
        case when c.strength is null                                                 then 'strength'     end,
        case when c.flavor_notes is null or array_length(c.flavor_notes, 1) is null  then 'flavor'       end,
        case when c.description is null or length(trim(c.description)) = 0           then 'description'  end
      ], null) as missing,
      c.source_tier,
      (c.verified_at is not null) as verified
    from cigars c
    where coalesce(c.is_public, true) = true
  )
  select
    g.id, g.cigar_navn, g.brand, g.ring_gauge, g.length_inches,
    g.country_origin, g.wrapper_leaf, g.strength, g.has_flavor, g.has_description,
    g.missing,
    cardinality(g.missing) as gap_count,
    g.source_tier, g.verified
  from g
  where cardinality(g.missing) > 0
    and (q is null or unaccent(coalesce(g.cigar_navn, g.brand, '')) ilike '%' || unaccent(q) || '%')
  order by
    (('dimensions' = any(g.missing))::int) desc,
    cardinality(g.missing) desc,
    g.cigar_navn asc nulls last
  limit 300;
end;
$function$;

-- Ekte totaltall (respekterer søk), uten 300-grensen — til toppen av gap-siden.
CREATE OR REPLACE FUNCTION public.admin_data_gaps_count(p_search text DEFAULT NULL)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  q text := nullif(btrim(coalesce(p_search, '')), '');
  n integer;
begin
  if not is_admin() then
    raise exception 'ikke autorisert';
  end if;

  select count(*)::int into n
  from cigars c
  where coalesce(c.is_public, true) = true
    and (
      c.ring_gauge is null or c.length_inches is null
      or c.country_origin is null or length(trim(c.country_origin)) = 0
      or c.wrapper_leaf is null or length(trim(c.wrapper_leaf)) = 0
      or c.strength is null
      or c.flavor_notes is null or array_length(c.flavor_notes, 1) is null
      or c.description is null or length(trim(c.description)) = 0
    )
    and (q is null or unaccent(coalesce(nullif(trim(concat_ws(' ', c.brand, c.series, c.vitola)),''), c.brand, '')) ilike '%' || unaccent(q) || '%');

  return n;
end;
$function$;
