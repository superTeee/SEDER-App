-- ============================================================
-- 005_my_father_brand_seed.sql
--
-- Full restrukturering av "My Father Cigars"-katalogen til riktig
-- hierarki: manufacturer -> brand (family) -> series -> vitola.
--
-- Steg:
--   1) Slett utgått serie som ikke finnes i produsentens nåværende
--      utvalg (Don Pepin Garcia Clasico 20th Anniversary).
--   2) Oppdater alle 27 eksisterende rader med korrekt
--      manufacturer/brand/series/vitola/format/shape/tobakk.
--   3) Sett inn alle manglende vitola-rader pr. serie.
--   4) Sett inn alias for OCR-gjenkjenning av båndtekst.
-- ============================================================

-- ----------------------------------------------------------------
-- 1) Utgått serie — finnes ikke i My Father Cigars' nåværende utvalg
-- ----------------------------------------------------------------
delete from cigars where id = 'bbb65677-5367-47ea-a239-a4cd6c4e9298';

-- ----------------------------------------------------------------
-- 2) UPDATE — eksisterende 27 rader, gruppert pr. brand family
-- ----------------------------------------------------------------

-- === My Father / Original Core Line ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'My Father', series = 'Original Core Line',
  vitola = 'No.1 Robusto', common_format = 'Robusto',
  ring_gauge = 52, length_inches = 5.25, shape = 'Parejo', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'Nicaragua', wrapper_leaf = 'Habano Rosado', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 5, price_range = '$125.35',
  description = 'My Fathers kjernelinje — den opprinnelige sigaren som satte familien Garcia på kartet. Habano Rosado-dekkblad, full styrke.'
where id = '6f1af13e-f261-4bf0-a394-94b82fa3b9dd';

-- === My Father / Le Bijou 1922 ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'My Father', series = 'Le Bijou 1922',
  vitola = 'Toro', common_format = 'Toro',
  ring_gauge = 52, length_inches = 6.0, shape = 'Parejo', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'Nicaragua', wrapper_leaf = 'Habano Oscuro-Oscuro', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 5, price_range = '$145.00',
  description = 'Et av My Fathers kraftigste merker — mørkt Habano Oscuro-Oscuro-dekkblad og svært full styrke.'
where id = 'b07b0dfd-e740-4d9e-a048-97509143c21d';

update cigars set
  manufacturer = 'My Father Cigars', brand = 'My Father', series = 'Le Bijou 1922',
  vitola = 'Torpedo Box Pressed', common_format = 'Torpedo',
  ring_gauge = 52, length_inches = 6.125, shape = 'Figurado', body_type = 'Torpedo Box-Pressed', head_type = 'Pointed', foot_type = 'Closed',
  wrapper_country = 'Ecuador', wrapper_leaf = 'Habano Oscuro-Oscuro', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 5, price_range = '$150.00',
  description = 'Et av My Fathers kraftigste merker — mørkt Habano Oscuro-Oscuro-dekkblad og svært full styrke.'
where id = '624801a5-117c-4a41-a0a4-ea38d918b61e';

-- === My Father / Connecticut ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'My Father', series = 'Connecticut',
  vitola = 'Robusto', common_format = 'Robusto',
  ring_gauge = 52, length_inches = 5.25, shape = 'Parejo', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'Ecuador', wrapper_leaf = 'Connecticut', binder = 'Nicaraguan Corojo 99', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 3, price_range = null,
  description = 'Den mildeste varianten i My Father-familien, med lyst Connecticut-dekkblad fra Ecuador.'
where id = '4d3ca9a8-36e1-43b5-9eb6-995f6db84884';

-- === My Father / The Judge ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'My Father', series = 'The Judge',
  vitola = 'Corona Gorda', common_format = 'Corona Gorda',
  ring_gauge = 46, length_inches = 5.625, shape = 'Box-Pressed', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'Ecuador', wrapper_leaf = 'Sumatra Oscuro', binder = 'Corojo/Criollo', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 5, price_range = null,
  description = 'Boxpresset sigar med mørkt Sumatra Oscuro-dekkblad — kraftig og krydret.'
where id = '33cd9397-6e32-422a-80f0-07d4a6795a8b';

-- === My Father / La Opulencia ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'My Father', series = 'La Opulencia',
  vitola = 'Petite', common_format = 'Petit Corona',
  ring_gauge = 48, length_inches = 4.5, shape = 'Box-Pressed', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'Mexico', wrapper_leaf = 'Rosado Oscuro', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 4, price_range = null,
  description = 'Boxpresset sigar med mørkt meksikansk Rosado Oscuro-dekkblad og rik, søtlig smak.'
where id = 'e03b8efc-76c6-4461-a8ba-5a3ba43d8227';

-- === My Father / La Gran Oferta ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'My Father', series = 'La Gran Oferta',
  vitola = 'Robusto', common_format = 'Robusto',
  ring_gauge = 50, length_inches = 5.0, shape = 'Parejo', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'Ecuador', wrapper_leaf = 'Habano Rosado', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 4, price_range = null,
  description = '«Det store tilbudet» — hyllest til en gammel kubansk merkevare fra 1913, med oljete Habano Rosado-dekkblad.'
where id = '193efe0a-69e7-4d3a-968b-84c62c4e010b';

-- === My Father / La Promesa ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'My Father', series = 'La Promesa',
  vitola = 'Corona Gorda', common_format = 'Corona Gorda',
  ring_gauge = 48, length_inches = 5.5, shape = 'Parejo', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'Nicaragua', wrapper_leaf = 'Habano', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 4, price_range = null,
  description = '«Løftet» — oppkalt etter Don Pepin Garcias løfte til familien om å lykkes utenfor Cuba.'
where id = '223f98b6-03f2-43e6-8709-92c811395c27';

-- === My Father / Blue ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'My Father', series = 'Blue',
  vitola = 'Petit Robusto', common_format = 'Petit Robusto',
  ring_gauge = 50, length_inches = 4.5, shape = 'Box-Pressed', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'USA', wrapper_leaf = 'Connecticut Broadleaf Rosado', binder = 'Honduran', filler = array['Honduras'],
  country_origin = 'Honduras', strength = 3, price_range = null,
  description = 'My Fathers nyeste linje (2025) — første sigar fra familiens nye fabrikk i Honduras.'
where id = 'ce71a662-a0eb-4845-bfc7-d04488b2c369';

-- === My Father / La Lealtad ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'My Father', series = 'La Lealtad',
  vitola = 'Robusto', common_format = 'Robusto',
  ring_gauge = 52, length_inches = 5.25, shape = 'Parejo', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'Ecuador', wrapper_leaf = 'Rosado Oscuro', binder = 'Nicaraguan and Honduran', filler = array['Honduras','Nicaragua'],
  country_origin = 'Honduras', strength = 5, price_range = null,
  description = '«Lojaliteten» — den nyeste sigaren fra familiens fabrikk i Honduras.'
