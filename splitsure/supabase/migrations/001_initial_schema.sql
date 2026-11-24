-- ============================================================
-- SplitSure – Initial Database Schema
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor)
-- ============================================================

-- ── Enable UUID extension ────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ============================================================
-- PROFILES
-- ============================================================
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  first_name    text,
  last_name     text,
  username      text unique,
  avatar_url    text,
  bio           text,
  country       text default 'Cameroon',
  city          text,
  phone         text,
  music_roles   text[]  default '{}',
  whatsapp_url  text,
  tiktok_url    text,
  youtube_url   text,
  facebook_url  text,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

-- Auto-create profile row on sign-up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, first_name, last_name, username, phone, country)
  values (
    new.id,
    new.raw_user_meta_data->>'first_name',
    new.raw_user_meta_data->>'last_name',
    new.raw_user_meta_data->>'username',
    new.raw_user_meta_data->>'phone',
    coalesce(new.raw_user_meta_data->>'country', 'Cameroon')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- RLS
alter table public.profiles enable row level security;
create policy "Users can view own profile"   on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);

-- ============================================================
-- AGREEMENTS
-- ============================================================
create table if not exists public.agreements (
  id                  uuid primary key default uuid_generate_v4(),
  user_id             uuid not null references auth.users(id) on delete cascade,
  song_title          text not null,
  description         text,
  genre               text,
  cover_art_url       text,
  recording_date      date,
  release_date        date,
  scope_of_rights     text,
  additional_terms    text,
  effective_date      date,
  status              text not null default 'draft'
                        check (status in ('draft','pending','accepted','changes_requested','declined')),
  witness_name        text,
  witness_email       text,
  witness_phone       text,
  witness_role        text,
  lawyer_name         text,
  lawyer_firm         text,
  lawyer_email        text,
  lawyer_phone        text,
  lawyer_registration text,
  pdf_url             text,
  created_at          timestamptz default now(),
  updated_at          timestamptz default now()
);

alter table public.agreements enable row level security;
create policy "Users manage own agreements" on public.agreements
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- AGREEMENT SPLITS (collaborators)
-- ============================================================
create table if not exists public.agreement_splits (
  id                       uuid primary key default uuid_generate_v4(),
  agreement_id             uuid not null references public.agreements(id) on delete cascade,
  collaborator_name        text not null,
  collaborator_email       text,
  phone                    text,
  role                     text not null,
  contribution_description text,
  split_percentage         numeric(5,2) not null check (split_percentage > 0 and split_percentage <= 100),
  response                 text check (response in ('accepted','changes_requested','declined')),
  accepted_at              timestamptz,
  created_at               timestamptz default now()
);

alter table public.agreement_splits enable row level security;
create policy "Users manage splits of own agreements" on public.agreement_splits
  using (
    exists (
      select 1 from public.agreements a
      where a.id = agreement_id and a.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.agreements a
      where a.id = agreement_id and a.user_id = auth.uid()
    )
  );

-- ============================================================
-- CAMPAIGNS
-- ============================================================
create table if not exists public.campaigns (
  id                   uuid primary key default uuid_generate_v4(),
  user_id              uuid not null references auth.users(id) on delete cascade,
  song_title           text not null,
  campaign_name        text,
  description          text,
  target_audience      text,
  budget_xaf           integer default 0,
  cover_art_url        text,
  music_file_url       text,
  release_date         date,
  promotional_message  text,
  streaming_link       text,
  snippet_start        numeric,
  snippet_end          numeric,
  generated_captions   text,
  generated_hashtags   text,
  status               text not null default 'draft'
                         check (status in ('draft','content_generated','ready_to_share','completed')),
  created_at           timestamptz default now(),
  updated_at           timestamptz default now()
);

alter table public.campaigns enable row level security;
create policy "Users manage own campaigns" on public.campaigns
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
create table if not exists public.notifications (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  title      text not null,
  body       text,
  type       text default 'general'
               check (type in ('agreement','campaign','subscription','general')),
  is_read    boolean default false,
  related_id uuid,
  created_at timestamptz default now()
);

alter table public.notifications enable row level security;
create policy "Users view own notifications" on public.notifications
  for select using (auth.uid() = user_id);
create policy "Users update own notifications" on public.notifications
  for update using (auth.uid() = user_id);
-- Allow backend/service role to insert notifications
create policy "Service role can insert notifications" on public.notifications
  for insert with check (true);

-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================
create table if not exists public.subscriptions (
  id                uuid primary key default uuid_generate_v4(),
  user_id           uuid not null references auth.users(id) on delete cascade,
  plan              text not null default 'free'
                      check (plan in ('free','monthly','quarterly','annual')),
  status            text not null default 'active'
                      check (status in ('active','expired','cancelled','demo')),
  amount_fcfa       integer default 0,
  started_at        timestamptz default now(),
  expires_at        timestamptz,
  payment_reference text,
  created_at        timestamptz default now()
);

alter table public.subscriptions enable row level security;
create policy "Users view own subscriptions"   on public.subscriptions for select using (auth.uid() = user_id);
create policy "Users insert own subscriptions" on public.subscriptions for insert with check (auth.uid() = user_id);
create policy "Users update own subscriptions" on public.subscriptions for update using (auth.uid() = user_id);

-- ============================================================
-- FCM TOKENS (for push notifications)
-- ============================================================
create table if not exists public.fcm_tokens (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  token      text not null unique,
  platform   text default 'web',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.fcm_tokens enable row level security;
create policy "Users manage own FCM tokens" on public.fcm_tokens
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- STORAGE BUCKETS
-- Run these separately in Supabase Dashboard > Storage
-- or via the Supabase CLI:
--   supabase storage create-bucket avatars --public
--   supabase storage create-bucket agreement-assets --public
--   supabase storage create-bucket campaign-assets --public
-- ============================================================

-- Storage RLS policies (run after creating buckets)
-- insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true);
-- insert into storage.buckets (id, name, public) values ('agreement-assets', 'agreement-assets', true);
-- insert into storage.buckets (id, name, public) values ('campaign-assets', 'campaign-assets', true);

-- create policy "Avatar upload" on storage.objects for insert
--   with check (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);
-- create policy "Avatar read"   on storage.objects for select using (bucket_id = 'avatars');
-- create policy "Agreement asset upload" on storage.objects for insert
--   with check (bucket_id = 'agreement-assets' and auth.role() = 'authenticated');
-- create policy "Agreement asset read"   on storage.objects for select using (bucket_id = 'agreement-assets');
-- create policy "Campaign asset upload"  on storage.objects for insert
--   with check (bucket_id = 'campaign-assets' and auth.role() = 'authenticated');
-- create policy "Campaign asset read"    on storage.objects for select using (bucket_id = 'campaign-assets');
