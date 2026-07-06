-- ============================================================
-- 064_profile_favorites.sql
--
-- RPC som aggregerer brukerens "smaksprofil" fra loggførte sigarer
-- (tasting_logs joinet mot cigars). Returnerer én rad med 9 favoritter.
--
-- Definisjon:
--   Favorittsigar = høyest gjennomsnittlig score (hybrid), tie-break på antall.
--   Resten        = mest loggført (mode), NULL-verdier ignoreres.
-- Tom logg → alle felt er NULL (appen viser "Kommer når du logger").
-- ============================================================

create or replace function public.get_own_profile_favorites()
returns table (
  favorite_cigar_id    uuid,
  favorite_cigar       text,
  favorite_cigar_score int,
  favorite_brand       text,
  favorite_vitola      text,
  favorite_country     text,
  favorite_wrapper     text,
  favorite_binder      text,
  favorite_filler      text,
  favorite_flavor      text,
  favorite_strength    numeric
)
language sql
security definer
set search_path = public
as $$
  with logs as (
    select tl.rating, c.*
    from tasting_logs tl
    join cigars c on c.id = tl.cigar_id
    where tl.user_id = auth.uid()
  ),
  fav_cigar as (
    select id,
           nullif(trim(concat_ws(' ', brand, series)), '') as name,
           round(avg(rating))::int as score
    from logs
    group by id, brand, series
    order by avg(rating) desc nulls last, count(*) desc
    limit 1
  ),
  fav_brand as (
    select brand as v from logs where brand is not null
    group by brand order by count(*) desc limit 1
  ),
  fav_vitola as (
    select vitola as v from logs where vitola is not null
    group by vitola order by count(*) desc limit 1
  ),
  fav_country as (
    select country_origin as v from logs where country_origin is not null
    group by country_origin order by count(*) desc limit 1
  ),
  fav_wrapper as (
    select wrapper_leaf as v from logs where wrapper_leaf is not null
    group by wrapper_leaf order by count(*) desc limit 1
  ),
  fav_binder as (
    select binder as v from logs where binder is not null
    group by binder order by count(*) desc limit 1
  ),
  fav_filler as (
    select f as v from (select unnest(filler) as f from logs) x
    where f is not null group by f order by count(*) desc limit 1
  ),
  fav_flavor as (
    select fn as v from (select unnest(flavor_notes) as fn from logs) x
    where fn is not null group by fn order by count(*) desc limit 1
  ),
  fav_strength as (
    select strength as v from logs where strength is not null
    group by strength order by count(*) desc limit 1
  )
  select
    (select id    from fav_cigar),
    (select name  from fav_cigar),
    (select score from fav_cigar),
    (select v from fav_brand),
    (select v from fav_vitola),
    (select v from fav_country),
    (select v from fav_wrapper),
    (select v from fav_binder),
    (select v from fav_filler),
    (select v from fav_flavor),
    (select v from fav_strength);
$$;

grant execute on function public.get_own_profile_favorites() to authenticated;
