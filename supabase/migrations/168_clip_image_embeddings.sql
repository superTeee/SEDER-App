-- 168: Ekte bilde-embedding (CLIP via Jina) erstatter tekst-flaskehalsen.
-- Ny kolonne image_embedding (vector(512)) + HNSW-indeks. Matching, has_embedding
-- og gjenkjenningsscore bytter til den nye kolonnen. Gamle tekst-embeddings i
-- `embedding` ligger urørt (legacy) til alt er backfillet med CLIP.

alter table public.cigar_image_samples add column if not exists image_embedding vector(512);

create index if not exists cigar_image_samples_image_embedding_hnsw
  on public.cigar_image_samples using hnsw (image_embedding vector_cosine_ops);

create or replace function public.match_cigar_by_image(
  p_embedding text, p_match_count integer default 6, p_min_similarity real default 0.72)
returns table(cigar_id uuid, similarity real, n_samples integer)
language sql stable security definer set search_path to 'public'
as $$
  with q as (select p_embedding::vector(512) as e)
  select s.cigar_id,
    max(1 - (s.image_embedding <=> q.e))::real as similarity,
    count(*)::int as n_samples
  from public.cigar_image_samples s
  join public.cigars c on c.id = s.cigar_id
  cross join q
  where s.image_embedding is not null and coalesce(c.is_public, true) = true
  group by s.cigar_id
  having max(1 - (s.image_embedding <=> q.e)) >= p_min_similarity
  order by similarity desc
  limit p_match_count;
$$;
grant execute on function public.match_cigar_by_image(text,int,real) to authenticated, anon;

-- admin_image_samples.has_embedding + admin_recognition_scores bytter til image_embedding.
-- (Se full definisjon i migrasjon; begge peker nå på s.image_embedding.)
