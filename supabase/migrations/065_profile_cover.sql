-- ============================================================
-- 065_profile_cover.sql
--
-- Legger til cover_url (toppbilde) på profiles, og inkluderer det i
-- get_friend_profile-RPC-en så det kan leses på profilsiden.
-- ============================================================

alter table profiles
  add column if not exists cover_url text;

create or replace function public.get_friend_profile(p_user_id uuid)
returns json
language plpgsql
security definer
as $$
declare
  v_profile profiles%rowtype;
  v_cigar_count int;
  v_humidor_count int;
  v_friend_count int;
  v_is_friend boolean;
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

  return json_build_object(
    'id',            v_profile.id,
    'display_name',  v_profile.display_name,
    'avatar_url',    v_profile.avatar_url,
    'cover_url',     v_profile.cover_url,
    'city',          v_profile.city,
    'friend_code',   v_profile.friend_code,
    'created_at',    v_profile.created_at,
    'cigar_count',   v_cigar_count,
    'humidor_count', v_humidor_count,
    'friend_count',  v_friend_count
  );
end;
$$;

grant execute on function public.get_friend_profile(uuid) to authenticated;
