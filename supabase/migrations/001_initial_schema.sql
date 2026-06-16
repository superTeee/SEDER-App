-- ============================================================
-- Cigar App — Initial Schema
-- Kjør denne i Supabase SQL Editor
-- ============================================================

-- UUID-støtte (er som regel allerede aktivert i Supabase)
create extension if not exists "uuid-ossp";

-- ============================================================
-- CIGARS — hoveddatabasen med alle sigarer
-- ============================================================
create table if not exists cigars (
  id                  uuid primary key default uuid_generate_v4(),
  brand               text not null,
  series              text,
  vitola              text,
  wrapper_country     text,
  wrapper_leaf        text,
  binder              text,
  filler              text[],
  strength            int check (strength between 1 and 5),
  country_origin      text,
  flavor_notes        text[],
  description         text,
  band_image_url      text,
  product_image_url   text,
  price_range         text,
  avg_rating          decimal(3,2),
  ring_gauge          int,
  length_inches       decimal(3,1),
  created_at          timestamptz default now()
);

-- Full-text søk (brand + series + vitola)
alter table cigars
  add column if not exists search_vector tsvector
  generated always as (
    to_tsvector('english',
      coalesce(brand, '') || ' ' ||
      coalesce(series, '') || ' ' ||
      coalesce(vitola, '')
    )
  ) stored;

-- ============================================================
-- PROFILES — brukerprofiler (kobles til Supabase Auth)
-- ============================================================
create table if not exists profiles (
  id              uuid primary key references auth.users on delete cascade,
  display_name    text,
  created_at      timestamptz default now()
);

-- ============================================================
-- HUMIDOR — brukerens sigarsamling
-- ============================================================
create table if not exists humidor (
  id              uuid primary key default uuid_generate_v4(),
  user_id         uuid not null references profiles(id) on delete cascade,
  cigar_id        uuid not null references cigars(id),
  quantity        int default 1,
  purchase_date   date,
  purchase_price  decimal(6,2),
  storage_notes   text,
  created_at      timestamptz default now()
);

-- ============================================================
-- TASTING_LOGS — røykenotater og smaksvurderinger
-- ============================================================
create table if not exists tasting_logs (
  id                  uuid primary key default uuid_generate_v4(),
  user_id             uuid not null references profiles(id) on delete cascade,
  cigar_id            uuid not null references cigars(id),
  smoked_at           timestamptz default now(),
  rating              int check (rating between 1 and 10),
  perceived_strength  int check (perceived_strength between 1 and 5),
  flavor_notes        text[],
  pairing             text,
  personal_notes      text,
  location            text,
  created_at          timestamptz default now()
);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- Kritisk for sikkerhet — brukere ser kun egne data
-- ============================================================
alter table cigars       enable row level security;
alter table profiles     enable row level security;
alter table humidor      enable row level security;
alter table tasting_logs enable row level security;

-- CIGARS: Alle kan lese, ingen kan skrive (kun via admin/seed)
create policy "cigars_public_read"
  on cigars for select using (true);

-- PROFILES: Kun egen profil
create policy "profiles_own_select"
  on profiles for select using (auth.uid() = id);

create policy "profiles_own_insert"
  on profiles for insert with check (auth.uid() = id);

create policy "profiles_own_update"
  on profiles for update using (auth.uid() = id);

-- HUMIDOR: Kun egne oppføringer
create policy "humidor_own_select"
  on humidor for select using (auth.uid() = user_id);

create policy "humidor_own_insert"
  on humidor for insert with check (auth.uid() = user_id);

create policy "humidor_own_update"
  on humidor for update using (auth.uid() = user_id);

create policy "humidor_own_delete"
  on humidor for delete using (auth.uid() = user_id);

-- TASTING_LOGS: Kun egne notater
create policy "tasting_logs_own_select"
  on tasting_logs for select using (auth.uid() = user_id);

create policy "tasting_logs_own_insert"
  on tasting_logs for insert with check (auth.uid() = user_id);

create policy "tasting_logs_own_update"
  on tasting_logs for update using (auth.uid() = user_id);

create policy "tasting_logs_own_delete"
  on tasting_logs for delete using (auth.uid() = user_id);

-- ============================================================
-- INDEKSER for ytelse
-- ============================================================
create index if not exists cigars_brand_idx        on cigars(brand);
create index if not exists cigars_series_idx       on cigars(series);
create index if not exists cigars_search_idx       on cigars using gin(search_vector);
create index if not exists humidor_user_idx        on humidor(user_id);
create index if not exists tasting_logs_user_idx   on tasting_logs(user_id);
create index if not exists tasting_logs_cigar_idx  on tasting_logs(cigar_id);

-- ============================================================
-- TRIGGER: Auto-opprett profil når ny bruker registrerer seg
-- ============================================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', 'Sigar-entusiast')
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- SEED DATA: Noen eksempelsigarer å starte med
-- ============================================================
insert into cigars (brand, series, vitola, wrapper_country, wrapper_leaf, binder, filler, strength, country_origin, flavor_notes, description, price_range, ring_gauge, length_inches) values
('Davidoff', 'Winston Churchill', 'Robusto', 'Ecuador', 'Connecticut Shade', 'Dominican', ARRAY['Dominican', 'Nicaraguan'], 3, 'Dominican Republic', ARRAY['Cedar', 'Cream', 'Toasted Nuts', 'White Pepper'], 'En elegant og balansert sigar med kompleks men tilgjengelig smaksprofil.', '$25–$35', 50, 5.0),
('Arturo Fuente', 'Hemingway', 'Signature', 'Cameroon', 'Natural', 'Dominican', ARRAY['Dominican'], 2, 'Dominican Republic', ARRAY['Coffee', 'Honey', 'Cedar', 'Cream'], 'En av de mest berømte figurado-sigarene i verden. Mild og søt.', '$12–$18', 49, 7.0),
('Padron', '1964 Anniversary', 'Hermoso', 'Nicaragua', 'Maduro', 'Nicaragua', ARRAY['Nicaraguan'], 4, 'Nicaragua', ARRAY['Cocoa', 'Coffee', 'Earth', 'Leather'], 'En kraftig og kompleks sigarer med rik nicaraguansk tobakk.', '$22–$30', 44, 6.5),
('Cohiba', 'Behike', 'BHK 52', 'Cuba', 'Colorado Claro', 'Cuba', ARRAY['Cuban'], 3, 'Cuba', ARRAY['Spice', 'Leather', 'Dark Fruit', 'Toast'], 'Cohiba Behike er blant de mest prestisjefylte kubanskene. Sjelden og eksklusiv.', '$40–$80', 52, 5.4),
('Macanudo', 'Cafe', 'Hyde Park', 'Ecuador', 'Connecticut Shade', 'Mexican', ARRAY['Dominican', 'Mexican'], 1, 'Dominican Republic', ARRAY['Cream', 'Wood', 'Mild Spice'], 'Perfekt for nybegynnere. Svært mild og lett med kremete avslutning.', '$8–$12', 49, 5.6);
