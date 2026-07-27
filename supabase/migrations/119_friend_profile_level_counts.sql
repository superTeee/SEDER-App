-- ============================================================
-- 119_friend_profile_level_counts.sql
--
-- get_friend_profile returnerer nå humidors_count (antall humidor-beholdere)
-- og rh_count (antall RH-målinger) i tillegg. Trengs for Primary-nivåberegningen
-- (Samler/Kurator krever flere humidorer + RH-målinger).
-- ============================================================

create or replace function public.get_friend_profile(p_user_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile        profiles%rowtype;
  v_cigar_count    int;
  v_humidor_count  int;
  v_humidors_count int;
  v_rh_count       int;
  v_friend_count   int;
  v_avg_score      int;
  v_fav_count      int;
  v_brands_tried   int;
  v_is_friend      boolean;
begin
  select exists (
    select 1 from friendships f
    where f.status = 'accepted'
      and (
        (f.requester_id = auth.uid() and f.recipient_id = p_user_id)
        or
        (f.recipient_id = auth.uid() and f.requester_id = p_user_id)
      )
  ) or auth.uid() = p_user_id
  into v_is_friend;

  if not v_is_friend then
    raise exception 'not_friend';
  end if;

  select * into v_profile from profiles where id = p_user_id;

  select count(*) into v_cigar_count from tasting_logs where user_id = p_user_id;
  select count(*) into v_humidor_count from humidor where user_id = p_user_id;
  select count(*) into v_humidors_count from humidors where user_id = p_user_id;
  select count(*) into v_rh_count from humidor_rh_readings where user_id = p_user_id;

  select count(*) into v_friend_count
    from friendships
    where status = 'accepted'
      and (requester_id = p_user_id or recipient_id = p_user_id);

  select round(avg(rating))::int into v_avg_score
    from tasting_logs where user_id = p_user_id and rating is not null;

  select count(*) into v_fav_count
    from tasting_logs where user_id = p_user_id and smoke_again = true;

  select count(distinct c.brand) into v_brands_tried
    from tasting_logs tl
    join cigars c on c.id = tl.cigar_id
    where tl.user_id = p_user_id and c.brand is not null;

  return json_build_object(
    'id',                 v_profile.id,
    'display_name',       v_profile.display_name,
    'avatar_url',         v_profile.avatar_url,
    'cover_url',          v_profile.cover_url,
    'city',               v_profile.city,
    'country',            v_profile.country,
    'friend_code',        v_profile.friend_code,
    'created_at',         v_profile.created_at,
    'bio',                v_profile.bio,
    'is_founding_member', v_profile.is_founding_member,
    'cigar_count',        v_cigar_count,
    'humidor_count',      v_humidor_count,
    'humidors_count',     v_humidors_count,
    'rh_count',           v_rh_count,
    'friend_count',       v_friend_count,
    'avg_score',          v_avg_score,
    'favorites_count',    v_fav_count,
    'brands_tried',       v_brands_tried
  );
end;
$$;

grant execute on function public.get_friend_profile(uuid) to authenticated;
