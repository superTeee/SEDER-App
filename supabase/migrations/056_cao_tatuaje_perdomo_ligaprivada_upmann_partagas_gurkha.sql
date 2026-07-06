-- ============================================================
-- 056_cao_tatuaje_perdomo_ligaprivada_upmann_partagas_gurkha.sql
--
-- Gap-analyse på tvers av de 10 største sigarnettsidene
-- (Famous Smoke, Thompson Cigar, Cigars International, JR Cigars,
--  Best Cigar Prices, Cigars.com, Gotham Cigars, Holt's, Neptune,
--  Pipes & Cigars) avslørte følgende topmerker som manglet helt:
--
--   1) CAO             — General Cigar Co., hugely popular
--   2) Tatuaje         — Pete Johnson, top-rated boutique brand
--   3) Perdomo         — Nick Perdomo, Nicaragua-focused powerhouse
--   4) Liga Privada    — Drew Estate, No.9 og T52 blant alle tiders best-rated
--   5) Undercrown      — Drew Estate, ligaprivada's accessible sibling
--   6) H. Upmann       — General Cigar Co., historisk dominikansk linje
--   7) Partagas        — General Cigar Co., hondurask-dominikansk
--   8) Gurkha          — Luxury/premium brand, stor detaljeringshandel
--
-- Alle rader inkluderer flavor_notes og avg_rating.
-- ============================================================

-- ================================================================
-- 1) CAO (General Cigar Co.)
-- ================================================================

INSERT INTO cigars (
  manufacturer, brand, series, vitola, common_format,
  ring_gauge, length_inches, shape,
  body_type, head_type, foot_type,
  wrapper_country, wrapper_leaf, binder, filler,
  country_origin, strength, price_range,
  description, flavor_notes, avg_rating
) VALUES

-- CAO Flathead V554 Steel Horse
('General Cigar Co.', 'CAO', 'Flathead', 'V554 Steel Horse', 'Gordo',
 56, 5.5, 'Parejo',
 'colorado', 'rounded', 'open',
 'Nicaragua', 'Habano', 'Nicaragua', ARRAY['Nicaragua','Honduras'],
 'Nicaragua', 4, '$$',
 'CAO Flathead Steel Horse er samlerens favoritt — bred 56-ring gordo med rik nikotinstyrke og motorkultur-tematikk. Designet i samarbeid med Paul Castellanos.',
 ARRAY['dark chocolate','leather','earth','black pepper','cedar','espresso'], 9.0),

-- CAO Cameroon Corona Gorda
('General Cigar Co.', 'CAO', 'Cameroon', 'Corona Gorda', 'Toro',
 54, 6.0, 'Parejo',
 'colorado', 'rounded', 'open',
 'Cameroon', 'Cameroon', 'Honduras', ARRAY['Honduras','Dominican Republic'],
 'Honduras', 3, '$$',
 'CAO Cameroon er en klassiker fra 1968 — det klassiske Cameroon-dekkbladet leverer søt, kremaktig balanse med medium styrke.',
 ARRAY['cedar','cream','toasted nuts','cocoa','mild spice'], 8.7),

-- CAO Nicaragua Toro
('General Cigar Co.', 'CAO', 'Nicaragua', 'Toro', 'Toro',
 54, 6.0, 'Parejo',
 'colorado', 'rounded', 'open',
 'Nicaragua', 'Habano', 'Nicaragua', ARRAY['Nicaragua'],
 'Nicaragua', 4, '$$',
 'CAO Nicaragua er full-nikotinsk gjennomgående nicaraguansk — Jalapa-dekkblad over Estelí-kjerne gir kompleks pepper-krydder-profil.',
 ARRAY['black pepper','earth','leather','dark chocolate','cedar'], 8.8),

-- CAO Amazon Basin Toro
('General Cigar Co.', 'CAO', 'Amazon Basin', 'Toro', 'Toro',
 54, 6.0, 'Parejo',
 'colorado oscuro', 'rounded', 'open',
 'Brazil', 'Bragança Oscuro', 'Peru', ARRAY['Nicaragua','Peru'],
 'Nicaragua', 4, '$$$',
 'CAO Amazon Basin bruker ekstremt sjeldent brasiliansk Bragança Oscuro-dekkblad fra Amazonas. Begrenset produksjon, meget etterspurt.',
 ARRAY['dark chocolate','earth','dried fruit','leather','cocoa','espresso'], 9.2),

