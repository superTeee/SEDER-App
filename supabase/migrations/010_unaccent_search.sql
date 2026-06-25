-- Migration 010: Make search permanently accent-insensitive
--
-- Problem: bulk imports brought in accented brand/series names (Padrón, Añejo,
-- Dueña, etc). Migration 009 normalized existing data with unaccent(), but:
--   1. That only fixed `brand`, not `series`/`manufacturer` -> asymmetric search
--   2. It didn't fix the *infrastructure* -> next bulk import with accents
--      would silently reintroduce unsearchable rows.
--
-- Fix: make the search_vector generated column and the search function both
-- accent-insensitive, so accented data is searchable with or without accents,
-- forever (not just for the rows we've manually cleaned today).

create extension if not exists unaccent;

-- unaccent(regdictionary, text) is STABLE, not IMMUTABLE, so it can't be used
-- directly inside a GENERATED ALWAYS AS (...) STORED column expression.
-- Wrap it in our own SQL function and mark it IMMUTABLE (standard, safe
-- workaround: the unaccent dictionary doesn't change at runtime).
create or replace function immutable_unaccent(text) returns text as $$
  select unaccent('unaccent', $1);
$$ language sql immutable;

-- Normalize any remaining accented text in source columns (belt and suspenders
-- on top of migration 009, which only touched `brand`).
update cigars set manufacturer = unaccent(manufacturer) where manufacturer ~ '[^\x00-\x7F]';
update cigars set brand = unaccent(brand) where brand ~ '[^\x00-\x7F]';
update cigars set series = unaccent(series) where series ~ '[^\x00-\x7F]';

-- Rebuild search_vector so it unaccents every source field before indexing.
drop index if exists cigars_search_idx;
alter table cigars drop column search_vector;
alter table cigars add column search_vector tsvector generated always as (
  to_tsvector('english',
    immutable_unaccent(coalesce(manufacturer,'')) || ' ' ||
    immutable_unaccent(coalesce(brand,'')) || ' ' ||
    immutable_unaccent(coalesce(series,'')) || ' ' ||
    immutable_unaccent(coalesce(vitola,'')) || ' ' ||
    immutable_unaccent(coalesce(common_format,''))
  )
) stored;
create index cigars_search_idx on cigars using gin (search_vector);

-- Update search function so a literally-typed accented query (e.g. "padrón")
-- also unaccents before matching against the now-unaccented search_vector.
CREATE OR REPLACE FUNCTION public.search_cigars_ranked(search_query text, raw_text text DEFAULT NULL::text)
RETURNS SETOF cigars
LANGUAGE plpgsql
STABLE
AS $function$
declare
tsq tsquery;
q text;
rt text;
begin
q := immutable_unaccent(coalesce(search_query, ''));
rt := immutable_unaccent(coalesce(raw_text, ''));
begin
tsq := to_tsquery('english', q);
exception when others then
tsq := plainto_tsquery('english', q);
end;

if tsq is null or tsq = ''::tsquery then
return;
end if;

return query
with alias_hits as (
select distinct c.id
from cigars c
join cigar_aliases a
on c.brand = a.brand
and (a.series is null or c.series = a.series)
where raw_text is not null
and rt ilike '%' || immutable_unaccent(a.alias) || '%'
)
select c.*
from cigars c
left join alias_hits h on h.id = c.id
where c.search_vector @@ tsq or h.id is not null
order by
(h.id is not null) desc,
ts_rank(c.search_vector, tsq) desc,
c.avg_rating desc nulls last
limit 100;
end;
$function$;

-- Verification (run manually, not part of migration):
-- select 'padron' t, count(*) from search_cigars_ranked('padron')
-- union all select 'padrón', count(*) from search_cigars_ranked('padr' || chr(243) || 'n');
-- Both should return identical counts.
