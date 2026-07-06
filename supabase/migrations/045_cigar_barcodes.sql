-- Migration 045: cigar_barcodes — crowdsourced barcode → cigar mapping
CREATE TABLE IF NOT EXISTS public.cigar_barcodes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  barcode         TEXT NOT NULL UNIQUE,
  cigar_id        UUID NOT NULL REFERENCES public.cigars(id) ON DELETE CASCADE,
  confirmed_count INT NOT NULL DEFAULT 1,
  source          TEXT NOT NULL DEFAULT 'user', -- 'user' | 'api' | 'admin'
  created_by      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cigar_barcodes_barcode   ON public.cigar_barcodes (barcode);
CREATE INDEX IF NOT EXISTS idx_cigar_barcodes_cigar_id  ON public.cigar_barcodes (cigar_id);

-- RLS
ALTER TABLE public.cigar_barcodes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "barcodes_select_all" ON public.cigar_barcodes
  FOR SELECT USING (true);

CREATE POLICY "barcodes_insert_authenticated" ON public.cigar_barcodes
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "barcodes_update_own" ON public.cigar_barcodes
  FOR UPDATE USING (auth.uid() = created_by);

-- RPC: lookup a barcode and return the matched cigar (for anonymous use)
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
LANGUAGE sql STABLE SECURITY DEFINER AS $$
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

-- RPC: save a new barcode mapping (or increment confirmed_count if already exists)
CREATE OR REPLACE FUNCTION public.save_barcode(p_barcode TEXT, p_cigar_id UUID, p_source TEXT DEFAULT 'user')
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO public.cigar_barcodes (barcode, cigar_id, source, created_by)
  VALUES (p_barcode, p_cigar_id, p_source, auth.uid())
  ON CONFLICT (barcode) DO UPDATE
    SET confirmed_count = cigar_barcodes.confirmed_count + 1
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;
