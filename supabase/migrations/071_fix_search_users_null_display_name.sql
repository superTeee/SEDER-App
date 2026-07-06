-- ============================================================
-- 071_fix_search_users_null_display_name.sql
--
-- Oppdaterer search_users RPC:
-- 1. Bruker coalesce(display_name, 'Sigar-entusiast') slik at
--    null-verdier ikke krasjer iOS-dekodingen (som forventer String,
--    ikke String?).
-- 2. Inkluderer alltid brukere som matcher på friend_code, selv om
--    de mangler display_name.
-- 3. Ekskluderer brukere uten friend_code (unngår null-decode-feil).
-- ============================================================

create or replace function public.search_users(p_query text)
returns table(id uuid, display_name text, friend_code text)
security definer
set search_path = public
language sql
as $$
  select
    p.id,
    coalesce(p.display_name, 'Sigar-entusiast') as display_name,
    p.friend_code
  from profiles p
  where p.id != auth.uid()
    and trim(p_query) != ''
    and p.friend_code is not null
    and (
      coalesce(p.display_name, '') ilike '%' || trim(p_query) || '%'
      or p.friend_code = upper(trim(p_query))
    )
  order by p.display_name nulls last
  limit 20;
$$;

grant execute on function public.search_users(text) to authenticated;
