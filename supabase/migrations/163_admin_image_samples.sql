-- 163: Admin-verktøy for bildeprøver (visuell gjenkjenning).
-- admin_image_samples: liste over cigar_image_samples med sigarnavn + bilde-URL
-- + embedding-status, slik at admin kan se hvilke bilder som er koblet til hvilken
-- sigar og fjerne de som ikke stemmer. admin_delete_image_sample: fjerner én rad
-- (fjerner den fra visuell matching). Begge er is_admin()-beskyttet.

create or replace function public.admin_image_samples(p_limit int default 400)
returns table(
  id uuid,
  cigar_id uuid,
  cigar_navn text,
  brand text,
  image_url text,
  storage_path text,
  source text,
  ocr_text text,
  has_embedding boolean,
  created_at timestamptz
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    s.id,
    s.cigar_id,
    trim(both ' ' from concat_ws(' ', c.brand, c.series, c.vitola)) as cigar_navn,
    c.brand,
    coalesce(
      s.image_url,
      case when s.storage_path is not null
        then 'https://wpcricosogcmzebkplwp.supabase.co/storage/v1/object/public/band-samples/' || s.storage_path
        else null end
    ) as image_url,
    s.storage_path,
    s.source,
    s.ocr_text,
    (s.embedding is not null) as has_embedding,
    s.created_at
  from cigar_image_samples s
  left join cigars c on c.id = s.cigar_id
  where is_admin()
  order by s.created_at desc
  limit greatest(1, least(p_limit, 1000));
$$;

create or replace function public.admin_delete_image_sample(p_id uuid)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not is_admin() then
    raise exception 'not authorized';
  end if;
  delete from cigar_image_samples where id = p_id;
  return found;
end;
$$;

grant execute on function public.admin_image_samples(int) to authenticated, anon;
grant execute on function public.admin_delete_image_sample(uuid) to authenticated, anon;
