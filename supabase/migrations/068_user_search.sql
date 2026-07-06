-- Migration 068: Brukersøk — finn venner via navn eller kode
--
-- Legger til en security definer-funksjon som lar innloggede brukere
-- søke etter andre profiler på display_name (ILIKE) eller eksakt
-- friend_code-treff. Bypasser RLS trygt, men eksponerer kun
-- id, display_name og friend_code — ingenting sensitivt.

create or replace function public.search_users(p_query text)
returns table(id uuid, display_name text, friend_code text)
security definer
set search_path = public
language sql
as $$
  select
    p.id,
    p.display_name,
    p.friend_code
  from profiles p
  where p.id != auth.uid()
    and trim(p_query) != ''
    and (
      p.display_name ilike '%' || trim(p_query) || '%'
      or p.friend_code = upper(trim(p_query))
    )
  order by p.display_name
  limit 20;
$$;

grant execute on function public.search_users(text) to authenticated;
