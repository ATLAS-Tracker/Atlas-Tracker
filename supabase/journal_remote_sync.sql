-- Row-based sync tables for Atlas-Tracker Hive-backed journal data.
-- Apply this in Supabase SQL editor before relying on journal/recipe sync.

create table if not exists public.user_intakes (
  user_id uuid not null references auth.users(id) on delete cascade,
  record_id text not null,
  payload jsonb not null,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  primary key (user_id, record_id)
);

create table if not exists public.user_recipes (
  user_id uuid not null references auth.users(id) on delete cascade,
  record_id text not null,
  payload jsonb not null,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  primary key (user_id, record_id)
);

create index if not exists user_intakes_user_updated_at_idx
  on public.user_intakes (user_id, updated_at desc);

create index if not exists user_recipes_user_updated_at_idx
  on public.user_recipes (user_id, updated_at desc);

alter table public.user_intakes enable row level security;
alter table public.user_recipes enable row level security;

drop policy if exists "Users can read own intakes" on public.user_intakes;
create policy "Users can read own intakes"
  on public.user_intakes for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own intakes" on public.user_intakes;
create policy "Users can insert own intakes"
  on public.user_intakes for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own intakes" on public.user_intakes;
create policy "Users can update own intakes"
  on public.user_intakes for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own intakes" on public.user_intakes;
create policy "Users can delete own intakes"
  on public.user_intakes for delete
  using (auth.uid() = user_id);

drop policy if exists "Users can read own recipes" on public.user_recipes;
create policy "Users can read own recipes"
  on public.user_recipes for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own recipes" on public.user_recipes;
create policy "Users can insert own recipes"
  on public.user_recipes for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own recipes" on public.user_recipes;
create policy "Users can update own recipes"
  on public.user_recipes for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own recipes" on public.user_recipes;
create policy "Users can delete own recipes"
  on public.user_recipes for delete
  using (auth.uid() = user_id);
