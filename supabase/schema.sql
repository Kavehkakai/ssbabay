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
