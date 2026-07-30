-- Likes på aktivitet (delte journal-oppføringer).
create table if not exists public.entry_likes (
  entry_id   uuid not null references public.tasting_logs(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (entry_id, user_id)
);

alter table public.entry_likes enable row level security;

drop policy if exists entry_likes_select on public.entry_likes;
create policy entry_likes_select on public.entry_likes
  for select using (auth.uid() is not null);

drop policy if exists entry_likes_insert on public.entry_likes;
create policy entry_likes_insert on public.entry_likes
  for insert with check (auth.uid() = user_id);

drop policy if exists entry_likes_delete on public.entry_likes;
create policy entry_likes_delete on public.entry_likes
  for delete using (auth.uid() = user_id);

-- Toggle: liker hvis ikke likt, fjerner ellers. Returnerer ny liked-status.
create or replace function public.toggle_entry_like(p_entry_id uuid)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_exists boolean;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  select exists(
    select 1 from public.entry_likes
    where entry_id = p_entry_id and user_id = auth.uid()
  ) into v_exists;

  if v_exists then
    delete from public.entry_likes
    where entry_id = p_entry_id and user_id = auth.uid();
    return false;
  else
    insert into public.entry_likes(entry_id, user_id)
    values (p_entry_id, auth.uid())
    on conflict do nothing;
    return true;
  end if;
end;
$$;

-- get_activity utvides med like_count + liked_by_me.
drop function if exists public.get_activity(integer, timestamptz);
create or replace function public.get_activity(p_limit integer default 30, p_before timestamptz default null)
returns table(
  entry_id uuid, user_id uuid, author_name text, author_avatar_url text,
  verb text, personal_notes text, tasting_photo_url text,
  cigar_id uuid, cigar_brand text, cigar_series text, cigar_vitola text,
  cigar_rating integer, shared_at timestamptz, public_slug text,
  like_count integer, liked_by_me boolean
)
language sql
stable security definer
set search_path to 'public'
as $function$
  select
    tl.id, tl.user_id,
    coalesce(pr.display_name, 'Sigar-entusiast'),
    pr.avatar_url,
    'logged'::text,
    tl.personal_notes, tl.photo_url,
    c.id, c.brand, c.series, c.vitola,
    tl.rating, tl.shared_at, tl.public_slug,
    (select count(*) from public.entry_likes el where el.entry_id = tl.id)::int,
    exists(select 1 from public.entry_likes el where el.entry_id = tl.id and el.user_id = auth.uid())
  from public.tasting_logs tl
  join public.cigars c   on c.id = tl.cigar_id
  left join public.profiles pr on pr.id = tl.user_id
  where tl.shared_to_community
    and auth.uid() is not null
    and (p_before is null or tl.shared_at < p_before)
    and not exists (
      select 1 from public.user_blocks b
      where (b.blocker_id = auth.uid() and b.blocked_id = tl.user_id)
         or (b.blocker_id = tl.user_id and b.blocked_id = auth.uid())
    )
  order by tl.shared_at desc
  limit greatest(p_limit, 1);
$function$;

grant execute on function public.toggle_entry_like(uuid) to authenticated;
grant execute on function public.get_activity(integer, timestamptz) to authenticated;
