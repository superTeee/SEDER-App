-- 169_match_cigar_decision.sql
-- Konfidensvurdering av bilde-skann. Returnerer én av fem beslutninger,
-- så appen aldri påstår «X funnet» uten dekning.
--   confident : ett klart treff (band + linje sikker)      -> smal velger
--   brand     : flere treff tett, SAMME merke              -> «X funnet», bred velger (delt bånd)
--   ambiguous : flere treff tett, ULIKE merker             -> still spørsmål, ingen påstand
--   uncertain : beste treff i mellomsjiktet                -> «ser dette ut som X?» (tentativt)
--   none      : ingenting over terskel                     -> manuelt søk
create or replace function public.match_cigar_decision(
  p_embedding text,
  p_high real default 0.85,           -- terskel for å tørre å påstå et merke
  p_cluster_margin real default 0.03, -- hvor tett treff må ligge for å regnes som «uavgjort»
  p_min_similarity real default 0.72,
  p_match_count int default 8
) returns jsonb
language plpgsql stable security definer set search_path to 'public'
as $function$
declare
  v_top real; v_brand text; v_cigar uuid;
  v_cluster_brands int; v_cluster_cigars int;
  v_cands jsonb; v_decision text;
begin
  with q as (select p_embedding::vector(512) as e),
  m as (
    select s.cigar_id,
           max(1 - (s.image_embedding <=> q.e))::real as similarity
    from public.cigar_image_samples s
    join public.cigars c on c.id = s.cigar_id
    cross join q
    where s.image_embedding is not null and coalesce(c.is_public,true)=true
    group by s.cigar_id
    having max(1 - (s.image_embedding <=> q.e)) >= p_min_similarity
    order by similarity desc
    limit p_match_count
  ),
  enr as (
    select m.cigar_id, m.similarity, c.brand, c.series, c.vitola
    from m join public.cigars c on c.id = m.cigar_id
  )
  select
    (select similarity from enr order by similarity desc limit 1),
    (select brand from enr order by similarity desc limit 1),
    (select cigar_id from enr order by similarity desc limit 1),
    count(distinct enr.brand) filter (where enr.similarity >= (select max(similarity) from enr) - p_cluster_margin),
    count(*)                  filter (where enr.similarity >= (select max(similarity) from enr) - p_cluster_margin),
    coalesce(jsonb_agg(jsonb_build_object(
       'cigar_id', enr.cigar_id, 'brand', enr.brand, 'series', enr.series,
       'vitola', enr.vitola, 'similarity', round(enr.similarity::numeric,3)
     ) order by enr.similarity desc), '[]'::jsonb)
  into v_top, v_brand, v_cigar, v_cluster_brands, v_cluster_cigars, v_cands
  from enr;

  if v_top is null then
    return jsonb_build_object('decision','none','candidates','[]'::jsonb);
  end if;

  if v_top < p_high then
    v_decision := 'uncertain';
  elsif v_cluster_brands > 1 then
    v_decision := 'ambiguous';
  elsif v_cluster_cigars > 1 then
    v_decision := 'brand';
  else
    v_decision := 'confident';
  end if;

  return jsonb_build_object(
    'decision', v_decision,
    'top_brand', v_brand,
    'top_cigar_id', v_cigar,
    'top_similarity', round(v_top::numeric,3),
    'cluster_brands', v_cluster_brands,
    'cluster_cigars', v_cluster_cigars,
    'candidates', v_cands
  );
end;
$function$;

grant execute on function public.match_cigar_decision(text,real,real,real,int) to anon, authenticated, service_role;
