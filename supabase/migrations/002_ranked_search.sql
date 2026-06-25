-- 002_ranked_search.sql
-- Fikser bug: scan-søk sorterte treff på avg_rating i stedet for hvor godt
-- teksten fra sigarbåndet faktisk matchet. Det gjorde at populære sigarer
-- med bare et løst tekst-treff (f.eks. "Black" i navnet) kunne overstyre
-- et faktisk bedre treff (f.eks. "Alec Bradley Black Market").
--
-- Denne funksjonen sorterer i stedet etter ts_rank (tekst-relevans),
-- med avg_rating kun som tie-breaker mellom like relevante treff.

create or replace function search_cigars_ranked(search_query text)
returns setof cigars
language plpgsql
stable
as $$
declare
  tsq tsquery;
begin
  -- search_query kommer ferdig bygget fra appen som "ord1 | ord2 | ord3"
  -- (OR mellom ordene). Faller tilbake til plainto_tsquery hvis teksten
  -- inneholder tegn to_tsquery ikke liker (f.eks. spesialtegn fra OCR).
  begin
    tsq := to_tsquery('english', search_query);
  exception when others then
    tsq := plainto_tsquery('english', search_query);
  end;

  if tsq is null or tsq = ''::tsquery then
    return;
  end if;

  return query
    select c.*
    from cigars c
    where c.search_vector @@ tsq
    order by
      ts_rank(c.search_vector, tsq) desc,
      c.avg_rating desc nulls last
    limit 100;
end;
$$;
