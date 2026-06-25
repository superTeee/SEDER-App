-- Migration 032: San Lotano (AJ Fernandez) — manglende serier
-- Eksisterende: San Lotano Oval, San Lotano Requiem Maduro
-- Ny: Connecticut, Habano, The Bull, Dominicano
-- San Lotano er AJ Fernandez sin premium-linje, oppkalt etter Jalapa-dalen i Nicaragua

INSERT INTO cigars (
    brand, series, vitola, wrapper_leaf, binder_leaf, filler_blend,
    origin_country, body_strength, flavor_notes, common_format,
    ring_gauge, length_inches, description
) VALUES

-- ============================================================
-- SAN LOTANO CONNECTICUT
-- Connecticut shade wrapper, Nicaraguan binder/filler
-- Mild-medium, kremet og søtt
-- ============================================================
('AJ Fernandez', 'San Lotano Connecticut', 'Robusto',
 'Connecticut Shade', 'Nicaraguan', 'Nicaraguan',
 'Nicaragua', 'mild-medium', ARRAY['cream', 'cedar', 'almond', 'mild spice', 'hay'],
 'robusto', 50, 5.0,
 'San Lotano Connecticut Robusto — 5" x 50. Connecticut shade-wrapper gir en myk og kremete røyk med noter av mandel og seder. AJ Fernandez sin tilnærming til en tilgjengelig, velbalansert Connecticut.'),

('AJ Fernandez', 'San Lotano Connecticut', 'Toro',
 'Connecticut Shade', 'Nicaraguan', 'Nicaraguan',
 'Nicaragua', 'mild-medium', ARRAY['cream', 'cedar', 'almond', 'white pepper', 'hay'],
 'toro', 52, 6.0,
 'San Lotano Connecticut Toro — 6" x 52. Mer kompleksitet enn Robusto takket være lengden. Kremete og glatt med hvit pepper i avslutningen.'),

('AJ Fernandez', 'San Lotano Connecticut', 'Churchill',
 'Connecticut Shade', 'Nicaraguan', 'Nicaraguan',
 'Nicaragua', 'mild-medium', ARRAY['cream', 'cedar', 'almond', 'floral', 'mild spice'],
 'churchill', 48, 7.0,
 'San Lotano Connecticut Churchill — 7" x 48. Den lengste vitolaen i linjen. Lang, jevn røyk med kremete og florale toner gjennom hele sigaren.'),

('AJ Fernandez', 'San Lotano Connecticut', 'Gran Toro',
 'Connecticut Shade', 'Nicaraguan', 'Nicaraguan',
 'Nicaragua', 'mild-medium', ARRAY['cream', 'cedar', 'nut', 'almond', 'white pepper'],
 'gordo', 58, 6.0,
 'San Lotano Connecticut Gran Toro — 6" x 58. Bred ring gauge gir en kjøl, kremet røyk. Mye volum med subtil nøtteaktig sødme.'),

-- ============================================================
-- SAN LOTANO HABANO
-- Ecuadorian Habano wrapper, Nicaraguan binder/filler
-- Medium til medium-full, jordete og krydret
-- ============================================================
('AJ Fernandez', 'San Lotano Habano', 'Robusto',
 'Ecuadorian Habano', 'Nicaraguan', 'Nicaraguan',
 'Nicaragua', 'medium', ARRAY['earth', 'spice', 'leather', 'cedar', 'coffee'],
 'robusto', 50, 5.0,
 'San Lotano Habano Robusto — 5" x 50. Ecuadorisk Habano-wrapper gir dyp jord og krydder. En robust og kompleks medium-styrke sigar med lærnoter og kaffe i avslutningen.'),

('AJ Fernandez', 'San Lotano Habano', 'Toro',
 'Ecuadorian Habano', 'Nicaraguan', 'Nicaraguan',
 'Nicaragua', 'medium', ARRAY['earth', 'spice', 'leather', 'dark chocolate', 'coffee'],
 'toro', 52, 6.0,
 'San Lotano Habano Toro — 6" x 52. Mer kompleksitet utvikles i lengden — mørk sjokolade og jord dominerer med et krydret ettersmak.'),

('AJ Fernandez', 'San Lotano Habano', 'Churchill',
 'Ecuadorian Habano', 'Nicaraguan', 'Nicaraguan',
 'Nicaragua', 'medium', ARRAY['earth', 'cedar', 'spice', 'leather', 'nougat'],
 'churchill', 48, 7.0,
 'San Lotano Habano Churchill — 7" x 48. Den lange vitolaen åpner opp den komplekse Habano-karakteren. Nougat og seder mot slutten.'),

('AJ Fernandez', 'San Lotano Habano', 'Gran Toro',
 'Ecuadorian Habano', 'Nicaraguan', 'Nicaraguan',
 'Nicaragua', 'medium', ARRAY['earth', 'spice', 'leather', 'cedar', 'dark fruit'],
 'gordo', 58, 6.0,
 'San Lotano Habano Gran Toro — 6" x 58. Bred ring gauge åpner for mye volum. Mørkt frukt og jord i en kompleks og langvarig røyk.'),

