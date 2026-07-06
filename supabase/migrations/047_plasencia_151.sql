-- Migration 047: Plasencia 151 — full lineup
-- Navn: "151" feirer 151 år med Plasencia-familiens tobakksdyrking (1865–2016), lansert 2019.
-- Nicaraguansk puro: Habano Sun-Grown dekkblad, nicaraguansk innpakning og fyll.
-- Kilde: plasenciacigars.com, halfwheel.com, cigaraficionado.com

INSERT INTO cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes, avg_rating)
VALUES
('Plasencia', 'Plasencia', '151', 'Robusto',  'Robusto',   50, 5.0, 'Parejo', null, null, null, 'Nicaragua', 'Nicaraguan Habano Sun-Grown', 'Nicaraguan', array['Nicaragua'], 'Nicaragua', 4, '$10-15', 'Plasencia 151 Robusto er en nicaraguansk puro som feirer 151 år med Plasencia-familiens tobakkstradisjon. Habano Sun-Grown-dekkbladet gir dyp kompleksitet med kakao, pepper og mørk frukt.', array['cocoa','black pepper','dark fruit','coffee','cedar'], 9.0),
('Plasencia', 'Plasencia', '151', 'Toro',     'Toro',      52, 6.0, 'Parejo', null, null, null, 'Nicaragua', 'Nicaraguan Habano Sun-Grown', 'Nicaraguan', array['Nicaragua'], 'Nicaragua', 4, '$10-15', 'Plasencia 151 Toro gir mer røyketid enn Robusto og utvikler gradvis en rikere smaksprofil med leather og søt sedertre. En av de mest populære størrelsene i serien.', array['cocoa','leather','dark fruit','cedar','black pepper'], 9.1),
('Plasencia', 'Plasencia', '151', 'Gordo',    'Gordo',     60, 6.0, 'Parejo', null, null, null, 'Nicaragua', 'Nicaraguan Habano Sun-Grown', 'Nicaraguan', array['Nicaragua'], 'Nicaragua', 4, '$12-17', 'Plasencia 151 Gordo har det største ringmålet i serien — det brede formatet åpner for en kremet, jevn røyk med konsentrerte kakao- og kaffetoner og lavere nikotinintensitet.', array['cocoa','coffee','cream','dark fruit','cedar'], 9.0),
('Plasencia', 'Plasencia', '151', 'Churchill', 'Churchill', 48, 7.0, 'Parejo', null, null, null, 'Nicaragua', 'Nicaraguan Habano Sun-Grown', 'Nicaraguan', array['Nicaragua'], 'Nicaragua', 4, '$12-17', 'Plasencia 151 Churchill er den lengste og smaleste vitolaen i serien. Det slankere ringmålet intensiverer pepper og krydder, mens den lange røyken tillater gradvis overgang mot sedertre og lær.', array['black pepper','cedar','leather','cocoa','dark fruit'], 9.0)

ON CONFLICT DO NOTHING;

-- Oppdater search_vector for de nye radene
UPDATE cigars
SET search_vector = to_tsvector('english',
    immutable_unaccent(coalesce(manufacturer,'')) || ' ' ||
    immutable_unaccent(coalesce(brand,'')) || ' ' ||
    immutable_unaccent(coalesce(series,'')) || ' ' ||
    immutable_unaccent(coalesce(vitola,'')) || ' ' ||
    immutable_unaccent(coalesce(wrapper_leaf,'')) || ' ' ||
    immutable_unaccent(coalesce(country_origin,''))
)
WHERE brand = 'Plasencia' AND series = '151';
