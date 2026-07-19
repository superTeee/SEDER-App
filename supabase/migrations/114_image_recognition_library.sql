-- 114_image_recognition_library
-- Datahjul for bildegjenkjenning:
--  1) cigar_image_samples = bibliotek over ALLE sigar-bilder (produkt, bånd,
--     journal, manuell skann-løsning). Klargjort for visuell matching (pgvector).
--  2) scan_resolutions + record_scan_resolution() = lærte tekst-aliaser fra
--     manuelle løsninger, med TERSKEL: 3 uavhengige brukere må koble samme
--     bånd-tekst til samme sigar før det går live (beskytter troverdigheten).
--  3) band-samples storage-bøtte for bånd-bilder fra manuelle løsninger.

create extension if not exists vector;

create table if not exists public.cigar_image_samples (
  id uuid primary key default gen_random_uuid(),
  cigar_id uuid not null references public.cigars(id) on delete cascade,
  storage_path text,
  image_url text,
  source text not null default 'unknown',  -- product | band | journal | manual_scan
  ocr_text text,
  submitted_by uuid,
  embedding vector(512),                    -- fylles senere av embedding-jobb
  created_at timestamptz not null default now()
);
create index if not exists cigar_image_samples_cigar_idx on public.cigar_image_samples (cigar_id);
alter table public.cigar_image_samples enable row level security;

-- Backfill: eksisterende bilder
insert into public.cigar_image_samples (cigar_id, image_url, source)
select id, product_image_url, 'product' from public.cigars where coalesce(product_image_url,'') <> ''
union all
select id, band_image_url, 'band' from public.cigars where coalesce(band_image_url,'') <> '';

insert into public.cigar_image_samples (cigar_id, image_url, source, submitted_by)
select cigar_id, photo_url, 'journal', user_id
from public.tasting_logs
where cigar_id is not null and coalesce(photo_url,'') <> '';

-- Fremtidige journal-bilder mates automatisk inn i biblioteket
create or replace function public.tasting_log_to_image_sample()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.cigar_id is not null and coalesce(new.photo_url,'') <> '' then
    insert into public.cigar_image_samples (cigar_id, image_url, source, submitted_by)
    values (new.cigar_id, new.photo_url, 'journal', new.user_id);
  end if;
  return new;
end $$;

drop trigger if exists trg_tasting_log_image on public.tasting_logs;
create trigger trg_tasting_log_image
after insert on public.tasting_logs
for each row execute function public.tasting_log_to_image_sample();

-- Lærte aliaser med terskel
create table if not exists public.scan_resolutions (
  id uuid primary key default gen_random_uuid(),
  norm_text text not null,
  cigar_id uuid not null references public.cigars(id) on delete cascade,
  submitted_by uuid,
  created_at timestamptz not null default now()
);
create unique index if not exists scan_resolutions_uniq
  on public.scan_resolutions (norm_text, cigar_id, submitted_by);
alter table public.scan_resolutions enable row level security;

create or replace function public.record_scan_resolution(
  p_ocr_text text,
  p_cigar_id uuid,
  p_image_path text default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  n text := public.norm_text(p_ocr_text);
  votes int;
begin
  if n = '' or p_cigar_id is null then return; end if;

  insert into public.scan_resolutions (norm_text, cigar_id, submitted_by)
  values (n, p_cigar_id, auth.uid())
  on conflict (norm_text, cigar_id, submitted_by) do nothing;

  if p_image_path is not null then
    insert into public.cigar_image_samples (cigar_id, storage_path, source, ocr_text, submitted_by)
    values (p_cigar_id, p_image_path, 'manual_scan', p_ocr_text, auth.uid());
  end if;

  select count(distinct submitted_by) into votes
  from public.scan_resolutions
  where norm_text = n and cigar_id = p_cigar_id and submitted_by is not null;

  if votes >= 3 then
    update public.cigars
      set aliases = array_append(aliases, btrim(p_ocr_text))
    where id = p_cigar_id
      and not exists (
        select 1 from unnest(aliases) a where public.norm_text(a) = n
      );
  end if;
end $$;

grant execute on function public.record_scan_resolution(text, uuid, text) to authenticated;

-- Storage-bøtte for bånd-bilder fra manuelle løsninger
insert into storage.buckets (id, name, public)
values ('band-samples','band-samples', true)
on conflict (id) do nothing;

drop policy if exists "band_samples_insert" on storage.objects;
create policy "band_samples_insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'band-samples');

drop policy if exists "band_samples_read" on storage.objects;
create policy "band_samples_read" on storage.objects
  for select to public
  using (bucket_id = 'band-samples');
