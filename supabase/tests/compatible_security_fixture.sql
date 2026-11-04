-- Synthetic isolated cluster only; never execute on a hosted project.
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;
create schema auth;
create schema extensions;
create table auth.users(id uuid primary key);
create table auth.sessions(id text primary key,user_id uuid references auth.users(id));
create function auth.uid() returns uuid language sql stable as
  $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
grant usage on schema public,auth to anon,authenticated,service_role;
grant execute on function auth.uid() to anon,authenticated,service_role;
create table public.users(id uuid primary key references auth.users(id),role text not null,
  coach_id uuid references public.users(id),display_name text,height_cm numeric(5,2),weight_kg numeric(5,2),
  gender text,goal text,birthday date,pal text,stripe_customer_id text);
create table public.subscription(id uuid primary key references public.users(id),is_subscribed boolean not null);
create table public.user_weight(id uuid default gen_random_uuid(),user_id uuid not null default auth.uid(),
  date date not null,weight numeric(5,2) not null,updatedat timestamptz default now(),primary key(user_id,date));
create table public.tracked_days(user_id uuid not null default auth.uid(),day date not null,
  "calorieGoal" float8 not null,"caloriesTracked" float8 not null,"carbsGoal" float8,
  "carbsTracked" float8,"fatGoal" float8,"fatTracked" float8,"proteinGoal" float8,
  "proteinTracked" float8,"caloriesBurned" float8,updated_at timestamptz default now(),primary key(user_id,day));
create table public.coach_macro_goals(user_id uuid primary key references public.users(id),
  start_date date not null,calorie_goal int not null,carb_goal int not null,fat_goal int not null,
  protein_goal int not null,updated_at timestamptz default now());
create table public.user_devices(user_id uuid primary key references public.users(id),fcm_token text);
create table public.daily_steps(user_id uuid,date date,steps int,primary key(user_id,date));
create table public.fdc_food(fdc_id bigint primary key,description_fr text);
create table public.fdc_nutrients(fdc_id bigint references public.fdc_food(fdc_id),nutrient_id bigint,amount numeric);
create table public.fdc_portions(fdc_id bigint references public.fdc_food(fdc_id),measure_unit_id bigint,amount numeric,gram_weight bigint);
grant all on all tables in schema public to anon,authenticated,service_role;
grant all on all tables in schema auth to service_role;
alter table public.users enable row level security;
alter table public.subscription enable row level security;
alter table public.user_weight enable row level security;
alter table public.tracked_days enable row level security;
alter table public.coach_macro_goals enable row level security;
alter table public.user_devices enable row level security;
create policy subscription_self on public.subscription for select using (auth.uid()=id);
create policy users_self on public.users for select using(auth.uid()=id and exists(select 1 from public.subscription s where s.id=auth.uid() and s.is_subscribed));
create policy users_coach on public.users for select using(coach_id=auth.uid() and exists(select 1 from public.subscription s where s.id=auth.uid() and s.is_subscribed));
create policy users_update on public.users for update using(auth.uid()=id);
create policy weight_legacy on public.user_weight for all using(exists(select 1 from public.subscription s where s.id=auth.uid() and s.is_subscribed));
create policy devices_legacy on public.user_devices for all using(exists(select 1 from public.subscription s where s.id=auth.uid() and s.is_subscribed));
create policy goal_read on public.coach_macro_goals for select using(exists(select 1 from public.subscription s where s.id=auth.uid() and s.is_subscribed));
create policy goal_insert on public.coach_macro_goals for insert with check(exists(select 1 from public.subscription s where s.id=auth.uid() and s.is_subscribed));
create policy goal_update on public.coach_macro_goals for update using(exists(select 1 from public.subscription s where s.id=auth.uid() and s.is_subscribed));
create policy days_owner on public.tracked_days for all using(auth.uid()=user_id and exists(select 1 from public.subscription s where s.id=auth.uid() and s.is_subscribed));
create policy days_coach on public.tracked_days for select using(exists(select 1 from public.users u where u.id=user_id and u.coach_id=auth.uid()) and exists(select 1 from public.subscription s where s.id=auth.uid() and s.is_subscribed));
create or replace function public.revoke_user_sessions(uid uuid) returns void
  language sql security definer as $$delete from auth.sessions where user_id=uid$$;
grant execute on function public.revoke_user_sessions(uuid) to anon,authenticated,service_role;
-- 1=student A, 2=student B, 3=coach A, 4=coach B, 5=unsubscribed student.
insert into auth.users select ('00000000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid from generate_series(1,5) i;
insert into public.users(id,role) select id,case when right(id::text,1) in ('3','4') then 'coach' else 'student' end from auth.users;
update public.users set coach_id='00000000-0000-4000-8000-000000000003' where right(id::text,1) in ('1','5');
update public.users set coach_id='00000000-0000-4000-8000-000000000004' where right(id::text,1)='2';
insert into public.subscription select id,right(id::text,1)<>'5' from auth.users;
insert into public.user_weight(user_id,date,weight) select id,current_date,80 from public.users where role='student';
insert into public.user_devices select id,'synthetic-token' from public.users;
insert into auth.sessions select id::text,id from auth.users;
insert into public.coach_macro_goals values('00000000-0000-4000-8000-000000000001',current_date,2000,250,60,115,now()),
  ('00000000-0000-4000-8000-000000000002',current_date,2000,250,60,115,now());
insert into public.fdc_food values(1,'Pâte'),(2,'Pomme');
create table public.test_notifications(user_id uuid,event text);
revoke all on public.test_notifications from anon,authenticated;
create function public.test_notify() returns trigger language plpgsql security definer set search_path='' as
  $$begin insert into public.test_notifications values(new.user_id,tg_op);return new;end$$;
create trigger "send notification" after insert or update on public.coach_macro_goals for each row execute function public.test_notify();
create function public.test_assert(ok boolean,label text) returns void language plpgsql as
  $$begin if ok is distinct from true then raise exception 'ASSERT: %',label;end if;end$$;
