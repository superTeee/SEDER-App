-- ============================================================
-- 058_strength_decimal_and_profile_fields.sql
--
-- 1) strength: integer → numeric(3,1) (støtter 2.5, 3.5 etc.)
-- 2) body           numeric(3,1)  — Fylde (0–5)
-- 3) sweetness      numeric(3,1)  — Sødme (0–5)
-- 4) flavor_intensity numeric(3,1) — Smaksintensitet (0–5)
-- ============================================================

-- Endre strength til desimaltall
ALTER TABLE cigars
  ALTER COLUMN strength TYPE numeric(3,1) USING strength::numeric;

-- Nye profilfelter
ALTER TABLE cigars
  ADD COLUMN IF NOT EXISTS body             numeric(3,1),
  ADD COLUMN IF NOT EXISTS sweetness        numeric(3,1),
  ADD COLUMN IF NOT EXISTS flavor_intensity numeric(3,1);
