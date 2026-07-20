-- 115_activity_sharing.sql
-- Fase 1 av IA/delings-oppdateringen: Feed → Aktivitet.
-- Aktivitet avledes fra journalen (tasting_logs), ikke fra en egen posts-tabell.
-- Deling er to flagg + en offentlig slug. Ingenting brytes; posts/feed lever videre
-- parallelt til senere faser.

-- 1) Delings-felt på journal-oppføringer -----------------------------------
alter table public.tasting_logs
  add column if not exists shared_to_community boolean not null default false,
  add column if not exists shared_externally   boolean not null default false,
  add column if not exists public_slug          text,
  add column if not exists shared_at            timestamptz;

-- Unik slug (nullbar). Deterministisk generert fra id, så aldri kollisjon.
create unique index if not exists tasting_logs_public_slug_key
  on public.tasting_logs (public_slug) where public_slug is not null;

-- Rask henting av aktivitets-strømmen (delte, nyeste først).
create index if not exists tasting_logs_activity_idx
  on public.tasting_logs (shared_at desc) where shared_to_community;

-- Deterministisk slug fra oppførings-id — samme id gir alltid samme slug.
create or replace function public.gen_entry_slug(p_entry_id uuid)
returns text language sql immutable as $$
  select substr(md5(p_entry_id::text || 'seder-slug-v1'), 1, 10);
$$;

-- 2) Backfill: eksisterende delte innlegg (posts) som er koblet til en
--    journal-oppføring → marker oppføringen som delt i community.
update public.tasting_logs tl
set shared_to_community = true,
    shared_at = coalesce(tl.shared_at, p.created_at, now()),
    public_slug = coalesce(tl.public_slug, public.gen_entry_slug(tl.id))
from public.posts p
where p.tasting_log_id = tl.id;

-- 3) Sett/endre deling på en oppføring (eier-sjekk via auth.uid()) ----------
create or replace function public.set_entry_sharing(
  p_entry_id uuid,
  p_community boolean,
  p_external boolean
)
returns table(entry_id uuid, shared_to_community boolean,
              shared_externally boolean, public_slug text, shared_at timestamptz)
language plpgsql security definer set search_path to 'public' as $$
declare
  v_owner uuid;
begin
  select user_id into v_owner from public.tasting_logs where id = p_entry_id;
  if v_owner is null then
    raise exception 'Fant ikke journal-oppføringen';
  end if;
  if v_owner <> auth.uid() then
    raise exception 'Ikke din oppføring';
  end if;

  if p_community or p_external then
    -- Deling på: sikre slug + settdato (settes kun første gang).
    update public.tasting_logs tl
      set shared_to_community = p_community,
          shared_externally   = p_external,
          public_slug = coalesce(tl.public_slug, public.gen_entry_slug(tl.id)),
          shared_at   = coalesce(tl.shared_at, now())
      where tl.id = p_entry_id;
  else
    -- Alt av: trekk tilbake — nullstill slug og dato (siden blir «privat»).
    update public.tasting_logs tl
      set shared_to_community = false,
          shared_externally   = false,
          public_slug = null,
          shared_at   = null
      where tl.id = p_entry_id;
  end if;

  return query
    select tl.id, tl.shared_to_community, tl.shared_externally, tl.public_slug, tl.shared_at
    from public.tasting_logs tl where tl.id = p_entry_id;
end;
$$;

-- 4) Aktivitets-strømmen: delte journal-hendelser, nyeste først ------------
-- Global (som dagens feed), minus blokkerte begge veier. Keyset-paginering
-- via p_before (shared_at til siste rad forrige side).
create or replace function public.get_activity(
  p_limit integer default 30,
  p_before timestamptz default null
)
returns table(
  entry_id uuid, user_id uuid, author_name text, author_avatar_url text,
  verb text, personal_notes text, tasting_photo_url text,
  cigar_id uuid, cigar_brand text, cigar_series text, cigar_vitola text,
  cigar_rating integer, shared_at timestamptz, public_slug text
)
language sql stable security definer set search_path to 'public' as $$
  select
    tl.id, tl.user_id,
    coalesce(pr.display_name, 'Sigar-entusiast'),
    pr.avatar_url,
    'logged'::text,
    tl.personal_notes, tl.photo_url,
    c.id, c.brand, c.series, c.vitola,
    tl.rating, tl.shared_at, tl.public_slug
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
$$;

-- 5) Offentlig lesing av én delt oppføring (til den offentlige siden) -------
-- Returnerer KUN trygge visningsfelt, og kun når deling er aktiv. Ingen auth.
create or replace function public.get_public_journal_entry(p_slug text)
returns table(
  author_name text, author_avatar_url text,
  cigar_brand text, cigar_series text, cigar_vitola text,
  rating integer, personal_notes text, photo_url text, smoked_at timestamptz
)
language sql stable security definer set search_path to 'public' as $$
  select
    coalesce(pr.display_name, 'Sigar-entusiast'),
    pr.avatar_url,
    c.brand, c.series, c.vitola,
    tl.rating, tl.personal_notes, tl.photo_url, tl.smoked_at
  from public.tasting_logs tl
  join public.cigars c on c.id = tl.cigar_id
  left join public.profiles pr on pr.id = tl.user_id
  where tl.public_slug = p_slug
    and (tl.shared_to_community or tl.shared_externally)
  limit 1;
$$;

-- Tilgang: get_public_journal_entry skal kunne kalles av anon (offentlig side).
grant execute on function public.get_public_journal_entry(text) to anon, authenticated;
grant execute on function public.get_activity(integer, timestamptz) to authenticated;
grant execute on function public.set_entry_sharing(uuid, boolean, boolean) to authenticated;
