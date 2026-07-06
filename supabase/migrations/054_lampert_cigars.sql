-- Migration 054: Lampert Cigars — full sortiment
-- Produsent: Lampert Cigars (Lampert International, Panama)
-- Kilde: https://lampertcigars.com/cigars/
--
-- Fabrikker:
--   • Tabacos de Costa Rica (Costa Rica) — Ocean Breeze, Oro Line, Limitada 2023/2025
--   • Fábrica Agrotabacos (Nicaragua) — 1675 Azul/Rojo/Morado, 1593 Verde
--   • Kelner Boutique Factory / KBF (Dominican Republic) — 1593 Oscura
--
-- Totalt: 22 vitolas

INSERT INTO cigars (
  manufacturer, brand, series, vitola, common_format,
  ring_gauge, length_inches, shape,
  body_type, head_type, foot_type,
  wrapper_country, wrapper_leaf, binder, filler,
  country_origin, strength, price_range,
  description, flavor_notes, avg_rating
)
VALUES

-- ============================================================
-- OCEAN BREEZE (Costa Rica — Tabacos de Costa Rica)
-- Wrapper: Ecuador H. Criollo, Binder/Filler: Undisclosed
-- Lagret 4-5 år — Ratings: 94 Stogie Press, 90 CJ, 89 André Dias
-- ============================================================
(
  'Lampert Cigars','Ocean Breeze',NULL,'Gordito','Gordo',
  58,4.0,'Parejo',
  null,null,null,
  'Ecuador','H. Criollo',NULL,ARRAY['Undisclosed'],
  'Costa Rica',3,'$10-15',
  'Lampert Ocean Breeze Gordito — 4"×58. Kompakt og flavorful Gordo-format. Ecuadoriansk H. Criollo wrapper, 4-5 år lagret. Åpner med mineraler, går til kakao og ristede mandler, avslutter med jord og lær. Inspirert av Costa Ricas Pura Vida-livsstil.',
  ARRAY['mineral','cocoa','roasted almonds','earth','leather','natural sweetness'],8.5
),
(
  'Lampert Cigars','Ocean Breeze',NULL,'Robusto Grande','Robusto Extra',
  54,5.0,'Parejo',
  null,null,null,
  'Ecuador','H. Criollo',NULL,ARRAY['Undisclosed'],
  'Costa Rica',3,'$10-15',
  'Lampert Ocean Breeze Robusto Grande — 5"×54. Flaggskipformatet i Ocean Breeze-linjen. Ecuadoriansk H. Criollo wrapper, lagret 4-5 år. Jevn mineralsk-kremet profil med kakao og ristede mandler som kjennetegner sigaren. Rated 94 av Stogie Press.',
  ARRAY['mineral','cocoa','roasted almonds','earth','leather','natural sweetness'],8.6
),
(
  'Lampert Cigars','Ocean Breeze',NULL,'Toro Grande','Toro Gordo',
  56,6.5,'Parejo',
  null,null,null,
  'Ecuador','H. Criollo',NULL,ARRAY['Undisclosed'],
  'Costa Rica',3,'$11-17',
  'Lampert Ocean Breeze Toro Grande — 6½"×56. Lengste format i linjen, laget for utvidet smaksopplevelse. Ecuadoriansk H. Criollo wrapper. Den lange røyken gir gradvis utvikling fra mineral og kakao til jord og lær mot siste tredjedel.',
  ARRAY['mineral','cocoa','roasted almonds','earth','leather','natural sweetness'],8.5
),

