-- 158: Rydd bort 6 feilførte Leaf by Oscar-rader (Churchill/Lonsdale).
-- Disse størrelsene finnes ikke i serien (verifisert via to uavhengige kildesøk;
-- Leaf by Oscar lages kun som Robusto/Toro/Gordo/Lancero). Alle 6 manglet mål.
--
-- FULL GJENOPPRETTING: kjør denne INSERT-blokken for å legge radene tilbake om ønskelig.
-- INSERT INTO public.cigars (brand,series,vitola,common_format,wrapper_leaf,wrapper_country,binder,filler,strength,country_origin,manufacturer,flavor_notes,description,is_public) VALUES
--   ('Leaf by Oscar','Connecticut','Churchill','Churchill','Connecticut Shade','Ecuador','Honduras',ARRAY['Honduras','Nicaragua']::text[],2,'Honduras','Oscar Valladares Tobacco & Co.',ARRAY['Cedar','Cream','Hay','Nuts','Pepper']::text[],'Leaf by Oscar Connecticut er en mild-til-medium sigar med ekte tobakksblad-wrapper og glatt, kremet røyk.',true),
--   ('Leaf by Oscar','Connecticut','Lonsdale','Lonsdale','Connecticut Shade','Ecuador','Honduras',ARRAY['Honduras','Nicaragua']::text[],2,'Honduras','Oscar Valladares Tobacco & Co.',ARRAY['Cedar','Cream','Hay','Nuts','Pepper']::text[],'Leaf by Oscar Connecticut er en mild-til-medium sigar med ekte tobakksblad-wrapper og glatt, kremet røyk.',true),
--   ('Leaf by Oscar','Corojo','Churchill','Churchill','Corojo','Honduras',NULL,ARRAY['Honduras','Nicaragua']::text[],3,'Honduras','Oscar Valladares Tobacco & Co.',ARRAY['Coffee','Earth','Leather','Pepper','Spice']::text[],'Leaf by Oscar Corojo har en Honduras Corojo-wrapper og er medium til full med kraftige krydder- og lær-toner.',true),
--   ('Leaf by Oscar','Corojo','Lonsdale','Lonsdale','Corojo','Honduras',NULL,ARRAY['Honduras','Nicaragua']::text[],3,'Honduras','Oscar Valladares Tobacco & Co.',ARRAY['Coffee','Earth','Leather','Pepper','Spice']::text[],'Leaf by Oscar Corojo har en Honduras Corojo-wrapper og er medium til full med kraftige krydder- og lær-toner.',true),
--   ('Leaf by Oscar','Maduro','Churchill','Churchill','San Andres Maduro','Mexico',NULL,ARRAY['Honduras','Nicaragua']::text[],3,'Honduras','Oscar Valladares Tobacco & Co.',ARRAY['Dark Chocolate','Dark Fruit','Earth','Espresso','Pepper']::text[],'Leaf by Oscar Maduro pakket i San Andres-wrapper gir rik, mørk røyk med sjokolade og mørk frukt.',true),
--   ('Leaf by Oscar','Sumatra','Churchill','Churchill','Sumatra','Indonesia',NULL,ARRAY['Honduras','Nicaragua']::text[],3,'Honduras','Oscar Valladares Tobacco & Co.',ARRAY['Coffee','Dark Chocolate','Earth','Sweetness','Wood']::text[],'Leaf by Oscar Sumatra har en indonesisk Sumatra-wrapper og leverer kompleks, jordnær røyk med kakao-innslag.',true);

DELETE FROM public.cigars WHERE id IN (
  'd185766c-2554-45c0-ae89-9064844c9ed7',
  'f28d388d-bf83-4a5d-bf1a-224d38231743',
  '86699ef4-77fa-41a5-8a13-7ab9b8930b12',
  'e7b7d662-9059-44ea-8ecf-d631be836a6f',
  'fc115662-b268-4513-9de4-72f777f3211d',
  '659a8ec3-09ee-4d30-8dd4-8819763511fc'
);
