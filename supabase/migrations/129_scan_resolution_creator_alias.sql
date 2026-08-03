-- 129: record_scan_resolution — kilde-alias med en gang.
-- Når innsenderen er den som opprettet sigaren (created_by = auth.uid()), gjøres
-- OCR-teksten fra det mislykkede skannet til alias umiddelbart, slik at samme bånd
-- matcher neste gang – også for én bruker alene. Andre brukere krever fortsatt
-- >=3 distinkte stemmer (folkeavstemning) før en forkortelse blir alias.
CREATE OR REPLACE FUNCTION public.record_scan_resolution(p_ocr_text text, p_cigar_id uuid, p_image_path text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  n text := public.norm_text(p_ocr_text);
  votes int;
  is_creator boolean;
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

  select exists(
    select 1 from public.cigars where id = p_cigar_id and created_by = auth.uid()
  ) into is_creator;

  if (is_creator or votes >= 3) then
    update public.cigars
      set aliases = array_append(aliases, btrim(p_ocr_text))
    where id = p_cigar_id
      and btrim(p_ocr_text) <> ''
      and not exists (
        select 1 from unnest(aliases) a where public.norm_text(a) = n
      );
  end if;
end $function$;
