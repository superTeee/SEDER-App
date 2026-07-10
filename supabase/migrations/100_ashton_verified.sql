-- 100_ashton_verified.sql
--
-- Ashton: 70 rader → 68, alle verifisert mot produsent.
-- Kilde: https://www.ashtoncigar.com/cigars/ashton/<slug> (10 linje-sider).
--
-- Etter kjøring: 68 rader, source_tier='manufacturer', 0 uverifiserte.
-- Ingen testerdata på merket (humidor/logg/ønskeliste/målinger/strekkoder = 0).
--
--
-- KILDEN
--
-- Ashton skriver hver vitola som «Navn - LENGDE x RINGMÅL» i desimaltommer
-- (4.375 = 4 3/8"), altså LENGDE × RINGMÅL som CAO/Joya. Målene er entydige,
-- så full erstatning var trygg: de 70 gamle radene hadde null referanser.
--
--
-- HVA ASHTON PUBLISERER — OG IKKE
--
-- Spec-boksen («Product Details») oppgir bare Strength, Country og Wrapper.
-- Omblad (binder) og innmat (filler) står IKKE på produsentens sider — bare
-- omtalt i løpende prosa. Vi fyller derfor dekkblad, opprinnelse og styrke,
-- og lar binder/filler stå tomme. Ashton lages av Fuente i Den dominikanske
-- republikk; det er dominikansk omblad/innmat, men uten en tallfestet kilde
-- gjetter vi ikke feltene.
--
-- Esquire oppgir ingen wrapper i spec-boksen → dekkblad står tomt der.
-- Small Cigars (Cameroon/Connecticut) oppgir ingen country → tomt.
--
--
-- STYRKE
--
-- Ashtons ord → tall: Mild=1, Mild-Medium=2, Medium=3, Medium-Full=4, Full=5.
--
--
-- FORM
--
-- shape = 'Figurado' for Belicoso/Pyramid/Torpedo (body_type = navnet).
-- Ellers 'Parejo'. Ashton oppgir ikke tverrsnitt.
--

delete from cigars where brand='Ashton';

insert into cigars
  (brand, series, vitola, ring_gauge, length_inches, shape, body_type,
   wrapper_leaf, country_origin, strength, source_url, verified_at,
   source_tier, is_public)
values
  ('Ashton','Classic','Cordial',30,5,'Parejo',NULL,'Connecticut Shade','Dominican Republic',1,'https://www.ashtoncigar.com/cigars/ashton/ashton',now(),'manufacturer',true),
  ('Ashton','Classic','Magnum',50,5,'Parejo',NULL,'Connecticut Shade','Dominican Republic',1,'https://www.ashtoncigar.com/cigars/ashton/ashton',now(),'manufacturer',true),
  ('Ashton','Classic','Corona',44,5.5,'Parejo',NULL,'Connecticut Shade','Dominican Republic',1,'https://www.ashtoncigar.com/cigars/ashton/ashton',now(),'manufacturer',true),
  ('Ashton','Classic','Panetela',36,6,'Parejo',NULL,'Connecticut Shade','Dominican Republic',1,'https://www.ashtoncigar.com/cigars/ashton/ashton',now(),'manufacturer',true),
  ('Ashton','Classic','Crystal Belicoso',49,6,'Figurado','Belicoso','Connecticut Shade','Dominican Republic',1,'https://www.ashtoncigar.com/cigars/ashton/ashton',now(),'manufacturer',true),
  ('Ashton','Classic','Double Magnum',50,6,'Parejo',NULL,'Connecticut Shade','Dominican Republic',1,'https://www.ashtoncigar.com/cigars/ashton/ashton',now(),'manufacturer',true),
  ('Ashton','Classic','Majesty',56,6,'Parejo',NULL,'Connecticut Shade','Dominican Republic',1,'https://www.ashtoncigar.com/cigars/ashton/ashton',now(),'manufacturer',true),
  ('Ashton','Classic','Monarch',50,6,'Parejo',NULL,'Connecticut Shade','Dominican Republic',1,'https://www.ashtoncigar.com/cigars/ashton/ashton',now(),'manufacturer',true),
  ('Ashton','Classic','898',44,6.5,'Parejo',NULL,'Connecticut Shade','Dominican Republic',1,'https://www.ashtoncigar.com/cigars/ashton/ashton',now(),'manufacturer',true),
  ('Ashton','Classic','Crystal No. 1',44,6.5,'Parejo',NULL,'Connecticut Shade','Dominican Republic',1,'https://www.ashtoncigar.com/cigars/ashton/ashton',now(),'manufacturer',true),
  ('Ashton','Classic','Prime Minister',48,6.875,'Parejo',NULL,'Connecticut Shade','Dominican Republic',1,'https://www.ashtoncigar.com/cigars/ashton/ashton',now(),'manufacturer',true),
  ('Ashton','Classic','Sovereign',55,6.75,'Parejo',NULL,'Connecticut Shade','Dominican Republic',1,'https://www.ashtoncigar.com/cigars/ashton/ashton',now(),'manufacturer',true),
  ('Ashton','Classic','Churchill',52,7.5,'Parejo',NULL,'Connecticut Shade','Dominican Republic',1,'https://www.ashtoncigar.com/cigars/ashton/ashton',now(),'manufacturer',true),
  ('Ashton','Aged Maduro','No. 10',50,5,'Parejo',NULL,'Connecticut Broadleaf','Dominican Republic',2,'https://www.ashtoncigar.com/cigars/ashton/ashton-aged-maduro',now(),'manufacturer',true),
  ('Ashton','Aged Maduro','No. 20',44,5.5,'Parejo',NULL,'Connecticut Broadleaf','Dominican Republic',2,'https://www.ashtoncigar.com/cigars/ashton/ashton-aged-maduro',now(),'manufacturer',true),
  ('Ashton','Aged Maduro','No. 30',44,6.75,'Parejo',NULL,'Connecticut Broadleaf','Dominican Republic',2,'https://www.ashtoncigar.com/cigars/ashton/ashton-aged-maduro',now(),'manufacturer',true),
  ('Ashton','Aged Maduro','No. 40',50,6,'Parejo',NULL,'Connecticut Broadleaf','Dominican Republic',2,'https://www.ashtoncigar.com/cigars/ashton/ashton-aged-maduro',now(),'manufacturer',true),
  ('Ashton','Aged Maduro','No. 50',48,7,'Parejo',NULL,'Connecticut Broadleaf','Dominican Republic',2,'https://www.ashtoncigar.com/cigars/ashton/ashton-aged-maduro',now(),'manufacturer',true),
  ('Ashton','Aged Maduro','No. 56',56,6,'Parejo',NULL,'Connecticut Broadleaf','Dominican Republic',2,'https://www.ashtoncigar.com/cigars/ashton/ashton-aged-maduro',now(),'manufacturer',true),
  ('Ashton','Aged Maduro','No. 60',52,7.5,'Parejo',NULL,'Connecticut Broadleaf','Dominican Republic',2,'https://www.ashtoncigar.com/cigars/ashton/ashton-aged-maduro',now(),'manufacturer',true),
  ('Ashton','Aged Maduro','Pyramid',52,6,'Figurado','Pyramid','Connecticut Broadleaf','Dominican Republic',2,'https://www.ashtoncigar.com/cigars/ashton/ashton-aged-maduro',now(),'manufacturer',true),
  ('Ashton','Cabinet Selection','No. 1',52,9,'Parejo',NULL,'Connecticut Shade','Dominican Republic',2,'https://www.ashtoncigar.com/cigars/ashton/ashton-cabinet-selection',now(),'manufacturer',true),
  ('Ashton','Cabinet Selection','No. 2',48,7,'Parejo',NULL,'Connecticut Shade','Dominican Republic',2,'https://www.ashtoncigar.com/cigars/ashton/ashton-cabinet-selection',now(),'manufacturer',true),
  ('Ashton','Cabinet Selection','No. 3',46,6,'Parejo',NULL,'Connecticut Shade','Dominican Republic',2,'https://www.ashtoncigar.com/cigars/ashton/ashton-cabinet-selection',now(),'manufacturer',true),
  ('Ashton','Cabinet Selection','No. 4',46,5.75,'Parejo',NULL,'Connecticut Shade','Dominican Republic',2,'https://www.ashtoncigar.com/cigars/ashton/ashton-cabinet-selection',now(),'manufacturer',true),
  ('Ashton','Cabinet Selection','No. 6',50,5.5,'Parejo',NULL,'Connecticut Shade','Dominican Republic',2,'https://www.ashtoncigar.com/cigars/ashton/ashton-cabinet-selection',now(),'manufacturer',true),
  ('Ashton','Cabinet Selection','No. 7',52,6.25,'Parejo',NULL,'Connecticut Shade','Dominican Republic',2,'https://www.ashtoncigar.com/cigars/ashton/ashton-cabinet-selection',now(),'manufacturer',true),
  ('Ashton','Cabinet Selection','No. 8',49,7,'Parejo',NULL,'Connecticut Shade','Dominican Republic',2,'https://www.ashtoncigar.com/cigars/ashton/ashton-cabinet-selection',now(),'manufacturer',true),
  ('Ashton','Cabinet Selection','No. 10',52,7.5,'Parejo',NULL,'Connecticut Shade','Dominican Republic',2,'https://www.ashtoncigar.com/cigars/ashton/ashton-cabinet-selection',now(),'manufacturer',true),
  ('Ashton','Cabinet Selection','Trés Petite',42,4.375,'Parejo',NULL,'Connecticut Shade','Dominican Republic',2,'https://www.ashtoncigar.com/cigars/ashton/ashton-cabinet-selection',now(),'manufacturer',true),
  ('Ashton','Cabinet Selection','Belicoso',52,5.25,'Figurado','Belicoso','Connecticut Shade','Dominican Republic',2,'https://www.ashtoncigar.com/cigars/ashton/ashton-cabinet-selection',now(),'manufacturer',true),
  ('Ashton','Cabinet Selection','Pyramid',52,6,'Figurado','Pyramid','Connecticut Shade','Dominican Republic',2,'https://www.ashtoncigar.com/cigars/ashton/ashton-cabinet-selection',now(),'manufacturer',true),
  ('Ashton','ESG','20 Year Salute',49,6.75,'Parejo',NULL,'Dominican','Dominican Republic',4,'https://www.ashtoncigar.com/cigars/ashton/ashton-estate-sun-grown',now(),'manufacturer',true),
  ('Ashton','ESG','21 Year Salute',52,5.25,'Parejo',NULL,'Dominican','Dominican Republic',4,'https://www.ashtoncigar.com/cigars/ashton/ashton-estate-sun-grown',now(),'manufacturer',true),
  ('Ashton','ESG','22 Year Salute',52,6,'Parejo',NULL,'Dominican','Dominican Republic',4,'https://www.ashtoncigar.com/cigars/ashton/ashton-estate-sun-grown',now(),'manufacturer',true),
  ('Ashton','ESG','23 Year Salute',52,6.25,'Parejo',NULL,'Dominican','Dominican Republic',4,'https://www.ashtoncigar.com/cigars/ashton/ashton-estate-sun-grown',now(),'manufacturer',true),
  ('Ashton','ESG','24 Year Salute',48,6.625,'Parejo',NULL,'Dominican','Dominican Republic',4,'https://www.ashtoncigar.com/cigars/ashton/ashton-estate-sun-grown',now(),'manufacturer',true),
  ('Ashton','Heritage Puro Sol','Belicoso No. 2',49,4.875,'Figurado','Belicoso','Ecuador Habano','Dominican Republic',3,'https://www.ashtoncigar.com/cigars/ashton/ashton-heritage-puro-sol',now(),'manufacturer',true),
  ('Ashton','Heritage Puro Sol','Robusto',50,5.5,'Parejo',NULL,'Ecuador Habano','Dominican Republic',3,'https://www.ashtoncigar.com/cigars/ashton/ashton-heritage-puro-sol',now(),'manufacturer',true),
  ('Ashton','Heritage Puro Sol','Corona Gorda',46,5.75,'Parejo',NULL,'Ecuador Habano','Dominican Republic',3,'https://www.ashtoncigar.com/cigars/ashton/ashton-heritage-puro-sol',now(),'manufacturer',true),
  ('Ashton','Heritage Puro Sol','Churchill',48,6.75,'Parejo',NULL,'Ecuador Habano','Dominican Republic',3,'https://www.ashtoncigar.com/cigars/ashton/ashton-heritage-puro-sol',now(),'manufacturer',true),
  ('Ashton','Heritage Puro Sol','Double Corona',52,7,'Parejo',NULL,'Ecuador Habano','Dominican Republic',3,'https://www.ashtoncigar.com/cigars/ashton/ashton-heritage-puro-sol',now(),'manufacturer',true),
  ('Ashton','Symmetry','Robusto',50,5,'Parejo',NULL,'Ecuador Habano','Dominican Republic',5,'https://www.ashtoncigar.com/cigars/ashton/ashton-symmetry',now(),'manufacturer',true),
  ('Ashton','Symmetry','Belicoso',52,5.25,'Figurado','Belicoso','Ecuador Habano','Dominican Republic',5,'https://www.ashtoncigar.com/cigars/ashton/ashton-symmetry',now(),'manufacturer',true),
  ('Ashton','Symmetry','Prism',46,5.625,'Parejo',NULL,'Ecuador Habano','Dominican Republic',5,'https://www.ashtoncigar.com/cigars/ashton/ashton-symmetry',now(),'manufacturer',true),
  ('Ashton','Symmetry','Sublime',52,6,'Parejo',NULL,'Ecuador Habano','Dominican Republic',5,'https://www.ashtoncigar.com/cigars/ashton/ashton-symmetry',now(),'manufacturer',true),
  ('Ashton','Symmetry','Prestige',49,6.75,'Parejo',NULL,'Ecuador Habano','Dominican Republic',5,'https://www.ashtoncigar.com/cigars/ashton/ashton-symmetry',now(),'manufacturer',true),
  ('Ashton','VSG','Trés Mystique',44,4.375,'Parejo',NULL,'Ecuador Sumatra','Dominican Republic',5,'https://www.ashtoncigar.com/cigars/ashton/ashton-vsg',now(),'manufacturer',true),
  ('Ashton','VSG','Enchantment',60,4.375,'Parejo',NULL,'Ecuador Sumatra','Dominican Republic',5,'https://www.ashtoncigar.com/cigars/ashton/ashton-vsg',now(),'manufacturer',true),
  ('Ashton','VSG','Pegasus',54,5,'Parejo',NULL,'Ecuador Sumatra','Dominican Republic',5,'https://www.ashtoncigar.com/cigars/ashton/ashton-vsg',now(),'manufacturer',true),
  ('Ashton','VSG','Belicoso No. 1',52,5.25,'Figurado','Belicoso','Ecuador Sumatra','Dominican Republic',5,'https://www.ashtoncigar.com/cigars/ashton/ashton-vsg',now(),'manufacturer',true),
  ('Ashton','VSG','Robusto',50,5.5,'Parejo',NULL,'Ecuador Sumatra','Dominican Republic',5,'https://www.ashtoncigar.com/cigars/ashton/ashton-vsg',now(),'manufacturer',true),
  ('Ashton','VSG','Corona Gorda',46,5.75,'Parejo',NULL,'Ecuador Sumatra','Dominican Republic',5,'https://www.ashtoncigar.com/cigars/ashton/ashton-vsg',now(),'manufacturer',true),
  ('Ashton','VSG','Eclipse',52,6,'Parejo',NULL,'Ecuador Sumatra','Dominican Republic',5,'https://www.ashtoncigar.com/cigars/ashton/ashton-vsg',now(),'manufacturer',true),
  ('Ashton','VSG','Wizard',56,6,'Parejo',NULL,'Ecuador Sumatra','Dominican Republic',5,'https://www.ashtoncigar.com/cigars/ashton/ashton-vsg',now(),'manufacturer',true),
  ('Ashton','VSG','Illusion',44,6.5,'Parejo',NULL,'Ecuador Sumatra','Dominican Republic',5,'https://www.ashtoncigar.com/cigars/ashton/ashton-vsg',now(),'manufacturer',true),
  ('Ashton','VSG','Torpedo',55,6.5,'Figurado','Torpedo','Ecuador Sumatra','Dominican Republic',5,'https://www.ashtoncigar.com/cigars/ashton/ashton-vsg',now(),'manufacturer',true),
  ('Ashton','VSG','Sorcerer',49,7,'Parejo',NULL,'Ecuador Sumatra','Dominican Republic',5,'https://www.ashtoncigar.com/cigars/ashton/ashton-vsg',now(),'manufacturer',true),
  ('Ashton','VSG','Spellbound',54,7.5,'Parejo',NULL,'Ecuador Sumatra','Dominican Republic',5,'https://www.ashtoncigar.com/cigars/ashton/ashton-vsg',now(),'manufacturer',true),
  ('Ashton','Esquire','Esquire',32,4.25,'Parejo',NULL,NULL,'Dominican Republic',1,'https://www.ashtoncigar.com/cigars/ashton/ashton-esquire',now(),'manufacturer',true),
  ('Ashton','Small Cigars Cameroon','Mini Cigarillos',20,3.25,'Parejo',NULL,'Cameroon',NULL,2,'https://www.ashtoncigar.com/cigars/ashton/ashton-small-cigars',now(),'manufacturer',true),
  ('Ashton','Small Cigars Cameroon','Senoritas',30,3.5,'Parejo',NULL,'Cameroon',NULL,2,'https://www.ashtoncigar.com/cigars/ashton/ashton-small-cigars',now(),'manufacturer',true),
  ('Ashton','Small Cigars Cameroon','Cigarillos',26,3.75,'Parejo',NULL,'Cameroon',NULL,2,'https://www.ashtoncigar.com/cigars/ashton/ashton-small-cigars',now(),'manufacturer',true),
  ('Ashton','Small Cigars Cameroon','Half Corona',37,4.125,'Parejo',NULL,'Cameroon',NULL,2,'https://www.ashtoncigar.com/cigars/ashton/ashton-small-cigars',now(),'manufacturer',true),
  ('Ashton','Small Cigars Connecticut','Mini Cigarillos',20,3.25,'Parejo',NULL,'Connecticut Shade',NULL,2,'https://www.ashtoncigar.com/cigars/ashton/small-cigars-connecticut',now(),'manufacturer',true),
  ('Ashton','Small Cigars Connecticut','Senoritas',30,3.5,'Parejo',NULL,'Connecticut Shade',NULL,2,'https://www.ashtoncigar.com/cigars/ashton/small-cigars-connecticut',now(),'manufacturer',true),
  ('Ashton','Small Cigars Connecticut','Cigarillos',26,3.75,'Parejo',NULL,'Connecticut Shade',NULL,2,'https://www.ashtoncigar.com/cigars/ashton/small-cigars-connecticut',now(),'manufacturer',true),
  ('Ashton','Small Cigars Connecticut','Half Corona',37,4.125,'Parejo',NULL,'Connecticut Shade',NULL,2,'https://www.ashtoncigar.com/cigars/ashton/small-cigars-connecticut',now(),'manufacturer',true);
