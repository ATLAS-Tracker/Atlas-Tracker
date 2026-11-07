-- LOCAL VALIDATION ONLY. Apply journal_remote_sync.sql first.
-- Production schema inspection and explicit approval are required before use.
-- WARNING: drops EVERY existing policy on user_intakes, user_recipes,
-- user_weight, tracked_days and coach_macro_goals (including atlas_compat_*
-- from production_compatible_security.sql and those from
-- journal_remote_sync.sql) and replaces them with the atlas_* policies below.
begin;

-- A legacy global unique day/date would prevent two users sharing a date.
-- Abort rather than dropping an unknown production constraint automatically.
do $preflight$
declare relation text; date_column text;
begin
  for relation, date_column in values ('tracked_days', 'day'), ('user_weight', 'date') loop
    if exists (
      select 1 from pg_index i join pg_attribute a
        on a.attrelid = i.indrelid and a.attnum = i.indkey[0]
      where i.indrelid = to_regclass('public.' || relation)
        and i.indisunique and i.indnkeyatts = 1 and a.attname = date_column
    ) then
      raise exception 'Review global unique %.% before this migration', relation, date_column;
    end if;
  end loop;
end
$preflight$;

create unique index if not exists atlas_days_owner_day on public.tracked_days(user_id, day);
create unique index if not exists atlas_weights_owner_date on public.user_weight(user_id, date);

do $columns$
declare relation text;
begin
  foreach relation in array array['user_intakes','user_recipes','user_weight','tracked_days'] loop
    execute format('alter table public.%I add column if not exists updated_at timestamptz not null default now()', relation);
    execute format('alter table public.%I add column if not exists modified_at timestamptz', relation);
    execute format('alter table public.%I add column if not exists deleted_at timestamptz', relation);
    execute format('update public.%I set modified_at = updated_at where modified_at is null', relation);
    execute format('alter table public.%I alter column modified_at set not null', relation);
    execute format('alter table public.%I alter column modified_at drop default', relation);
    execute format('alter table public.%I enable row level security', relation);
    execute format('revoke all on public.%I from public, anon', relation);
    execute format('revoke delete, truncate, references, trigger on public.%I from authenticated', relation);
    execute format('grant select, insert, update on public.%I to authenticated', relation);
  end loop;
  if exists(select 1 from information_schema.columns where table_schema='public'
      and table_name='user_weight' and column_name='updatedat') then
    alter table public.user_weight alter column updatedat set default now();
  end if;
end
$columns$;

-- Preserve every effective date; scheduling C must not replace current B.
alter table public.coach_macro_goals add column if not exists id uuid default gen_random_uuid();
alter table public.coach_macro_goals add column if not exists updated_at timestamptz not null default now();
do $history$
declare constraint_name text;
begin
  for constraint_name in
    select c.conname from pg_constraint c join pg_attribute a
      on a.attrelid=c.conrelid and a.attnum=c.conkey[1]
    where c.conrelid='public.coach_macro_goals'::regclass
      and c.contype in ('p','u') and cardinality(c.conkey)=1 and a.attname='user_id'
  loop
    execute format('alter table public.coach_macro_goals drop constraint %I', constraint_name);
  end loop;
  if exists(select 1 from pg_index i join pg_attribute a on a.attrelid=i.indrelid and a.attnum=i.indkey[0]
      where i.indrelid='public.coach_macro_goals'::regclass and i.indisunique
        and i.indnkeyatts=1 and a.attname='user_id') then
    raise exception 'Review remaining unique user_id index on coach_macro_goals';
  end if;
end
$history$;
create unique index if not exists atlas_goals_owner_start on public.coach_macro_goals(user_id,start_date);
create unique index if not exists atlas_goals_id on public.coach_macro_goals(id);

create or replace function public.atlas_is_coach(student uuid) returns boolean
language sql stable security definer set search_path='' as $fn$
  select exists(select 1 from public.users s join public.users c on c.id=s.coach_id
    where s.id=student and c.id=(select auth.uid()) and c.role='coach')
$fn$;
revoke all on function public.atlas_is_coach(uuid) from public, anon;
grant execute on function public.atlas_is_coach(uuid) to authenticated;

