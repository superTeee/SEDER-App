-- 161: Visuell båndgjenkjenning — finn sigarer med lignende bånd.
--
-- Sammenligner et 512-d embedding (fra embed-band edge-funksjonen) mot alle
-- lagrede bilde-prøver og returnerer de offentlige sigarene med nærmest bånd.
-- SECURITY DEFINER: matcher på tvers av ALLE brukeres prøver (det er hele
-- poenget — «neste mann» drar nytte av det andre har løst), men returnerer kun
-- offentlig sigar-metadata, aldri hvem som la inn prøven.

create or replace function public.match_cigar_by_band(
  p_embedding text,
  p_match_count int default 6,
  p_min_similarity real default 0.72
)
returns table(cigar_id uuid, similarity real, n_samples int)
language sql
stable
security definer
set search_path = public
as $$
  with q as (select p_embedding::vector(512) as e)
  select
    s.cigar_id,
    max(1 - (s.embedding <=> q.e))::real as similarity,
    count(*)::int as n_samples
  from public.cigar_image_samples s
  join public.cigars c on c.id = s.cigar_id
  cross join q
  where s.embedding is not null
    and coalesce(c.is_public, true) = true
  group by s.cigar_id
  having max(1 - (s.embedding <=> q.e)) >= p_min_similarity
  order by similarity desc
  limit p_match_count;
$$;

grant execute on function public.match_cigar_by_band(text, int, real) to authenticated, anon;

-- HNSW-indeks for rask cosinus-nærhet når prøvemengden vokser.
create index if not exists cigar_image_samples_embedding_hnsw
  on public.cigar_image_samples using hnsw (embedding vector_cosine_ops);