where id = 'fb981f95-d75a-40be-9067-71aab7b79c60';

-- === My Father / Garcia & Garcia (begrenset offentlig produktinfo) ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'My Father', series = 'Garcia & Garcia',
  common_format = 'Robusto', shape = 'Parejo',
  description = 'Et mindre kjent merke i My Father-familien. Detaljert produktinformasjon er ikke offentlig tilgjengelig fra produsenten.'
where id = '9a27c34e-9ad7-4cd0-b655-b05405a24b7c';

update cigars set
  manufacturer = 'My Father Cigars', brand = 'My Father', series = 'Garcia & Garcia',
  common_format = 'Toro', shape = 'Parejo',
  description = 'Et mindre kjent merke i My Father-familien. Detaljert produktinformasjon er ikke offentlig tilgjengelig fra produsenten.'
where id = '8c900786-780f-402a-ab13-e06deb60fbec';

-- === Flor de las Antillas / Natural ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'Flor de las Antillas', series = 'Natural',
  vitola = 'Robusto', common_format = 'Robusto',
  ring_gauge = 50, length_inches = 5.0, shape = 'Box-Pressed', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'Nicaragua', wrapper_leaf = 'Sun Grown', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 4, price_range = null,
  description = 'Kåret til årets sigar nr. 1 i 2012 — boxpresset med solgrodd dekkblad og rik kakaosmak.'
where id = 'dbe51de9-16a3-4e4e-869b-387f64c1beca';

-- === Flor de las Antillas / Maduro ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'Flor de las Antillas', series = 'Maduro',
  vitola = 'Toro Gordo Maduro', common_format = 'Toro Gordo',
  ring_gauge = 56, length_inches = 6.5, shape = 'Box-Pressed', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'Nicaragua', wrapper_leaf = 'Habano Sun Grown Oscuro', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 4, price_range = null,
  description = 'Maduro-versjonen av Flor de las Antillas, med mørkere og søtere dekkblad.'
where id = 'b8532341-fe22-42e6-a28f-28ef46acca49';

-- === Don Pepin Garcia / Original (Blue Label) ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'Don Pepin Garcia', series = 'Original / Blue Label',
  vitola = 'Invictos', common_format = 'Robusto',
  ring_gauge = 50, length_inches = 5.0, shape = 'Parejo', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'USA', wrapper_leaf = 'Habano Rosado', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'USA', strength = 5, price_range = null,
  description = 'Den opprinnelige Don Pepin Garcia-linjen («Blue Label») — håndrullet i Miami, USA.'
where id = 'e3f1263f-e84d-4961-a235-1d526abe50ed';

-- === Don Pepin Garcia / Cuban Classic ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'Don Pepin Garcia', series = 'Cuban Classic',
  vitola = '1979', common_format = 'Robusto',
  ring_gauge = 50, length_inches = 5.0, shape = 'Parejo', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'Nicaragua', wrapper_leaf = 'Habano Rosado', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 4, price_range = null,
  description = 'Hyllest til kubanske årstall i familiens historie — håndrullet i Nicaragua.'
where id = '56d62785-690f-4c00-9c03-c10150fb4fda';

-- === Don Pepin Garcia / Series JJ ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'Don Pepin Garcia', series = 'Series JJ',
  vitola = 'Belicosos', common_format = 'Belicoso',
  ring_gauge = 52, length_inches = 5.75, shape = 'Figurado', body_type = 'Belicoso', head_type = 'Pointed', foot_type = 'Closed',
  wrapper_country = 'Nicaragua', wrapper_leaf = 'Corojo Rosado', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'USA', strength = 5, price_range = null,
  description = 'Oppkalt etter Don Pepins barnebarn JJ — håndrullet i Miami med Corojo Rosado-dekkblad.'
where id = 'c175e133-8a81-4817-b662-ff13cb4f0e69';

-- === Don Pepin Garcia / Vegas Cubanas ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'Don Pepin Garcia', series = 'Vegas Cubanas',
  vitola = 'Coronas', common_format = 'Corona',
  ring_gauge = 44, length_inches = 5.5, shape = 'Parejo', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'Nicaragua', wrapper_leaf = 'Corojo Rosado', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 3, price_range = null,
  description = 'Mildere og mer tilgjengelig variant av Don Pepin-blandingen.'
where id = '1e01f934-28af-439c-a2ae-04e3aa0e703a';

-- === Don Pepin Garcia / Vintage Edition ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'Don Pepin Garcia', series = 'Vintage Edition',
  vitola = 'Corona Gorda', common_format = 'Corona Gorda',
  ring_gauge = 48, length_inches = 5.75, shape = 'Parejo', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'Nicaragua', wrapper_leaf = 'Corojo 99', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 4, price_range = null,
  description = 'Lansert i 2023 for å feire Don Pepin Garcias 20-årsjubileum.'
where id = '826f4be6-f8e9-42e7-afe2-60737f6df72b';

-- === Don Pepin Garcia / E.R.H ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'Don Pepin Garcia', series = 'E.R.H',
  vitola = 'Robusto', common_format = 'Robusto',
  ring_gauge = 54, length_inches = 5.0, shape = 'Parejo', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'Ecuador', wrapper_leaf = 'Sumatra Ecuador', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 4, price_range = null,
  description = 'El Rey de los Habanos — «Habanoenes konge».'
where id = 'ee0817a0-2dba-4fde-bb03-80dd7d028b37';

-- === Jaime Garcia / Reserva Especial ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'Jaime Garcia', series = 'Reserva Especial',
  vitola = 'Petit Robusto', common_format = 'Petit Robusto',
  ring_gauge = 50, length_inches = 4.5, shape = 'Parejo', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'USA', wrapper_leaf = 'Broad Leaf', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 4, price_range = null,
  description = 'Oppkalt etter Jaime Garcia — bredt utvalg fra liten robusto til ekstreme ringmål.'
where id = '08fd32ff-c0db-48e1-972b-cdf6a94623b2';

-- === Jaime Garcia / Reserva Especial Connecticut ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'Jaime Garcia', series = 'Reserva Especial Connecticut',
  vitola = 'Robusto', common_format = 'Robusto',
  ring_gauge = 50, length_inches = 5.0, shape = 'Parejo', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'Ecuador', wrapper_leaf = 'Connecticut Ecuador', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 3, price_range = null,
  description = 'Mildere Connecticut-variant av Jaime Garcia Reserva Especial.'
where id = '1a39c6e8-b561-42e8-b2e4-ef1f1d95f039';