do $policies$
declare relation text; policy_name text;
begin
  foreach relation in array array['user_intakes','user_recipes','user_weight','tracked_days','coach_macro_goals'] loop
    -- Replace permissive old policies; no old write policy may widen access.
    for policy_name in select policyname from pg_policies where schemaname='public' and tablename=relation loop
      execute format('drop policy %I on public.%I',policy_name,relation);
    end loop;
    execute format('alter table public.%I enable row level security',relation);
    execute format('create policy atlas_read on public.%I for select to authenticated using ((select auth.uid())=user_id or public.atlas_is_coach(user_id))',relation);
    if relation <> 'coach_macro_goals' then
      execute format('create policy atlas_insert on public.%I for insert to authenticated with check ((select auth.uid())=user_id)',relation);
      execute format('create policy atlas_update on public.%I for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id)',relation);
    end if;
  end loop;
end
$policies$;
revoke all on public.coach_macro_goals from public,anon,authenticated;
grant select on public.coach_macro_goals to authenticated;

-- A profile owner must not be able to assign their coach or elevate their role.
revoke insert,update,delete,truncate,references,trigger on public.users from public,anon,authenticated;
do $profile_columns$
declare column_name text;
begin
  for column_name in select attname from pg_attribute where attrelid='public.users'::regclass
      and attnum>0 and not attisdropped loop
    execute format('revoke insert (%I),update (%I),references (%I) on public.users from public,anon,authenticated',
      column_name,column_name,column_name);
  end loop;
end
$profile_columns$;
grant update(height_cm,weight_kg,gender,goal,birthday,pal) on public.users to authenticated;

create or replace function public.atlas_valid_meal(meal jsonb) returns boolean
language plpgsql immutable set search_path='' as $fn$
declare field text; value numeric;
begin
  if jsonb_typeof(meal) is distinct from 'object' or jsonb_typeof(meal->'nutriments') is distinct from 'object' then return false; end if;
  if jsonb_typeof(meal->'nutriments'->'energyKcalPerQuantity') is distinct from 'number' then return false; end if;
  foreach field in array array['energyKcalPerQuantity','carbohydratesPerQuantity','fatPerQuantity',
      'proteinsPerQuantity','sugarsPerQuantity','saturatedFatPerQuantity','fiberPerQuantity'] loop
    if meal->'nutriments'->field is not null and meal->'nutriments'->field <> 'null'::jsonb then
      if jsonb_typeof(meal->'nutriments'->field) is distinct from 'number' then return false; end if;
      value := (meal->'nutriments'->>field)::numeric;
      if value < 0 or value > (case when field='energyKcalPerQuantity' then 1000000 else 100000 end) then return false; end if;
    end if;
  end loop;
  if meal->>'servingQuantity' is not null and
      not ((meal->>'servingQuantity')::numeric > 0 and (meal->>'servingQuantity')::numeric <= 100000) then return false; end if;
  return true;
exception when others then return false;
end
$fn$;

