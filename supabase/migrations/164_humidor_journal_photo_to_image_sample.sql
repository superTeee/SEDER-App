-- 164: Fang bilder til visuell gjenkjenning "fra nå av".
-- (1) Journal: fanget bare ved INSERT før — men appen laster ofte opp loggbildet
--     ETTER at loggen er opprettet (UPDATE). Utvid til INSERT OR UPDATE OF photo_url,
--     med NOT EXISTS-vakt mot duplikater.
-- (2) Humidor: ny trigger — når en humidor-oppføring får et bilde (skann-bilde som
--     blir oppføringens bilde, eller et bilde brukeren legger til), lag en
--     cigar_image_samples-rad (source='humidor'). Embedding fylles av backfill.

create or replace function public.tasting_log_to_image_sample()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if new.cigar_id is not null and coalesce(new.photo_url,'') <> '' then
    insert into public.cigar_image_samples (cigar_id, image_url, source, submitted_by)
    select new.cigar_id, new.photo_url, 'journal', new.user_id
    where not exists (
      select 1 from public.cigar_image_samples s
      where s.cigar_id = new.cigar_id and s.image_url = new.photo_url
    );
  end if;
  return new;
end $$;

drop trigger if exists trg_tasting_log_image on public.tasting_logs;
create trigger trg_tasting_log_image
  after insert or update of photo_url on public.tasting_logs
  for each row execute function public.tasting_log_to_image_sample();

create or replace function public.humidor_to_image_sample()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if new.cigar_id is not null and coalesce(new.photo_url,'') <> '' then
    insert into public.cigar_image_samples (cigar_id, image_url, source, submitted_by)
    select new.cigar_id, new.photo_url, 'humidor', new.user_id
    where not exists (
      select 1 from public.cigar_image_samples s
      where s.cigar_id = new.cigar_id and s.image_url = new.photo_url
    );
  end if;
  return new;
end $$;

drop trigger if exists trg_humidor_image on public.humidor;
create trigger trg_humidor_image
  after insert or update of photo_url on public.humidor
  for each row execute function public.humidor_to_image_sample();
