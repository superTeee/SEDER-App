-- Migration 041: Profilside — avatar, by, og offentlig humidor

-- 1. Legg til avatar_url og city på profiles
alter table profiles
  add column if not exists avatar_url text,
  add column if not exists city       text;

-- 2. Legg til is_public på humidor (venner kan se delte humidorer)
alter table humidor
  add column if not exists is_public boolean not null default false;

-- 3. RLS-policy: venner kan se humidorer som er satt til is_public = true
drop policy if exists "humidor_friends_select_public" on humidor;
create policy "humidor_friends_select_public"
  on humidor for select
  using (
    is_public = true
    and exists (
      select 1 from friendships f
      where f.status = 'accepted'
        and (
          (f.requester_id = auth.uid() and f.recipient_id = humidor.user_id)
          or
          (f.recipient_id = auth.uid() and f.requester_id = humidor.user_id)
        )
    )
  );

-- 4. Venner kan lese hverandres profiler (display_name, avatar_url, city, friend_code, created_at)
drop policy if exists "profiles_friends_select" on profiles;
create policy "profiles_friends_select"
  on profiles for select
  using (
    auth.uid() = id
    or exists (
      select 1 from friendships f
      where f.status = 'accepted'
        and (
          (f.requester_id = auth.uid() and f.recipient_id = profiles.id)
          or
          (f.recipient_id = auth.uid() and f.requester_id = profiles.id)
        )
    )
  );

-- 5. RPC: hent offentlig profil for en venn (stats inkludert)
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
  -- Sjekk at kallende bruker er venn med p_user_id
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
    'id',           v_profile.id,
    'display_name', v_profile.display_name,
    'avatar_url',   v_profile.avatar_url,
    'city',         v_profile.city,
    'friend_code',  v_profile.friend_code,
    'created_at',   v_profile.created_at,
    'cigar_count',  v_cigar_count,
    'humidor_count', v_humidor_count,
    'friend_count', v_friend_count
  );
end;
$$;

grant execute on function public.get_friend_profile(uuid) to authenticated;
