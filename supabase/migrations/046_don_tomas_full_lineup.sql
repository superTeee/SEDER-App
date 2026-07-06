-- Migration 046: Don Tomás — full Clásico + International + Special Edition lineup
-- Eksisterende rader (Clasico/Robusto, Sun Grown/Toro, Allegro/Robusto) beholdes.
-- Alle tilføyde varianter bruker unaccented navn siden søkefunksjonen bruker unaccent().

-- Don Tomás Clásico (manglende vitola-størrelser)
INSERT INTO cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes, avg_rating)
VALUES
-- Clasico (resterende vitola-størrelser)
('General Cigar Co.', 'Don Tomas', 'Clasico', 'No. 1',        'Lonsdale',      43, 6.625, 'Parejo', null, null, null, 'Honduras', 'Honduras', 'Honduras', array['Honduras','Nicaragua'], 'Honduras', 3, '$3-5', 'Don Tomas Clasico No. 1 i klassisk Lonsdale-format — jordnær og balansert, med Honduras-dekkblad.', array['earth','cedar','black pepper','toasted nuts'], 8.2),
('General Cigar Co.', 'Don Tomas', 'Clasico', 'No. 2',        'Corona',        43, 5.625, 'Parejo', null, null, null, 'Honduras', 'Honduras', 'Honduras', array['Honduras','Nicaragua'], 'Honduras', 3, '$3-5', 'Don Tomas Clasico No. 2 i Corona-format, kompakt og velbalansert med typisk honduransk jordprofil.', array['earth','cedar','black pepper','leather'], 8.2),
('General Cigar Co.', 'Don Tomas', 'Clasico', 'No. 4',        'Toro',          50, 6.0,   'Parejo', null, null, null, 'Honduras', 'Honduras', 'Honduras', array['Honduras','Nicaragua'], 'Honduras', 3, '$3-5', 'Clasico No. 4 i Toro-format — litt mer røyketid enn Robusto og rikere smaksutvikling.', array['earth','cedar','black pepper','toasted nuts'], 8.2),
('General Cigar Co.', 'Don Tomas', 'Clasico', 'No. 5',        'Churchill',     50, 7.0,   'Parejo', null, null, null, 'Honduras', 'Honduras', 'Honduras', array['Honduras','Nicaragua'], 'Honduras', 3, '$3-5', 'Clasico No. 5 i Churchill-format — lang røyk med gradvis utviklende smak.', array['earth','cedar','leather','black pepper'], 8.2),
('General Cigar Co.', 'Don Tomas', 'Clasico', 'Gigante',      'Gigante',       52, 8.0,   'Parejo', null, null, null, 'Honduras', 'Honduras', 'Honduras', array['Honduras','Nicaragua'], 'Honduras', 3, '$4-6', 'Clasico Gigante — Hondurans lengste format med rik og kompleks smaksprofil.', array['earth','cedar','black pepper','coffee'], 8.2),
('General Cigar Co.', 'Don Tomas', 'Clasico', 'Epicure',      'Corona Grande', 44, 6.0,   'Parejo', null, null, null, 'Honduras', 'Honduras', 'Honduras', array['Honduras','Nicaragua'], 'Honduras', 3, '$3-5', 'Clasico Epicure i Corona Grande-format — balansert og jordnær med god lengde.', array['earth','cedar','cream','black pepper'], 8.2),
('General Cigar Co.', 'Don Tomas', 'Clasico', 'Matador',      'Torpedo',       52, 5.625, 'Parejo', 'Torpedo', null, null, 'Honduras', 'Honduras', 'Honduras', array['Honduras','Nicaragua'], 'Honduras', 3, '$3-5', 'Clasico Matador i Torpedo-format — smalner mot hodet og gir konsentrert jordnær smak.', array['earth','cedar','black pepper','leather'], 8.2),

