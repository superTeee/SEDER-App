-- 037_tasting_logs_photo.sql
-- Legg til foto-støtte på røykeloggen + oppretter log-photos storage bucket

-- Ny kolonne for foto-URL
ALTER TABLE tasting_logs
  ADD COLUMN IF NOT EXISTS photo_url TEXT;

COMMENT ON COLUMN tasting_logs.photo_url IS 'Offentlig URL til bilde tatt under røykingen (Supabase Storage: log-photos bucket)';

-- Storage bucket for logg-bilder (opprettes manuelt i Supabase Dashboard eller via API)
-- Bucket navn: log-photos
-- Public: true (bildene er tilgjengelige uten autentisering, for deling)

-- RLS: brukere kan kun laste opp til sin egen mappe (userId/logId.jpg)
-- Policy opprettes i Supabase Dashboard under Storage > Policies