-- === El Centurion / Original ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'El Centurion', series = 'Original',
  vitola = 'Robusto', common_format = 'Robusto',
  ring_gauge = 50, length_inches = 5.75, shape = 'Parejo', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'Nicaragua', wrapper_leaf = 'Sun Grown Criollo 98', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 4, price_range = null,
  description = 'Solgrodd Criollo 98-dekkblad gir en jordnær, kraftig smaksprofil.'
where id = '2459f4d2-7a26-4200-85d3-e6fe2f4515e9';

-- === El Centurion / H-2K-CT ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'El Centurion', series = 'H-2K-CT',
  vitola = 'Corona', common_format = 'Corona',
  ring_gauge = 48, length_inches = 5.5, shape = 'Parejo', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'USA', wrapper_leaf = 'H-2K-CT hybrid', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 4, price_range = null,
  description = 'El Centurion med en eksperimentell hybrid-dekkbladblanding (H-2K-CT).'
where id = 'a46f3394-1d12-4b5d-bcc6-bb56ed0f2c43';

-- === Fonseca by My Father / Corojo / Natural ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'Fonseca by My Father', series = 'Corojo / Natural',
  vitola = 'Belicoso', common_format = 'Belicoso',
  ring_gauge = 54, length_inches = 5.5, shape = 'Figurado', body_type = 'Belicoso', head_type = 'Pointed', foot_type = 'Closed',
  wrapper_country = 'Nicaragua', wrapper_leaf = 'Corojo 99', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 3, price_range = null,
  description = 'Den historiske Fonseca-merkevaren (Havana, 1892), nå rullet av familien Garcia.'
where id = '9fd1c2d5-ecc0-4c49-b840-1c92657a88b7';

-- === Fonseca by My Father / Mexico Edition ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'Fonseca by My Father', series = 'Mexico Edition',
  vitola = 'Toro Grande', common_format = 'Toro Grande',
  ring_gauge = 56, length_inches = 6.5, shape = 'Parejo', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'Mexico', wrapper_leaf = 'Mexico San Andres Maduro', binder = 'Nicaraguan', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 4, price_range = null,
  description = 'Fonseca med oljete meksikansk San Andres Maduro-dekkblad — fyldigere enn originalen.'
where id = '50a254b8-fe45-4038-a5c3-4d534c134502';

-- === La Antiguedad (standalone) ===
update cigars set
  manufacturer = 'My Father Cigars', brand = 'La Antiguedad', series = 'La Antiguedad',
  vitola = 'Robusto', common_format = 'Robusto',
  ring_gauge = 52, length_inches = 5.25, shape = 'Parejo', body_type = null, head_type = null, foot_type = null,
  wrapper_country = 'Ecuador', wrapper_leaf = 'Habano Ecuador Rosado Oscuro', binder = 'Corojo/Criollo', filler = array['Nicaragua'],
  country_origin = 'Nicaragua', strength = 4, price_range = null,
  description = '«Antikviteten» — boxpresset Habano Ecuador-dekkblad med kraftig smak.'
where id = '8692737d-1b6e-4464-b254-27e2f8f8bed8';

-- ----------------------------------------------------------------
-- 3) INSERT — alle manglende vitola-rader pr. serie
-- ----------------------------------------------------------------

-- My Father / Original Core Line (resterende 7 av 8)
insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description) values
('My Father Cigars','My Father','Original Core Line','No.2 Belicoso','Belicoso',54,5.5,'Figurado','Belicoso','Pointed','Closed','Nicaragua','Habano Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',5,'$140.35','My Fathers kjernelinje — den opprinnelige sigaren som satte familien Garcia på kartet. Habano Rosado-dekkblad, full styrke.'),
('My Father Cigars','My Father','Original Core Line','No.3 Crema','Corona Gorda',49,6.0,'Parejo',null,null,null,'Nicaragua','Habano Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',5,'$145.35','My Fathers kjernelinje — den opprinnelige sigaren som satte familien Garcia på kartet. Habano Rosado-dekkblad, full styrke.'),
('My Father Cigars','My Father','Original Core Line','No.4 Lancero','Lancero',38,7.5,'Parejo',null,null,null,'Nicaragua','Habano Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',5,'$161.00','My Fathers kjernelinje — den opprinnelige sigaren som satte familien Garcia på kartet. Habano Rosado-dekkblad, full styrke.'),
('My Father Cigars','My Father','Original Core Line','No.5 Toro','Toro Gordo',56,6.0,'Parejo',null,null,null,'Nicaragua','Habano Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',5,'$161.00','My Fathers kjernelinje — den opprinnelige sigaren som satte familien Garcia på kartet. Habano Rosado-dekkblad, full styrke.'),
('My Father Cigars','My Father','Original Core Line','No.6 Toro Gordo','Toro Grande',60,6.0,'Box-Pressed',null,null,null,'Nicaragua','Habano Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',5,'$120.85','My Fathers kjernelinje — den opprinnelige sigaren som satte familien Garcia på kartet. Habano Rosado-dekkblad, full styrke.'),
('My Father Cigars','My Father','Original Core Line','Cedro Deluxe Eminentes','Corona Gorda',46,5.625,'Parejo',null,null,null,'Nicaragua','Habano Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',5,'$116.15','My Fathers kjernelinje — den opprinnelige sigaren som satte familien Garcia på kartet. Habano Rosado-dekkblad, full styrke.'),
('My Father Cigars','My Father','Original Core Line','Cedro Deluxe Cervantes','Corona',44,6.5,'Parejo',null,null,null,'Nicaragua','Habano Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',5,'$116.15','My Fathers kjernelinje — den opprinnelige sigaren som satte familien Garcia på kartet. Habano Rosado-dekkblad, full styrke.'),

-- My Father / Le Bijou 1922 (resterende 3 av 5)
('My Father Cigars','My Father','Le Bijou 1922','Churchill','Churchill',50,7.0,'Parejo',null,null,null,'Nicaragua','Habano Oscuro-Oscuro','Nicaraguan',array['Nicaragua'],'Nicaragua',5,null,'Et av My Fathers kraftigste merker — mørkt Habano Oscuro-Oscuro-dekkblad og svært full styrke.'),
('My Father Cigars','My Father','Le Bijou 1922','Petit Robusto','Petit Robusto',50,4.5,'Parejo',null,null,null,'Nicaragua','Habano Oscuro-Oscuro','Nicaraguan',array['Nicaragua'],'Nicaragua',5,null,'Et av My Fathers kraftigste merker — mørkt Habano Oscuro-Oscuro-dekkblad og svært full styrke.'),
('My Father Cigars','My Father','Le Bijou 1922','Grand Robusto','Robusto',55,5.625,'Parejo',null,null,null,'Nicaragua','Habano Oscuro-Oscuro','Nicaraguan',array['Nicaragua'],'Nicaragua',5,null,'Et av My Fathers kraftigste merker — mørkt Habano Oscuro-Oscuro-dekkblad og svært full styrke.'),