-- CAO Pilon Anejo Robusto
('General Cigar Co.', 'CAO', 'Pilon Anejo', 'Robusto', 'Robusto',
 52, 5.0, 'Parejo',
 'colorado maduro', 'rounded', 'open',
 'Dominican Republic', 'Piloto Ligero', 'Dominican Republic', ARRAY['Dominican Republic','Nicaragua'],
 'Dominican Republic', 3, '$',
 'CAO Pilon er en verdi-linje med dominikansk Piloto Ligero-dekkblad og tilgjengelig medium styrke.',
 ARRAY['cedar','nuts','cream','mild spice','earth'], 8.3),

-- ================================================================
-- 2) Tatuaje (Pete Johnson / My Father Cigars Factory)
-- ================================================================

-- Tatuaje Brown Label Robusto
('My Father Cigars', 'Tatuaje', 'Brown Label', 'Robusto', 'Robusto',
 50, 5.0, 'Parejo',
 'colorado', 'rounded', 'open',
 'Nicaragua', 'Habano Oscuro', 'Nicaragua', ARRAY['Nicaragua'],
 'Nicaragua', 4, '$$',
 'Tatuaje Brown Label er Pete Johnsons klassiske Habano Oscuro-linje — medium-full med typisk nicaraguansk krydder fra My Father-fabrikken.',
 ARRAY['black pepper','cedar','leather','dark chocolate','earth'], 9.0),

-- Tatuaje Havana VI Robusto
('My Father Cigars', 'Tatuaje', 'Havana VI', 'Robusto', 'Robusto',
 50, 5.0, 'Parejo',
 'colorado claro', 'rounded', 'open',
 'Ecuador', 'Connecticut Shade', 'Nicaragua', ARRAY['Nicaragua'],
 'Nicaragua', 3, '$$',
 'Havana VI er Tatuajes mildere linje — Ecuador Connecticut Shade-dekkblad over nicaraguansk kjerne for en balansert røyk.',
 ARRAY['cream','cedar','toasted nuts','mild spice','hay'], 8.6),

-- Tatuaje La Verite Toro
('My Father Cigars', 'Tatuaje', 'La Verite', 'Toro', 'Toro',
 52, 6.0, 'Parejo',
 'colorado oscuro', 'rounded', 'open',
 'Nicaragua', 'Habano', 'Nicaragua', ARRAY['Nicaragua'],
 'Nicaragua', 5, '$$$',
 'La Verite er Tatuajes prestisjeproduksjon — intensivt aldret hondurask- og nicaraguansk tobakk gir en av de mest komplekse røykene i hele porteføljen.',
 ARRAY['dark chocolate','espresso','black pepper','leather','dried fruit','cedar'], 9.4),

-- Tatuaje Pork Tenderloin (Mi Amor Reserva)
('My Father Cigars', 'Tatuaje', 'Mi Amor Reserva', 'Torpedo', 'Torpedo',
 52, 6.5, 'Figurado',
 'colorado', 'pointed', 'closed',
 'Nicaragua', 'Habano', 'Nicaragua', ARRAY['Nicaragua'],
 'Nicaragua', 4, '$$$',
 'Tatuaje Mi Amor Reserva er en av de mest ettertraktede limited releases — en torpedo med konsentrert krydder og dybde fra fullt aldret nicaraguansk tobakk.',
 ARRAY['black pepper','dark chocolate','earth','leather','espresso'], 9.1),

-- ================================================================
-- 3) Perdomo (Perdomo Cigar Co.)
-- ================================================================

-- Perdomo 10th Anniversary Champagne Robusto
('Perdomo Cigar Co.', 'Perdomo', '10th Anniversary Champagne', 'Robusto', 'Robusto',
 54, 5.0, 'Parejo',
 'claro', 'rounded', 'open',
 'Nicaragua', 'Connecticut Shade', 'Nicaragua', ARRAY['Nicaragua'],
 'Nicaragua', 2, '$$',
 'Perdomo 10th Anniversary Champagne er mild og kremet — et Ecuador Connecticut Shade-dekkblad over all-nicaraguansk kjerne for glatt, tilgjengelig røyk.',
 ARRAY['cream','cedar','almond','mild spice','hay'], 8.7),

