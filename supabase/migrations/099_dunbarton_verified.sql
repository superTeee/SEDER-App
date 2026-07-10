-- 099_dunbarton_verified.sql
--
-- Dunbarton Tobacco & Trust: 67 rader → 68, hvorav 61 verifisert mot produsent.
-- Kilde: https://www.dunbartoncigars.com/marca/<slug>/ (13 marca-sider).
--
-- Etter kjøring: 68 rader — 61 'manufacturer'-verifisert, 7 uverifisert.
-- Ingen testerdata på merket (humidor/logg/ønskeliste/målinger = 0, sjekket).
--
--
-- HVA VI FANT: 67 FEILSEEDEDE RADER
--
-- Gammel base hadde 67 rader, men bare 12 unike sigarer — hver seedet 6 ganger.
-- To serier fantes: den klassiske Sobremesa-linjen og Sobremesa Brûlée.
-- Produsenten publiserer i dag 13 marcaer med til sammen 61 vitolaer.
--
--
-- SOBREMESA: SOLITA I DAG, KLASSIKERNE I GÅR
--
-- Produsentens nåværende Sobremesa-side lister KUN «Solita»-formatet (5 vitolaer).
-- Den klassiske linjen (Robusto, Cervantes, El Americano, Frédéric, Lancero,
-- Passionado, Toro) er ikke lenger publisert. Vi sletter den ikke — den var ekte
-- og testere kan eie dem — men den kan ikke verifiseres mot en kilde produsenten
-- har tatt ned. Derfor: 7 klassiske Sobremesa-vitolaer beholdes, én kopi hver,
-- med verified_at = NULL (uverifisert). Nettopp det tre-nivå-merket er til for.
--
-- Sobremesa Brûlée er derimot en levende linje, så de gamle Brûlée-radene byttes
-- ut med de 6 produsenten lister nå (verifisert).
--
--
-- BLEND: SPANSKE ETIKETTER, VERDI FØR ETIKETT
--
-- Dunbarton skriver blend med spanske ord og verdien FORAN etiketten:
--   «Connecticut Broadleaf Capa  Nicaraguan Capote  Nicaraguan Various Tripa»
--   → Capa = dekkblad, Capote = omblad, Tripa = innmat.
-- Målene står som LENGDE × RINGMÅL (som CAO og Joya, motsatt av Habanos/Padrón).
--
-- Muestra de Saka og Stillwell Star oppgir ingen innmats-opprinnelse utover
-- «Various» — feltet står tomt der, vi gjetter ikke.
--
--
-- OPPRINNELSE OG STYRKE
--
-- Alle Dunbarton er håndrullet i Nicaragua (Fábrica NACSA, Estelí) →
-- country_origin = 'Nicaragua'. Produsenten oppgir ikke tallfestet styrke på
-- marca-sidene; strength står tomt heller enn gjettet.
--
--
-- FORM
--
-- shape = 'Figurado' for Torpedo/Belicoso/Diadema (body_type = undertypen).
-- Ellers 'Parejo'.
--

with keep as (
  select distinct on (vitola) id
  from cigars
  where brand='Dunbarton Tobacco & Trust' and series='Sobremesa'
    and vitola in ('Frédéric','Robusto','Passionado','Cervantes','El Americano','Lancero','Toro')
  order by vitola, id
)
delete from cigars
where brand='Dunbarton Tobacco & Trust' and id not in (select id from keep);

insert into cigars
  (brand, series, vitola, ring_gauge, length_inches, shape, body_type,
   wrapper_leaf, binder, filler, country_origin, source_url, verified_at,
   source_tier, is_public)
