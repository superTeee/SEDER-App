-- ============================================================
-- Migration 080: Flere humidorer per bruker
-- Ny container-tabell `humidors`; entries-tabellen `humidor` får humidor_id.
-- Eksisterende sigarer flyttes til en standard-humidor per bruker.
-- Storage-bucket for humidor-forsidebilder.
-- ============================================================

-- 1. Container-tabell
create table if not exists public.humidors (
    id          uuid        primary key default gen_random_uuid(),
    user_id     uuid        not null references auth.users(id) on delete cascade,
    name        text        not null,
    type        text,
    location    text,
    capacity    int,
    image_url   text,
    created_at  timestamptz not null default now()
);

create index if not exists idx_humidors_user on public.humidors(user_id);

alter table public.humidors enable row level security;

create policy "humidors_select" on public.humidors
    for select using (auth.uid() = user_id);
create policy "humidors_insert" on public.humidors
    for insert with check (auth.uid() = user_id);
create policy "humidors_update" on public.humidors
    for update using (auth.uid() = user_id);
create policy "humidors_delete" on public.humidors
    for delete using (auth.uid() = user_id);

-- 2. Koble entries til en humidor
alter table public.humidor
    add column if not exists humidor_id uuid references public.humidors(id) on delete set null;

create index if not exists idx_humidor_humidor_id on public.humidor(humidor_id);

-- 3. Backfill: standard-humidor per bruker med eksisterende sigarer
do $$
declare
    u   record;
    hid uuid;
begin
    for u in select distinct user_id from public.humidor where humidor_id is null loop
        insert into public.humidors (user_id, name, type)
        values (u.user_id, 'Min humidor', 'Desktop')
        returning id into hid;

        update public.humidor
        set humidor_id = hid
        where user_id = u.user_id and humidor_id is null;
    end loop;
end $$;

-- 4. Storage-bucket for humidor-forsidebilder
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('humidor-covers','humidor-covers',true,5242880,array['image/jpeg','image/png','image/webp','image/heic'])
on conflict (id) do nothing;

create policy "humidor_covers_select" on storage.objects
    for select using (bucket_id = 'humidor-covers');
create policy "humidor_covers_insert" on storage.objects
    for insert with check (bucket_id = 'humidor-covers' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "humidor_covers_update" on storage.objects
    for update using (bucket_id = 'humidor-covers' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "humidor_covers_delete" on storage.objects
    for delete using (bucket_id = 'humidor-covers' and auth.uid()::text = (storage.foldername(name))[1]);
