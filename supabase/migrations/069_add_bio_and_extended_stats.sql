-- ============================================================
-- 069_add_bio_and_extended_stats.sql
--
-- 1. Legger til bio-felt på profiles (fritekst om brukeren).
-- 2. Oppdaterer get_friend_profile RPC med:
--    - bio
--    - avg_score   (gjennomsnittlig rating fra tasting_logs)
--    - favorites_count (antall røkt igjen = true)
--    - brands_tried    (unike merker røkt)
-- ============================================================

alter table public.profiles
  add column if not exists bio text;

create or replace function public.get_friend_profile(p_user_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile       profiles%rowtype;
  v_cigar_count   int;
  v_humidor_count int;
  v_friend_count  int;
  v_avg_score     int;
  v_fav_count     int;
  v_brands_tried  int;
  v_is_friend     boolean;
begin
  -- Kun venner (eller seg selv) kan se full profil
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

  -- Antall loggede sigarer (røkt)
  select count(*) into v_cigar_count
    from tasting_logs where user_id = p_user_id;

  -- Antall sigarer i humidor
  select count(*) into v_humidor_count
    from humidor where user_id = p_user_id;

  -- Antall venner (aksepterte vennskap)
  select count(*) into v_friend_count
    from friendships
    where status = 'accepted'
      and (requester_id = p_user_id or recipient_id = p_user_id);

  -- Gjennomsnittlig score (avrundet, NULL hvis ingen scores)
  select round(avg(rating))::int into v_avg_score
    from tasting_logs
    where user_id = p_user_id and rating is not null;

  -- Favoritter = "røk igjen" = true
  select count(*) into v_fav_count
    from tasting_logs
    where user_id = p_user_id and smoke_again = true;

  -- Unike merker røkt
  select count(distinct c.brand) into v_brands_tried
    from tasting_logs tl
    join cigars c on c.id = tl.cigar_id
    where tl.user_id = p_user_id and c.brand is not null;

  return json_build_object(
    'id',              v_profile.id,
    'display_name',    v_profile.display_name,
    'avatar_url',      v_profile.avatar_url,
    'cover_url',       v_profile.cover_url,
    'city',            v_profile.city,
    'friend_code',     v_profile.friend_code,
    'created_at',      v_profile.created_at,
    'bio',             v_profile.bio,
    'cigar_count',     v_cigar_count,
    'humidor_count',   v_humidor_count,
    'friend_count',    v_friend_count,
    'avg_score',       v_avg_score,
    'favorites_count', v_fav_count,
    'brands_tried',    v_brands_tried
  );
end;
$$;

grant execute on function public.get_friend_profile(uuid) to authenticated;
