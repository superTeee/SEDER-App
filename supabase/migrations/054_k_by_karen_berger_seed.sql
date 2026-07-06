-- Migration 054: K by Karen Berger full lineup
-- 4 wrapper lines × multiple vitolas = 15 cigars
-- All Nicaragua (Estelí Cigars S.A.), all box-pressed

INSERT INTO cigars (
    brand, series, vitola, common_format,
    length_inches, ring_gauge,
    country_origin, wrapper_type,
    strength, flavor_notes,
    manufacturer
) VALUES

-- ─── Connecticut ───────────────────────────────────────────────
('K by Karen Berger', 'Connecticut', 'Robusto',  'Robusto',  5.0, 52, 'Nicaragua', 'Connecticut',
 'mild-medium', 'Cream, Cedar, Almond, Light Pepper', 'Karen Berger Cigars'),

('K by Karen Berger', 'Connecticut', 'Toro',     'Toro',     6.0, 52, 'Nicaragua', 'Connecticut',
 'mild-medium', 'Cream, Cedar, Almond, Light Pepper', 'Karen Berger Cigars'),

('K by Karen Berger', 'Connecticut', 'Salomon',  'Figurado', 6.0, 58, 'Nicaragua', 'Connecticut',
 'mild-medium', 'Cream, Vanilla, Cedar, Nut', 'Karen Berger Cigars'),

('K by Karen Berger', 'Connecticut', 'Pyramid',  'Pyramid',  6.0, 52, 'Nicaragua', 'Connecticut',
 'mild-medium', 'Cream, Cedar, Almond, Toasted Bread', 'Karen Berger Cigars'),

-- ─── Habano ────────────────────────────────────────────────────
('K by Karen Berger', 'Habano', 'Robusto',  'Robusto',  5.0, 52, 'Nicaragua', 'Habano',
 'medium', 'Spice, Cedar, Earth, Pepper', 'Karen Berger Cigars'),

('K by Karen Berger', 'Habano', 'Toro',     'Toro',     6.0, 52, 'Nicaragua', 'Habano',
 'medium', 'Spice, Cedar, Earth, Leather', 'Karen Berger Cigars'),

('K by Karen Berger', 'Habano', 'Salomon',  'Figurado', 6.0, 58, 'Nicaragua', 'Habano',
 'medium', 'Spice, Cedar, Earth, Dark Fruit', 'Karen Berger Cigars'),

('K by Karen Berger', 'Habano', 'Lancero',  'Lancero',  7.0, 38, 'Nicaragua', 'Habano',
 'medium', 'Spice, Cedar, Pepper, Floral', 'Karen Berger Cigars'),

('K by Karen Berger', 'Habano', 'Pyramid',  'Pyramid',  6.0, 52, 'Nicaragua', 'Habano',
 'medium', 'Spice, Cedar, Earth, Pepper', 'Karen Berger Cigars'),

('K by Karen Berger', 'Habano', 'Grande',   'Gordo',    6.0, 60, 'Nicaragua', 'Habano',
 'medium', 'Spice, Cedar, Earth, Leather', 'Karen Berger Cigars'),

-- ─── Maduro ────────────────────────────────────────────────────
('K by Karen Berger', 'Maduro', 'Toro',     'Toro',     6.0, 52, 'Nicaragua', 'Maduro',
 'medium-full', 'Dark Chocolate, Coffee, Earth, Sweetness', 'Karen Berger Cigars'),

('K by Karen Berger', 'Maduro', 'Salomon',  'Figurado', 6.0, 58, 'Nicaragua', 'Maduro',
 'medium-full', 'Dark Chocolate, Coffee, Espresso, Earth', 'Karen Berger Cigars'),

('K by Karen Berger', 'Maduro', 'Pyramid',  'Pyramid',  6.0, 52, 'Nicaragua', 'Maduro',
 'medium-full', 'Dark Chocolate, Coffee, Earth, Sweetness', 'Karen Berger Cigars'),

('K by Karen Berger', 'Maduro', 'Grande',   'Gordo',    6.0, 60, 'Nicaragua', 'Maduro',
 'medium-full', 'Dark Chocolate, Coffee, Earth, Cedar', 'Karen Berger Cigars'),

-- ─── Cameroon ──────────────────────────────────────────────────
('K by Karen Berger', 'Cameroon', 'Pyramid', 'Pyramid',  6.0, 52, 'Nicaragua', 'Cameroon',
 'medium', 'Sweet Spice, Earth, Cedar, Complexity', 'Karen Berger Cigars');
