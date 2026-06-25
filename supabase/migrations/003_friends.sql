-- ============================================================
-- Cigar App — Venner (friends)
-- Kjør denne i Supabase SQL Editor
--
-- Legger til:
--   1. friend_code på profiles — en kort delbar kode hver bruker
--      kan gi til andre for å bli lagt til som venn (ingen
--      brukernavn-system eller eksponering av e-post nødvendig).
--   2. friendships — venneforespørsler/vennskap mellom to brukere.
--   3. RPC-funksjoner som klienten kaller for å finne brukere via
--      kode, sende forespørsel og hente venner+forespørsler i ett
--      kall (de bypasser RLS trygt, kun for de spesifikke formålene).
-- ============================================================

-- ============================================================
-- 1. FRIEND_CODE på profiles
-- ============================================================
alter table profiles add column if not exists friend_code text unique;

-- Genererer en unik 6-tegns kode (f.eks. "K3M9XQ"), prøver på nytt
-- ved kollisjon (ekstremt sjeldent, men trygt uansett antall brukere).
create or replace function public.generate_unique_friend_code()
returns text as $$
declare
  v_code text;
  v_exists boolean;
begin
  loop
    v_code := upper(substr(md5(random()::text || clock_timestamp()::text || uuid_generate_v4()::text), 1, 6));
    select exists(select 1 from profiles where friend_code = v_code) into v_exists;
    if not v_exists then
      exit;
    end if;
  end loop;
  return v_code;
end;
$$ language plpgsql;

-- Auto-generer kode for nye profiler
create or replace function public.set_friend_code()
returns trigger as $$
begin
  if new.friend_code is null then
    new.friend_code := public.generate_unique_friend_code();
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists profiles_set_friend_code on profiles;
create trigger profiles_set_friend_code
  before insert on profiles
  for each row execute procedure public.set_friend_code();

-- Backfill for eksisterende profiler som ikke har kode ennå
do $$
declare
  r record;
begin
  for r in select id from profiles where friend_code is null loop
    update profiles set friend_code = public.generate_unique_friend_code() where id = r.id;
  end loop;
end;
$$;

-- ============================================================
-- 2. FRIENDSHIPS — venneforespørsler og vennskap
-- ============================================================
create table if not exists friendships (
  id              uuid primary key default uuid_generate_v4(),
  requester_id    uuid not null references profiles(id) on delete cascade,
  recipient_id    uuid not null references profiles(id) on delete cascade,
  status          text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  created_at      timestamptz default now(),
  responded_at    timestamptz,
  -- Sørger for at det kun finnes ÉN rad mellom to brukere, uansett
  -- hvem som sendte forespørselen (A->B og B->A regnes som samme par).
  pair_key text generated always as (
    case when requester_id < recipient_id
      then requester_id::text || '_' || recipient_id::text
      else recipient_id::text || '_' || requester_id::text
    end
  ) stored,
  constraint friendships_not_self check (requester_id <> recipient_id),
  constraint friendships_pair_unique unique (pair_key)
);

create index if not exists friendships_requester_idx on friendships(requester_id);
create index if not exists friendships_recipient_idx on friendships(recipient_id);

alter table friendships enable row level security;

-- Begge parter kan se vennskapet/forespørselen
create policy "friendships_select_own"
  on friendships for select
  using (auth.uid() = requester_id or auth.uid() = recipient_id);

-- Du kan bare sende forespørsler som deg selv (selve sendingen går
-- normalt via send_friend_request()-funksjonen under, men policyen
-- er her som et sikkerhetsnett)
create policy "friendships_insert_own"
  on friendships for insert
  with check (auth.uid() = requester_id);

-- Mottaker kan godta/avslå
create policy "friendships_update_recipient"
  on friendships for update
  using (auth.uid() = recipient_id);

-- Begge parter kan slette (avbryt forespørsel / fjern venn)
create policy "friendships_delete_own"
  on friendships for delete
  using (auth.uid() = requester_id or auth.uid() = recipient_id);

-- ============================================================
-- 3. RPC-FUNKSJONER
-- ============================================================

-- Finn en bruker via venne-kode (kun id + visningsnavn, ikke hele
-- profilen — profiles_own_select hindrer ellers alle fra å se
-- andres profiler, så dette gir et trygt, begrenset unntak).
create or replace function public.find_user_by_friend_code(p_code text)
returns table(id uuid, display_name text)
security definer
set search_path = public
language sql
as $$
  select id, display_name
  from profiles
  where friend_code = upper(trim(p_code));
$$;

-- Send venneforespørsel via kode. Håndterer alle feilcase med en
-- tydelig norsk feiltekst klienten kan vise direkte.
create or replace function public.send_friend_request(p_code text)
returns friendships
security definer
set search_path = public
language plpgsql
as $$
declare
  v_recipient_id uuid;
  v_existing friendships;
  v_result friendships;
begin
  select id into v_recipient_id
  from profiles
  where friend_code = upper(trim(p_code));

  if v_recipient_id is null then
    raise exception 'Fant ingen bruker med denne koden';
  end if;

  if v_recipient_id = auth.uid() then
    raise exception 'Du kan ikke legge til deg selv som venn';
  end if;

  select * into v_existing
  from friendships
  where pair_key = case
    when auth.uid() < v_recipient_id then auth.uid()::text || '_' || v_recipient_id::text
    else v_recipient_id::text || '_' || auth.uid()::text
  end;

  if v_existing.id is not null then
    if v_existing.status = 'accepted' then
      raise exception 'Dere er allerede venner';
    elsif v_existing.status = 'pending' then
      raise exception 'Det finnes allerede en venneforespørsel mellom dere';
    else
      -- Tidligere avslått — la dem prøve på nytt
      update friendships
      set requester_id = auth.uid(),
          recipient_id = v_recipient_id,
          status = 'pending',
          created_at = now(),
          responded_at = null
      where id = v_existing.id
      returning * into v_result;
      return v_result;
    end if;
  end if;

  insert into friendships (requester_id, recipient_id, status)
  values (auth.uid(), v_recipient_id, 'pending')
  returning * into v_result;

  return v_result;
end;
$$;

-- Henter alt Venner-fanen trenger i ett kall: aktive venner +
-- innkommende/utgående forespørsler, med den andre partens navn.
create or replace function public.get_friends_and_requests()
returns table(
  friendship_id uuid,
  other_user_id uuid,
  other_display_name text,
  status text,
  direction text,
  created_at timestamptz
)
security definer
set search_path = public
language sql
as $$
  select
    f.id,
    case when f.requester_id = auth.uid() then f.recipient_id else f.requester_id end,
    p.display_name,
    f.status,
    case when f.requester_id = auth.uid() then 'outgoing' else 'incoming' end,
    f.created_at
  from friendships f
  join profiles p
    on p.id = case when f.requester_id = auth.uid() then f.recipient_id else f.requester_id end
  where f.requester_id = auth.uid() or f.recipient_id = auth.uid()
  order by f.created_at desc;
$$;

grant execute on function public.find_user_by_friend_code(text) to authenticated;
grant execute on function public.send_friend_request(text) to authenticated;
grant execute on function public.get_friends_and_requests() to authenticated;
