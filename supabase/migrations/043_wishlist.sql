-- Migration 043: Wishlist table
-- Lagrer brukerens ønskeliste (sigarer de vil prøve/kjøpe)

CREATE TABLE IF NOT EXISTS wishlist (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cigar_id   UUID NOT NULL REFERENCES cigars(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, cigar_id)
);

-- Row Level Security
ALTER TABLE wishlist ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own wishlist"
  ON wishlist FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can add to own wishlist"
  ON wishlist FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove from own wishlist"
  ON wishlist FOR DELETE
  USING (auth.uid() = user_id);

-- Index for raske oppslag
CREATE INDEX IF NOT EXISTS wishlist_user_id_idx ON wishlist (user_id);
CREATE INDEX IF NOT EXISTS wishlist_cigar_id_idx ON wishlist (cigar_id);
