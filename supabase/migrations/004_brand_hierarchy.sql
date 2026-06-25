-- ============================================================
-- 004_brand_hierarchy.sql
--
-- Bakgrunn: "My Father Cigars" er et HUS (produsent) som lager flere
-- distinkte merkefamilier (My Father, Don Pepin Garcia, Flor de las
-- Antillas, Jaime Garcia, El Centurion, Fonseca by My Father, La
-- Antiguedad, La Dueña, Tabacos Baez). Den gamle flate modellen (alt
-- under brand="My Father") gjorde det umulig å skille disse fra
-- hverandre i UI og søk. Denne migrasjonen innfører et eksplisitt
-- hierarki uten å måtte skrive om eksisterende kode:
--
--   manufacturer  = huset/produsenten   ("My Father Cigars")
--   brand         = merkefamilien       ("Don Pepin Garcia")  <- samme
--                   kolonne som før, bare strengere definert
--   series        = serien/sub-linjen   ("Series JJ")
--   vitola        = det navngitte produktet ("Belicosos")
--   common_format = generisk vitola-form, for søk/OCR ("Belicoso")
--   shape         = fysisk form: Parejo / Box-Pressed / Figurado
--   body_type     = figurado-undertype (Torpedo/Belicoso/Perfecto/Salomon)
--   head_type     = "Pointed" — kun figurados, null = standard/rundt
--   foot_type     = "Closed"/"Tapered" — kun figurados, null = standard/åpen
--
-- Eksisterende kode (CigarService.fetchCigarsByBrand, ResultRow,
-- CigarDetailView) bruker allerede brand/series/vitola til visning —
-- de trenger IKKE endres, siden vi fortsetter å bruke samme kolonner,
-- bare med riktigere data i dem.
-- ============================================================

alter table cigars
  add column if not exists manufacturer  text,
  add column if not exists common_format text,
  add column if not exists body_type     text,
  add column if not exists head_type     text,
  add column if not exists foot_type     text;

comment on column cigars.brand is
  'Merkefamilie (brand family), f.eks. "Don Pepin Garcia". Ikke nødvendigvis samme som produsent — se manufacturer.';
comment on column cigars.manufacturer is
  'Produsenten/huset som lager sigaren, f.eks. "My Father Cigars". Kan dekke flere brand families.';
comment on column cigars.common_format is
  'Generisk vitola-kategori (Robusto/Toro/Churchill/Belicoso/...) brukt til søk og OCR-matching, uavhengig av det proprietære produktnavnet i vitola-kolonnen.';
comment on column cigars.shape is
  'Fysisk form: Parejo (standard), Box-Pressed eller Figurado.';
comment on column cigars.body_type is
  'Figurado-undertype (Torpedo, Belicoso, Perfecto, Pyramid, Salomon). Null for Parejo/Box-Pressed.';
comment on column cigars.head_type is
  'Formen på sigarens hode (f.eks. "Pointed"). Null = standard/rundt.';
comment on column cigars.foot_type is
  'Formen på sigarens fot (f.eks. "Closed", "Tapered"). Null = standard/åpen.';

-- search_vector er en GENERATED-kolonne og kan ikke endres in-place —
-- må droppes og bygges på nytt for å inkludere manufacturer/common_format.
drop index if exists cigars_search_idx;
alter table cigars drop column if exists search_vector;
alter table cigars
  add column search_vector tsvector
  generated always as (
    to_tsvector('english',
      coalesce(manufacturer, '')   || ' ' ||
      coalesce(brand, '')          || ' ' ||
      coalesce(series, '')         || ' ' ||
      coalesce(vitola, '')         || ' ' ||
      coalesce(common_format, '')
    )
  ) stored;
create index cigars_search_idx on cigars using gin(search_vector);
create index if not exists cigars_manufacturer_idx on cigars(manufacturer);

-- ============================================================
-- CIGAR_ALIASES
-- Alternative skrivemåter for merke/serie — brukt til å matche OCR-tekst
-- fra sigarbånd som ikke inneholder det fulle/offisielle navnet
-- (f.eks. "MF The Judge", "FDLA", "Blue Label").
-- ============================================================
create table if not exists cigar_aliases (
  id            uuid primary key default uuid_generate_v4(),
  alias         text not null,
  manufacturer  text,
  brand         text not null,   -- merkefamilien aliaset peker til
  series        text,            -- null = gjelder hele merkefamilien, uansett serie
  created_at    timestamptz default now(),
  unique (alias, brand, series)
);

alter table cigar_aliases enable row level security;

create policy "cigar_aliases_public_read"
  on cigar_aliases for select using (true);

create index if not exists cigar_aliases_alias_idx on cigar_aliases(lower(alias));
create index if not exists cigar_aliases_brand_idx on cigar_aliases(brand);

-- ============================================================
-- Oppdatert søkefunksjon: matcher først på alias (når raw_text gis),
-- deretter på vanlig tekst-relevans (ts_rank). Alias-treff prioriteres
-- høyest siden de representerer en kjent, eksakt forkortelse/variant —
-- "raw_text" er den ORIGINALE OCR-teksten (før den brytes opp i
-- OR-spørreord), så vi kan sjekke om et helt alias-uttrykk (f.eks.
-- "mf the judge") faktisk forekommer i båndteksten.
-- ============================================================
create or replace function search_cigars_ranked(search_query text, raw_text text default null)
returns setof cigars
language plpgsql
stable
as $$
declare
  tsq tsquery;
begin
  begin
    tsq := to_tsquery('english', search_query);
  exception when others then
    tsq := plainto_tsquery('english', search_query);
  end;

  if tsq is null or tsq = ''::tsquery then
    return;
  end if;

  return query
    with alias_hits as (
      select distinct c.id
      from cigars c
      join cigar_aliases a
        on c.brand = a.brand
       and (a.series is null or c.series = a.series)
      where raw_text is not null
        and raw_text ilike '%' || a.alias || '%'
    )
    select c.*
    from cigars c
    left join alias_hits h on h.id = c.id
    where c.search_vector @@ tsq or h.id is not null
    order by
      (h.id is not null) desc,
      ts_rank(c.search_vector, tsq) desc,
      c.avg_rating desc nulls last
    limit 100;
end;
$$;
