-- ============================================================
-- 118_founding_members.sql
--
-- Founding members: alle brukere som finnes VED lanseringstidspunktet
-- (dvs. testerne) får livstids Pro + et «Founding Member»-merke på profilen.
-- Nye brukere som opprettes etter denne migrasjonen får default false.
--
-- is_founding_member fungerer inntil videre som appens «Pro»-flagg. Når
-- RevenueCat kobles på, blir effektiv Pro = (is_founding_member OR aktivt abonnement).
-- ============================================================

alter table public.profiles
  add column if not exists is_founding_member boolean not null default false;

-- Backfill: flagg alle eksisterende profiler (testerne) som founding members.
update public.profiles set is_founding_member = true;

-- Ta med feltet i get_friend_profile (egen + venners profil).
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

  select count(*) into v_cigar_count
    from tasting_logs where user_id = p_user_id;

  select count(*) into v_humidor_count
    from humidor where user_id = p_user_id;

  select count(*) into v_friend_count
    from friendships
    where status = 'accepted'
      and (requester_id = p_user_id or recipient_id = p_user_id);

  select round(avg(rating))::int into v_avg_score
    from tasting_logs
    where user_id = p_user_id and rating is not null;

  select count(*) into v_fav_count
    from tasting_logs
    where user_id = p_user_id and smoke_again = true;

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
    'friend_count',       v_friend_count,
    'avg_score',          v_avg_score,
    'favorites_count',    v_fav_count,
    'brands_tried',       v_brands_tried
  );
end;
$$;

grant execute on function public.get_friend_profile(uuid) to authenticated;