('AJ Fernandez', 'San Lotano Habano', 'Torpedo',
 'Ecuadorian Habano', 'Nicaraguan', 'Nicaraguan',
 'Nicaragua', 'medium', ARRAY['spice', 'earth', 'leather', 'pepper', 'coffee'],
 'torpedo', 52, 6.25,
 'San Lotano Habano Torpedo — 6 1/4" x 52. Det tilspissede hodet konsentrerer smaken — mer pepper og krydder enn de andre Habano-vitolaene.'),

-- ============================================================
-- SAN LOTANO THE BULL
-- Nicaraguan puro — San Andrés Mexican wrapper, all Nicaraguan
-- Medium-full, jordete og kraftig
-- ============================================================
('AJ Fernandez', 'San Lotano The Bull', 'Robusto',
 'Mexican San Andrés', 'Nicaraguan', 'Nicaraguan',
 'Nicaragua', 'medium-full', ARRAY['dark chocolate', 'earth', 'espresso', 'spice', 'leather'],
 'robusto', 52, 5.0,
 'San Lotano The Bull Robusto — 5" x 52. Meksikansk San Andrés-wrapper gir mørk sjokolade og espresso. Kraftig og jordete — en av de sterkeste San Lotano-linjene.'),

('AJ Fernandez', 'San Lotano The Bull', 'Toro',
 'Mexican San Andrés', 'Nicaraguan', 'Nicaraguan',
 'Nicaragua', 'medium-full', ARRAY['dark chocolate', 'earth', 'espresso', 'pepper', 'leather'],
 'toro', 52, 6.0,
 'San Lotano The Bull Toro — 6" x 52. Den mest populære The Bull-vitolaen. Lang røyk som utvikler seg fra pepper tidlig til mørk sjokolade og lær mot slutten.'),

('AJ Fernandez', 'San Lotano The Bull', 'Gran Toro',
 'Mexican San Andrés', 'Nicaraguan', 'Nicaraguan',
 'Nicaragua', 'medium-full', ARRAY['dark chocolate', 'espresso', 'earth', 'dark fruit', 'spice'],
 'gordo', 58, 6.0,
 'San Lotano The Bull Gran Toro — 6" x 58. Den bredeste The Bull-vitolaen. Enormt volum av mørk røyk med sjokolade og mørkt frukt.'),

-- ============================================================
-- SAN LOTANO DOMINICANO
-- Olor Dominicano wrapper — unik linje med dominikansk wrapper
-- Medium, jevn og balansert
-- ============================================================
('AJ Fernandez', 'San Lotano Dominicano', 'Robusto',
 'Dominican Olor', 'Nicaraguan', 'Nicaraguan',
 'Nicaragua', 'medium', ARRAY['cedar', 'cream', 'earth', 'mild spice', 'nut'],
 'robusto', 50, 5.0,
 'San Lotano Dominicano Robusto — 5" x 50. Den eneste San Lotano-linjen med dominikansk Olor-wrapper. Glatt og jevn med en balansert kombinasjon av seder, krem og jord.'),

('AJ Fernandez', 'San Lotano Dominicano', 'Toro',
 'Dominican Olor', 'Nicaraguan', 'Nicaraguan',
 'Nicaragua', 'medium', ARRAY['cedar', 'earth', 'cream', 'leather', 'mild spice'],
 'toro', 52, 6.0,
 'San Lotano Dominicano Toro — 6" x 52. Dominikansk wrapper kombinert med nicaraguansk kjerne gir en unik smaksprofil. Balansert mellom det kremete og det jordete.'),

('AJ Fernandez', 'San Lotano Dominicano', 'Churchill',
 'Dominican Olor', 'Nicaraguan', 'Nicaraguan',
 'Nicaragua', 'medium', ARRAY['cedar', 'cream', 'earth', 'floral', 'nut'],
 'churchill', 48, 7.0,
 'San Lotano Dominicano Churchill — 7" x 48. Lang røyk som utvikler seg fra florale noter tidlig til kremet seder og nøtt mot slutten.'),

('AJ Fernandez', 'San Lotano Dominicano', 'Torpedo',
 'Dominican Olor', 'Nicaraguan', 'Nicaraguan',
 'Nicaragua', 'medium', ARRAY['spice', 'cedar', 'earth', 'leather', 'cream'],
 'torpedo', 52, 6.25,
 'San Lotano Dominicano Torpedo — 6 1/4" x 52. Torpedo-formen forsterker krydder og seder i en ellers balansert og glatt Dominicano.');

-- Verifisér
SELECT brand, series, vitola, common_format, ring_gauge, length_inches
FROM cigars
WHERE brand = 'AJ Fernandez'
ORDER BY series, vitola;
