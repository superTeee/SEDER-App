-- Migration 036: Extend tasting_logs for 0-100 scoring system
-- Adds: smoke_again, draw_rating, burn_rating, flavor_rating
-- Note: existing "rating" column is kept and repurposed as 0-100 integer

ALTER TABLE tasting_logs
  ADD COLUMN IF NOT EXISTS smoke_again   BOOLEAN,
  ADD COLUMN IF NOT EXISTS draw_rating   SMALLINT CHECK (draw_rating BETWEEN 1 AND 5),
  ADD COLUMN IF NOT EXISTS burn_rating   SMALLINT CHECK (burn_rating BETWEEN 1 AND 5),
  ADD COLUMN IF NOT EXISTS flavor_rating SMALLINT CHECK (flavor_rating BETWEEN 1 AND 5);

-- Relax the range constraint on existing rating column so it accepts 0-100
-- (Previously no constraint existed beyond SMALLINT, so this is just documentation)
COMMENT ON COLUMN tasting_logs.rating IS '0-100 personal score (Cigar Aficionado scale)';
COMMENT ON COLUMN tasting_logs.smoke_again IS 'Would smoke again? true=yes, false=no, null=maybe/unset';
COMMENT ON COLUMN tasting_logs.draw_rating IS '1-5 sub-rating for draw';
COMMENT ON COLUMN tasting_logs.burn_rating IS '1-5 sub-rating for burn';
COMMENT ON COLUMN tasting_logs.flavor_rating IS '1-5 sub-rating for flavor';
