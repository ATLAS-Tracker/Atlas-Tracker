\set ON_ERROR_STOP on
-- Synthetic database only. Never run this fixture on a hosted project.
create role anon nologin;
create role authenticated nologin;
create schema auth;
create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql stable as
  $$select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid$$;
grant usage on schema auth, public to anon, authenticated;
grant execute on function auth.uid() to anon, authenticated;
create table public.users (
  id uuid primary key references auth.users(id),
  coach_id uuid references auth.users(id), role text not null default 'student',
  display_name text, height_cm float8, weight_kg float8,
  gender text, goal text, birthday date, pal text
);
create table public.fdc_food(fdc_id bigint primary key, description_fr text);
create table public.fdc_portions(id bigint primary key, fdc_id bigint, grams float8);
create table public.fdc_nutrients(id bigint primary key, fdc_id bigint, value float8);
grant all on public.fdc_food, public.fdc_portions, public.fdc_nutrients to anon, authenticated;
grant update(description_fr) on public.fdc_food to anon;
create table public.tracked_days (
  user_id uuid not null references auth.users(id), day date not null,
  "calorieGoal" float8 not null default 0, "caloriesTracked" float8 not null default 0,
  "carbsGoal" float8, "carbsTracked" float8, "fatGoal" float8, "fatTracked" float8,
  "proteinGoal" float8, "proteinTracked" float8, "caloriesBurned" float8 not null default 0,
  updated_at timestamptz not null default now(), primary key(user_id, day)
);
create table public.user_weight (
  user_id uuid not null references auth.users(id), id text not null,
  date date not null, weight float8 not null, updated_at timestamptz not null default now(),
  primary key(user_id, date)
);
create table public.coach_macro_goals (
  user_id uuid primary key references auth.users(id), start_date date not null,
  calorie_goal float8 not null, carb_goal float8 not null,
  fat_goal float8 not null, protein_goal float8 not null
);
insert into public.fdc_food values (1, 'Pomme');
insert into auth.users values
  ('00000000-0000-4000-8000-000000000001'),
  ('00000000-0000-4000-8000-000000000002'),
  ('00000000-0000-4000-8000-000000000003');
insert into public.users(id, role, coach_id) values
  ('00000000-0000-4000-8000-000000000001', 'student', '00000000-0000-4000-8000-000000000003'),
  ('00000000-0000-4000-8000-000000000002', 'student', null),
  ('00000000-0000-4000-8000-000000000003', 'coach', null);