-- ============================================================
-- ORO LINE (Costa Rica — Tabacos de Costa Rica)
-- Wrapper: Ecuador Connecticut, Binder: Ecuador H. 2000
-- Filler: Dominican Republic + Peru — Lagret 4-5 år
-- Jevn og kremet; grassy, spicy, woody, nutty mot slutten
-- * Størrelser er standard-estimater (ikke publisert på nettsiden)
-- ============================================================
(
  'Lampert Cigars','Oro Line',NULL,'Señorito','Half Corona',
  44,3.5,'Parejo',
  null,null,null,
  'Ecuador','Connecticut',NULL,ARRAY['Dominican','Peruvian'],
  'Costa Rica',2,'$7-11',
  'Lampert Oro Line Señorito — ca. 3½"×44 Half Corona. Korteste format i Oro Line, tilgjengelig i kabinetter med 25 og 100. Ecuador Connecticut wrapper over Dominican og peruansk filler, lagret 4-5 år. Kremet og aromatisk med grassy og krydret åpning.',
  ARRAY['cream','cedar','grass','spice','nuts'],8.1
),
(
  'Lampert Cigars','Oro Line',NULL,'El Gringo','Robusto',
  50,5.0,'Parejo',
  null,null,null,
  'Ecuador','Connecticut',NULL,ARRAY['Dominican','Peruvian'],
  'Costa Rica',2,'$9-13',
  'Lampert Oro Line El Gringo — ca. 5"×50 Robusto. Midtformatet i Oro Line, i 10-pakengs esker. Ecuador Connecticut wrapper + Ecuador H. 2000 binder, Dominican og peruansk filler. Kremet, aromatisk og mild til medium-sterk. Rated 91 av Blind Man''s Puff.',
  ARRAY['cream','cedar','grass','spice','nuts','roasted aromas'],8.2
),
(
  'Lampert Cigars','Oro Line',NULL,'Don Patrón','Toro',
  52,6.0,'Parejo',
  null,null,null,
  'Ecuador','Connecticut',NULL,ARRAY['Dominican','Peruvian'],
  'Costa Rica',2,'$10-14',
  'Lampert Oro Line Don Patrón — ca. 6"×52 Toro. Lengste regulære format. Ecuador Connecticut wrapper, Ecuador H. 2000 binder, Dominican og peruansk filler. Lagret 4-5 år. Kremet og balansert med grassy, spicy aromer som utvikler seg mot sterk ristede toner mot slutten.',
  ARRAY['cream','cedar','grass','spice','nuts','roasted aromas'],8.2
),

-- ============================================================
-- ORO LINE SHORT PERFECTO (Costa Rica — Small Batch Production)
-- Samme blend som Oro Line men i korteste Perfecto-format
-- Begrenset produksjon — 4½"×62
-- ============================================================
(
  'Lampert Cigars','Oro Line','Short Perfecto','Short Perfecto','Short Perfecto',
  62,4.5,'Perfecto',
  null,null,null,
  'Ecuador','Connecticut',NULL,ARRAY['Dominican','Peruvian'],
  'Costa Rica',3,'$12-17',
  'Lampert Oro Line Short Perfecto — 4½"×62, small batch. Ecuador Connecticut wrapper + Ecuador H. 2000 binder, Dominican og peruansk filler, lagret 4-5 år. Begrenset produksjon i 10-pakengs esker. Perfecto-formen gir rik, jevn røyk med kremet åpning etterfulgt av sedertre, ristet krem og lett krydder.',
  ARRAY['cream','cedar','toasted cream','gentle spice','nuts'],8.3
),

-- ============================================================
-- LIMITADA 2023 (Costa Rica — Limited Edition, PCA 2024 debut)
-- Wrapper: Ecuador Criollo 98, Binder: Brazil, Filler: Brazil
-- Kun 450 esker til USA — eksklusive og seltenhet
-- * Vitola-størrelse ikke publisert på nettsiden
-- ============================================================
(
  'Lampert Cigars','Lampert Limitada','2023','Limitada 2023','Toro',
  NULL,NULL,'Parejo',
  null,null,null,
  'Ecuador','Criollo 98','Brazil',ARRAY['Brazil'],
  'Costa Rica',4,'$15-22',
  'Lampert Limitada 2023 — begrenset opplag, kun 450 esker til USA. Debuterte på PCA 2024. Ecuadoriansk Criollo 98 wrapper med brasiliansk binder og filler. Kraftfull og eksklusiv med dype mørke tobakkstoner. Costa Rica-produsert, 10 stk per eske.',
  ARRAY['dark tobacco','earth','cedar','spice','leather'],8.4
),

