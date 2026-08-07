-- 159: Skann-bildet blir sigarens bilde når den mangler ett fra før.
--
-- Når en skanning løses (brukeren velger riktig sigar) laster appen allerede
-- opp bånd-bildet til den offentlige band-samples-bøtta og kaller denne
-- funksjonen. Tidligere ble bildet kun lagret som «prøve» for læring — det ble
-- aldri vist noe sted. Nå:
--   1) lagrer vi også den offentlige URL-en på prøven (image_url), slik at
--      alle prøver er ensartede og klare for embedding/visning, og
--   2) hvis sigaren IKKE har noe bilde fra før (verken band- eller
--      produktbilde), settes skann-bildet som sigarens band_image_url.
--      Det vises da automatisk på sigar-detalj (i humidoren) og i journalen
--      via klientens fallback. Vi fyller KUN når det er tomt — et eksisterende
--      (kuratert) bilde overskrives aldri.

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

  -- Alltid: lagre bilde-prøven hvis vi har den.
  if p_image_path is not null and btrim(p_image_path) <> '' then
    -- Offentlig URL til band-samples-bøtta (public bucket).
    v_url := 'https://wpcricosogcmzebkplwp.supabase.co/storage/v1/object/public/band-samples/' || p_image_path;

    insert into public.cigar_image_samples (cigar_id, storage_path, image_url, source, ocr_text, submitted_by)
    values (p_cigar_id, p_image_path, v_url, 'manual_scan', nullif(btrim(p_ocr_text), ''), auth.uid());

    -- Har sigaren ikke noe bilde fra før → skann-bildet blir sigarens bilde.
    update public.cigars
       set band_image_url = v_url
     where id = p_cigar_id
       and coalesce(band_image_url, '') = ''
       and coalesce(product_image_url, '') = '';
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
