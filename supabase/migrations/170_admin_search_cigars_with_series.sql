-- 170_admin_search_cigars_with_series.sql
-- Utvid admin_search_cigars til å returnere series + vitola, så admin kan
-- gruppere treff per serie/linje (én dropzone per bånd-variant i stedet for
-- per størrelse). Returtypen endres, så funksjonen droppes og gjenskapes.
drop function if exists public.admin_search_cigars(text, integer);

create function public.admin_search_cigars(p_query text, p_limit integer default 20)
returns table(id uuid, cigar_navn text, brand text, series text, vitola text)
language sql stable security definer set search_path to 'public'
as $function$
  select
    c.id,
    trim(both ' ' from concat_ws(' ', c.brand, c.series, c.vitola)) as cigar_navn,
    c.brand,
    c.series,
    c.vitola
  from cigars c
  where is_admin()
    and coalesce(c.is_public, true) = true
    and (
      p_query is null or length(trim(p_query)) = 0
      or (
        select bool_and(concat_ws(' ', c.brand, c.series, c.vitola) ilike '%' || w || '%')
        from unnest(string_to_array(lower(trim(p_query)), ' ')) as w
        where length(w) > 0
      )
    )
  order by c.brand nulls last, c.series nulls last, c.vitola nulls last
  limit greatest(1, least(p_limit, 50));
$function$;

grant execute on function public.admin_search_cigars(text, integer) to authenticated, service_role;
