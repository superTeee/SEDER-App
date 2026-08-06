-- 157: Dekk resterende hull som lar seg researche/utlede.
-- Idempotent (COALESCE). El Septimo (Luxus/Sacred Arts), Leaf by Oscar Churchill/Lonsdale (finnes ikke),
-- og Freud Sigmund (uoppgitt LE-dekkblad) står igjen som ekte tomrom.

-- Artista: opphav Den dominikanske republikk for alle linjer
UPDATE public.cigars SET country_origin=COALESCE(country_origin,'Dominican Republic') WHERE brand='Artista';
-- Artista Club Mini: dekkblad per variant
UPDATE public.cigars SET wrapper_leaf=COALESCE(wrapper_leaf,'Ecuadorian Habano'), wrapper_country=COALESCE(wrapper_country,'Ecuador') WHERE brand='Artista' AND series='Club Mini' AND vitola='Oscuro';
UPDATE public.cigars SET wrapper_leaf=COALESCE(wrapper_leaf,'Ecuadorian Connecticut'), wrapper_country=COALESCE(wrapper_country,'Ecuador') WHERE brand='Artista' AND series='Club Mini' AND vitola='Claro';
UPDATE public.cigars SET wrapper_leaf=COALESCE(wrapper_leaf,'Kentucky Fire Cured'), wrapper_country=COALESCE(wrapper_country,'United States') WHERE brand='Artista' AND series='Club Mini' AND vitola='Rustico';
-- Artista Limited 1.4: Pennsylvania (M32-hybrid)
UPDATE public.cigars SET wrapper_leaf=COALESCE(wrapper_leaf,'Pennsylvania'), wrapper_country=COALESCE(wrapper_country,'United States') WHERE brand='Artista' AND series='Limited 1.4';

-- Joya de Nicaragua
UPDATE public.cigars SET wrapper_leaf=COALESCE(wrapper_leaf,'Nicaragua'), wrapper_country=COALESCE(wrapper_country,'Nicaragua') WHERE brand='Joya de Nicaragua' AND series='Cinco Décadas';
UPDATE public.cigars SET strength=COALESCE(strength,3) WHERE brand='Joya de Nicaragua' AND series='Número Uno';

-- Ashton Esquire
UPDATE public.cigars SET wrapper_leaf=COALESCE(wrapper_leaf,'Connecticut Shade'), wrapper_country=COALESCE(wrapper_country,'Ecuador') WHERE brand='Ashton' AND series='Esquire';

-- Mål (lengde x ringmål)
UPDATE public.cigars SET length_inches=COALESCE(length_inches,8.0), ring_gauge=COALESCE(ring_gauge,60) WHERE brand='Eiroa' AND series='The First 20 Years' AND vitola='Diadema';
UPDATE public.cigars SET length_inches=COALESCE(length_inches,6.5), ring_gauge=COALESCE(ring_gauge,56) WHERE brand='Lampert Cigars' AND series='Limitada 2023';
UPDATE public.cigars SET length_inches=COALESCE(length_inches,6.75), ring_gauge=COALESCE(ring_gauge,40) WHERE brand='Patoro' AND series='Terre Blanche' AND vitola='Lancero';

-- Enkeltmerker: dekkblad (og styrke)
UPDATE public.cigars SET wrapper_leaf=COALESCE(wrapper_leaf,'San Andrés Maduro'), wrapper_country=COALESCE(wrapper_country,'Mexico') WHERE brand='Neanderthal' AND series='Neanderthal';
UPDATE public.cigars SET wrapper_leaf=COALESCE(wrapper_leaf,'Habano'), wrapper_country=COALESCE(wrapper_country,'Ecuador') WHERE brand='Eladio Diaz' AND series='La Diana';
UPDATE public.cigars SET wrapper_leaf=COALESCE(wrapper_leaf,'Corojo'), wrapper_country=COALESCE(wrapper_country,'Ecuador') WHERE brand='Principle' AND series='Aviator Series';
UPDATE public.cigars SET wrapper_leaf=COALESCE(wrapper_leaf,'Cotuí'), wrapper_country=COALESCE(wrapper_country,'Dominican Republic') WHERE brand='Principle' AND series='Frothy Monkey';
UPDATE public.cigars SET wrapper_leaf=COALESCE(wrapper_leaf,'San Andrés'), wrapper_country=COALESCE(wrapper_country,'Mexico') WHERE brand='Lampert Cigars' AND series='1593 Edicion Oscura';
UPDATE public.cigars SET wrapper_leaf=COALESCE(wrapper_leaf,'Habano'), wrapper_country=COALESCE(wrapper_country,'Nicaragua'), strength=COALESCE(strength,4) WHERE brand='Flor de Nicaragua';