-- My Father / Connecticut (resterende 3 av 4)
('My Father Cigars','My Father','Connecticut','Toro','Toro',54,6.5,'Parejo',null,null,null,'Ecuador','Connecticut','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Den mildeste varianten i My Father-familien, med lyst Connecticut-dekkblad fra Ecuador.'),
('My Father Cigars','My Father','Connecticut','Toro Gordo','Toro Gordo',60,6.0,'Parejo',null,null,null,'Ecuador','Connecticut','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Den mildeste varianten i My Father-familien, med lyst Connecticut-dekkblad fra Ecuador.'),
('My Father Cigars','My Father','Connecticut','Corona Gorda','Corona Gorda',48,6.0,'Parejo',null,null,null,'Ecuador','Connecticut','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Den mildeste varianten i My Father-familien, med lyst Connecticut-dekkblad fra Ecuador.'),

-- My Father / The Judge (resterende 3 av 4)
('My Father Cigars','My Father','The Judge','Grand Robusto','Robusto',60,5.0,'Box-Pressed',null,null,null,'Ecuador','Sumatra Oscuro','Corojo/Criollo',array['Nicaragua'],'Nicaragua',5,null,'Boxpresset sigar med mørkt Sumatra Oscuro-dekkblad — kraftig og krydret.'),
('My Father Cigars','My Father','The Judge','Toro Fino','Toro',52,6.0,'Box-Pressed',null,null,null,'Ecuador','Sumatra Oscuro','Corojo/Criollo',array['Nicaragua'],'Nicaragua',5,null,'Boxpresset sigar med mørkt Sumatra Oscuro-dekkblad — kraftig og krydret.'),
('My Father Cigars','My Father','The Judge','Toro','Toro Gordo',56,6.0,'Box-Pressed',null,null,null,'Ecuador','Sumatra Oscuro','Corojo/Criollo',array['Nicaragua'],'Nicaragua',5,null,'Boxpresset sigar med mørkt Sumatra Oscuro-dekkblad — kraftig og krydret.'),

-- My Father / La Opulencia (resterende 6 av 7)
('My Father Cigars','My Father','La Opulencia','Corona','Corona',46,5.0,'Box-Pressed',null,null,null,'Mexico','Rosado Oscuro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Boxpresset sigar med mørkt meksikansk Rosado Oscuro-dekkblad og rik, søtlig smak.'),
('My Father Cigars','My Father','La Opulencia','Robusto','Robusto',52,5.25,'Box-Pressed',null,null,null,'Mexico','Rosado Oscuro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Boxpresset sigar med mørkt meksikansk Rosado Oscuro-dekkblad og rik, søtlig smak.'),
('My Father Cigars','My Father','La Opulencia','Toro','Toro',54,6.0,'Box-Pressed',null,null,null,'Mexico','Rosado Oscuro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Boxpresset sigar med mørkt meksikansk Rosado Oscuro-dekkblad og rik, søtlig smak.'),
('My Father Cigars','My Father','La Opulencia','Toro Gordo','Toro Gordo',56,7.0,'Box-Pressed',null,null,null,'Mexico','Rosado Oscuro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Boxpresset sigar med mørkt meksikansk Rosado Oscuro-dekkblad og rik, søtlig smak.'),
('My Father Cigars','My Father','La Opulencia','Super Toro','Toro Grande',60,6.0,'Box-Pressed',null,null,null,'Mexico','Rosado Oscuro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Boxpresset sigar med mørkt meksikansk Rosado Oscuro-dekkblad og rik, søtlig smak.'),
('My Father Cigars','My Father','La Opulencia','Torpedo','Torpedo',52,6.125,'Figurado','Torpedo','Pointed','Closed','Mexico','Rosado Oscuro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Boxpresset sigar med mørkt meksikansk Rosado Oscuro-dekkblad og rik, søtlig smak.'),

