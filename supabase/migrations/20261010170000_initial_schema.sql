-- Initial database schema for ssbabay: live votes, guest wishes, quiz entries and admin membership.
-- This migration is intentionally idempotent so it can be applied to a project where schema.sql was run manually.
-- Run in Supabase SQL Editor to enable shared real-time voting, quiz scores and wishes.
create table if not exists public.votes (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) <= 60),
  team text not null check (team in ('boy','girl')),
  weight numeric not null check (weight between 2 and 5),
  day integer not null check (day between 1 and 31),
  baby_name text not null default '' check (char_length(baby_name) <= 50),
  created_at timestamptz not null default now()
);
create table if not exists public.wishes (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) <= 60),
  message text not null check (char_length(message) <= 1200),
  created_at timestamptz not null default now()
);
create table if not exists public.quiz_entries (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) <= 60),
  score integer not null check (score between 0 and 10),
  created_at timestamptz not null default now()
);

alter table public.votes enable row level security;
alter table public.wishes enable row level security;
alter table public.quiz_entries enable row level security;

drop policy if exists "public read votes" on public.votes;
create policy "public read votes" on public.votes for select to anon, authenticated using (true);
drop policy if exists "public submit votes" on public.votes;
create policy "public submit votes" on public.votes for insert to anon, authenticated with check (true);
drop policy if exists "public read wishes" on public.wishes;
create policy "public read wishes" on public.wishes for select to anon, authenticated using (true);
drop policy if exists "public submit wishes" on public.wishes;
create policy "public submit wishes" on public.wishes for insert to anon, authenticated with check (true);
drop policy if exists "public read quiz entries" on public.quiz_entries;
create policy "public read quiz entries" on public.quiz_entries for select to anon, authenticated using (true);
drop policy if exists "public submit quiz entries" on public.quiz_entries;
create policy "public submit quiz entries" on public.quiz_entries for insert to anon, authenticated with check (true);

do $$ begin alter publication supabase_realtime add table public.votes; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.wishes; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.quiz_entries; exception when duplicate_object then null; end $$;

-- Admin access: create the Auth user first, then insert that user's UUID below.
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;
drop policy if exists "admins can read own admin membership" on public.admin_users;
create policy "admins can read own admin membership"
  on public.admin_users for select to authenticated
  using (auth.uid() = user_id);

-- Destructive actions are restricted to users explicitly listed in admin_users.
drop policy if exists "admins can delete votes" on public.votes;
create policy "admins can delete votes" on public.votes for delete to authenticated
  using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));
drop policy if exists "admins can delete wishes" on public.wishes;
create policy "admins can delete wishes" on public.wishes for delete to authenticated
  using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));
drop policy if exists "admins can delete quiz entries" on public.quiz_entries;
create policy "admins can delete quiz entries" on public.quiz_entries for delete to authenticated
  using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));
