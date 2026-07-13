-- 105_my_father_verified.sql
--
-- My Father: bekreftet mot produsent (myfathercigars.com) og markert verifisert.
-- 27 av 48 rader stemplet 'manufacturer' + verified_at.
--
-- Basen hadde allerede riktige vitolaer og blend (uverifisert). Produsentens
-- linje-sider oppgir mål som LENGDE × RINGMÅL (med brøker), og de matchet basen
-- (minus litt avrunding). Vi OPPDATERER derfor de eksisterende radene: setter
-- verified_at + source_tier + source_url og retter målene til nøyaktige verdier.
-- Blend (wrapper_leaf) beholdes — den var allerede riktig.
--
-- Kun UPDATE på matchende (series, vitola) med verified_at IS NULL — ingen
-- sletting, ingen dubletter. Rader som ikke matchet et navn på produsentsiden
-- (Blue, La Lealtad, Garcia & Garcia, Original Core Line, deler av The Judge)
-- står fortsatt uverifisert; sidene lot seg ikke hente rent.
--
-- Alle My Father rulles i Estelí, Nicaragua → country_origin='Nicaragua'.

update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-le-bijou-1922/', country_origin='Nicaragua', length_inches=7, ring_gauge=50 where brand='My Father' and series='Le Bijou 1922' and vitola='Churchill' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-le-bijou-1922/', country_origin='Nicaragua', length_inches=4.5, ring_gauge=50 where brand='My Father' and series='Le Bijou 1922' and vitola='Petit Robusto' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-le-bijou-1922/', country_origin='Nicaragua', length_inches=6, ring_gauge=52 where brand='My Father' and series='Le Bijou 1922' and vitola='Toro' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-le-bijou-1922/', country_origin='Nicaragua', length_inches=5.625, ring_gauge=55 where brand='My Father' and series='Le Bijou 1922' and vitola='Grand Robusto' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-le-bijou-1922/', country_origin='Nicaragua', length_inches=6.125, ring_gauge=52 where brand='My Father' and series='Le Bijou 1922' and vitola='Torpedo Box Pressed' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-connecticut/', country_origin='Nicaragua', length_inches=5.25, ring_gauge=52 where brand='My Father' and series='Connecticut' and vitola='Robusto' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-connecticut/', country_origin='Nicaragua', length_inches=6.5, ring_gauge=54 where brand='My Father' and series='Connecticut' and vitola='Toro' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-connecticut/', country_origin='Nicaragua', length_inches=6, ring_gauge=60 where brand='My Father' and series='Connecticut' and vitola='Toro Gordo' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-connecticut/', country_origin='Nicaragua', length_inches=6, ring_gauge=48 where brand='My Father' and series='Connecticut' and vitola='Corona Gorda' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-mf-the-judge/', country_origin='Nicaragua', length_inches=5.625, ring_gauge=46 where brand='My Father' and series='The Judge' and vitola='Corona Gorda' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-la-opulencia/', country_origin='Nicaragua', length_inches=4.5, ring_gauge=48 where brand='My Father' and series='La Opulencia' and vitola='Petite' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-la-opulencia/', country_origin='Nicaragua', length_inches=5, ring_gauge=46 where brand='My Father' and series='La Opulencia' and vitola='Corona' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-la-opulencia/', country_origin='Nicaragua', length_inches=5.25, ring_gauge=52 where brand='My Father' and series='La Opulencia' and vitola='Robusto' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-la-opulencia/', country_origin='Nicaragua', length_inches=6, ring_gauge=54 where brand='My Father' and series='La Opulencia' and vitola='Toro' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-la-opulencia/', country_origin='Nicaragua', length_inches=7, ring_gauge=56 where brand='My Father' and series='La Opulencia' and vitola='Toro Gordo' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-la-opulencia/', country_origin='Nicaragua', length_inches=6, ring_gauge=60 where brand='My Father' and series='La Opulencia' and vitola='Super Toro' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-la-opulencia/', country_origin='Nicaragua', length_inches=6.125, ring_gauge=52 where brand='My Father' and series='La Opulencia' and vitola='Torpedo' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-la-gran-oferta/', country_origin='Nicaragua', length_inches=5, ring_gauge=50 where brand='My Father' and series='La Gran Oferta' and vitola='Robusto' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-la-gran-oferta/', country_origin='Nicaragua', length_inches=7.5, ring_gauge=38 where brand='My Father' and series='La Gran Oferta' and vitola='Lancero' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-la-gran-oferta/', country_origin='Nicaragua', length_inches=6.125, ring_gauge=52 where brand='My Father' and series='La Gran Oferta' and vitola='Torpedo' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-la-gran-oferta/', country_origin='Nicaragua', length_inches=6, ring_gauge=50 where brand='My Father' and series='La Gran Oferta' and vitola='Toro' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-la-gran-oferta/', country_origin='Nicaragua', length_inches=6, ring_gauge=56 where brand='My Father' and series='La Gran Oferta' and vitola='Toro Gordo' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-la-promesa/', country_origin='Nicaragua', length_inches=5.5, ring_gauge=48 where brand='My Father' and series='La Promesa' and vitola='Corona Gorda' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-la-promesa/', country_origin='Nicaragua', length_inches=7.5, ring_gauge=38 where brand='My Father' and series='La Promesa' and vitola='Lancero' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-la-promesa/', country_origin='Nicaragua', length_inches=4.5, ring_gauge=50 where brand='My Father' and series='La Promesa' and vitola='Petite' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-la-promesa/', country_origin='Nicaragua', length_inches=5.5, ring_gauge=54 where brand='My Father' and series='La Promesa' and vitola='Robusto Grande' and verified_at is null;
update cigars set verified_at=now(), source_tier='manufacturer', source_url='https://myfathercigars.com/cigar/my-father-la-promesa/', country_origin='Nicaragua', length_inches=6, ring_gauge=52 where brand='My Father' and series='La Promesa' and vitola='Toro' and verified_at is null;
