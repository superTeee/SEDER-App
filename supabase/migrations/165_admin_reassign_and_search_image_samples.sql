-- 165: Admin kan flytte et bildeprøve til riktig sigar (behold embedding —
-- fingeravtrykket beskriver båndets utseende, uavhengig av etiketten), og søke
-- opp mål-sigaren. Begge is_admin()-beskyttet.

create or replace function public.admin_reassign_image_sample(p_id uuid, p_cigar_id uuid)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not is_admin() then
    raise exception 'not authorized';
  end if;
  update cigar_image_samples set cigar_id = p_cigar_id where id = p_id;
  return found;
end;
$$;

create or replace function public.admin_search_cigars(p_query text, p_limit int default 20)
returns table(id uuid, cigar_navn text, brand text)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    c.id,
    trim(both ' ' from concat_ws(' ', c.brand, c.series, c.vitola)) as cigar_navn,
    c.brand
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
$$;

grant execute on function public.admin_reassign_image_sample(uuid, uuid) to authenticated, anon;
grant execute on function public.admin_search_cigars(text, int) to authenticated, anon;