-- Perdomo 10th Anniversary Maduro Robusto
('Perdomo Cigar Co.', 'Perdomo', '10th Anniversary Maduro', 'Robusto', 'Robusto',
 54, 5.0, 'Parejo',
 'colorado maduro', 'rounded', 'open',
 'Nicaragua', 'Maduro', 'Nicaragua', ARRAY['Nicaragua'],
 'Nicaragua', 4, '$$',
 'Maduro-versjonen av jubileumsjubileet: naturlig fermentert nicaraguansk Maduro-dekkblad som gir søt, kaffepreget fullkroppethet.',
 ARRAY['dark chocolate','espresso','cedar','earth','cocoa'], 9.0),

-- Perdomo Habano Bourbon Barrel-Aged Sun Grown
('Perdomo Cigar Co.', 'Perdomo', 'Habano Bourbon Barrel-Aged', 'Toro', 'Toro',
 54, 6.0, 'Parejo',
 'colorado', 'rounded', 'open',
 'Nicaragua', 'Habano', 'Nicaragua', ARRAY['Nicaragua'],
 'Nicaragua', 4, '$$',
 'Habano Bourbon Barrel-Aged er el av Perdomos mest særpregede linjer — tobakken aldres i bourbon-fat for vaniljetoner og en karakteristisk sødme.',
 ARRAY['vanilla','oak','leather','black pepper','cedar','dark chocolate'], 9.1),

-- Perdomo Champagne Lot 23
('Perdomo Cigar Co.', 'Perdomo', 'Champagne Lot 23', 'Toro', 'Toro',
 60, 6.0, 'Parejo',
 'claro', 'rounded', 'open',
 'Nicaragua', 'Connecticut Shade', 'Nicaragua', ARRAY['Nicaragua'],
 'Nicaragua', 2, '$$$',
 'Champagne Lot 23 er Perdomos flaggskip i Connecticut-kategorien: ekstremt aldret, 60-rings gordo med silkemyk finish.',
 ARRAY['cream','toasted nuts','cedar','vanilla','mild spice'], 9.2),

-- Perdomo Inmenso Seventy Robusto
('Perdomo Cigar Co.', 'Perdomo', 'Inmenso Seventy', 'Robusto', 'Robusto',
 54, 5.0, 'Parejo',
 'colorado oscuro', 'rounded', 'open',
 'Nicaragua', 'Habano', 'Nicaragua', ARRAY['Nicaragua'],
 'Nicaragua', 5, '$$$',
 'Inmenso Seventy ble lansert for å feire Nick Perdomos 70-årsdag — full-kroppet, ekstremt kompleks og kun i begrenset opplag.',
 ARRAY['dark chocolate','espresso','black pepper','cedar','leather','dried fruit'], 9.3),

-- ================================================================
-- 4) Liga Privada (Drew Estate)
-- ================================================================

-- Liga Privada No. 9 Robusto
('Drew Estate', 'Liga Privada', 'No. 9', 'Robusto', 'Robusto',
 52, 5.0, 'Parejo',
 'colorado oscuro', 'rounded', 'open',
 'United States', 'Connecticut Broadleaf', 'Honduras', ARRAY['Nicaragua','Honduras'],
 'Nicaragua', 5, '$$$',
 'Liga Privada No. 9 er Jonathan Drews personlige blend — #1 på Cigar Aficionados Top 25-liste og en av tidenes mest gjenkjøpte premium-sigarer. Intenst mørkt Connecticut Broadleaf-dekkblad fra Hartford (CT).',
 ARRAY['dark chocolate','espresso','black pepper','leather','earth','cedar'], 9.7),

-- Liga Privada No. 9 Toro
('Drew Estate', 'Liga Privada', 'No. 9', 'Toro', 'Toro',
 54, 6.0, 'Parejo',
 'colorado oscuro', 'rounded', 'open',
 'United States', 'Connecticut Broadleaf', 'Honduras', ARRAY['Nicaragua','Honduras'],
 'Nicaragua', 5, '$$$',
 'Toro-formatet av No. 9 gir lenger røyketid og enda mer kompleksitet — en av de mest ettertraktede toro-sigarene i premiumsegmentet.',
 ARRAY['dark chocolate','espresso','black pepper','leather','earth','dark fruit'], 9.6),

