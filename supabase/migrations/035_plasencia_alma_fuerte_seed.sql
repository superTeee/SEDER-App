-- Migrasjon 035: Plasencia Alma Fuerte + manglende Plasencia-serier
-- Kilde: plasenciacigars.com, cigaraficionado.com, halfwheel.com
-- Plasencia er en av de største og mest anerkjente produsentene fra Nicaragua/Honduras.
-- Alma Fuerte er flaggskipet — en nicaraguansk puro med svart Ecuador-wrapper.
-- Merk: "Alma del Campo" (hvit Connecticut) er allerede i databasen (migrasjon 019).

INSERT INTO cigars (
  brand, manufacturer, series, vitola, common_format,
  ring_gauge, length_inches, shape,
  country_of_origin, wrapper_origin, wrapper_leaf,
  filler_countries, binder_origin,
  strength, body_type,
  avg_rating,
  description, flavor_notes
) VALUES

-- ─── PLASENCIA ALMA FUERTE ───────────────────────────────────────────────────
-- Nicaraguansk puro med Oscuro-wrapper. 90+ rating fra CA.

('Plasencia','Plasencia','Alma Fuerte','Robustito','Robusto',50,5.25,'Parejo',
 'Nicaragua','Ecuador','Ecuador Oscuro',
 array['Nicaragua'],'Nicaragua',
 5,null,93,
 'Plasencias kronjuvel — en kraftfull nicaraguansk puro kledt i en skinnende sort Ecuador Oscuro-wrapper. Robustito-formatet gir en konsentrert smakopplevelse med espresso, mørk sjokolade og lær.',
 array['dark chocolate','espresso','leather','black pepper','cedar','earth']),

('Plasencia','Plasencia','Alma Fuerte','Nestor II','Toro',52,6.0,'Parejo',
 'Nicaragua','Ecuador','Ecuador Oscuro',
 array['Nicaragua'],'Nicaragua',
 5,null,94,
 'Nestor II er toro-formatet i Alma Fuerte-serien — en av de mest prisvinnende nicaraguanske puros i nyere tid. Rik og kompleks med mørke, søte noter balansert av kraftig rygggrad.',
 array['dark chocolate','espresso','cedar','black pepper','leather','sweet spice']),

('Plasencia','Plasencia','Alma Fuerte','Nestor IV','Gran Toro',54,6.5,'Parejo',
 'Nicaragua','Ecuador','Ecuador Oscuro',
 array['Nicaragua'],'Nicaragua',
 5,null,93,
 'Gran Toro-utgaven av Alma Fuerte lar blenden åpne seg mer, med en søtere og fyldigere røykopplevelse som avslutter med langt etterspill.',
 array['espresso','dark chocolate','dried fruit','earth','leather','sweet cedar']),

('Plasencia','Plasencia','Alma Fuerte','Nimbostratus','Gordo',58,6.0,'Parejo',
 'Nicaragua','Ecuador','Ecuador Oscuro',
 array['Nicaragua'],'Nicaragua',
 5,null,92,
 'Den brede ringmålen i Alma Fuerte-serien — rik og kremet røykutvikling med kraftig styrke og dyp kompleksitet.',
 array['dark chocolate','earth','leather','espresso','cedar','pepper']),

('Plasencia','Plasencia','Alma Fuerte','Consentido','Lancero',40,7.0,'Parejo',
 'Nicaragua','Ecuador','Ecuador Oscuro',
 array['Nicaragua'],'Nicaragua',
 5,null,92,
 'Lanseringen av Alma Fuerte Consentido demonstrerer Plasencias mesterskapsevne med det krevende lancero-formatet — elegant, konsentrert og lang i munnen.',
 array['cedar','espresso','dark chocolate','leather','black pepper','earth']),

-- ─── PLASENCIA COSECHA 146 ───────────────────────────────────────────────────
-- "Cosecha" betyr "høst" på spansk; tallene refererer til høståret.
-- Cosecha 146 er en spesialbegrensede blending fra 2018-høsten, svært prisbelønt.

('Plasencia','Plasencia','Cosecha 146','Gran Toro','Gran Toro',56,6.0,'Parejo',
 'Nicaragua','Nicaragua','Nicaraguan Jalapa',
 array['Nicaragua'],'Nicaragua',
 4,null,94,
 'En av de mest omtalte sigarene fra Plasencia — Cosecha 146 Gran Toro ble kåret til #2 sigar i verden av Cigar Aficionado i 2019. Kremet og balansert med middels-sterk styrke.',
 array['cream','cedar','coffee','sweet spice','earth','almond']),