-- ============================================================
-- LIMITADA 2025 (Costa Rica — Limited Edition, Box Pressed)
-- Wrapper: Ecuadorian Habano Vuelta Abajo (HVA) dark
-- Binder: Ecuadorian Habano 2000
-- Filler: Brazil, Dominican Republic, Nicaragua
-- Kun 500 esker — første box-pressed sigar fra Lampert
-- ============================================================
(
  'Lampert Cigars','Lampert Limitada','2025','Limitada 2025 Toro','Toro',
  54,6.0,'Box Pressed',
  null,null,null,
  'Ecuador','Habano Vuelta Abajo HVA dark','Ecuador Habano 2000',ARRAY['Brazilian','Dominican','Nicaraguan'],
  'Costa Rica',4,'$18-26',
  'Lampert Limitada 2025 — 6"×54 Box Pressed Toro. Lammerts første box-pressed sigar, kun 500 esker produsert. Ecuadoriansk Habano Vuelta Abajo (HVA) mørk wrapper, Ecuadoriansk H. 2000 binder, og small-batch filler fra Brasil, Dominikanske Republikk og Nicaragua. Dristig blend med begrenset tilgjengelighet — en ekte samlerestykke.',
  ARRAY['dark tobacco','earth','cedar','leather','spice','dark chocolate'],8.5
),

-- ============================================================
-- LAMPERT 1675 EDICIÓN AZUL (Nicaragua — Fábrica Agrotabacos)
-- Wrapper: Ecuador H. 2000, Binder: Nicaragua, Filler: Nicaragua + Peru
-- Tobakk fra Jalapa, Condega, Peru — Lagret 3-5 år
-- Ratings: 94 Blind Man's Puff, 93 Cigar Journal
-- ============================================================
(
  'Lampert Cigars','Lampert 1675','Edición Azul','Short Robusto','Short Robusto',
  52,3.5,'Parejo',
  null,null,null,
  'Ecuador','H. 2000','Nicaraguan',ARRAY['Nicaraguan','Peruvian'],
  'Nicaragua',3,'$10-15',
  'Lampert 1675 Edición Azul Short Robusto — 3½"×52. Kompakt reiseformat. Ecuador H. 2000 wrapper, nicaraguansk binder og filler fra Jalapa og Condega, peruansk ligero for sitruslyshet. Medium-kropp med full smaksprofil. Lagret 3-5 år ved Fábrica Agrotabacos.',
  ARRAY['cedar','soft spice','nuts','earth','citrus'],8.4
),
(
  'Lampert Cigars','Lampert 1675','Edición Azul','Robusto','Robusto',
  50,5.0,'Parejo',
  null,null,null,
  'Ecuador','H. 2000','Nicaraguan',ARRAY['Nicaraguan','Peruvian'],
  'Nicaragua',3,'$11-16',
  'Lampert 1675 Edición Azul Robusto — 5"×50. Flaggskipformatet, fremhever blend''s kremete struktur. Ecuador H. 2000 wrapper med tobakk fra Jalapa, Condega og Peru. Sitruslyshet fra peruansk ligero. Rated 94 av Blind Man''s Puff.',
  ARRAY['cedar','soft spice','nuts','earth','citrus','cream'],8.6
),
(
  'Lampert Cigars','Lampert 1675','Edición Azul','Toro','Toro',
  52,6.0,'Parejo',
  null,null,null,
  'Ecuador','H. 2000','Nicaraguan',ARRAY['Nicaraguan','Peruvian'],
  'Nicaragua',3,'$12-17',
  'Lampert 1675 Edición Azul Toro — 6"×52. Lengste format i Azul-linjen, gir strukturert smaksutvikling over tre tydelige tredjedeler. Ecuador H. 2000 wrapper, nicaraguansk binder/filler fra Jalapa og Condega, peruansk ligero.',
  ARRAY['cedar','soft spice','nuts','earth','citrus','cream'],8.5
),

