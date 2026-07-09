-- ============================================================
-- Migration 087: Herkomst på sigardata + «Meld feil»-rapporter
--
-- Bakgrunn: databasen kunne ikke skille en rad hentet fra produsentens egen
-- katalog fra en rad noen hadde gjettet seg fram til. Migrasjon 028 la inn
-- Montecristo Wide Edmundo som dominikansk med Connecticut-dekkblad. Den er
-- kubansk. Ingenting i skjemaet avslørte at spesifikasjonene var oppdiktet.
--
-- Løsningen er ikke å love at alt er riktig. Det er å si hva vi vet og hvor
-- vi vet det fra — og gjøre det lett for brukerne å rette oss.
--
--   1. cigars.source_url    hvor spesifikasjonene kommer fra
--   2. cigars.verified_at   når en menneskelig kilde sist bekreftet dem
--   3. cigar_reports        brukerens «denne er feil»-melding
-- ============================================================

-- ── 1 + 2. Herkomst ─────────────────────────────────────────

ALTER TABLE public.cigars
  ADD COLUMN IF NOT EXISTS source_url  TEXT,
  ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ;

COMMENT ON COLUMN public.cigars.source_url IS
  'Lenke til kilden spesifikasjonene er hentet fra. NULL = ingen kjent kilde.';
COMMENT ON COLUMN public.cigars.verified_at IS
  'Når spesifikasjonene sist ble sjekket mot kilden. NULL = ikke verifisert; '
  'appen skal si det til brukeren i stedet for å presentere gjetning som fakta.';

CREATE INDEX IF NOT EXISTS idx_cigars_verified_at ON public.cigars(verified_at);

-- De fire radene vi faktisk har verifisert mot primærkilder i dag.
UPDATE cigars
SET source_url  = 'https://cigars.co.uk/news/montecristo-wide-edmundo/',
    verified_at = NOW()
WHERE brand = 'Montecristo' AND series = 'Wide Edmundo';

UPDATE cigars
SET source_url  = 'https://www.cigaraficionado.com/top25cigar/montecristo-petit-edmundo-2007',
    verified_at = NOW()
WHERE brand = 'Montecristo' AND series = 'Petit Edmundo';

UPDATE cigars
SET source_url  = 'https://www.cubancigarwebsite.com/brand/montecristo',
    verified_at = NOW()
WHERE brand = 'Montecristo' AND series IN ('Especial No. 2', 'Edmundo', 'No. 2', 'No. 4');

-- ── 3. cigar_reports ────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.cigar_reports (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    cigar_id    UUID        NOT NULL REFERENCES public.cigars(id) ON DELETE CASCADE,
    reporter_id UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    field       TEXT        NOT NULL,   -- 'origin' | 'dimensions' | 'tobacco' | 'description' | 'flavor' | 'other'
    comment     TEXT,                   -- brukerens egen forklaring
    status      TEXT        NOT NULL DEFAULT 'pending',  -- 'pending' | 'accepted' | 'rejected'
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(cigar_id, reporter_id, field),
    CHECK (field IN ('origin', 'dimensions', 'tobacco', 'description', 'flavor', 'other')),
    CHECK (comment IS NULL OR char_length(comment) <= 1000)
);

CREATE INDEX IF NOT EXISTS idx_cigar_reports_cigar_id ON public.cigar_reports(cigar_id);
CREATE INDEX IF NOT EXISTS idx_cigar_reports_status   ON public.cigar_reports(status);

ALTER TABLE public.cigar_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cigar_reports_insert" ON public.cigar_reports;
CREATE POLICY "cigar_reports_insert" ON public.cigar_reports
    FOR INSERT WITH CHECK (auth.uid() = reporter_id);

DROP POLICY IF EXISTS "cigar_reports_select_own" ON public.cigar_reports;
CREATE POLICY "cigar_reports_select_own" ON public.cigar_reports
    FOR SELECT USING (auth.uid() = reporter_id);

-- ── 4. RPC: report_cigar ────────────────────────────────────
--
-- Samme mønster som report_post. Reporter-ID leses fra auth.uid(), aldri fra
-- klienten. Ny rapport på samme felt fra samme bruker overskriver den gamle.

CREATE OR REPLACE FUNCTION public.report_cigar(
    p_cigar_id UUID,
    p_field    TEXT,
    p_comment  TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Ikke innlogget';
    END IF;

    INSERT INTO cigar_reports (cigar_id, reporter_id, field, comment)
    VALUES (p_cigar_id, v_uid, p_field, NULLIF(btrim(p_comment), ''))
    ON CONFLICT (cigar_id, reporter_id, field)
    DO UPDATE SET comment    = EXCLUDED.comment,
                  status     = 'pending',
                  created_at = NOW();
END;
$$;

GRANT EXECUTE ON FUNCTION public.report_cigar(UUID, TEXT, TEXT) TO authenticated;
