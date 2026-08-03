-- 130: record_scan_resolution — lagre bånd-bildet ALLTID når vi har det, også når
-- OCR-teksten er tom. Grafiske bånd (mye grafikk, lite/ingen tekst) gir ingen tekst
-- å lage alias av, men bildet er nettopp da mest verdifullt for fremtidig visuell
-- matching (embeddings over cigar_image_samples). Tekst-stemme/alias krever tekst.
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
  if p_cigar_id is null then return; end if;

  -- Alltid: lagre bilde-prøven hvis vi har den.
  if p_image_path is not null then
    insert into public.cigar_image_samples (cigar_id, storage_path, source, ocr_text, submitted_by)
    values (p_cigar_id, p_image_path, 'manual_scan', nullif(btrim(p_ocr_text), ''), auth.uid());
  end if;

  -- Tekst-basert stemme + alias krever faktisk tekst.
  if n <> '' then
    insert into public.scan_resolutions (norm_text, cigar_id, submitted_by)
    values (n, p_cigar_id, auth.uid())
    on conflict (norm_text, cigar_id, submitted_by) do nothing;

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
  end if;
end $function$;
