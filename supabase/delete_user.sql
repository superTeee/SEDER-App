-- Vitola: Slett-konto funksjon
-- Kjør dette i Supabase Dashboard → SQL Editor
--
-- Funksjonen lar brukere slette sin egen konto fra klienten.
-- SECURITY DEFINER gjør at den kjøres med forhøyet tilgang,
-- men auth.uid() sørger for at man kun kan slette sin egen bruker.

create or replace function public.delete_user()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Slett brukerdata fra egne tabeller først (cascade håndterer resten)
  -- (foreign keys med ON DELETE CASCADE rydder opp automatisk)

  -- Slett Supabase Auth-brukeren
  delete from auth.users where id = auth.uid();
end;
$$;

-- Gi innloggede brukere tilgang til å kalle funksjonen
grant execute on function public.delete_user() to authenticated;