-- Liga Privada T52 Robusto
('Drew Estate', 'Liga Privada', 'T52', 'Robusto', 'Robusto',
 52, 5.0, 'Parejo',
 'colorado oscuro', 'rounded', 'open',
 'United States', 'Connecticut Stalk Cut', 'Honduras', ARRAY['Nicaragua','Honduras'],
 'Nicaragua', 4, '$$$',
 'T52 bruker et "stalk-cut"-Broadleaf-dekkblad fra 52-raden — litt lettere og mer silkeaktig enn No. 9, men like kompleks og full-kroppet.',
 ARRAY['dark chocolate','black pepper','leather','cedar','espresso','toasted nuts'], 9.4),

-- Liga Privada Unico Serie H.O.F.
('Drew Estate', 'Liga Privada', 'Unico Serie', 'H.O.F. (Hall of Fame)', 'Toro',
 54, 6.0, 'Parejo',
 'colorado oscuro', 'rounded', 'open',
 'United States', 'Connecticut Broadleaf', 'Honduras', ARRAY['Nicaragua','Honduras'],
 'Nicaragua', 5, '$$$$',
 'Unico Serie H.O.F. er en svært begrenset spesialutgivelse fra Drew Estate — kun solgt gjennom utvalgte forhandlere med "Hall of Fame"-status.',
 ARRAY['dark chocolate','espresso','earth','black pepper','cedar','leather'], 9.5),

-- ================================================================
-- 5) Undercrown (Drew Estate)
-- ================================================================

-- Undercrown Robusto
('Drew Estate', 'Undercrown', 'Original', 'Robusto', 'Robusto',
 52, 5.0, 'Parejo',
 'colorado oscuro', 'rounded', 'open',
 'United States', 'Connecticut Broadleaf', 'Honduras', ARRAY['Nicaragua','Honduras'],
 'Nicaragua', 4, '$$',
 'Undercrown ble skapt av torcedorene på Drew Estate som blander Liga Privada — et mer tilgjengelig alternativ til No.9 med de samme dekkbladsortene og tobakkopprinnelsene.',
 ARRAY['dark chocolate','black pepper','cedar','leather','earth','espresso'], 9.0),

-- Undercrown Shade Toro
('Drew Estate', 'Undercrown', 'Shade', 'Toro', 'Toro',
 54, 6.0, 'Parejo',
 'claro', 'rounded', 'open',
 'Ecuador', 'Connecticut Shade', 'Honduras', ARRAY['Nicaragua','Honduras'],
 'Nicaragua', 3, '$$',
 'Undercrown Shade er den mildere, lysere broren til originalen — Ecuador Connecticut Shade-dekkblad for silkemykhet og en kremaktig, nøtteaktig profil.',
 ARRAY['cream','toasted nuts','cedar','mild spice','cocoa'], 9.1),

-- Undercrown Sun Grown Robusto
('Drew Estate', 'Undercrown', 'Sun Grown', 'Robusto', 'Robusto',
 52, 5.0, 'Parejo',
 'colorado', 'rounded', 'open',
 'Nicaragua', 'Sun Grown', 'Honduras', ARRAY['Nicaragua','Honduras'],
 'Nicaragua', 4, '$$',
 'Undercrown Sun Grown bytter til et lysedyrket nicaraguansk dekkblad — mer pepper og lær enn Shade, men litt lettere enn Broadleaf-originalen.',
 ARRAY['black pepper','leather','cedar','dark chocolate','earth'], 8.9),

-- ================================================================
-- 6) H. Upmann (General Cigar Co. / Altadis)
-- ================================================================

-- H. Upmann Vintage Cameroon Robusto
('Altadis U.S.A.', 'H. Upmann', 'Vintage Cameroon', 'Robusto', 'Robusto',
 50, 5.0, 'Parejo',
 'colorado claro', 'rounded', 'open',
 'Cameroon', 'Cameroon', 'Dominican Republic', ARRAY['Dominican Republic','Honduras'],
 'Dominican Republic', 2, '$$',
 'H. Upmann Vintage Cameroon er en elegant mild-medium røyk med det karakteristiske Cameroon-dekkbladet — notater av honning, sedertre og fint krydder.',
 ARRAY['honey','cedar','toasted nuts','mild spice','cream'], 8.7),

