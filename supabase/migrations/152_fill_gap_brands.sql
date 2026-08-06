-- 152: Fyll manglende felt for topp-hullmerker (smak/styrke/dekkblad/mål).
-- Idempotent: setter kun felt som er NULL/tomme (COALESCE / CASE).
-- El Septimo utelatt: dekkblad ikke offentliggjort av produsent (halfwheel bekrefter 'undisclosed').
-- Leaf by Oscar: kun Robusto/Toro/Gordo har verifiserte mål; Churchill/Lonsdale står åpne (finnes trolig ikke i serien).

-- Regius (smak + styrke)
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cream','Cedar','Hay','Cinnamon','White Pepper']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 2) WHERE brand='Regius' AND series='Connecticut';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Dark Chocolate','Coffee','Leather','Earth','Cinnamon']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 4) WHERE brand='Regius' AND series='Maduro';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Dark Fruit','Coffee','Cedar','Caramel','Nuts']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 3) WHERE brand='Regius' AND series='Original';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Earth','Chocolate','Citrus','Black Pepper']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 4) WHERE brand='Regius' AND series='Sun Grown';

-- Powstanie (smak)
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Toasted Nuts','Caramel','Oak','Pepper','Hay']::text[] ELSE flavor_notes END WHERE brand='Powstanie' AND series='Connecticut';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cedar','Earth','Coffee','Cocoa','Pepper']::text[] ELSE flavor_notes END WHERE brand='Powstanie' AND series='Habano';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cocoa','Coffee','Oak','Pepper','Earth']::text[] ELSE flavor_notes END WHERE brand='Powstanie' AND series='San Andrés';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Wood','Coffee','Cocoa','Baking Spice','Sweetness']::text[] ELSE flavor_notes END WHERE brand='Powstanie' AND series='Sumatra';

-- Rojas (smak)
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cedar','Pepper','Cocoa','Coffee','Cream']::text[] ELSE flavor_notes END WHERE brand='Rojas' AND series='Bluebonnets';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Pepper','Spice','Cocoa','Earth','Sweetness']::text[] ELSE flavor_notes END WHERE brand='Rojas' AND series='Street Tacos Al Pastor';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Coffee','Cocoa','Pepper','Leather','Earth']::text[] ELSE flavor_notes END WHERE brand='Rojas' AND series='Street Tacos Carnitas';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cedar','Pepper','Coffee','Cocoa','Leather']::text[] ELSE flavor_notes END WHERE brand='Rojas' AND series='Unfinished Business';

-- H. Upmann (cubansk, smak)
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cedar','Cream','Coffee','Nuts','Spice']::text[] ELSE flavor_notes END WHERE brand='H. Upmann' AND series='Connossieur A';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cedar','Cream','Coffee','Leather','Baking Spice']::text[] ELSE flavor_notes END WHERE brand='H. Upmann' AND series='Connossieur B';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cedar','Cream','Coffee','Nuts','Cocoa']::text[] ELSE flavor_notes END WHERE brand='H. Upmann' AND series='Connossieur No. 2';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cedar','Cream','Coffee','Hay']::text[] ELSE flavor_notes END WHERE brand='H. Upmann' AND series='Coronas Junior';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cedar','Cream','Coffee','Nuts']::text[] ELSE flavor_notes END WHERE brand='H. Upmann' AND series='Coronas Major';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cedar','Cream','Coffee','Floral','Spice']::text[] ELSE flavor_notes END WHERE brand='H. Upmann' AND series='Epicures';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cedar','Cream','Coffee','Hay']::text[] ELSE flavor_notes END WHERE brand='H. Upmann' AND series='Half Corona';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cedar','Cream','Coffee','Nuts','Leather']::text[] ELSE flavor_notes END WHERE brand='H. Upmann' AND series='Magnum 50';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cedar','Cream','Coffee','Cocoa','Leather']::text[] ELSE flavor_notes END WHERE brand='H. Upmann' AND series='Magnum 54';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cedar','Cream','Coffee','Hay','Spice']::text[] ELSE flavor_notes END WHERE brand='H. Upmann' AND series='Majestic';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cedar','Cream','Coffee','Nuts']::text[] ELSE flavor_notes END WHERE brand='H. Upmann' AND series='Noellas';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cedar','Cream','Coffee','Hay']::text[] ELSE flavor_notes END WHERE brand='H. Upmann' AND series='Regalias';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cedar','Cream','Coffee','Nuts','Baking Spice']::text[] ELSE flavor_notes END WHERE brand='H. Upmann' AND series='Royal Robusto';