create or replace function public.atlas_accept_sync_version() returns trigger
language plpgsql security definer set search_path='' as $fn$
declare ingredient jsonb; amount numeric;
begin
  if new.modified_at is null or new.modified_at < '1970-01-01'::timestamptz
      or new.modified_at > clock_timestamp()+interval '5 minutes' then
    raise exception 'Invalid modification version' using errcode='22023';
  end if;
  if tg_op='UPDATE' then
    if new.modified_at <= old.modified_at then return null; end if;
    if tg_table_name='user_weight' then new.id := old.id; end if;
  end if;
  if tg_table_name='user_weight' then
    if new.date < date '2000-01-01' or new.date > current_date+730 or
        (new.deleted_at is null and not(new.weight>0 and new.weight<=400)) then
      raise exception 'Invalid weight' using errcode='22023';
    end if;
  elsif new.deleted_at is null then
    if length(new.record_id)=0 or length(new.record_id)>256 or octet_length(new.payload::text)>262144 then
      raise exception 'Invalid record' using errcode='22023';
    end if;
    if tg_table_name='user_intakes' then
      amount := (new.payload->>'amount')::numeric;
      if new.payload->>'id' is distinct from new.record_id or amount is null or amount<=0 or amount>100000
          or jsonb_typeof(new.payload->'amount') is distinct from 'number'
          or new.payload->>'unit' is null or new.payload->>'unit' not in ('g','ml','serving')
          or new.payload->>'dateTime' is null
          or (new.payload->>'dateTime')::date < date '2000-01-01'
          or (new.payload->>'dateTime')::date > current_date+730
          or not public.atlas_valid_meal(new.payload->'meal') then
        raise exception 'Invalid intake' using errcode='22023';
      end if;
      new.payload := jsonb_set(new.payload,'{updatedAt}',to_jsonb(new.modified_at::text));
    else
      if coalesce(new.payload->'recipe'->>'code',new.payload->'recipe'->>'name') is distinct from new.record_id
          or not public.atlas_valid_meal(new.payload->'recipe')
          or jsonb_typeof(new.payload->'ingredients') is distinct from 'array' then
        raise exception 'Invalid saved food or recipe' using errcode='22023';
      end if;
      for ingredient in select jsonb_array_elements(new.payload->'ingredients') loop
        if ingredient->>'amount' is null or not((ingredient->>'amount')::numeric>0 and (ingredient->>'amount')::numeric<=100000)
            or not public.atlas_valid_meal(ingredient->'meal') then
          raise exception 'Invalid ingredient' using errcode='22023';
        end if;
      end loop;
      new.payload := jsonb_set(new.payload,'{updated_at}',to_jsonb(new.modified_at::text));
    end if;
  end if;
  new.updated_at := clock_timestamp();
  if new.deleted_at is not null then new.deleted_at := new.updated_at; end if;
  if to_jsonb(new) ? 'updatedat' then
    new := jsonb_populate_record(new,jsonb_build_object('updatedat',new.updated_at));
  end if;
  return new;
end
$fn$;

create or replace function public.atlas_project_day() returns trigger
language plpgsql security definer set search_path='' as $fn$
declare totals record; goal record;
begin
  if new.day < date '2000-01-01' or new.day > current_date+730 then
    raise exception 'Invalid day' using errcode='22023';
  end if;
  select coalesce(sum(qty*coalesce((nutrients->>'energyKcalPerQuantity')::float8,0)/scale),0) kcal,
      coalesce(sum(qty*coalesce((nutrients->>'carbohydratesPerQuantity')::float8,0)/scale),0) carbs,
      coalesce(sum(qty*coalesce((nutrients->>'fatPerQuantity')::float8,0)/scale),0) fat,
      coalesce(sum(qty*coalesce((nutrients->>'proteinsPerQuantity')::float8,0)/scale),0) protein into totals
  from (select (payload->>'amount')::float8 * case when payload->>'unit'='serving'
      then coalesce((payload->'meal'->>'servingQuantity')::float8,1) else 1 end qty,
      payload->'meal'->'nutriments' nutrients,
      case when payload->'meal'->'nutriments'->>'mealOrRecipe'='recipe' then 1 else 100 end scale
    from public.user_intakes where user_id=new.user_id and deleted_at is null
      and (payload->>'dateTime')::date=new.day) source;
  if not(totals.kcal between 0 and 100000 and totals.carbs between 0 and 25000
      and totals.fat between 0 and 25000 and totals.protein between 0 and 25000) then
    raise exception 'Implausible daily total' using errcode='22023';
  end if;
  new."caloriesTracked":=totals.kcal; new."carbsTracked":=totals.carbs;
  new."fatTracked":=totals.fat; new."proteinTracked":=totals.protein;
  select * into goal from public.coach_macro_goals where user_id=new.user_id and start_date<=new.day
    order by start_date desc,updated_at desc limit 1;
  if found then
    new."calorieGoal":=goal.carb_goal*4+goal.fat_goal*9+goal.protein_goal*4;
    new."carbsGoal":=goal.carb_goal; new."fatGoal":=goal.fat_goal; new."proteinGoal":=goal.protein_goal;
  end if;
  if not(new."calorieGoal" between 0 and 10000 and new."caloriesBurned" between 0 and 100000)
      or coalesce(new."carbsGoal",0) not between 0 and 1000
      or coalesce(new."fatGoal",0) not between 0 and 1000
      or coalesce(new."proteinGoal",0) not between 0 and 1000 then
    raise exception 'Invalid day goals' using errcode='22023';
  end if;
  if new.modified_at is null or new.modified_at > clock_timestamp()+interval '5 minutes' then
    raise exception 'Invalid day version' using errcode='22023';
  end if;
  if tg_op='UPDATE' then new.modified_at:=greatest(new.modified_at,old.modified_at); end if;
  new.updated_at:=clock_timestamp();
  return new;