-- H. Upmann 1844 Robusto
('Altadis U.S.A.', 'H. Upmann', '1844', 'Robusto', 'Robusto',
 52, 5.0, 'Parejo',
 'claro', 'rounded', 'open',
 'Ecuador', 'Connecticut Shade', 'Dominican Republic', ARRAY['Dominican Republic'],
 'Dominican Republic', 1, '$',
 'H. Upmann 1844 er en klassisk mild, tilgjengelig linje oppkalt etter grunnleggelsesåret — glatt Ecuador Connecticut Shade-dekkblad.',
 ARRAY['cream','cedar','mild spice','hay','toasted bread'], 8.3),

-- H. Upmann Connecticut Toro
('Altadis U.S.A.', 'H. Upmann', 'Connecticut', 'Toro', 'Toro',
 54, 6.0, 'Parejo',
 'claro', 'rounded', 'open',
 'Ecuador', 'Connecticut Shade', 'Honduras', ARRAY['Dominican Republic','Nicaragua'],
 'Dominican Republic', 2, '$$',
 'H. Upmann Connecticut er den moderne Connecticut-linjen — medium-mild med Ecuador Shade-dekkblad over dominikansk/nicaraguansk kjerne.',
 ARRAY['cream','cedar','almonds','mild spice','vanilla'], 8.6),

-- H. Upmann The Banker Toro
('General Cigar Co.', 'H. Upmann', 'The Banker', 'Toro', 'Toro',
 50, 6.0, 'Parejo',
 'colorado', 'rounded', 'open',
 'Ecuador', 'Habano', 'Honduras', ARRAY['Nicaragua','Honduras'],
 'Honduras', 4, '$$$',
 'H. Upmann The Banker er den kraftigste og mest prestisjefylte moderne U-linjen — Ecuador Habano-dekkblad over full-kroppet hondurask/nicaraguansk kjerne.',
 ARRAY['dark chocolate','black pepper','leather','cedar','earth','coffee'], 9.2),

-- ================================================================
-- 7) Partagas (General Cigar Co. / Altadis — non-Cuban)
-- ================================================================

-- Partagas Black Label Robusto
('General Cigar Co.', 'Partagas', 'Black Label', 'Robusto', 'Robusto',
 50, 5.0, 'Parejo',
 'colorado oscuro', 'rounded', 'open',
 'Nicaragua', 'Habano', 'Honduras', ARRAY['Honduras','Nicaragua'],
 'Honduras', 5, '$$',
 'Partagas Black Label er den kraftigste linjen i den dominikansk-honduransk-nicaraguanske Partagas-porteføljen — full styrke med mørkt nicaraguansk Habano-dekkblad.',
 ARRAY['black pepper','leather','dark chocolate','earth','espresso'], 9.0),

-- Partagas 1845 Robusto
('General Cigar Co.', 'Partagas', '1845', 'Robusto', 'Robusto',
 50, 5.0, 'Parejo',
 'colorado', 'rounded', 'open',
 'Nicaragua', 'Nicaraguan', 'Honduras', ARRAY['Honduras','Dominican Republic'],
 'Honduras', 3, '$$',
 'Partagas 1845 er en medium-full hyllest til merkets grunnleggelsesår — balansert pepper og sedertre med honduransk kjerne.',
 ARRAY['cedar','black pepper','leather','toasted nuts','earth'], 8.7),

-- Partagas Heritage Robusto
('Altadis U.S.A.', 'Partagas', 'Heritage', 'Robusto', 'Robusto',
 50, 5.0, 'Parejo',
 'colorado', 'rounded', 'open',
 'United States', 'Connecticut Broadleaf', 'Dominican Republic', ARRAY['Dominican Republic'],
 'Dominican Republic', 3, '$$',
 'Partagas Heritage bruker et naturlig Connecticut Broadleaf-dekkblad som gir kaffe og sedertre-notater over en ren dominikansk kjerne.',
 ARRAY['coffee','cedar','leather','mild spice','earth'], 8.5),

