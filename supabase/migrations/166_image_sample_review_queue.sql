-- 166: «Nye bilder» som innboks. reviewed_at = når admin har håndtert bildet
-- (Behold, eller Flytt som også teller som håndtert). Bildet forlater køen når
-- reviewed_at settes; ellers ligger det til det er >30 dager gammelt (backstop).

alter table public.cigar_image_samples add column if not exists reviewed_at timestamptz;

drop function if exists public.admin_image_samples(int);
create function public.admin_image_samples(p_limit int default 400)
returns table(
  id uuid, cigar_id uuid, cigar_navn text, brand text, image_url text,
  storage_path text, source text, ocr_text text, has_embedding boolean,
  reviewed_at timestamptz, created_at timestamptz
)
language sql stable security definer set search_path to 'public'
as $$
  select
    s.id, s.cigar_id,
    trim(both ' ' from concat_ws(' ', c.brand, c.series, c.vitola)) as cigar_navn,
    c.brand,
    coalesce(s.image_url,
      case when s.storage_path is not null
        then 'https://wpcricosogcmzebkplwp.supabase.co/storage/v1/object/public/band-samples/' || s.storage_path
        else null end) as image_url,
    s.storage_path, s.source, s.ocr_text, (s.embedding is not null) as has_embedding,
    s.reviewed_at, s.created_at
  from cigar_image_samples s
  left join cigars c on c.id = s.cigar_id
  where is_admin()
  order by s.created_at desc
  limit greatest(1, least(p_limit, 1000));
$$;
grant execute on function public.admin_image_samples(int) to authenticated, anon;

create or replace function public.admin_mark_image_reviewed(p_id uuid)
returns boolean language plpgsql security definer set search_path to 'public'
as $$
begin
  if not is_admin() then raise exception 'not authorized'; end if;
  update cigar_image_samples set reviewed_at = now() where id = p_id;
  return found;
end;
$$;
grant execute on function public.admin_mark_image_reviewed(uuid) to authenticated, anon;

create or replace function public.admin_reassign_image_sample(p_id uuid, p_cigar_id uuid)
returns boolean language plpgsql security definer set search_path to 'public'
as $$
begin
  if not is_admin() then raise exception 'not authorized'; end if;
  update cigar_image_samples set cigar_id = p_cigar_id, reviewed_at = now() where id = p_id;
  return found;
end;
$$;
