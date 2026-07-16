-- Migrasjon 108: la fritekst-søket også treffe smaksnoter (norsk søkeord)
--
-- Bakgrunn: search_cigars_ranked matcher merke/serie/form via search_vector
-- (full-text, engelsk). Smaksnotene lagres på engelsk ("nuts"), så et norsk
-- søk som "Nøtter" ga ingen treff. Denne migrasjonen legger til en norsk→engelsk
-- smaksnote-mapping (samme som appens FlavorIcon) og returnerer også sigarer der
-- flavor_notes overlapper de engelske notene for en familie hvis navn inneholder
-- søkeordet. Speiler Android-oppførselen.

CREATE OR REPLACE FUNCTION public.search_cigars_ranked(search_query text, raw_text text DEFAULT NULL::text)
RETURNS SETOF cigars
LANGUAGE plpgsql
STABLE
AS $function$
declare
  tsq tsquery;
  q text;
  rt text;
  qraw text;
begin
  q := immutable_unaccent(coalesce(search_query, ''));
  rt := immutable_unaccent(coalesce(raw_text, ''));
  qraw := lower(immutable_unaccent(coalesce(search_query, '')));

  begin
    tsq := to_tsquery('english', q);
  exception when others then
    tsq := plainto_tsquery('english', q);
  end;

  return query
  with alias_hits as (
    select distinct c.id
    from cigars c
    join cigar_aliases a
      on c.brand = a.brand
     and (a.series is null or c.series = a.series)
    where raw_text is not null
      and rt ilike '%' || immutable_unaccent(a.alias) || '%'
  ),
  flavor_map(no_label, en_note) as (values
    ('Blomst','floral'),
    ('Blomst','gentle floral'),
    ('Blomst','light floral'),
    ('Frukt','dark fruit'),
    ('Frukt','dried fruit'),
    ('Frukt','fruit'),
    ('Honning','caramel'),
    ('Honning','honey'),
    ('Honning','maple'),
    ('Honning','molasses'),
    ('Honning','natural sweetness'),
    ('Høy','grass'),
    ('Høy','hay'),
    ('Jord','dark earth'),
    ('Jord','earth'),
    ('Jord','gentle earth'),
    ('Jord','light earth'),
    ('Jord','mild earth'),
    ('Jord','sweet earth'),
    ('Kaffe','coffee'),
    ('Kaffe','dark roasted coffee'),
    ('Kaffe','espresso'),
    ('Kaffe','mild coffee'),
    ('Kaffe','roasted aromas'),
    ('Kaffe','roasted coffee'),
    ('Kaffe','roasted espresso'),
    ('Kakao','chocolate'),
    ('Kakao','cocoa'),
    ('Kakao','dark chocolate'),
    ('Kakao','dark cocoa'),
    ('Kanel','anise'),
    ('Kanel','cardamom'),
    ('Kanel','cinnamon'),
    ('Kremete','butter'),
    ('Kremete','cream'),
    ('Kremete','kremete'),
    ('Kremete','mild cream'),
    ('Kremete','sweet cream'),
    ('Kremete','toasted cream'),
    ('Krydder','dark spice'),
    ('Krydder','gentle spice'),
    ('Krydder','light spice'),
    ('Krydder','mild krydder'),
    ('Krydder','mild spice'),
    ('Krydder','soft spice'),
    ('Krydder','spice'),
    ('Krydder','sweet spice'),
    ('Krydder','sweet spices'),
    ('Lær','leather'),
    ('Mineral','mineral'),
    ('Mineral','minerals'),
    ('Mynte','mint'),
    ('Mynte','minty'),
    ('Mynte','mynte'),
    ('Mynte','peppermint'),
    ('Mynte','spearmint'),
    ('Nøtter','almond'),
    ('Nøtter','almonds'),
    ('Nøtter','nougat'),
    ('Nøtter','nut'),
    ('Nøtter','nuts'),
    ('Nøtter','nøtter'),
    ('Nøtter','roasted almonds'),
    ('Nøtter','roasted cashews'),
    ('Nøtter','roasted nuts'),
    ('Nøtter','toasted nuts'),
    ('Pepper','black pepper'),
    ('Pepper','gentle pepper'),
    ('Pepper','light pepper'),
    ('Pepper','mild pepper'),
    ('Pepper','paprika'),
    ('Pepper','pepper'),
    ('Pepper','white pepper'),
    ('Sedertre','cedar'),
    ('Sedertre','sedertre'),
    ('Sitrus','citrus'),
    ('Toast','toast'),
    ('Toast','toasted bread'),
    ('Tobakk','dark tobacco'),
    ('Tobakk','tobacco'),
    ('Tre','light wood'),
    ('Tre','oak'),
    ('Tre','smoky wood'),
    ('Tre','toasted wood'),
    ('Tre','wood'),
    ('Vanilje','vanilla'),
    ('Whisky','whiskey')
  ),
  flavor_hits as (
    select c.id
    from cigars c
    where length(qraw) >= 2
      and exists (
        select 1 from flavor_map m
        where lower(immutable_unaccent(m.no_label)) like '%' || qraw || '%'
          and lower(m.en_note) = any (select lower(x) from unnest(c.flavor_notes) x)
      )
  )
  select c.*
  from cigars c
  left join alias_hits h on h.id = c.id
  left join flavor_hits f on f.id = c.id
  where (tsq is not null and tsq <> ''::tsquery and c.search_vector @@ tsq)
     or h.id is not null
     or f.id is not null
  order by
    (h.id is not null) desc,
    (tsq is not null and tsq <> ''::tsquery and c.search_vector @@ tsq) desc,
    ts_rank(c.search_vector, coalesce(tsq, ''::tsquery)) desc,
    c.avg_rating desc nulls last
  limit 100;
end;
$function$;