values
  ('Dunbarton Tobacco & Trust','Mi Querida','Gran Búfalo',64,7,'Parejo',NULL,'Connecticut Broadleaf','Nicaraguan',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/mi-querida/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Mi Querida','Muy Gordo Grande',56,6,'Parejo',NULL,'Connecticut Broadleaf','Nicaraguan',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/mi-querida/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Mi Querida','Ancho Largo',52,6,'Parejo',NULL,'Connecticut Broadleaf','Nicaraguan',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/mi-querida/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Mi Querida','Fino Largo',48,6,'Parejo',NULL,'Connecticut Broadleaf','Nicaraguan',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/mi-querida/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Mi Querida','Ancho Corto',52,5,'Parejo',NULL,'Connecticut Broadleaf','Nicaraguan',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/mi-querida/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Mi Querida','Gordita',48,4,'Parejo',NULL,'Connecticut Broadleaf','Nicaraguan',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/mi-querida/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Mi Querida Black','SakaKhan',54,7.25,'Parejo',NULL,'Connecticut Broadleaf No. 1 Darks','San Andrés Negro',ARRAY['Nicaragua','Honduras','Dominican Republic']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/mi-querida-black/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Mi Querida Black','PapaSaka',48,5.63,'Parejo',NULL,'Connecticut Broadleaf No. 1 Darks','San Andrés Negro',ARRAY['Nicaragua','Honduras','Dominican Republic']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/mi-querida-black/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Mi Querida Triqui Traca','No. 764',64,7,'Parejo',NULL,'Connecticut Broadleaf No. 1 Darks','Nicaraguan',ARRAY['Nicaragua','USA']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/mi-querida-triqui-traca/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Mi Querida Triqui Traca','No. 652',52,6,'Parejo',NULL,'Connecticut Broadleaf No. 1 Darks','Nicaraguan',ARRAY['Nicaragua','USA']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/mi-querida-triqui-traca/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Mi Querida Triqui Traca','No. 648',48,6,'Parejo',NULL,'Connecticut Broadleaf No. 1 Darks','Nicaraguan',ARRAY['Nicaragua','USA']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/mi-querida-triqui-traca/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Mi Querida Triqui Traca','No. 552',52,5,'Parejo',NULL,'Connecticut Broadleaf No. 1 Darks','Nicaraguan',ARRAY['Nicaragua','USA']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/mi-querida-triqui-traca/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Mi Querida Triqui Traca','No. 448',48,4,'Parejo',NULL,'Connecticut Broadleaf No. 1 Darks','Nicaraguan',ARRAY['Nicaragua','USA']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/mi-querida-triqui-traca/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Muestra de Saka','Exclusivo',52,6,'Parejo',NULL,'Ecuador Habano Grade A1','Nicaraguan Sungrown',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/muestra-de-saka/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Muestra de Saka','Nacatamale',48,6,'Parejo',NULL,'Ecuador Habano Grade A1','Nicaraguan Sungrown',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/muestra-de-saka/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Muestra de Saka','#NLMTHA',38,7,'Parejo',NULL,'Ecuador Habano Grade A1','Nicaraguan Sungrown',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/muestra-de-saka/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Muestra de Saka','Unstolen Valor',52,6,'Parejo',NULL,'Ecuador Habano Grade A1','Nicaraguan Sungrown',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/muestra-de-saka/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Muestra de Saka','"The Bewitched"',48,6.63,'Parejo',NULL,'Ecuador Habano Grade A1','Nicaraguan Sungrown',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/muestra-de-saka/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Muestra de Saka','Krakatoa',48,6,'Parejo',NULL,'Ecuador Habano Grade A1','Nicaraguan Sungrown',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/muestra-de-saka/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Red Meat Lovers','“Porterhouse”',60,6,'Parejo',NULL,'Connecticut Broadleaf','San Andrés Negro',ARRAY['Nicaragua','USA']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/red-meat-lovers/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Red Meat Lovers','“Ribeye”',52,6,'Parejo',NULL,'Connecticut Broadleaf','San Andrés Negro',ARRAY['Nicaragua','USA']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/red-meat-lovers/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Red Meat Lovers','“Beef Stick”',48,6,'Parejo',NULL,'Connecticut Broadleaf','San Andrés Negro',ARRAY['Nicaragua','USA']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/red-meat-lovers/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Red Meat Lovers','“Filet Mignon”',54,5,'Parejo',NULL,'Connecticut Broadleaf','San Andrés Negro',ARRAY['Nicaragua','USA']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/red-meat-lovers/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Red Meat Lovers','"Fritanga"',52,6,'Parejo',NULL,'Connecticut Broadleaf','San Andrés Negro',ARRAY['Nicaragua','USA']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/red-meat-lovers/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Sin Compromiso','Selección No. 7',56,7,'Parejo',NULL,'San Andrés Negro "Cultivo Tonto"','Ecuador Habano "Thin Ligero"',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/sin-compromiso/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Sin Compromiso','Selección Varita Mágica',44,7,'Parejo',NULL,'San Andrés Negro "Cultivo Tonto"','Ecuador Habano "Thin Ligero"',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/sin-compromiso/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Sin Compromiso','Selección No. 2',52,6,'Figurado','Torpedo','San Andrés Negro "Cultivo Tonto"','Ecuador Habano "Thin Ligero"',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/sin-compromiso/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Sin Compromiso','Selección No. 5',54,6,'Parejo',NULL,'San Andrés Negro "Cultivo Tonto"','Ecuador Habano "Thin Ligero"',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/sin-compromiso/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Sin Compromiso','Selección Intrépido',46,5.63,'Parejo',NULL,'San Andrés Negro "Cultivo Tonto"','Ecuador Habano "Thin Ligero"',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/sin-compromiso/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Sin Compromiso','Selección No. 4',54,5,'Parejo',NULL,'San Andrés Negro "Cultivo Tonto"','Ecuador Habano "Thin Ligero"',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/sin-compromiso/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Sin Compromiso','Selección Paladin de Saka',52,7,'Parejo',NULL,'San Andrés Negro "Cultivo Tonto"','Ecuador Habano "Thin Ligero"',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/sin-compromiso/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Sobremesa','Solita Churchill en Cedros',50,7,'Parejo',NULL,'Ecuador Habano','San Andrés Negro',ARRAY['Nicaragua','Pennsylvania']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/sobremesa/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Sobremesa','Solita Toro',52,6,'Parejo',NULL,'Ecuador Habano','San Andrés Negro',ARRAY['Nicaragua','Pennsylvania']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/sobremesa/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Sobremesa','Solita Robusto',52,5.25,'Parejo',NULL,'Ecuador Habano','San Andrés Negro',ARRAY['Nicaragua','Pennsylvania']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/sobremesa/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Sobremesa','Solita Short Churchill',48,4.75,'Parejo',NULL,'Ecuador Habano','San Andrés Negro',ARRAY['Nicaragua','Pennsylvania']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/sobremesa/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Sobremesa','Solita Red',46,6.25,'Parejo',NULL,'Ecuador Habano','San Andrés Negro',ARRAY['Nicaragua','Pennsylvania']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/sobremesa/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Sobremesa Brûlée','Brûlée Double Corona',54,7,'Parejo',NULL,'Ecuador Connecticut Shade G2BW','San Andrés Negro',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/sobremesa-brulee/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Sobremesa Brûlée','Brûlée Gordo',60,6.25,'Parejo',NULL,'Ecuador Connecticut Shade G2BW','San Andrés Negro',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/sobremesa-brulee/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Sobremesa Brûlée','Brûlée Toro',52,6,'Parejo',NULL,'Ecuador Connecticut Shade G2BW','San Andrés Negro',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/sobremesa-brulee/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Sobremesa Brûlée','Brûlée Robusto',52,5.25,'Parejo',NULL,'Ecuador Connecticut Shade G2BW','San Andrés Negro',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/sobremesa-brulee/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Sobremesa Brûlée','Brûlée Blue',46,6.25,'Parejo',NULL,'Ecuador Connecticut Shade G2BW','San Andrés Negro',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/sobremesa-brulee/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Sobremesa Brûlée','Brûlée Wagashi 和菓子',50,6,'Parejo',NULL,'Ecuador Connecticut Shade G2BW','San Andrés Negro',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/sobremesa-brulee/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Stillwell Star','Aromatic No. 1',52,6,'Parejo',NULL,'Ecuador Connecticut Shade','San Andrés Negro "Cultivo Tonto"',NULL,'Nicaragua','https://www.dunbartoncigars.com/marca/stillwell-star/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Stillwell Star','Aromatic No. 22',52,6,'Parejo',NULL,'Ecuador Connecticut Shade','San Andrés Negro "Cultivo Tonto"',NULL,'Nicaragua','https://www.dunbartoncigars.com/marca/stillwell-star/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Stillwell Star','English No. 27',52,6,'Parejo',NULL,'Ecuador Connecticut Shade','San Andrés Negro "Cultivo Tonto"',NULL,'Nicaragua','https://www.dunbartoncigars.com/marca/stillwell-star/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Stillwell Star','Bayou No. 32',52,6,'Parejo',NULL,'Ecuador Connecticut Shade','San Andrés Negro "Cultivo Tonto"',NULL,'Nicaragua','https://www.dunbartoncigars.com/marca/stillwell-star/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Stillwell Star','Navy No. 1056',52,6,'Parejo',NULL,'Ecuador Connecticut Shade','San Andrés Negro "Cultivo Tonto"',NULL,'Nicaragua','https://www.dunbartoncigars.com/marca/stillwell-star/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Stillwell Star','Holiday Y2024',52,6,'Parejo',NULL,'Ecuador Connecticut Shade','San Andrés Negro "Cultivo Tonto"',NULL,'Nicaragua','https://www.dunbartoncigars.com/marca/stillwell-star/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Todos Las Dias','Toro',52,6,'Parejo',NULL,'Nicaraguan Sun Grown','Nicaraguan',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/todos-las-dias/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Todos Las Dias','Thick Lonsdale "MF"',46,6,'Parejo',NULL,'Nicaraguan Sun Grown','Nicaraguan',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/todos-las-dias/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Todos Las Dias','Robusto',52,5,'Parejo',NULL,'Nicaraguan Sun Grown','Nicaraguan',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/todos-las-dias/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Todos Las Dias','Double Wide Belicoso',60,4.75,'Figurado','Belicoso','Nicaraguan Sun Grown','Nicaraguan',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/todos-las-dias/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Polpetta','Polpetta Petit Puros',48,4,'Parejo',NULL,'Connecticut Broadleaf','San Andrés Negro',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/polpetta/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Umbagog','Gordo Gordo',56,6,'Parejo',NULL,'Connecticut Broadleaf','San Andrés Negro',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/umbagog/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Umbagog','Toro Toro',52,6,'Parejo',NULL,'Connecticut Broadleaf','San Andrés Negro',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/umbagog/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Umbagog','Corona Gorda',48,6,'Parejo',NULL,'Connecticut Broadleaf','San Andrés Negro',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/umbagog/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Umbagog','Robusto Plus',52,5,'Parejo',NULL,'Connecticut Broadleaf','San Andrés Negro',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/umbagog/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Umbagog','Bronzeback',48,5,'Parejo',NULL,'Connecticut Broadleaf','San Andrés Negro',ARRAY['Nicaragua']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/umbagog/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Unicorns','Muestra de Saka Unicorn',60,6.25,'Figurado','Diadema','Connecticut Broadleaf No. 1 Darks','San Andrés Negro "Cultivo Tonto"',ARRAY['Nicaragua','Honduras','Dominican Republic']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/unicorns/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Unicorns','Sobremesa Brûlée Blue Unicorn',60,6.25,'Figurado','Diadema','Connecticut Broadleaf No. 1 Darks','San Andrés Negro "Cultivo Tonto"',ARRAY['Nicaragua','Honduras','Dominican Republic']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/unicorns/',now(),'manufacturer',true),
  ('Dunbarton Tobacco & Trust','Unicorns','Mi Querida Black Unicorn',60,6.25,'Figurado','Diadema','Connecticut Broadleaf No. 1 Darks','San Andrés Negro "Cultivo Tonto"',ARRAY['Nicaragua','Honduras','Dominican Republic']::text[],'Nicaragua','https://www.dunbartoncigars.com/marca/unicorns/',now(),'manufacturer',true);
