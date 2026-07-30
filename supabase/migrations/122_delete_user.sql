-- Selvbetjent konto-sletting (Apple 5.1.1(v) + Google Play-krav).
-- iOS kaller supabase.rpc("delete_user"); Android bruker delete-account edge fn.
-- SECURITY DEFINER kjører som eier (postgres) → kan slette auth.users-raden.
-- auth.uid() sikrer at brukeren KUN kan slette seg selv. Sletting av auth.users
-- kaskaderer auth.identities/sessions. Profilraden fjernes eksplisitt.
create or replace function public.delete_user()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  delete from public.profiles where id = auth.uid();
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_user() from public, anon;
grant execute on function public.delete_user() to authenticated;
