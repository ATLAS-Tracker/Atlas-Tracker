-- Each security regression has its own rollback, so the baseline run shows
-- each failing category without leaving changes in the disposable fixture.
begin;
set local role anon;
select public.test_assert(not has_table_privilege('anon','public.fdc_food','INSERT'),'FDC anonymous write blocked');
select public.test_assert((select count(*)=2 from public.fdc_food),'FDC anonymous read retained');
select public.test_assert((select count(*)=1 from public.search_fdc_food('pate')),'actual French search RPC retained');
rollback;

begin;
set local role authenticated;
set local request.jwt.claim.sub='00000000-0000-4000-8000-000000000001';
select public.test_assert((select count(*)=1 from public.user_weight),'weight owner isolation');
do $$begin
  begin insert into public.user_weight(user_id,date,weight) values('00000000-0000-4000-8000-000000000002',current_date+1,90);
    raise exception 'foreign weight accepted'; exception when insufficient_privilege then null;end;
  update public.user_weight set weight=90 where user_id='00000000-0000-4000-8000-000000000002';
  if found then raise exception 'foreign weight update accepted';end if;
end$$;
set local request.jwt.claim.sub='00000000-0000-4000-8000-000000000003';
select public.test_assert((select count(*)=2 from public.user_weight),'coach reads assigned students only');
do $$begin
  update public.user_weight set weight=90 where user_id='00000000-0000-4000-8000-000000000001';
  if found then raise exception 'coach weight write accepted';end if;
end$$;
rollback;

begin;
set local role authenticated;
set local request.jwt.claim.sub='00000000-0000-4000-8000-000000000001';
select public.test_assert((select count(*)=1 from public.coach_macro_goals),'goal owner isolation');
do $$begin
  update public.coach_macro_goals set carb_goal=300 where user_id=auth.uid();
  if found then raise exception 'student goal write accepted';end if;
end$$;
set local request.jwt.claim.sub='00000000-0000-4000-8000-000000000003';
select public.test_assert((select count(*)=1 from public.coach_macro_goals),'coach goals limited to assigned students');
do $$begin
  begin insert into public.coach_macro_goals(user_id,start_date,calorie_goal,carb_goal,fat_goal,protein_goal)
    values('00000000-0000-4000-8000-000000000002',current_date,2000,250,60,115)
    on conflict(user_id) do update set carb_goal=300;
    raise exception 'unassigned goal upsert accepted';exception when insufficient_privilege then null;end;
end$$;
rollback;

begin;
set local role authenticated;
set local request.jwt.claim.sub='00000000-0000-4000-8000-000000000001';
select public.test_assert((select count(*)=1 from public.user_devices),'device owner isolation');
do $$begin
  update public.user_devices set fcm_token='hijack' where user_id='00000000-0000-4000-8000-000000000002';
  if found then raise exception 'foreign token update accepted';end if;
end$$;
rollback;

begin;
set local role authenticated;
set local request.jwt.claim.sub='00000000-0000-4000-8000-000000000001';
do $$begin
  begin update public.users set role='coach' where id=auth.uid();
    raise exception 'profile elevation accepted';exception when insufficient_privilege then null;end;
  begin update public.users set coach_id='00000000-0000-4000-8000-000000000004' where id=auth.uid();
    raise exception 'self-assignment accepted';exception when insufficient_privilege then null;end;
  begin update public.users set stripe_customer_id='hijack' where id=auth.uid();
    raise exception 'billing reassignment accepted';exception when insufficient_privilege then null;end;
end$$;
rollback;

begin;
select public.test_assert(not has_function_privilege('anon','public.revoke_user_sessions(uuid)','EXECUTE'),'anonymous session revocation denied');
set local role authenticated;
set local request.jwt.claim.sub='00000000-0000-4000-8000-000000000001';
do $$begin
  begin perform public.revoke_user_sessions('00000000-0000-4000-8000-000000000002');
    raise exception 'foreign session revocation accepted';exception when insufficient_privilege then null;end;
