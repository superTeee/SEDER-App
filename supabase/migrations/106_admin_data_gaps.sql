-- 106_admin_data_gaps.sql
--
-- DATAHULL
--
-- Køen (097) håndterer det brukerne melder inn — reaktivt. Datahull er det
-- motsatte: de offentlige radene som allerede mangler noe, sortert etter hvor
-- mye de mangler, slik at en admin kan tette dem uten å lete.
--
-- Et "hull" er et tomt felt som appen faktisk viser brukeren. Vi teller seks:
--
--   dimensions  ring_gauge ELLER length_inches mangler   (verst — et halvt mål
--               er verre enn ingen mål; appen skjuler «50 × ?»)
--   origin      country_origin tomt
--   wrapper     wrapper_leaf tomt
--   strength    strength null
--   flavor      flavor_notes tomt eller {}
--   description description tomt
--
-- Bare offentlige rader (is_public = true). Private rader er brukernes egne
-- kladder — de skal ikke telle som hull i katalogen.
--
--
-- FUNKSJONER
--
-- admin_data_gaps()   Leser hullene, verst først. Admin-only. Manglende mål
--                     løftes øverst, deretter flest hull, deretter navn.
--
-- admin_fill_cigar()  Fyller ETT eller flere tomme felt. Overskriver ALDRI et
--                     felt som allerede har verdi — den TETTER hull, den RETTER
--                     ikke (det gjør admin_fix_cigar fra 097). Krever kildelenke.
--
--
-- HVA FYLLING IKKE GJØR
--
-- admin_fill_cigar setter IKKE verified_at og rører IKKE source_tier. Å tette
-- et tomt felt betyr ikke at hele raden er kontrollert mot produsenten. «Kilde»
-- lagres i source_url dersom den var tom, som spor — ikke som løfte. Skal raden
-- bli verifisert, går det gjennom admin_fix_cigar, som krever nivå.


-- MARK: - admin_data_gaps()

create or replace function admin_data_gaps()
returns table (
  id              uuid,
  cigar_navn      text,
  brand           text,
  ring_gauge      int,
  length_inches   numeric,
  country_origin  text,
  wrapper_leaf    text,
  strength        numeric,
  has_flavor      boolean,
  has_description boolean,
  missing         text[],
  gap_count       int,
  source_tier     text,
  verified        boolean
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not is_admin() then
    raise exception 'ikke autorisert';
  end if;

  return query
  with g as (
    select
      c.id,
      nullif(trim(concat_ws(' ', c.brand, c.series, c.vitola)), '') as cigar_navn,
      c.brand,
      c.ring_gauge,
      c.length_inches,
      c.country_origin,
      c.wrapper_leaf,
      c.strength,
      (c.flavor_notes is not null and array_length(c.flavor_notes, 1) > 0) as has_flavor,
      (c.description is not null and length(trim(c.description)) > 0)       as has_description,
      array_remove(array[
        case when c.ring_gauge is null or c.length_inches is null                        then 'dimensions'  end,
        case when c.country_origin is null or length(trim(c.country_origin)) = 0         then 'origin'       end,
        case when c.wrapper_leaf is null or length(trim(c.wrapper_leaf)) = 0             then 'wrapper'      end,
        case when c.strength is null                                                      then 'strength'     end,
        case when c.flavor_notes is null or array_length(c.flavor_notes, 1) is null      then 'flavor'       end,
        case when c.description is null or length(trim(c.description)) = 0               then 'description'  end
      ], null) as missing,
      c.source_tier,
      (c.verified_at is not null) as verified
    from cigars c
    where coalesce(c.is_public, true) = true
  )
  select
    g.id, g.cigar_navn, g.brand, g.ring_gauge, g.length_inches,
    g.country_origin, g.wrapper_leaf, g.strength, g.has_flavor, g.has_description,
    g.missing,
    cardinality(g.missing) as gap_count,
    g.source_tier, g.verified
  from g
  where cardinality(g.missing) > 0
  order by
    (('dimensions' = any(g.missing))::int) desc,  -- manglende mål øverst
    cardinality(g.missing) desc,                  -- så flest hull
    g.cigar_navn asc nulls last
  limit 300;
end;
$$;

grant execute on function admin_data_gaps() to authenticated;


-- MARK: - admin_fill_cigar()
--
-- Alle p_-parametere er valgfrie unntatt id og kilde. Utelatte parametere
-- (JSON-nøkkelen mangler) blir null og lar feltet stå. coalesce/nullif sørger
-- for at bare TOMME felt fylles — et felt med verdi røres aldri.

create or replace function admin_fill_cigar(
  p_cigar_id      uuid,
  p_source_url    text,
  p_ring_gauge    int     default null,
  p_length_inches numeric default null,
  p_country_origin text   default null,
  p_wrapper_leaf  text    default null,
  p_strength      numeric default null,
  p_flavor_notes  text[]  default null,
  p_description   text    default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not is_admin() then
    raise exception 'ikke autorisert';
  end if;

  if p_source_url is null or length(trim(p_source_url)) = 0 then
    raise exception 'kilde kreves';
  end if;

  update cigars set
    ring_gauge     = coalesce(ring_gauge, p_ring_gauge),
    length_inches  = coalesce(length_inches, p_length_inches),
    country_origin = coalesce(nullif(trim(country_origin), ''), nullif(trim(p_country_origin), '')),
    wrapper_leaf   = coalesce(nullif(trim(wrapper_leaf), ''), nullif(trim(p_wrapper_leaf), '')),
    strength       = coalesce(strength, p_strength),
    flavor_notes   = case
                       when flavor_notes is null or array_length(flavor_notes, 1) is null
                       then p_flavor_notes
                       else flavor_notes
                     end,
    description    = coalesce(nullif(trim(description), ''), nullif(trim(p_description), '')),
    -- Kilden lagres bare som spor, og bare hvis feltet var tomt. Ikke et løfte.
    source_url     = coalesce(nullif(trim(source_url), ''), nullif(trim(p_source_url), ''))
  where id = p_cigar_id
    and coalesce(is_public, true) = true;
end;
$$;

grant execute on function admin_fill_cigar(
  uuid, text, int, numeric, text, text, numeric, text[], text
) to authenticated;