-- ============================================================
-- LAMPERT 1675 EDICIÓN ROJO (Nicaragua — Fábrica Agrotabacos)
-- Wrapper: Ecuador Connecticut, Binder: Nicaragua, Filler: Nicaragua
-- Tobakk fra Jalapa og Condega — Lagret 3-5 år
-- Stefan Lamperts personlige smaksprofil — mild til medium
-- ============================================================
(
  'Lampert Cigars','Lampert 1675','Edición Rojo','Short Robusto','Short Robusto',
  52,3.5,'Parejo',
  null,null,null,
  'Ecuador','Connecticut','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',2,'$10-14',
  'Lampert 1675 Edición Rojo Short Robusto — 3½"×52. Kompakt format basert på Stefan Lamperts personlige smakspreferanser. Ecuador Connecticut wrapper, nicaraguansk binder og filler fra Jalapa og Condega, lagret 4 år.',
  ARRAY['cedar','roasted nuts','cocoa','gentle spice','natural sweetness'],8.3
),
(
  'Lampert Cigars','Lampert 1675','Edición Rojo','Robusto','Robusto',
  50,5.0,'Parejo',
  null,null,null,
  'Ecuador','Connecticut','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',2,'$11-15',
  'Lampert 1675 Edición Rojo Robusto — 5"×50. Balansert og ideelt dagligformat. Ecuador Connecticut wrapper, nicaraguansk binder og filler fra Jalapa og Condega. Medium kropp med sedertre, ristede nøtter, kakao og milde krydder. Jevnt brennende konstruksjon fra start til slutt.',
  ARRAY['cedar','roasted nuts','cocoa','gentle spice','natural sweetness'],8.3
),
(
  'Lampert Cigars','Lampert 1675','Edición Rojo','Toro','Toro',
  52,6.0,'Parejo',
  null,null,null,
  'Ecuador','Connecticut','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',2,'$12-16',
  'Lampert 1675 Edición Rojo Toro — 6"×52. Lengste format i Rojo-linjen. Ecuador Connecticut wrapper med 4-årig lagret nicaraguansk tobakk. Medium-kropp med gradvis utvikling av sedertre og nøtteblandingen. Passer godt til medium-lagret rom eller bourbon.',
  ARRAY['cedar','roasted nuts','cocoa','gentle spice','natural sweetness'],8.3
),

-- ============================================================
-- LAMPERT 1675 EDICIÓN MORADO (Nicaragua — Fábrica Agrotabacos)
-- Wrapper: Mexico NSA (Negro San Andrés) Maduro
-- Binder: Nicaragua, Filler: Nicaragua — Lagret 3-5 år
-- Maduro-profil: espresso, mørk kakao, tre, søte krydder
-- Rated 92 Blind Man's Puff
-- ============================================================
(
  'Lampert Cigars','Lampert 1675','Edición Morado','Short Robusto','Short Robusto',
  52,3.5,'Parejo',
  null,null,null,
  'Mexico','Negro San Andrés Maduro','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',4,'$11-16',
  'Lampert 1675 Edición Morado Short Robusto — 3½"×52. Kompakt Maduro-format. Meksikansk Negro San Andrés Maduro wrapper over nicaraguansk binder og filler. Åpner med ristede espressobønner og mørk kakao, utvikler seg til tre og søte krydder. Lagret 3-5 år ved Fábrica Agrotabacos.',
  ARRAY['roasted espresso','dark cocoa','wood','sweet spices','natural sweetness'],8.4
),
(
  'Lampert Cigars','Lampert 1675','Edición Morado','Robusto','Robusto',
  50,5.0,'Parejo',
  null,null,null,
  'Mexico','Negro San Andrés Maduro','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',4,'$12-17',
  'Lampert 1675 Edición Morado Robusto — 5"×50. Meksikansk Negro San Andrés Maduro wrapper, nicaraguansk binder og filler. Medium til full kropp med rik men balansert Maduro-profil. Espresso, kakao og søte krydder gjennom hele røyken. Rated 92 av Blind Man''s Puff.',
  ARRAY['roasted espresso','dark cocoa','wood','sweet spices','natural sweetness'],8.5
),
(
  'Lampert Cigars','Lampert 1675','Edición Morado','Toro','Toro',
  52,6.0,'Parejo',
  null,null,null,
  'Mexico','Negro San Andrés Maduro','Nicaraguan',ARRAY['Nicaraguan'],
  'Nicaragua',4,'$13-18',
  'Lampert 1675 Edición Morado Toro — 6"×52. Lengste format i Morado-linjen. Meksikansk NSA Maduro wrapper, nicaraguansk binder og filler, lagret 3-5 år. Lengre røyketid lar den lagvise smaksutviklingen fra espresso og kakao gjennom tre og søte krydder åpne seg fullt ut.',
  ARRAY['roasted espresso','dark cocoa','wood','sweet spices','natural sweetness'],8.5
),

