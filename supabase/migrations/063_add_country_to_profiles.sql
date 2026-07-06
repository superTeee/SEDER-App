-- ============================================================
-- 063_add_country_to_profiles.sql
--
-- Legger til country-kolonne på profiles, brukt av den nye
-- "Fullfør profil"-skjermen ved e-post-registrering (fornavn,
-- etternavn og land). Fornavn+etternavn lagres i display_name.
-- ============================================================

alter table profiles
  add column if not exists country text;
