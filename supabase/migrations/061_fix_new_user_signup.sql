-- ============================================================
-- 061_fix_new_user_signup.sql
--
-- FIKS: "Database error saving new user" ved registrering.
--
-- Rotårsak: BEFORE INSERT-triggeren profiles_set_friend_code (migrasjon 003)
-- kaller generate_unique_friend_code(), som brukte uuid_generate_v4() UTEN
-- skjema-prefiks. Under GoTrue-registrering kjører triggeren med en search_path
-- som ikke inkluderer 'extensions'-skjemaet, så funksjonen ikke finnes →
-- hele registreringen ruller tilbake.
--
-- Løsning:
--   1) Fjern avhengigheten av uuid_generate_v4() helt (random() + clock_timestamp()
--      gir mer enn nok entropi for en 6-tegns kode og er innebygd i Postgres).
--   2) Lås search_path eksplisitt på alle funksjoner i registrerings-kjeden.
-- ============================================================

-- 1. Venne-kode-generator — nå uten extension-avhengighet
create or replace function public.generate_unique_friend_code()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_exists boolean;
begin
  loop
    v_code := upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));
    select exists(select 1 from profiles where friend_code = v_code) into v_exists;
    if not v_exists then
      exit;
    end if;
  end loop;
  return v_code;
end;
$$;

-- 2. BEFORE INSERT-trigger på profiles — lås search_path
create or replace function public.set_friend_code()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.friend_code is null then
    new.friend_code := public.generate_unique_friend_code();
  end if;
  return new;
end;
$$;

-- 3. Auto-opprett profil ved ny bruker — lås search_path
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', 'Sigar-entusiast')
  );
  return new;
end;
$$;
