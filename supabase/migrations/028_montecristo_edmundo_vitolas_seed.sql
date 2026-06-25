-- Migration 028: Legg til manglende Montecristo Edmundo-vitolaer
--
-- Eksisterende rad: Montecristo / Edmundo / Robusto
-- Manglende:
--   - Wide Edmundo (5.5 x 60, Gordo) — det Tom skanner
--   - Petit Edmundo (4.5 x 52, Robusto)

insert into cigars (
  brand, series, vitola, shape, common_format,
  wrapper_leaf, country_of_origin,
  flavor_notes, avg_rating,
  body_type, head_type, foot_type
)
values
  -- Wide Edmundo: bred gordo-vitola (60 rg), Ecuadorian Connecticut wrapper
  (
    'Montecristo', 'Wide Edmundo', 'Wide Toro', 'Gordo', 'Gordo',
    'Connecticut', 'Dominican Republic',
    ARRAY['Kremete', 'sedertre', 'nøtter', 'mild krydder'], 9.0,
    'medium', 'closed', 'open'
  ),
  -- Petit Edmundo: kortere versjon av Edmundo-serien (4.5 x 52)
  (
    'Montecristo', 'Petit Edmundo', 'Robusto', 'Robusto', 'Robusto',
    'Connecticut', 'Dominican Republic',
    ARRAY['Kremete', 'sedertre', 'nøtter', 'mild krydder'], 8.9,
    'medium', 'closed', 'open'
  );
