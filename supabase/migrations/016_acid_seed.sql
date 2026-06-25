-- ============================================================
-- 016_acid_seed.sql
--
-- Setter inn Acid (by Drew Estate) — lansert 2001 av Jonathan
-- Drew og Marvin Samel som verdens første "super-premium infused"
-- sigar. Tobakken modnes i "aromarom" med over 200 urter, krydder
-- og eteriske oljer før rulling. Kjent for fargerik emballasje og
-- et stort, lojalt fellesskap ("Acid Heads"). Nr. 16 på Atlantic
-- Cigars salgsliste for 2026 — et av de tydeligste gapene i
-- databasen relativt til faktisk popularitet.
--
-- 13 nye rader fordelt på 6 serier/produktlinjer:
--   1) Kuba Kuba       — flaggskipet, medium-bodied robusto
--   2) Blondie         — mild, søt, liten format (4x38)
--   3) Cold Infusion   — lys, frisk, Connecticut-dekkblad
--   4) 1400cc          — robusto i glasstube
--   5) Atom Maduro     — mørkere, kraftigere infused-variant
--   6) One             — ikke-aromatisert torpedo, Cameroon-dekkblad
--
-- Smaksnoter er satt direkte ved innsetting (ikke som egen
-- backfill-runde) for å unngå samme mangel som ble funnet og
-- fikset i migrasjon 015.
--
-- Kilder: cigarsinternational.com, gothamcigars.com,
-- famous-smoke.com/cigaradvisor, neptunecigar.com, drewestate.com
-- ============================================================

-- ----------------------------------------------------------------
-- 1) Kuba Kuba — Acids mest kjente linje. Ecuador Sumatra-dekkblad
--    over nicaraguansk bind, fylt med nicaraguansk/honduransk
--    innmat infundert med urter og eteriske oljer.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Drew Estate','Acid','Kuba Kuba','Original','Robusto',54,5.0,'Parejo',null,null,null,'Ecuador','Sumatra','Nicaraguan',array['Nicaragua','Honduras'],'Nicaragua',3,null,'Kuba Kuba er Acids flaggskip — en fyldig robusto med Ecuador Sumatra-dekkblad, infundert med urter og eteriske oljer i Drew Estates aromarom.',array['honey','herbs','cedar','sweet spice','earth']),
('Drew Estate','Acid','Kuba Kuba','Maduro','Robusto',54,5.0,'Parejo',null,null,null,'United States','Connecticut Broadleaf','Nicaraguan',array['Nicaragua','Honduras'],'Nicaragua',3,null,'Kuba Kuba Maduro bytter ut dekkbladet med mørkt Connecticut Broadleaf for en søtere, mer jordnær infused-opplevelse.',array['dark chocolate','molasses','herbs','sweet spice','earth']),
('Drew Estate','Acid','Kuba Kuba','Candela','Robusto',54,5.0,'Parejo',null,null,null,'Nicaragua','Candela','Nicaraguan',array['Nicaragua','Honduras'],'Nicaragua',2,null,'Kuba Kuba Candela bruker det grønne, soltørkede Candela-dekkbladet — friskere og lysere enn originalen.',array['fresh herbs','green tea','grass','mild spice','sweetness']),
('Drew Estate','Acid','Kuba Deluxe','Toro','Toro',54,6.0,'Parejo',null,null,null,'Ecuador','Sumatra','Nicaraguan',array['Nicaragua','Honduras'],'Nicaragua',3,null,'Kuba Deluxe er en større toro-utgave av Kuba Kuba, ofte solgt i glasstube for å bevare aromaene.',array['honey','herbs','cedar','sweet spice','cream']);