('Plasencia','Plasencia','Cosecha 146','Robusto','Robusto',52,5.0,'Parejo',
 'Nicaragua','Nicaragua','Nicaraguan Jalapa',
 array['Nicaragua'],'Nicaragua',
 4,null,93,
 'Robusto-utgaven av Cosecha 146 gir den prisbelønte blenden i et kortere, konsentrert format — kremet og smøraktig med søte kryddertoner.',
 array['cream','almond','coffee','sweet cedar','earth','mild spice']),

('Plasencia','Plasencia','Cosecha 146','Toro','Toro',54,6.0,'Parejo',
 'Nicaragua','Nicaragua','Nicaraguan Jalapa',
 array['Nicaragua'],'Nicaragua',
 4,null,93,
 'Toro-formatet av Cosecha 146 er kanskje den mest allsidige utgaven — rik nok til å tilfredsstille erfarne røykere, men tilgjengelig nok for de som er nye til nicaraguanske premium-sigarer.',
 array['cream','cedar','coffee','sweet spice','almond','light earth']),

('Plasencia','Plasencia','Cosecha 146','Churchill','Churchill',50,7.0,'Parejo',
 'Nicaragua','Nicaragua','Nicaraguan Jalapa',
 array['Nicaragua'],'Nicaragua',
 4,null,92,
 'Det lange Churchill-formatet gir Cosecha 146-blenden tid til å åpne seg fullt — langsomt byggende med et langt, søtt etterspill.',
 array['cream','coffee','cedar','sweet spice','almond','hay']),

-- ─── PLASENCIA RESERVA ORIGINAL ──────────────────────────────────────────────
-- Klassisk nicaraguansk linje med Habano-wrapper. God inngangsport til merket.

('Plasencia','Plasencia','Reserva Original','Toro','Toro',52,6.0,'Parejo',
 'Nicaragua','Ecuador','Ecuador Habano',
 array['Nicaragua'],'Nicaragua',
 3,null,90,
 'Reserva Original er Plasencias klassiske linje — en tilgjengelig og velbalansert nicaraguansk sigar med Habano-wrapper. Jevnt kremet røyk med milde kryddertoner.',
 array['cedar','cream','coffee','mild spice','leather','cocoa']),

('Plasencia','Plasencia','Reserva Original','Robusto','Robusto',50,5.0,'Parejo',
 'Nicaragua','Ecuador','Ecuador Habano',
 array['Nicaragua'],'Nicaragua',
 3,null,89,
 'Robusto Reserva Original — en pålitelig hverdagssigar fra Plasencia med naturlig sødme og mild-medium styrke.',
 array['cedar','cream','coffee','cocoa','mild spice','almond']),

-- ─── PLASENCIA RESERVA ORGANICA ──────────────────────────────────────────────
-- Laget av 100% organisk tobakk uten sprøytemidler. Sjelden og spesiell.

('Plasencia','Plasencia','Reserva Organica','Toro','Toro',52,6.0,'Parejo',
 'Nicaragua','Nicaragua','Nicaraguan Organico',
 array['Nicaragua'],'Nicaragua',
 3,null,91,
 'En sjelden nicaraguansk puro laget utelukkende av organisk dyrket tobakk. Renere og mer urtektig enn konvensjonelle nicaraguanere, med en naturlig søthet og lett, floral karakter.',
 array['floral','cedar','cream','light earth','almond','mild pepper'])

ON CONFLICT DO NOTHING;

-- Oppdater search_vector for nye rader
UPDATE cigars
SET search_vector = to_tsvector('english',
  coalesce(brand,'') || ' ' ||
  coalesce(manufacturer,'') || ' ' ||
  coalesce(series,'') || ' ' ||
  coalesce(vitola,'') || ' ' ||
  coalesce(common_format,'') || ' ' ||
  coalesce(wrapper_leaf,'') || ' ' ||
  coalesce(country_of_origin,'')
)
WHERE brand = 'Plasencia'
  AND series IN ('Alma Fuerte','Cosecha 146','Reserva Original','Reserva Organica');
