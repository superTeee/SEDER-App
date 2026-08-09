-- 162: Distinkte feltverdier for autocomplete (land, dekkblad, vitola ...).
-- Brukes i «Legg til sigar» så alle felt som kan kobles til basen får forslag.
-- Whitelist av felt + verdien sendes parameterisert ($1) = trygt mot injection.
create or replace function public.distinct_cigar_values(
  p_field text,
  p_query text default '',
  p_limit int default 8
)
returns setof text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  q text := coalesce(p_query, '');
begin
  if p_field not in ('country_origin','wrapper_leaf','vitola','binder','shape') then
    return;
  end if;
  return query execute format(
    'select distinct %1$I from public.cigars
       where %1$I is not null and btrim(%1$I) <> ''''
         and coalesce(is_public, true) = true
         and ($1 = '''' or %1$I ilike ''%%'' || $1 || ''%%'')
     order by %1$I
     limit %2$s',
    p_field, greatest(1, least(p_limit, 20))
  ) using q;
end $$;

grant execute on function public.distinct_cigar_values(text, text, int) to authenticated, anon;
