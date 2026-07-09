-- 085_hardening.sql
--
-- Oppfølging etter kodegjennomgangen. Ingen av disse er akutte som 084, men de
-- lukker gjenværende svakheter i feed-policyene og strekkode-funksjonene.
--
--   0. cigar_barcodes-tabellen fantes ALDRI i produksjon — migrasjon 045 ble
--      aldri kjørt. Hele strekkode-skanningen har vært død siden den ble skrevet
--      (BarcodeService svelger feilen i en `do/catch` og returnerer nil).
--      Tabellen, indeksene og RLS opprettes her.
--   1. lookup_barcode / save_barcode mangler `SET search_path`.
--   2. save_barcode lot klienten sette `p_source` fritt (også 'admin').
--   3. post_likes og post_comments var lesbare for ALLE innloggede brukere,
--      også på innlegg de ikke har tilgang til.

-- ── 0. Tabellen fra 045, som aldri ble kjørt ────────────────────────────────

CREATE TABLE IF NOT EXISTS public.cigar_barcodes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  barcode         TEXT NOT NULL UNIQUE,
  cigar_id        UUID NOT NULL REFERENCES public.cigars(id) ON DELETE CASCADE,
  confirmed_count INT NOT NULL DEFAULT 1,
  source          TEXT NOT NULL DEFAULT 'user', -- 'user' | 'api' | 'admin'
  created_by      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cigar_barcodes_barcode  ON public.cigar_barcodes (barcode);
CREATE INDEX IF NOT EXISTS idx_cigar_barcodes_cigar_id ON public.cigar_barcodes (cigar_id);

ALTER TABLE public.cigar_barcodes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "barcodes_select_all" ON public.cigar_barcodes;
CREATE POLICY "barcodes_select_all" ON public.cigar_barcodes
  FOR SELECT USING (true);

-- Direkte insert fra klienten er ikke nødvendig — save_barcode() er veien inn,
-- og den er SECURITY DEFINER. Ingen insert-policy betyr ingen omvei rundt den.
DROP POLICY IF EXISTS "barcodes_insert_authenticated" ON public.cigar_barcodes;
DROP POLICY IF EXISTS "barcodes_update_own" ON public.cigar_barcodes;

-- ── 1 + 2. Strekkode-funksjonene ────────────────────────────────────────────
--
-- Uten `SET search_path` kan en angriper som klarer å opprette objekter i en
-- schema tidligere i search_path kapre funksjonskall inne i en SECURITY
-- DEFINER-funksjon. Alle andre SECURITY DEFINER-funksjoner i prosjektet har
-- den satt; disse to ble glemt.

CREATE OR REPLACE FUNCTION public.lookup_barcode(p_barcode TEXT)
RETURNS TABLE (
  barcode_id      UUID,
  cigar_id        UUID,
  confirmed_count INT,
  brand           TEXT,
  series          TEXT,
  vitola          TEXT,
  wrapper_country TEXT,
  strength        INT,
  avg_rating      NUMERIC,
  flavor_notes    TEXT[]
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    b.id AS barcode_id,
    b.cigar_id,
    b.confirmed_count,
    c.brand,
    c.series,
    c.vitola,
    c.wrapper_country,
    c.strength,
    c.avg_rating,
    c.flavor_notes
  FROM public.cigar_barcodes b
  JOIN public.cigars c ON c.id = b.cigar_id
  WHERE b.barcode = p_barcode
  LIMIT 1;
$$;

-- p_source kom fra klienten uten validering. Nå tvinges den til 'user' med
-- mindre kallet kommer fra en betrodd rolle.
CREATE OR REPLACE FUNCTION public.save_barcode(p_barcode TEXT, p_cigar_id UUID, p_source TEXT DEFAULT 'user')
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id     UUID;
  v_source TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Ikke innlogget';
  END IF;

  -- Kun 'user' og 'scan' er gyldige fra klienten. Alt annet normaliseres.
  v_source := CASE WHEN p_source IN ('user', 'scan') THEN p_source ELSE 'user' END;

  INSERT INTO public.cigar_barcodes (barcode, cigar_id, source, created_by)
  VALUES (p_barcode, p_cigar_id, v_source, auth.uid())
  ON CONFLICT (barcode) DO UPDATE
    -- Bekreft kun når innsendt cigar_id faktisk matcher eksisterende kobling.
    -- Ellers ville feilinnsendinger forsterket feil kobling.
    SET confirmed_count = CASE
      WHEN cigar_barcodes.cigar_id = EXCLUDED.cigar_id
      THEN cigar_barcodes.confirmed_count + 1
      ELSE cigar_barcodes.confirmed_count
    END
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.lookup_barcode(TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.save_barcode(TEXT, UUID, TEXT) TO authenticated;

-- ── 3. Likes og kommentarer følger innleggets synlighet ─────────────────────
--
-- Før: `USING (auth.uid() IS NOT NULL)` — enhver innlogget bruker kunne lese
-- alle likes og alle kommentarer via PostgREST, også på innlegg de ikke har
-- tilgang til. Kommentarinnhold lakk.
--
-- Nå: samme synlighetsregel som posts — eget innlegg, eller innlegg fra en
-- akseptert venn, og ingen blokkering i noen retning.

CREATE OR REPLACE FUNCTION public.can_see_post(p_post_id UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM posts p
    WHERE p.id = p_post_id
      AND auth.uid() IS NOT NULL
      AND (
        p.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM friendships f
          WHERE f.status = 'accepted'
            AND ((f.requester_id = auth.uid() AND f.recipient_id = p.user_id)
              OR (f.recipient_id = auth.uid() AND f.requester_id = p.user_id))
        )
      )
      AND NOT EXISTS (
        SELECT 1 FROM user_blocks b
        WHERE (b.blocker_id = auth.uid() AND b.blocked_id = p.user_id)
           OR (b.blocker_id = p.user_id AND b.blocked_id = auth.uid())
      )
  );
$$;

GRANT EXECUTE ON FUNCTION public.can_see_post(UUID) TO authenticated;

DROP POLICY IF EXISTS "post_likes_select" ON public.post_likes;
CREATE POLICY "post_likes_select" ON public.post_likes
    FOR SELECT USING (public.can_see_post(post_id));

DROP POLICY IF EXISTS "post_comments_select" ON public.post_comments;
CREATE POLICY "post_comments_select" ON public.post_comments
    FOR SELECT USING (public.can_see_post(post_id));

-- Man skal heller ikke kunne kommentere eller like et innlegg man ikke ser.
DROP POLICY IF EXISTS "post_likes_insert" ON public.post_likes;
CREATE POLICY "post_likes_insert" ON public.post_likes
    FOR INSERT WITH CHECK (auth.uid() = user_id AND public.can_see_post(post_id));

DROP POLICY IF EXISTS "post_comments_insert" ON public.post_comments;
CREATE POLICY "post_comments_insert" ON public.post_comments
    FOR INSERT WITH CHECK (auth.uid() = user_id AND public.can_see_post(post_id));