-- Serino (smak + styrke)
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Sweetness','Dark Chocolate','White Pepper','Dark Fruit','Oak']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 4) WHERE brand='Serino' AND series='Elenor Rose';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Coffee','Almonds','Cedar','Pepper','Earth']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 3) WHERE brand='Serino' AND series='Royale Maduro XX';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Sweetness','Almonds','White Pepper','Hay']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 3) WHERE brand='Serino' AND series='Taino Heritage';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cocoa','Dark Fruit','Coffee','Cinnamon']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 3) WHERE brand='Serino' AND series='The Expat';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Citrus','Hay','Cedar','Pepper','Sweetness']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 3) WHERE brand='Serino' AND series='Wayfarer';

-- Falto (smak + styrke + dekkblad der oppgitt)
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cedar','Nuts','Hay']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 3) WHERE brand='Falto' AND series='Ballibo Edición Especial Abuelos';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Sweetness','Spice','Citrus','Coffee','Earth']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 4), wrapper_leaf = COALESCE(wrapper_leaf, 'Corojo') WHERE brand='Falto' AND series='Dos Banderas';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Chocolate','Coffee','Cream','Dark Fruit','Sweetness']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 4), wrapper_leaf = COALESCE(wrapper_leaf, 'Cameroon') WHERE brand='Falto' AND series='Edición Especial ELH Hato Viejo';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Toasted Nuts','Hay','Wood']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 3) WHERE brand='Falto' AND series='El Falto Los Menesteres';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Sweetness','Cream','Coffee','Chocolate','Black Pepper']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 4), wrapper_leaf = COALESCE(wrapper_leaf, 'Habano') WHERE brand='Falto' AND series='El Prócer Historias';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Chocolate','Coffee','Cream','Dark Fruit','Sweetness']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 4), wrapper_leaf = COALESCE(wrapper_leaf, 'Cameroon') WHERE brand='Falto' AND series='El Surco Cosecheros';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Chocolate','Espresso','Spice']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 4), wrapper_leaf = COALESCE(wrapper_leaf, 'Habano') WHERE brand='Falto' AND series='LJF Reserva del Fundador';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Toasted Nuts','Hay','Wood']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 3) WHERE brand='Falto' AND series='La Obra Azojuano';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Wood','Sweetness','Baking Spice','Cinnamon']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 4), wrapper_leaf = COALESCE(wrapper_leaf, 'Corojo') WHERE brand='Falto' AND series='La Pureza';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Toasted Nuts','Hay','Wood']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 3) WHERE brand='Falto' AND series='Legado';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cream','Leather','Coffee','Pepper','Sweetness']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 3), wrapper_leaf = COALESCE(wrapper_leaf, 'Sumatra') WHERE brand='Falto' AND series='Lonsdale';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Chocolate','Coffee','Sweetness']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 4) WHERE brand='Falto' AND series='Perla Reserva Especial';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Espresso','Coffee','Wood']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 4), wrapper_leaf = COALESCE(wrapper_leaf, 'Cameroon') WHERE brand='Falto' AND series='Prominente Gran Reserva Especial';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Wood','Cedar','Cream']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 4), wrapper_leaf = COALESCE(wrapper_leaf, 'Cameroon') WHERE brand='Falto' AND series='Reserva Especial Tres Luises';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Sweetness','Pepper','Earth','Cream','Caramel']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 3) WHERE brand='Falto' AND series='Selección Especial';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Cedar','Earth','Black Pepper','Sweetness','Cream']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 3), wrapper_leaf = COALESCE(wrapper_leaf, 'Corojo') WHERE brand='Falto' AND series='Terruño Hermanos';
UPDATE public.cigars SET flavor_notes = CASE WHEN flavor_notes IS NULL OR cardinality(flavor_notes)=0 THEN ARRAY['Black Pepper','Cedar','Sweetness']::text[] ELSE flavor_notes END, strength = COALESCE(strength, 3), wrapper_leaf = COALESCE(wrapper_leaf, 'Corojo') WHERE brand='Falto' AND series='Yagüez Arawaco';

-- Padrón 1964 Anniversary Series (styrke medium-full = 4)
UPDATE public.cigars SET strength = COALESCE(strength, 4) WHERE brand='Padrón' AND series='1964 Anniversary Series';

-- Leaf by Oscar (mål, kun verifiserte vitolaer)
UPDATE public.cigars SET length_inches=COALESCE(length_inches,5), ring_gauge=COALESCE(ring_gauge,50) WHERE brand='Leaf by Oscar' AND vitola='Robusto';
UPDATE public.cigars SET length_inches=COALESCE(length_inches,6), ring_gauge=COALESCE(ring_gauge,52) WHERE brand='Leaf by Oscar' AND vitola='Toro';
UPDATE public.cigars SET length_inches=COALESCE(length_inches,6), ring_gauge=COALESCE(ring_gauge,60) WHERE brand='Leaf by Oscar' AND vitola='Gordo';