end
$fn$;

create or replace function public.atlas_intake_projects_days() returns trigger
language plpgsql security definer set search_path='' as $fn$
declare selected_day date; previous_day date;
begin
  selected_day:=(new.payload->>'dateTime')::date;
  if tg_op='UPDATE' then previous_day:=(old.payload->>'dateTime')::date; end if;
  for selected_day in select distinct d from unnest(array[selected_day,previous_day]) d where d is not null loop
    insert into public.tracked_days(user_id,day,modified_at) values(new.user_id,selected_day,clock_timestamp())
      on conflict(user_id,day) do update set modified_at=clock_timestamp();
  end loop;
  return null;
end
$fn$;

do $triggers$
declare relation text;
begin
  foreach relation in array array['user_intakes','user_recipes','user_weight'] loop
    execute format('drop trigger if exists atlas_sync_version on public.%I',relation);
    execute format('create trigger atlas_sync_version before insert or update on public.%I for each row execute function public.atlas_accept_sync_version()',relation);
  end loop;
end
$triggers$;
drop trigger if exists atlas_project_day on public.tracked_days;
create trigger atlas_project_day before insert or update on public.tracked_days for each row execute function public.atlas_project_day();
drop trigger if exists atlas_intake_projects_days on public.user_intakes;
create trigger atlas_intake_projects_days after insert or update on public.user_intakes for each row execute function public.atlas_intake_projects_days();

create or replace function public.atlas_set_macro_goal(p_user_id uuid,p_start_date date,
    p_carb_goal integer,p_fat_goal integer,p_protein_goal integer) returns jsonb
language plpgsql security definer set search_path='' as $fn$
declare saved public.coach_macro_goals;
begin
  if auth.uid() is null or not public.atlas_is_coach(p_user_id) then
    raise exception 'Coach assignment required' using errcode='42501';
  end if;
  if p_start_date is null or p_carb_goal is null or p_fat_goal is null or p_protein_goal is null
      or p_start_date < (now() at time zone 'Europe/Paris')::date or p_start_date > current_date+730
      or p_carb_goal not between 0 and 1000 or p_fat_goal not between 0 and 1000
      or p_protein_goal not between 0 and 1000
      or (p_carb_goal*4+p_fat_goal*9+p_protein_goal*4) not between 1 and 10000 then
    raise exception 'Invalid macro goal' using errcode='22023';
  end if;
  insert into public.coach_macro_goals(user_id,start_date,carb_goal,fat_goal,protein_goal,calorie_goal,updated_at)
    values(p_user_id,p_start_date,p_carb_goal,p_fat_goal,p_protein_goal,
      p_carb_goal*4+p_fat_goal*9+p_protein_goal*4,clock_timestamp())
    on conflict(user_id,start_date) do update set carb_goal=excluded.carb_goal,fat_goal=excluded.fat_goal,
      protein_goal=excluded.protein_goal,calorie_goal=excluded.calorie_goal,updated_at=clock_timestamp()
    returning * into saved;
  update public.tracked_days set modified_at=clock_timestamp() where user_id=p_user_id and day>=p_start_date;
  return to_jsonb(saved);
end
$fn$;
revoke all on function public.atlas_valid_meal(jsonb),public.atlas_accept_sync_version(),
    public.atlas_project_day(),public.atlas_intake_projects_days() from public,anon,authenticated;
revoke all on function public.atlas_set_macro_goal(uuid,date,integer,integer,integer) from public,anon;
grant execute on function public.atlas_set_macro_goal(uuid,date,integer,integer,integer) to authenticated;
commit;
