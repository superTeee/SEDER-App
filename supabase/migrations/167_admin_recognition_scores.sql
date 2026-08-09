-- 167: Gjenkjenningsstyrke per sigar, basert på embeddede bildeprøver.
-- Score = 70% dekning (antall embeddede bilder, metter ved 5) + 30% særpreg
-- (avstand til nærmeste ANDRE sigars fingeravtrykk). is_admin()-beskyttet.

create or replace function public.admin_recognition_scores()
returns table(
  cigar_id uuid, n_embedded int, nearest_rival_navn text,
  nearest_rival_sim real, score int, label text
)
language sql stable security definer set search_path to 'public'
as $$
  with emb as (
    select cigar_id, embedding from cigar_image_samples
    where embedding is not null and cigar_id is not null
  ),
  cnt as (select cigar_id, count(*)::int as n from emb group by cigar_id),
  rival as (
    select e.cigar_id, (1 - (e.embedding <=> nn.embedding))::real as sim, nn.cigar_id as rival_id
    from emb e cross join lateral (
      select o.cigar_id, o.embedding from emb o where o.cigar_id <> e.cigar_id
      order by e.embedding <=> o.embedding limit 1
    ) nn
  ),
  worst as (
    select distinct on (cigar_id) cigar_id, sim, rival_id
    from rival order by cigar_id, sim desc
  ),
  scored as (
    select cnt.cigar_id, cnt.n, w.sim as rival_sim, w.rival_id,
      ( 0.7 * least(cnt.n, 5) / 5.0
        + 0.3 * (case when w.sim is null then 0.6
                      else greatest(0, least(1, ((1 - w.sim) - 0.15) / (0.45 - 0.15))) end)
      ) as raw
    from cnt left join worst w on w.cigar_id = cnt.cigar_id
  )
  select
    s.cigar_id, s.n as n_embedded,
    trim(both ' ' from concat_ws(' ', rc.brand, rc.series, rc.vitola)) as nearest_rival_navn,
    s.rival_sim as nearest_rival_sim,
    greatest(0, least(100, round(100 * s.raw)))::int as score,
    case when round(100 * s.raw) >= 70 then 'Sterk'
         when round(100 * s.raw) >= 35 then 'OK'
         else 'Svak' end as label
  from scored s
  left join cigars rc on rc.id = s.rival_id
  where is_admin()
  order by score asc, n_embedded asc;
$$;

grant execute on function public.admin_recognition_scores() to authenticated, anon;
