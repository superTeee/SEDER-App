-- Migrasjon 034: Endre purchase_date fra DATE til TIMESTAMPTZ
-- Årsak: Swift Supabase SDK dekoder datoer som ISO 8601 timestamps.
-- DATE-kolonner returneres som "YYYY-MM-DD" som ikke kan dekodes som Swift Date.
-- TIMESTAMPTZ returneres som "YYYY-MM-DDThh:mm:ss+00:00" som dekodes korrekt.

ALTER TABLE humidor
  ALTER COLUMN purchase_date TYPE TIMESTAMPTZ
  USING purchase_date::TIMESTAMPTZ;

COMMENT ON COLUMN humidor.purchase_date IS 'Kjøpsdato (TIMESTAMPTZ for Swift SDK-kompatibilitet)';