end$$;
select public.revoke_user_sessions(auth.uid());
reset role;
select public.test_assert((select count(*)=4 from auth.sessions),'self-revocation changes only own sessions');
set local role service_role;
select public.revoke_user_sessions('00000000-0000-4000-8000-000000000002');
reset role;
select public.test_assert((select count(*)=3 from auth.sessions),'backend revocation retained');
rollback;

begin;
-- Deployed payloads and conflict keys, including notification execution.
set local role authenticated;
set local request.jwt.claim.sub='00000000-0000-4000-8000-000000000001';
insert into public.user_weight(user_id,date,weight,updatedat) values(auth.uid(),current_date,81,now())
  on conflict(user_id,date) do update set weight=excluded.weight,updatedat=excluded.updatedat;
select public.test_assert((select weight=81 from public.user_weight where user_id=auth.uid()),'owner weight upsert retained');
delete from public.user_weight where user_id=auth.uid();
select public.test_assert((select count(*)=0 from public.user_weight where user_id=auth.uid()),'owner weight delete retained');
update public.users set role=role,coach_id=coach_id,height_cm=181,weight_kg=81,gender='male',
  goal='maintainWeight',pal='active',birthday='2000-01-01',display_name='Profil' where id=auth.uid();
select public.test_assert((select height_cm=181 from public.users where id=auth.uid()),'profile editing and echoed metadata retained');
insert into public.user_devices(user_id,fcm_token) values(auth.uid(),'refreshed-token')
  on conflict(user_id) do update set fcm_token=excluded.fcm_token;
select public.test_assert((select fcm_token='refreshed-token' from public.user_devices where user_id=auth.uid()),'FCM token refresh retained');
insert into public.tracked_days(user_id,day,"calorieGoal","caloriesTracked") values(auth.uid(),current_date,2000,1500)
  on conflict(user_id,day) do update set "caloriesTracked"=excluded."caloriesTracked";
select public.test_assert((select "caloriesTracked"=1500 from public.tracked_days where user_id=auth.uid()),'existing day sync retained');
set local request.jwt.claim.sub='00000000-0000-4000-8000-000000000003';
insert into public.coach_macro_goals(user_id,start_date,calorie_goal,carb_goal,fat_goal,protein_goal)
  values('00000000-0000-4000-8000-000000000001',current_date,2100,275,60,115)
  on conflict(user_id) do update set calorie_goal=excluded.calorie_goal,carb_goal=excluded.carb_goal;
insert into public.coach_macro_goals(user_id,start_date,calorie_goal,carb_goal,fat_goal,protein_goal)
  values('00000000-0000-4000-8000-000000000005',current_date+1,2000,250,60,115)
  on conflict(user_id) do update set calorie_goal=excluded.calorie_goal;
select public.test_assert((select carb_goal=275 from public.coach_macro_goals where user_id='00000000-0000-4000-8000-000000000001'),'legacy coach upsert on user_id retained');
reset role;
select public.test_assert((select count(*)=2 from public.test_notifications),'notification triggers retained');
set local role service_role;
select public.test_assert((select count(*)=5 from public.user_devices),'backend notification token reads retained');
update public.users set stripe_customer_id='backend-customer' where id='00000000-0000-4000-8000-000000000001';
reset role;
select public.test_assert((select stripe_customer_id='backend-customer' from public.users where id='00000000-0000-4000-8000-000000000001'),'backend billing updates retained');
set local role authenticated;
set local request.jwt.claim.sub='00000000-0000-4000-8000-000000000005';
select public.test_assert((select count(*)=0 from public.user_weight),'unsubscribed user still denied');
select public.test_assert((select count(*)=0 from public.coach_macro_goals),'unsubscribed goals still denied');
reset role;
update public.subscription set is_subscribed=false where id='00000000-0000-4000-8000-000000000003';
set local role authenticated;
set local request.jwt.claim.sub='00000000-0000-4000-8000-000000000003';
select public.test_assert((select count(*)=0 from public.coach_macro_goals),'unsubscribed coach still denied');
rollback;

begin;
select public.test_assert(not exists(select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relkind='r' and c.relname<>'test_notifications'
    and (has_table_privilege('anon',c.oid,'TRUNCATE') or has_table_privilege('authenticated',c.oid,'TRUNCATE'))),'client TRUNCATE privileges removed');
rollback;