-- My Father / La Gran Oferta (resterende 4 av 5)
('My Father Cigars','My Father','La Gran Oferta','Lancero','Lancero',38,7.5,'Parejo',null,null,null,'Ecuador','Habano Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'«Det store tilbudet» — hyllest til en gammel kubansk merkevare fra 1913, med oljete Habano Rosado-dekkblad.'),
('My Father Cigars','My Father','La Gran Oferta','Torpedo','Torpedo',52,6.125,'Figurado','Torpedo','Pointed','Closed','Ecuador','Habano Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'«Det store tilbudet» — hyllest til en gammel kubansk merkevare fra 1913, med oljete Habano Rosado-dekkblad.'),
('My Father Cigars','My Father','La Gran Oferta','Toro','Toro',50,6.0,'Parejo',null,null,null,'Ecuador','Habano Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'«Det store tilbudet» — hyllest til en gammel kubansk merkevare fra 1913, med oljete Habano Rosado-dekkblad.'),
('My Father Cigars','My Father','La Gran Oferta','Toro Gordo','Toro Gordo',56,6.0,'Parejo',null,null,null,'Ecuador','Habano Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'«Det store tilbudet» — hyllest til en gammel kubansk merkevare fra 1913, med oljete Habano Rosado-dekkblad.'),

-- My Father / La Promesa (resterende 4 av 5)
('My Father Cigars','My Father','La Promesa','Lancero','Lancero',38,7.5,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'«Løftet» — oppkalt etter Don Pepin Garcias løfte til familien om å lykkes utenfor Cuba.'),
('My Father Cigars','My Father','La Promesa','Petite','Petit Robusto',50,4.5,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'«Løftet» — oppkalt etter Don Pepin Garcias løfte til familien om å lykkes utenfor Cuba.'),
('My Father Cigars','My Father','La Promesa','Robusto Grande','Robusto',54,5.5,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'«Løftet» — oppkalt etter Don Pepin Garcias løfte til familien om å lykkes utenfor Cuba.'),
('My Father Cigars','My Father','La Promesa','Toro','Toro',52,6.0,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'«Løftet» — oppkalt etter Don Pepin Garcias løfte til familien om å lykkes utenfor Cuba.'),

-- My Father / Blue (resterende 3 av 4)
('My Father Cigars','My Father','Blue','Robusto','Robusto',52,5.25,'Box-Pressed',null,null,null,'USA','Connecticut Broadleaf Rosado','Honduran',array['Honduras'],'Honduras',3,null,'My Fathers nyeste linje (2025) — første sigar fra familiens nye fabrikk i Honduras.'),
('My Father Cigars','My Father','Blue','Toro','Toro',54,6.0,'Box-Pressed',null,null,null,'USA','Connecticut Broadleaf Rosado','Honduran',array['Honduras'],'Honduras',3,null,'My Fathers nyeste linje (2025) — første sigar fra familiens nye fabrikk i Honduras.'),
('My Father Cigars','My Father','Blue','Toro Gordo','Toro Gordo',60,6.0,'Box-Pressed',null,null,null,'USA','Connecticut Broadleaf Rosado','Honduran',array['Honduras'],'Honduras',3,null,'My Fathers nyeste linje (2025) — første sigar fra familiens nye fabrikk i Honduras.'),

-- My Father / La Lealtad (resterende 3 av 4)
('My Father Cigars','My Father','La Lealtad','Toro','Toro',54,6.0,'Parejo',null,null,null,'Ecuador','Rosado Oscuro','Nicaraguan and Honduran',array['Honduras','Nicaragua'],'Honduras',5,null,'«Lojaliteten» — den nyeste sigaren fra familiens fabrikk i Honduras.'),
('My Father Cigars','My Father','La Lealtad','Toro Gordo','Toro Gordo',60,6.0,'Parejo',null,null,null,'Ecuador','Rosado Oscuro','Nicaraguan and Honduran',array['Honduras','Nicaragua'],'Honduras',5,null,'«Lojaliteten» — den nyeste sigaren fra familiens fabrikk i Honduras.'),
('My Father Cigars','My Father','La Lealtad','Torpedo Box Pressed','Torpedo',52,6.125,'Figurado','Torpedo Box-Pressed','Pointed','Closed','Ecuador','Rosado Oscuro','Nicaraguan and Honduran',array['Honduras','Nicaragua'],'Honduras',5,null,'«Lojaliteten» — den nyeste sigaren fra familiens fabrikk i Honduras.'),

-- Flor de las Antillas / Natural (resterende 4 av 5)
('My Father Cigars','Flor de las Antillas','Natural','Belicoso','Belicoso',52,5.5,'Figurado','Belicoso','Pointed','Closed','Nicaragua','Sun Grown','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Kåret til årets sigar nr. 1 i 2012 — boxpresset med solgrodd dekkblad og rik kakaosmak.'),
('My Father Cigars','Flor de las Antillas','Natural','Toro','Toro',52,6.0,'Box-Pressed',null,null,null,'Nicaragua','Sun Grown','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Kåret til årets sigar nr. 1 i 2012 — boxpresset med solgrodd dekkblad og rik kakaosmak.'),
('My Father Cigars','Flor de las Antillas','Natural','Toro Gordo','Toro Gordo',56,6.5,'Box-Pressed',null,null,null,'Nicaragua','Sun Grown','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Kåret til årets sigar nr. 1 i 2012 — boxpresset med solgrodd dekkblad og rik kakaosmak.'),
('My Father Cigars','Flor de las Antillas','Natural','Toro Grande','Toro Grande',60,6.0,'Box-Pressed',null,null,null,'Nicaragua','Sun Grown','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Kåret til årets sigar nr. 1 i 2012 — boxpresset med solgrodd dekkblad og rik kakaosmak.'),

-- Flor de las Antillas / Maduro (resterende 4 av 5)
('My Father Cigars','Flor de las Antillas','Maduro','Toro Maduro','Toro',52,6.0,'Box-Pressed',null,null,null,'Nicaragua','Habano Sun Grown Oscuro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Maduro-versjonen av Flor de las Antillas, med mørkere og søtere dekkblad.'),
('My Father Cigars','Flor de las Antillas','Maduro','Corona Maduro','Corona Gorda',46,5.625,'Box-Pressed',null,null,null,'Nicaragua','Habano Sun Grown Oscuro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Maduro-versjonen av Flor de las Antillas, med mørkere og søtere dekkblad.'),
('My Father Cigars','Flor de las Antillas','Maduro','Petit Robusto Maduro','Petit Robusto',50,4.5,'Box-Pressed',null,null,null,'Nicaragua','Habano Sun Grown Oscuro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Maduro-versjonen av Flor de las Antillas, med mørkere og søtere dekkblad.'),
('My Father Cigars','Flor de las Antillas','Maduro','Torpedo Maduro','Torpedo',52,6.125,'Figurado','Torpedo','Pointed','Closed','Nicaragua','Habano Sun Grown Oscuro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Maduro-versjonen av Flor de las Antillas, med mørkere og søtere dekkblad.'),

-- Don Pepin Garcia / Original (resterende 9 av 10)
('My Father Cigars','Don Pepin Garcia','Original / Blue Label','Generosos','Toro',50,6.0,'Parejo',null,null,null,'USA','Habano Rosado','Nicaraguan',array['Nicaragua'],'USA',5,null,'Den opprinnelige Don Pepin Garcia-linjen («Blue Label») — håndrullet i Miami, USA.'),
('My Father Cigars','Don Pepin Garcia','Original / Blue Label','Delicias','Churchill',50,7.0,'Parejo',null,null,null,'USA','Habano Rosado','Nicaraguan',array['Nicaragua'],'USA',5,null,'Den opprinnelige Don Pepin Garcia-linjen («Blue Label») — håndrullet i Miami, USA.'),
('My Father Cigars','Don Pepin Garcia','Original / Blue Label','Imperiales','Torpedo',52,6.125,'Figurado','Torpedo','Pointed','Closed','USA','Habano Rosado','Nicaraguan',array['Nicaragua'],'USA',5,null,'Den opprinnelige Don Pepin Garcia-linjen («Blue Label») — håndrullet i Miami, USA.'),
('My Father Cigars','Don Pepin Garcia','Original / Blue Label','Lanceros','Lancero',38,7.5,'Parejo',null,null,null,'USA','Habano Rosado','Nicaraguan',array['Nicaragua'],'USA',5,null,'Den opprinnelige Don Pepin Garcia-linjen («Blue Label») — håndrullet i Miami, USA.'),
('My Father Cigars','Don Pepin Garcia','Original / Blue Label','Exquisitos','Corona Gorda',46,5.625,'Parejo',null,null,null,'USA','Habano Rosado','Nicaraguan',array['Nicaragua'],'USA',5,null,'Den opprinnelige Don Pepin Garcia-linjen («Blue Label») — håndrullet i Miami, USA.'),
('My Father Cigars','Don Pepin Garcia','Original / Blue Label','Toro Gordo','Toro Gordo',56,6.0,'Parejo',null,null,null,'USA','Habano Rosado','Nicaraguan',array['Nicaragua'],'USA',5,null,'Den opprinnelige Don Pepin Garcia-linjen («Blue Label») — håndrullet i Miami, USA.'),
('My Father Cigars','Don Pepin Garcia','Original / Blue Label','Exclusivos','Gran Corona',48,9.25,'Parejo',null,null,null,'USA','Habano Rosado','Nicaraguan',array['Nicaragua'],'USA',5,null,'Den opprinnelige Don Pepin Garcia-linjen («Blue Label») — håndrullet i Miami, USA.'),
('My Father Cigars','Don Pepin Garcia','Original / Blue Label','Toro Grande','Toro Grande',62,6.0,'Box-Pressed',null,null,null,'USA','Habano Rosado','Nicaraguan',array['Nicaragua'],'USA',5,null,'Den opprinnelige Don Pepin Garcia-linjen («Blue Label») — håndrullet i Miami, USA.'),
('My Father Cigars','Don Pepin Garcia','Original / Blue Label','Demitasse','Demitasse',32,4.5,'Parejo',null,null,null,'USA','Habano Rosado','Nicaraguan',array['Nicaragua'],'USA',5,null,'Den opprinnelige Don Pepin Garcia-linjen («Blue Label») — håndrullet i Miami, USA.'),

-- Don Pepin Garcia / Cuban Classic (resterende 3 av 4)
('My Father Cigars','Don Pepin Garcia','Cuban Classic','1970','Belicoso',54,5.5,'Figurado','Belicoso','Pointed','Closed','Nicaragua','Habano Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Hyllest til kubanske årstall i familiens historie — håndrullet i Nicaragua.'),
('My Father Cigars','Don Pepin Garcia','Cuban Classic','1950','Toro',52,6.0,'Parejo',null,null,null,'Nicaragua','Habano Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Hyllest til kubanske årstall i familiens historie — håndrullet i Nicaragua.'),
('My Father Cigars','Don Pepin Garcia','Cuban Classic','2001','Toro Gordo',60,6.0,'Parejo',null,null,null,'Nicaragua','Habano Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Hyllest til kubanske årstall i familiens historie — håndrullet i Nicaragua.'),

-- Don Pepin Garcia / Series JJ (resterende 3 av 4)
('My Father Cigars','Don Pepin Garcia','Series JJ','Toros','Toro',54,6.0,'Parejo',null,null,null,'Nicaragua','Corojo Rosado','Nicaraguan',array['Nicaragua'],'USA',5,null,'Oppkalt etter Don Pepins barnebarn JJ — håndrullet i Miami med Corojo Rosado-dekkblad.'),
('My Father Cigars','Don Pepin Garcia','Series JJ','Selectos','Robusto',50,5.0,'Parejo',null,null,null,'Nicaragua','Corojo Rosado','Nicaraguan',array['Nicaragua'],'USA',5,null,'Oppkalt etter Don Pepins barnebarn JJ — håndrullet i Miami med Corojo Rosado-dekkblad.'),
('My Father Cigars','Don Pepin Garcia','Series JJ','Salomones','Salomon',57,7.25,'Figurado','Salomon','Pointed','Tapered','Nicaragua','Corojo Rosado','Nicaraguan',array['Nicaragua'],'USA',5,null,'Oppkalt etter Don Pepins barnebarn JJ — håndrullet i Miami med Corojo Rosado-dekkblad.'),

-- Don Pepin Garcia / Vegas Cubanas (resterende 4 av 5)
('My Father Cigars','Don Pepin Garcia','Vegas Cubanas','Invictos','Robusto',50,5.0,'Parejo',null,null,null,'Nicaragua','Corojo Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Mildere og mer tilgjengelig variant av Don Pepin-blandingen.'),
('My Father Cigars','Don Pepin Garcia','Vegas Cubanas','Generosos','Toro',50,6.0,'Parejo',null,null,null,'Nicaragua','Corojo Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Mildere og mer tilgjengelig variant av Don Pepin-blandingen.'),
('My Father Cigars','Don Pepin Garcia','Vegas Cubanas','Imperiales','Torpedo',52,6.125,'Figurado','Torpedo','Pointed','Closed','Nicaragua','Corojo Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Mildere og mer tilgjengelig variant av Don Pepin-blandingen.'),
('My Father Cigars','Don Pepin Garcia','Vegas Cubanas','Toro Gordo','Toro Gordo',60,6.0,'Parejo',null,null,null,'Nicaragua','Corojo Rosado','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Mildere og mer tilgjengelig variant av Don Pepin-blandingen.'),

-- Don Pepin Garcia / Vintage Edition (resterende 4 av 5)
('My Father Cigars','Don Pepin Garcia','Vintage Edition','Petit Robusto','Petit Robusto',50,4.5,'Parejo',null,null,null,'Nicaragua','Corojo 99','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Lansert i 2023 for å feire Don Pepin Garcias 20-årsjubileum.'),
('My Father Cigars','Don Pepin Garcia','Vintage Edition','Robusto','Robusto',54,5.0,'Parejo',null,null,null,'Nicaragua','Corojo 99','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Lansert i 2023 for å feire Don Pepin Garcias 20-årsjubileum.'),
('My Father Cigars','Don Pepin Garcia','Vintage Edition','Toro Gordo','Toro Gordo',60,6.0,'Parejo',null,null,null,'Nicaragua','Corojo 99','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Lansert i 2023 for å feire Don Pepin Garcias 20-årsjubileum.'),
('My Father Cigars','Don Pepin Garcia','Vintage Edition','Toro','Toro',52,6.0,'Parejo',null,null,null,'Nicaragua','Corojo 99','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Lansert i 2023 for å feire Don Pepin Garcias 20-årsjubileum.'),

-- Don Pepin Garcia / E.R.H (resterende 2 av 3)
('My Father Cigars','Don Pepin Garcia','E.R.H','Toro','Toro',52,6.0,'Parejo',null,null,null,'Ecuador','Sumatra Ecuador','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'El Rey de los Habanos — «Habanoenes konge».'),
('My Father Cigars','Don Pepin Garcia','E.R.H','Toro Gordo','Toro Gordo',60,6.0,'Parejo',null,null,null,'Ecuador','Sumatra Ecuador','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'El Rey de los Habanos — «Habanoenes konge».'),

-- Jaime Garcia / Reserva Especial (resterende 8 av 9)
('My Father Cigars','Jaime Garcia','Reserva Especial','Belicoso','Belicoso',52,5.5,'Figurado','Belicoso','Pointed','Closed','USA','Broad Leaf','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Oppkalt etter Jaime Garcia — bredt utvalg fra liten robusto til ekstreme ringmål.'),
('My Father Cigars','Jaime Garcia','Reserva Especial','Robusto','Robusto',52,5.25,'Parejo',null,null,null,'USA','Broad Leaf','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Oppkalt etter Jaime Garcia — bredt utvalg fra liten robusto til ekstreme ringmål.'),
('My Father Cigars','Jaime Garcia','Reserva Especial','Toro','Toro',54,6.0,'Parejo',null,null,null,'USA','Broad Leaf','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Oppkalt etter Jaime Garcia — bredt utvalg fra liten robusto til ekstreme ringmål.'),
('My Father Cigars','Jaime Garcia','Reserva Especial','Toro Gordo','Toro Gordo',60,6.0,'Parejo',null,null,null,'USA','Broad Leaf','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Oppkalt etter Jaime Garcia — bredt utvalg fra liten robusto til ekstreme ringmål.'),
('My Father Cigars','Jaime Garcia','Reserva Especial','Super Gordo','Gordo',66,5.75,'Parejo',null,null,null,'USA','Broad Leaf','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Oppkalt etter Jaime Garcia — bredt utvalg fra liten robusto til ekstreme ringmål.'),
('My Father Cigars','Jaime Garcia','Reserva Especial','Gordo Extra','Gordo',70,7.0,'Parejo',null,null,null,'USA','Broad Leaf','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Oppkalt etter Jaime Garcia — bredt utvalg fra liten robusto til ekstreme ringmål.'),
('My Father Cigars','Jaime Garcia','Reserva Especial','Corona Grande','Corona Gorda',48,6.25,'Parejo',null,null,null,'USA','Broad Leaf','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Oppkalt etter Jaime Garcia — bredt utvalg fra liten robusto til ekstreme ringmål.'),
('My Father Cigars','Jaime Garcia','Reserva Especial','Figurado-J.G.','Perfecto',52,5.625,'Figurado','Perfecto','Pointed','Tapered','USA','Broad Leaf','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Oppkalt etter Jaime Garcia — bredt utvalg fra liten robusto til ekstreme ringmål.'),

-- Jaime Garcia / Reserva Especial Connecticut (resterende 3 av 4)
('My Father Cigars','Jaime Garcia','Reserva Especial Connecticut','Toro','Toro',54,6.0,'Parejo',null,null,null,'Ecuador','Connecticut Ecuador','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Mildere Connecticut-variant av Jaime Garcia Reserva Especial.'),
('My Father Cigars','Jaime Garcia','Reserva Especial Connecticut','Toro Gordo','Toro Gordo',60,6.0,'Parejo',null,null,null,'Ecuador','Connecticut Ecuador','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Mildere Connecticut-variant av Jaime Garcia Reserva Especial.'),
('My Father Cigars','Jaime Garcia','Reserva Especial Connecticut','Churchill','Churchill',50,7.0,'Parejo',null,null,null,'Ecuador','Connecticut Ecuador','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Mildere Connecticut-variant av Jaime Garcia Reserva Especial.'),

-- El Centurion / Original (resterende 2 av 3)
('My Father Cigars','El Centurion','Original','Toro','Toro',52,6.25,'Parejo',null,null,null,'Nicaragua','Sun Grown Criollo 98','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Solgrodd Criollo 98-dekkblad gir en jordnær, kraftig smaksprofil.'),
('My Father Cigars','El Centurion','Original','Toro Grande','Toro Grande',58,6.5,'Parejo',null,null,null,'Nicaragua','Sun Grown Criollo 98','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Solgrodd Criollo 98-dekkblad gir en jordnær, kraftig smaksprofil.'),

-- El Centurion / H-2K-CT (resterende 2 av 3)
('My Father Cigars','El Centurion','H-2K-CT','Toro','Toro',52,6.0,'Parejo',null,null,null,'USA','H-2K-CT hybrid','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'El Centurion med en eksperimentell hybrid-dekkbladblanding (H-2K-CT).'),
('My Father Cigars','El Centurion','H-2K-CT','Toro Grande','Toro Grande',58,6.5,'Parejo',null,null,null,'USA','H-2K-CT hybrid','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'El Centurion med en eksperimentell hybrid-dekkbladblanding (H-2K-CT).'),

-- Fonseca by My Father / Corojo / Natural (resterende 5 av 6)
('My Father Cigars','Fonseca by My Father','Corojo / Natural','Cedros','Toro',52,6.25,'Parejo',null,null,null,'Nicaragua','Corojo 99','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Den historiske Fonseca-merkevaren (Havana, 1892), nå rullet av familien Garcia.'),
('My Father Cigars','Fonseca by My Father','Corojo / Natural','Cosacos','Corona',42,5.375,'Parejo',null,null,null,'Nicaragua','Corojo 99','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Den historiske Fonseca-merkevaren (Havana, 1892), nå rullet av familien Garcia.'),
('My Father Cigars','Fonseca by My Father','Corojo / Natural','Petit Corona','Petit Corona',40,4.25,'Parejo',null,null,null,'Nicaragua','Corojo 99','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Den historiske Fonseca-merkevaren (Havana, 1892), nå rullet av familien Garcia.'),
('My Father Cigars','Fonseca by My Father','Corojo / Natural','Robustos','Robusto',52,5.25,'Parejo',null,null,null,'Nicaragua','Corojo 99','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Den historiske Fonseca-merkevaren (Havana, 1892), nå rullet av familien Garcia.'),
('My Father Cigars','Fonseca by My Father','Corojo / Natural','Toro Gordo','Toro Gordo',55,6.0,'Parejo',null,null,null,'Nicaragua','Corojo 99','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'Den historiske Fonseca-merkevaren (Havana, 1892), nå rullet av familien Garcia.'),

-- Fonseca by My Father / Mexico Edition (resterende 3 av 4)
('My Father Cigars','Fonseca by My Father','Mexico Edition','Cedros','Toro',52,6.25,'Parejo',null,null,null,'Mexico','Mexico San Andres Maduro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Fonseca med oljete meksikansk San Andres Maduro-dekkblad — fyldigere enn originalen.'),
('My Father Cigars','Fonseca by My Father','Mexico Edition','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Mexico','Mexico San Andres Maduro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Fonseca med oljete meksikansk San Andres Maduro-dekkblad — fyldigere enn originalen.'),
('My Father Cigars','Fonseca by My Father','Mexico Edition','Toro Gordo','Toro Gordo',60,6.0,'Parejo',null,null,null,'Mexico','Mexico San Andres Maduro','Nicaraguan',array['Nicaragua'],'Nicaragua',4,null,'Fonseca med oljete meksikansk San Andres Maduro-dekkblad — fyldigere enn originalen.'),

-- La Antiguedad (resterende 4 av 5)
('My Father Cigars','La Antiguedad','La Antiguedad','Toro','Toro',55,5.625,'Parejo',null,null,null,'Ecuador','Habano Ecuador Rosado Oscuro','Corojo/Criollo',array['Nicaragua'],'Nicaragua',4,null,'«Antikviteten» — boxpresset Habano Ecuador-dekkblad med kraftig smak.'),
('My Father Cigars','La Antiguedad','La Antiguedad','Corona Grande','Corona Gorda',47,6.375,'Parejo',null,null,null,'Ecuador','Habano Ecuador Rosado Oscuro','Corojo/Criollo',array['Nicaragua'],'Nicaragua',4,null,'«Antikviteten» — boxpresset Habano Ecuador-dekkblad med kraftig smak.'),
('My Father Cigars','La Antiguedad','La Antiguedad','Super Toro','Toro Gordo',56,7.0,'Parejo',null,null,null,'Ecuador','Habano Ecuador Rosado Oscuro','Corojo/Criollo',array['Nicaragua'],'Nicaragua',4,null,'«Antikviteten» — boxpresset Habano Ecuador-dekkblad med kraftig smak.'),
('My Father Cigars','La Antiguedad','La Antiguedad','Toro Gordo','Toro Grande',60,6.0,'Box-Pressed',null,null,null,'Ecuador','Habano Ecuador Rosado Oscuro','Corojo/Criollo',array['Nicaragua'],'Nicaragua',4,null,'«Antikviteten» — boxpresset Habano Ecuador-dekkblad med kraftig smak.'),

-- La Dueña (helt ny serie, standalone — 6 vitolas)
('My Father Cigars','La Dueña','La Dueña','No.5 Robusto','Robusto',50,5.0,'Parejo',null,null,null,'USA','Connecticut Broadleaf','Connecticut Broadleaf / Nicaragua',array['Nicaragua'],'Nicaragua',4,null,'Hyllest til Janny Garcia — blandet av Jaime Garcia og Pete Johnson (Tatuaje).'),
('My Father Cigars','La Dueña','La Dueña','No.2 Belicoso','Belicoso',54,5.5,'Figurado','Belicoso','Pointed','Closed','USA','Connecticut Broadleaf','Connecticut Broadleaf / Nicaragua',array['Nicaragua'],'Nicaragua',4,null,'Hyllest til Janny Garcia — blandet av Jaime Garcia og Pete Johnson (Tatuaje).'),
('My Father Cigars','La Dueña','La Dueña','No.7 Petit Lancero','Lancero',42,6.0,'Parejo',null,null,null,'USA','Connecticut Broadleaf','Connecticut Broadleaf / Nicaragua',array['Nicaragua'],'Nicaragua',4,null,'Hyllest til Janny Garcia — blandet av Jaime Garcia og Pete Johnson (Tatuaje).'),
('My Father Cigars','La Dueña','La Dueña','No.9 Petit Belicoso','Belicoso',48,4.75,'Figurado','Belicoso','Pointed','Closed','USA','Connecticut Broadleaf','Connecticut Broadleaf / Nicaragua',array['Nicaragua'],'Nicaragua',4,null,'Hyllest til Janny Garcia — blandet av Jaime Garcia og Pete Johnson (Tatuaje).'),
('My Father Cigars','La Dueña','La Dueña','No.11 Petit Robusto','Petit Robusto',52,4.5,'Parejo',null,null,null,'USA','Connecticut Broadleaf','Connecticut Broadleaf / Nicaragua',array['Nicaragua'],'Nicaragua',4,null,'Hyllest til Janny Garcia — blandet av Jaime Garcia og Pete Johnson (Tatuaje).'),
('My Father Cigars','La Dueña','La Dueña','No.13 Toro Gordo','Toro Gordo',56,6.0,'Parejo',null,null,null,'USA','Connecticut Broadleaf','Connecticut Broadleaf / Nicaragua',array['Nicaragua'],'Nicaragua',4,null,'Hyllest til Janny Garcia — blandet av Jaime Garcia og Pete Johnson (Tatuaje).'),

-- Tabacos Baez Serie SF (helt ny serie, standalone — 3 vitolas)
('My Father Cigars','Tabacos Baez Serie SF','Tabacos Baez Serie SF','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'My Fathers første short-filler-merke («Cuban Sandwich»), pakket i kabinettboks.'),
('My Father Cigars','Tabacos Baez Serie SF','Tabacos Baez Serie SF','Toro','Toro',50,6.0,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'My Fathers første short-filler-merke («Cuban Sandwich»), pakket i kabinettboks.'),
('My Father Cigars','Tabacos Baez Serie SF','Tabacos Baez Serie SF','Corona','Corona',46,6.0,'Parejo',null,null,null,'Nicaragua','Habano','Nicaraguan',array['Nicaragua'],'Nicaragua',3,null,'My Fathers første short-filler-merke («Cuban Sandwich»), pakket i kabinettboks.');

-- ----------------------------------------------------------------
-- 4) ALIAS — kjente forkortelser/variant-skrivemåter for OCR-treff
-- ----------------------------------------------------------------
insert into cigar_aliases (alias, manufacturer, brand, series) values
('MF The Judge', 'My Father Cigars', 'My Father', 'The Judge'),
('The Judge', 'My Father Cigars', 'My Father', 'The Judge'),
('My Father MF The Judge', 'My Father Cigars', 'My Father', 'The Judge'),
('Le Bijou', 'My Father Cigars', 'My Father', 'Le Bijou 1922'),
('My Father Le Bijou', 'My Father Cigars', 'My Father', 'Le Bijou 1922'),
('MF Blue', 'My Father Cigars', 'My Father', 'Blue'),
('Gran Oferta', 'My Father Cigars', 'My Father', 'La Gran Oferta'),
('Opulencia', 'My Father Cigars', 'My Father', 'La Opulencia'),
('Garcia y Garcia', 'My Father Cigars', 'My Father', 'Garcia & Garcia'),
('García & García', 'My Father Cigars', 'My Father', 'Garcia & Garcia'),
('Flor de Las Antillas', 'My Father Cigars', 'Flor de las Antillas', null),
('FDLA', 'My Father Cigars', 'Flor de las Antillas', null),
('Don Pepin Blue', 'My Father Cigars', 'Don Pepin Garcia', 'Original / Blue Label'),
('Blue Label', 'My Father Cigars', 'Don Pepin Garcia', 'Original / Blue Label'),
('DPG Blue', 'My Father Cigars', 'Don Pepin Garcia', 'Original / Blue Label'),
('Don Pepin Garcia Blue Label', 'My Father Cigars', 'Don Pepin Garcia', 'Original / Blue Label'),
('DPG', 'My Father Cigars', 'Don Pepin Garcia', null),
('Jaime Garcia R.E.', 'My Father Cigars', 'Jaime Garcia', 'Reserva Especial'),
('JG Reserva Especial', 'My Father Cigars', 'Jaime Garcia', 'Reserva Especial'),
('El Centurión', 'My Father Cigars', 'El Centurion', null),
('Centurion', 'My Father Cigars', 'El Centurion', null),
('My Father Fonseca', 'My Father Cigars', 'Fonseca by My Father', null);