-- Don Tomás International Series (kjent for Connecticut Shade-dekkblad)
('General Cigar Co.', 'Don Tomas', 'International', 'No. 1',  'Lonsdale',      43, 6.625, 'Parejo', null, null, null, 'United States', 'Connecticut Shade', 'Honduras', array['Honduras','Dominican Republic'], 'Honduras', 2, '$3-5', 'Don Tomas International bruker Connecticut Shade-dekkblad for en mildere og kremere profil enn Clasico.', array['cream','cedar','earth','toasted nuts'], 8.0),
('General Cigar Co.', 'Don Tomas', 'International', 'No. 2',  'Corona',        43, 5.625, 'Parejo', null, null, null, 'United States', 'Connecticut Shade', 'Honduras', array['Honduras','Dominican Republic'], 'Honduras', 2, '$3-5', 'International No. 2 i Corona-format — mildt og kremete med glatt Connecticut Shade.', array['cream','cedar','earth','white pepper'], 8.0),
('General Cigar Co.', 'Don Tomas', 'International', 'No. 4',  'Toro',          50, 6.0,   'Parejo', null, null, null, 'United States', 'Connecticut Shade', 'Honduras', array['Honduras','Dominican Republic'], 'Honduras', 2, '$3-5', 'International No. 4 Toro — mer røyketid og gradvis utvikling av den kremete smaksprofilen.', array['cream','cedar','earth','toasted nuts'], 8.0),
('General Cigar Co.', 'Don Tomas', 'International', 'No. 5',  'Churchill',     50, 7.0,   'Parejo', null, null, null, 'United States', 'Connecticut Shade', 'Honduras', array['Honduras','Dominican Republic'], 'Honduras', 2, '$3-5', 'International No. 5 Churchill — lang røyk med lett kremete Connecticut Shade-profil.', array['cream','cedar','earth','toasted nuts'], 8.0),

-- Don Tomás Special Edition (Maduro-dekkblad)
('General Cigar Co.', 'Don Tomas', 'Special Edition', 'Robusto',   'Robusto',   50, 5.0, 'Parejo', null, null, null, 'United States', 'Connecticut Broadleaf Maduro', 'Honduras', array['Honduras','Nicaragua'], 'Honduras', 3, '$4-6', 'Special Edition Maduro med Connecticut Broadleaf-dekkblad — søtere og rikere enn Clasico med mørke sjokolade- og kaffetoner.', array['dark chocolate','coffee','earth','sweet spice'], 8.3),
('General Cigar Co.', 'Don Tomas', 'Special Edition', 'Toro',      'Toro',      50, 6.0, 'Parejo', null, null, null, 'United States', 'Connecticut Broadleaf Maduro', 'Honduras', array['Honduras','Nicaragua'], 'Honduras', 3, '$4-6', 'Special Edition Toro Maduro — rik mellom/full styrke med sjokolade og søt krydder.', array['dark chocolate','coffee','earth','sweet spice'], 8.3),
('General Cigar Co.', 'Don Tomas', 'Special Edition', 'Churchill',  'Churchill', 50, 7.0, 'Parejo', null, null, null, 'United States', 'Connecticut Broadleaf Maduro', 'Honduras', array['Honduras','Nicaragua'], 'Honduras', 3, '$5-7', 'Special Edition Churchill Maduro — lang og kompleks Maduro-opplevelse med dype røkte og søte noter.', array['dark chocolate','espresso','leather','sweet spice'], 8.3),

-- Don Tomás Sun Grown (manglende vitola-størrelser)
('General Cigar Co.', 'Don Tomas', 'Sun Grown', 'Robusto',  'Robusto',   50, 5.0, 'Parejo', null, null, null, 'Honduras', 'Jamastran Sun Grown', 'Honduras', array['Honduras'], 'Honduras', 3, '$3-5', 'Sun Grown Robusto — det røde Jamastran-dekkbladet gir rik aroma og kremet medium styrke.', array['leather','cedar','sweet spice','earth'], 8.1),
('General Cigar Co.', 'Don Tomas', 'Sun Grown', 'Churchill', 'Churchill', 50, 7.0, 'Parejo', null, null, null, 'Honduras', 'Jamastran Sun Grown', 'Honduras', array['Honduras'], 'Honduras', 3, '$4-6', 'Sun Grown Churchill — lang røyk med det karakteristiske rødbrune Jamastran-dekkbladet.', array['leather','cedar','sweet spice','earth'], 8.1)

ON CONFLICT DO NOTHING;

-- Oppdater search_vector for de nye radene
UPDATE cigars
SET search_vector = to_tsvector('english',
    immutable_unaccent(coalesce(manufacturer,'')) || ' ' ||
    immutable_unaccent(coalesce(brand,'')) || ' ' ||
    immutable_unaccent(coalesce(series,'')) || ' ' ||
    immutable_unaccent(coalesce(vitola,'')) || ' ' ||
    immutable_unaccent(coalesce(common_format,''))
)
WHERE brand = 'Don Tomas';
