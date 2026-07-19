-- 110_cigar_alias_matching
-- Kjernefiks for skanning: gjør at bånd-navn (linje- og vitola-egennavn som
-- "Forrader"/"Blücher") kan matches til riktig sigar, ikke bare merkenavnet.
--
-- 1) aliases[] per sigar = alternative navn som faktisk står på banderolen.
-- 2) match_cigar() = én felles, accent-/skrivefeil-tolerant søke-RPC som
--    matcher mot merke + serie + vitola + aliases. Brukes av app + edge function.

create extension if not exists unaccent;
create extension if not exists pg_trgm;

alter table cigars add column if not exists aliases text[] not null default '{}';

-- Immutabel unaccent-wrapper (unaccent() er ikke immutable som standard, så den
-- kan ikke brukes direkte i uttrykk som må være deterministiske).
create or replace function public.imm_unaccent(text)
returns text
language sql
immutable
parallel safe
strict
as $$ select public.unaccent('public.unaccent', $1) $$;

-- Normaliserer tekst for matching: liten bokstav, uten aksenter, trimmet.
create or replace function public.norm_text(text)
returns text
language sql
immutable
parallel safe
as $$ select lower(public.imm_unaccent(coalesce($1, ''))) $$;

-- match_cigar: rangerte kandidater for en fritekst-spørring fra båndet.
-- Slår sammen merke+serie+vitola+aliases til én "haystack", normaliserer begge
-- sider, og scorer på (a) direkte delstreng-treff og (b) trigram-likhet.
create or replace function public.match_cigar(
  p_query text,
  p_limit int default 10
)
returns table (
  id uuid,
  brand text,
  series text,
  vitola text,
  score real
)
language sql
stable
as $$
  with q as (
    select public.norm_text(p_query) as nq
  ),
  scored as (
    select
      c.id, c.brand, c.series, c.vitola,
      public.norm_text(
        coalesce(c.brand,'') || ' ' || coalesce(c.series,'') || ' ' ||
        coalesce(c.vitola,'') || ' ' || array_to_string(c.aliases, ' ')
      ) as hay,
      public.norm_text(array_to_string(c.aliases, ' ')) as alias_hay
    from cigars c
    where coalesce(c.is_public, true) = true
  )
  select
    s.id, s.brand, s.series, s.vitola,
    (
      (case when q.nq <> '' and s.hay like '%' || q.nq || '%' then 0.6 else 0 end)
      + (case when q.nq <> '' and s.alias_hay like '%' || q.nq || '%' then 0.3 else 0 end)
      + similarity(s.hay, q.nq) * 0.4
    )::real as score
  from scored s, q
  where q.nq <> ''
    and (s.hay like '%' || q.nq || '%' or similarity(s.hay, q.nq) > 0.12)
  order by score desc, s.brand, s.series
  limit greatest(p_limit, 1);
$$;

grant execute on function public.match_cigar(text, int) to authenticated, anon;
grant execute on function public.imm_unaccent(text) to authenticated, anon;
grant execute on function public.norm_text(text) to authenticated, anon;