-- ================================================================
-- 8) Gurkha (Kaizad Hansotia)
-- ================================================================

-- Gurkha Ghost Torpedo
('Gurkha Cigar Group', 'Gurkha', 'Ghost', 'Torpedo', 'Torpedo',
 52, 6.5, 'Figurado',
 'colorado oscuro', 'pointed', 'closed',
 'Ecuador', 'Habano', 'Honduras', ARRAY['Honduras','Nicaragua'],
 'Honduras', 5, '$$$$',
 'Gurkha Ghost er den berømte ultra-premium Gurkha — "ghost" dekkbladet er dyrket under skyggetnett i Ecuador for maksimal oljerikdom. Full styrke med kompleks profil.',
 ARRAY['dark chocolate','espresso','black pepper','leather','earth','cedar'], 9.3),

-- Gurkha Royal Challenge Toro
('Gurkha Cigar Group', 'Gurkha', 'Royal Challenge', 'Toro', 'Toro',
 54, 6.0, 'Parejo',
 'colorado', 'rounded', 'open',
 'Honduras', 'Habano', 'Honduras', ARRAY['Honduras','Nicaragua'],
 'Honduras', 3, '$$$',
 'Gurkha Royal Challenge er en god inngang til Gurkha-universet — medium-full med et glatt honduransk Habano-dekkblad.',
 ARRAY['cedar','leather','black pepper','earth','mild spice'], 8.7),

-- Gurkha Heritage Robusto
('Gurkha Cigar Group', 'Gurkha', 'Heritage', 'Robusto', 'Robusto',
 52, 5.0, 'Parejo',
 'colorado claro', 'rounded', 'open',
 'Ecuador', 'Connecticut Shade', 'Ecuador', ARRAY['Honduras','Nicaragua'],
 'Honduras', 2, '$$',
 'Gurkha Heritage er den mildere linjen — Ecuador Connecticut Shade-dekkblad over honduransk/nicaraguansk kjerne gir en kremet, tilgjengelig røyk.',
 ARRAY['cream','cedar','toasted nuts','mild spice','vanilla'], 8.5),

-- Gurkha Black Dragon Perfecto
('Gurkha Cigar Group', 'Gurkha', 'Black Dragon', 'Perfecto', 'Perfecto',
 52, 5.5, 'Figurado',
 'colorado oscuro', 'rounded', 'perfecto',
 'Nicaragua', 'Maduro', 'Honduras', ARRAY['Honduras','Nicaragua'],
 'Honduras', 4, '$$$$',
 'Gurkha Black Dragon er en av merkets ikoniske utgaver — sjelden perfecto-form med nicaraguansk Maduro-dekkblad. Selges i svart lakklakkert boks.',
 ARRAY['dark chocolate','espresso','black pepper','cedar','molasses','leather'], 9.0);

-- cigar_aliases for søkbarhet
INSERT INTO cigar_aliases (alias, manufacturer, brand) VALUES
  ('C.A.O.', 'General Cigar Co.', 'CAO'),
  ('Cao Cigars', 'General Cigar Co.', 'CAO'),
  ('Pete Johnson', 'My Father Cigars', 'Tatuaje'),
  ('Tatuaje Brown', 'My Father Cigars', 'Tatuaje'),
  ('Nick Perdomo', 'Perdomo Cigar Co.', 'Perdomo'),
  ('Perdomo Cigars', 'Perdomo Cigar Co.', 'Perdomo'),
  ('LP No.9', 'Drew Estate', 'Liga Privada'),
  ('Liga Privada No 9', 'Drew Estate', 'Liga Privada'),
  ('LP T52', 'Drew Estate', 'Liga Privada'),
  ('Drew Estate Undercrown', 'Drew Estate', 'Undercrown'),
  ('Upmann', 'Altadis U.S.A.', 'H. Upmann'),
  ('HUpmann', 'Altadis U.S.A.', 'H. Upmann'),
  ('H Upmann', 'Altadis U.S.A.', 'H. Upmann'),
  ('Partagas Non-Cuban', 'General Cigar Co.', 'Partagas'),
  ('Gurkha Cigars', 'Gurkha Cigar Group', 'Gurkha')
ON CONFLICT DO NOTHING;
