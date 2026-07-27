-- ============================================================
-- 120_get_user_stats.sql
--
-- Aggregert statistikk for innlogget bruker (avansert statistikk / innsikt-side).
-- Returnerer nøkkeltall + topp merker + score-serie for trend-graf.
-- ============================================================

create or replace function public.get_user_stats()
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid           uuid := auth.uid();
  v_total         int;
  v_brands        int;
  v_avg           int;
  v_strength      numeric;
  v_value         numeric;
  v_top_brands    json;
  v_score_series  json;
begin
  if v_uid is null then raise exception 'not_authenticated'; end if;

  select count(*) into v_total from tasting_logs where user_id = v_uid;

  select count(distinct c.brand) into v_brands
    from tasting_logs tl join cigars c on c.id = tl.cigar_id
    where tl.user_id = v_uid and c.brand is not null;

  select round(avg(rating))::int into v_avg
    from tasting_logs where user_id = v_uid and rating is not null;

  select round(avg(c.strength)::numeric, 1) into v_strength
    from tasting_logs tl join cigars c on c.id = tl.cigar_id
    where tl.user_id = v_uid and c.strength is not null;

  select coalesce(sum(coalesce(purchase_price,0) * coalesce(quantity,1)), 0) into v_value
    from humidor where user_id = v_uid and coalesce(quantity,1) > 0;

  select coalesce(json_agg(t), '[]'::json) into v_top_brands
  from (
    select c.brand as brand, count(*)::int as n
    from tasting_logs tl join cigars c on c.id = tl.cigar_id
    where tl.user_id = v_uid and c.brand is not null
    group by c.brand order by n desc, c.brand asc limit 5
  ) t;

  select coalesce(json_agg(s order by s.d), '[]'::json) into v_score_series
  from (
    select smoked_at as d, rating as s
    from tasting_logs
    where user_id = v_uid and rating is not null
    order by smoked_at desc limit 100
  ) s;

  return json_build_object(
    'total_logged', v_total,
    'brands_tried', v_brands,
    'avg_score',    v_avg,
    'strength_avg', v_strength,
    'humidor_value',v_value,
    'top_brands',   v_top_brands,
    'score_series', v_score_series
  );
end;
$$;

grant execute on function public.get_user_stats() to authenticated;