-- ----------------------------------------------------------------
-- 2) Blondie — den mildeste og mest populære Acid-linjen. Ecuador
--    Connecticut Shade-dekkblad, liten petit corona-format (4x38).
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Drew Estate','Acid','Blondie','Original','Petit Corona',38,4.0,'Parejo',null,null,null,'Ecuador','Connecticut Shade','Connecticut',array['Nicaragua','Honduras'],'Nicaragua',2,null,'Blondie er Acids mildeste og mest tilgjengelige sigar — en liten, søt 20-minutters røyk med Ecuador Connecticut Shade-dekkblad.',array['vanilla','honey','herbs','cream','mild spice']),
('Drew Estate','Acid','Blondie','Maduro','Petit Corona',38,4.0,'Parejo',null,null,null,'United States','Connecticut Broadleaf','Connecticut',array['Nicaragua','Honduras'],'Nicaragua',2,null,'Blondie Maduro gir den klassiske Blondie en mørkere, søtere vri med Connecticut Broadleaf-dekkblad.',array['cocoa','vanilla','sweet spice','cream','earth']),
('Drew Estate','Acid','Blondie','Belicoso','Belicoso',54,5.0,'Figurado','Belicoso','Pointed','Closed','Ecuador','Connecticut Shade','Connecticut',array['Nicaragua','Honduras'],'Nicaragua',2,null,'Blondie Belicoso pakker den samme milde, søte smaksprofilen inn i en større, spiss figurado-form.',array['vanilla','honey','cedar','herbs','cream']),
('Drew Estate','Acid','Blondie','Gold','Petit Corona',38,4.0,'Parejo',null,null,null,'Ecuador','Connecticut Shade','Connecticut',array['Nicaragua','Honduras'],'Nicaragua',1,null,'Blondie Gold er den glatteste og mildeste varianten i serien — lett, kremet og svært tilgjengelig for nye røykere.',array['vanilla','cream','honey','mild herbs','sweetness']);

-- ----------------------------------------------------------------
-- 3) Cold Infusion — lys og frisk, bygget på et silkeaktig
--    Connecticut Shade-dekkblad fremfor de tyngre infusjonene.
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Drew Estate','Acid','Cold Infusion','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Connecticut Shade','Connecticut',array['Nicaragua'],'Nicaragua',2,null,'Cold Infusion er Acids letteste, mest "skinny dipped"-aktige linje — lys, sitrussøt og oppfriskende.',array['citrus','honey','cream','light herbs','sweetness']),
('Drew Estate','Acid','Cold Infusion','Toro','Toro',52,6.0,'Parejo',null,null,null,'Ecuador','Connecticut Shade','Connecticut',array['Nicaragua'],'Nicaragua',2,null,'Toro-utgaven av Cold Infusion gir samme lyse, friske profil i en lengre røyketid.',array['citrus','cream','honey','light herbs','mild spice']);

-- ----------------------------------------------------------------
-- 4) Andre kjente enkeltprodukter — 1400cc (glasstube-robusto),
--    Atom Maduro (kraftigere infused-variant) og One (Acids
--    ikke-aromatiserte torpedo med Cameroon-dekkblad).
-- ----------------------------------------------------------------
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
('Drew Estate','Acid','1400cc','1400cc','Robusto',50,5.0,'Parejo',null,null,null,'Ecuador','Sumatra','Nicaraguan',array['Nicaragua','Honduras'],'Nicaragua',3,null,'1400cc selges i forseglet glasstube for å bevare de kremete, sterkt aromatiske infusjonene.',array['cream','herbs','sweet spice','cedar','honey']),
('Drew Estate','Acid','Atom','Maduro','Robusto',50,5.0,'Parejo',null,null,null,'United States','Connecticut Broadleaf','Nicaraguan',array['Nicaragua','Honduras'],'Nicaragua',4,null,'Atom Maduro er en av de kraftigste Acid-utgivelsene — mørkt dekkblad og dypere, mer jordnær infusjon.',array['dark chocolate','espresso','sweet spice','earth','herbs']),
('Drew Estate','Acid','One','Torpedo','Torpedo',52,6.0,'Figurado',null,'Pointed','Closed','Cameroon','Cameroon','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Acid One er merkets ikke-aromatiserte sigar — uten tilsatte urter/oljer — for de som vil ha Acid-konstruksjonen med en mer tradisjonell, krydret Cameroon-smak.',array['cedar','black pepper','toasted nuts','earth','light spice']);
