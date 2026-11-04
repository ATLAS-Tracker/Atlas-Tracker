-- Compatible with the deployed client: no table, column, key or webhook change.
-- Apply separately from lot6_integrity.sql, which requires a coordinated release.
begin;
set local lock_timeout='3s';
set local statement_timeout='15s';

do $preflight$
declare relation text;
begin
  foreach relation in array array['users','subscription','tracked_days','user_weight',
      'coach_macro_goals','daily_steps','user_devices','fdc_food','fdc_portions','fdc_nutrients'] loop
    if to_regclass('public.'||relation) is null then
      raise exception 'Missing table public.%: inspect before applying',relation;
    end if;
    if relation in ('users','subscription','tracked_days','user_weight','coach_macro_goals','user_devices')
        and not (select relrowsecurity from pg_class where oid=to_regclass('public.'||relation)) then
      raise exception 'Expected existing RLS on public.%',relation;
    end if;
  end loop;
end
$preflight$;

-- These DDL privileges are never needed for mobile CRUD or backend webhooks.
do $privileges$
declare relation text;
begin
  foreach relation in array array['users','subscription','tracked_days','user_weight',
      'coach_macro_goals','daily_steps','user_devices','fdc_food','fdc_portions','fdc_nutrients'] loop
    execute format('revoke truncate, references, trigger on public.%I from public,anon,authenticated',relation);
  end loop;
end
$privileges$;

-- Restrictive policies intersect with the existing subscription policies.
-- They do not replace or widen the existing permissive policies.
do $ownership$
declare relation text; coach_check text; writer_check text;
begin
  foreach relation in array array['user_weight','coach_macro_goals','user_devices'] loop
    coach_check := format('exists(select 1 from public.users student where student.id=%I.user_id and student.coach_id=(select auth.uid())) and exists(select 1 from public.users coach where coach.id=(select auth.uid()) and coach.role=''coach'')',relation);
    execute format('drop policy if exists atlas_compat_select on public.%I',relation);
    if relation='user_devices' then
      execute format('create policy atlas_compat_select on public.%I as restrictive for select to authenticated using ((select auth.uid())=user_id)',relation);
    else
      execute format('create policy atlas_compat_select on public.%I as restrictive for select to authenticated using ((select auth.uid())=user_id or (%s))',relation,coach_check);
    end if;
    writer_check := case when relation='coach_macro_goals' then coach_check else '(select auth.uid())=user_id' end;
    execute format('drop policy if exists atlas_compat_insert on public.%I',relation);
    execute format('create policy atlas_compat_insert on public.%I as restrictive for insert to authenticated with check (%s)',relation,writer_check);
    execute format('drop policy if exists atlas_compat_update on public.%I',relation);
    execute format('create policy atlas_compat_update on public.%I as restrictive for update to authenticated using (%s) with check (%s)',relation,writer_check,writer_check);
    execute format('drop policy if exists atlas_compat_delete on public.%I',relation);
    execute format('create policy atlas_compat_delete on public.%I as restrictive for delete to authenticated using (%s)',relation,writer_check);
  end loop;
end
$ownership$;

-- Echoing unchanged profile fields remains compatible with older clients.
-- Privileged backend/admin writes continue to work.
create or replace function public.atlas_guard_profile_authority() returns trigger
language plpgsql security invoker set search_path='' as $function$
begin
  if current_user in ('anon','authenticated') and (
      new.id is distinct from old.id or new.role is distinct from old.role
      or new.coach_id is distinct from old.coach_id
      or new.stripe_customer_id is distinct from old.stripe_customer_id) then
    raise exception 'Profile authority fields require backend access' using errcode='42501';
  end if;
  return new;
end
$function$;
revoke all on function public.atlas_guard_profile_authority() from public,anon,authenticated;
drop trigger if exists atlas_guard_profile_authority on public.users;
create trigger atlas_guard_profile_authority before update on public.users
  for each row execute function public.atlas_guard_profile_authority();

create or replace function public.revoke_user_sessions(uid uuid) returns void
language plpgsql security definer set search_path='' as $function$
begin
  -- The role setting remains the caller's role inside a SECURITY DEFINER call.
  if coalesce(current_setting('role',true),'') not in ('service_role','postgres','supabase_admin','none')
      and ((select auth.uid()) is null or uid is distinct from (select auth.uid())) then
    raise exception 'Only own sessions may be revoked' using errcode='42501';
  end if;
  delete from auth.sessions where user_id=uid;
end
$function$;
revoke all on function public.revoke_user_sessions(uuid) from public,anon;
grant execute on function public.revoke_user_sessions(uuid) to authenticated,service_role;

commit;
