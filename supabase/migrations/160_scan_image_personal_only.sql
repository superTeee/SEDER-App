-- 160: Skann-bildet skal IKKE på det delte katalogkortet.
--
-- Korrigerer 159. Bildet fra en skanning skal kun ligge på brukerens EGNE
-- plasseringer (humidor-oppføringen og journaloppføringene) — aldri på
-- cigars.band_image_url, som er delt og synlig for alle. Klienten setter nå
-- skann-bildet direkte på humidor.photo_url / tasting_logs.photo_url.
--
-- Vi beholder å lagre bilde-prøven i cigar_image_samples MED offentlig URL,
-- for det er nettopp den prøven som skal mate den visuelle båndgjenkjenningen
-- (Del 3) — «hjelp for skanningen senere når neste mann skanner samme sigar».
-- Samplene er per bruker (submitted_by) og vises ikke som sigarens katalogbilde.

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
  v_url text;
begin
  if p_cigar_id is null then return; end if;

  -- Lagre bilde-prøven (med offentlig URL) — mater båndgjenkjenningen i Del 3.
  -- Setter IKKE cigars.band_image_url: skann-bildet er personlig, ikke katalog.
  if p_image_path is not null and btrim(p_image_path) <> '' then
    v_url := 'https://wpcricosogcmzebkplwp.supabase.co/storage/v1/object/public/band-samples/' || p_image_path;

    insert into public.cigar_image_samples (cigar_id, storage_path, image_url, source, ocr_text, submitted_by)
    values (p_cigar_id, p_image_path, v_url, 'manual_scan', nullif(btrim(p_ocr_text), ''), auth.uid());
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