-- ============================================================
-- LAMPERT 1593 EDICIÓN VERDE (Nicaragua — Fábrica Agrotabacos)
-- Wrapper: Mexico NSA (Negro San Andrés) — naturlig mørk og sjelden
-- Binder/Filler: Undisclosed — Lagret 5+ år
-- Oval-form — første ovale sigar fra Lampert
-- Smak: mørk ristet kaffe, lær, anis, kardemomme, røykig tre
-- ============================================================
(
  'Lampert Cigars','Lampert 1593','Edición Verde','Oval Short Robusto','Short Robusto',
  52,4.0,'Oval',
  null,null,null,
  'Mexico','Negro San Andrés','Undisclosed',ARRAY['Undisclosed'],
  'Nicaragua',4,'$15-22',
  'Lampert 1593 Edición Verde Oval Short Robusto — oval form, ca. 4"×52. Lammerts første ovale sigar, laget av Agrotabacos mestere kun for connoisseurs. Sjelden meksikansk Negro San Andrés wrapper, lagret 5+ år. Rik og full kropp med mørk ristet kaffe, lær, anis, kardemomme og røykig tre.',
  ARRAY['dark roasted coffee','leather','anise','cardamom','smoky wood'],8.6
),
(
  'Lampert Cigars','Lampert 1593','Edición Verde','Oval Robusto Grande','Robusto Extra',
  56,5.25,'Oval',
  null,null,null,
  'Mexico','Negro San Andrés','Undisclosed',ARRAY['Undisclosed'],
  'Nicaragua',4,'$16-23',
  'Lampert 1593 Edición Verde Oval Robusto Grande — oval form, ca. 5¼"×56. Oval-formen gir en komfortabel røykopplevelse og konsentrerer smakenes dypeste nivåer. Sjelden NSA Maduro wrapper, lagret 5+ år av Agrotabacos. Mørk ristet kaffe, lær, anis og røykig tre.',
  ARRAY['dark roasted coffee','leather','anise','cardamom','smoky wood'],8.7
),
(
  'Lampert Cigars','Lampert 1593','Edición Verde','Oval Toro Grande','Toro Grande',
  60,6.0,'Oval',
  null,null,null,
  'Mexico','Negro San Andrés','Undisclosed',ARRAY['Undisclosed'],
  'Nicaragua',4,'$18-26',
  'Lampert 1593 Edición Verde Oval Toro Grande — oval form, ca. 6"×60. Lengste og største format i Verde-linjen. Sjelden meksikansk NSA wrapper, lagret 5+ år. Rik og komplett full-kropp opplevelse med mørk ristet kaffe, lær, anis, kardemomme og røykig tre over en lang røyketid.',
  ARRAY['dark roasted coffee','leather','anise','cardamom','smoky wood'],8.7
),

-- ============================================================
-- LAMPERT 1593 EDICIÓN OSCURA (Dominican Republic — KBF)
-- Blender: Hendrik Kelner Jr. ved Kelner Boutique Factory
-- Wrapper/Binder/Filler: Undisclosed — Lagret 5-8 år
-- Rik full-kropp Maduro: jord, anis, espresso, krydder
-- ============================================================
(
  'Lampert Cigars','Lampert 1593','Edición Oscura','Toro','Toro',
  52,6.0,'Parejo',
  null,null,null,
  NULL,NULL,NULL,ARRAY['Undisclosed'],
  'Dominican Republic',4,'$18-26',
  'Lampert 1593 Edición Oscura Toro — 6"×52. Blandet og produsert av Hendrik Kelner Jr. ved det prestisjetunge Kelner Boutique Factory (KBF) i Dominikanske Republikk. Full kropp med eksepsjonell balanse. Wrapper, binder og filler er undisclosed. Lagret 5-8 år. Lag av jord, anis, espresso og krydder med en subtil naturlig sødme.',
  ARRAY['earth','anise','espresso','spice','natural sweetness'],8.6
)

ON CONFLICT DO NOTHING;
