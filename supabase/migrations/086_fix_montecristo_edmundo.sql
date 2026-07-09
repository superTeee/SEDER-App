-- 086_fix_montecristo_edmundo.sql
--
-- Retter to feilregistrerte rader fra migrasjon 028.
--
-- Bakgrunnen: 028 ble skrevet ad hoc da Tom skannet et bånd, og spesifikasjonene
-- ble gjettet. Både «Wide Edmundo» og «Petit Edmundo» er CUBANSKE Habanos-vitolaer
-- i Montecristo-linjen — men de ble lagt inn som dominikanske, med Connecticut-
-- dekkblad, feil ringmål og uten lengde.
--
-- Merket Montecristo er delt: Habanos S.A. eier det på Cuba, Altadis/Tabacalera
-- de García eier det for resten av verden (Den dominikanske republikk). Edmundo-
-- familien — Edmundo, Petit Edmundo, Double Edmundo, Wide Edmundo — er Habanos.
--
-- Verifiserte spesifikasjoner:
--   Wide Edmundo   Duke No. 3, 125 mm × 54 rg  (4 7/8"), lansert 2021
--   Petit Edmundo  Petit Robusto, 110 mm × 52 rg (4 3/8"), lansert 2006
--
-- Begge er Totalmente a Mano con Tripa Larga, med blader fra Vuelta Abajo
-- i Pinar del Río.

update cigars
set manufacturer     = 'Habanos S.A.',
    country_origin   = 'Cuba',
    wrapper_country  = 'Cuba',
    wrapper_leaf     = 'Cuba',
    binder           = 'Cuba',
    filler           = array['Cuba'],
    vitola           = 'Duke No. 3',
    common_format    = 'Robusto Extra',
    shape            = 'Parejo',
    ring_gauge       = 54,
    length_inches    = 4.9,
    strength         = 3,
    description      = 'Montecristo Wide Edmundo — lansert i 2021 som den fjerde faste Edmundo-en, og det største ringmålet i merkets ordinære linje. Egen vitola hos Habanos: Duke No. 3. Kubansk tobakk fra Vuelta Abajo, med sedertre, kremet sødme, nøtter og et mildt krydder.',
    flavor_notes     = array['cedar','cream','nuts','sweet spice','coffee']
where brand = 'Montecristo' and series = 'Wide Edmundo';

update cigars
set manufacturer     = 'Habanos S.A.',
    country_origin   = 'Cuba',
    wrapper_country  = 'Cuba',
    wrapper_leaf     = 'Cuba',
    binder           = 'Cuba',
    filler           = array['Cuba'],
    vitola           = 'Petit Robusto',
    common_format    = 'Petit Robusto',
    shape            = 'Parejo',
    ring_gauge       = 52,
    length_inches    = 4.3,
    strength         = 4,
    description      = 'Montecristo Petit Edmundo — kortere utgave av Edmundo fra 2006, med egen blend. Kubansk tobakk fra Vuelta Abajo. Eik og sedertre med lær, dobbeltristet kaffe og fyldig kakao. Røyketid rundt 25 minutter.',
    flavor_notes     = array['oak','cedar','leather','coffee','cocoa']
where brand = 'Montecristo' and series = 'Petit Edmundo';
