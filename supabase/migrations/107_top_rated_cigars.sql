-- 107_top_rated_cigars.sql
--
-- «Brukernes topp 3» var i praksis ikke brukerdrevet: den sorterte cigars.avg_rating,
-- som for mange rader er satt fra import/seed — ikke fra brukere. Flere topp-treff
-- hadde 0 reelle stemmer (f.eks. Padrón 1926 på 9.5, Liga No. 9 Toro på 9.6).
--
-- Denne RPC-en regner snittet direkte fra tasting_logs (ekte brukerratinger) og
-- krever et minimum antall stemmer. Dermed faller seed-radene ut, og listen blir
-- faktisk brukerdrevet. Terskelen er en parameter: hev den etter hvert som
-- brukermassen vokser (i dag har ingen sigar >1 stemme, så p_min_votes = 1).

create or replace function top_rated_cigars(
  p_limit     int default 3,
  p_min_votes int default 1
)
returns setof cigars
language sql
stable
security definer
set search_path = public
as $$
  select c.*
  from cigars c
  join (
    select cigar_id,
           avg(rating)::numeric as snitt,
           count(*)             as antall
    from tasting_logs
    where rating is not null
    group by cigar_id
    having count(*) >= greatest(p_min_votes, 1)
  ) r on r.cigar_id = c.id
  where coalesce(c.is_public, true) = true
  order by r.snitt desc, r.antall desc
  limit p_limit;
$$;

grant execute on function top_rated_cigars(int, int) to authenticated, anon;
