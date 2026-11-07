-- Read-only role emulation. No production row or session is changed.
-- Run as an administrator, optionally inside the hardening transaction.
do $read_checks$
declare subject record; subscribed boolean; expected_weights bigint; actual_weights bigint;
  expected_goals bigint; actual_goals bigint; expected_devices bigint; actual_devices bigint;
  expected_profile bigint; actual_profile bigint;
  original_subject text := current_setting('request.jwt.claim.sub',true);
  original_role text := current_setting('role',true);
begin
  for subject in select id,role from public.users loop
    select coalesce((select is_subscribed from public.subscription where id=subject.id),false) into subscribed;
    select count(*) into expected_weights from public.user_weight w where subscribed and
      (w.user_id=subject.id or (subject.role='coach' and exists(select 1 from public.users s where s.id=w.user_id and s.coach_id=subject.id)));
    select count(*) into expected_goals from public.coach_macro_goals g where subscribed and
      (g.user_id=subject.id or (subject.role='coach' and exists(select 1 from public.users s where s.id=g.user_id and s.coach_id=subject.id)));
    select count(*) into expected_devices from public.user_devices where subscribed and user_id=subject.id;
    expected_profile := case when subscribed then 1 else 0 end;
    perform set_config('request.jwt.claim.sub',subject.id::text,true);
    execute 'set local role authenticated';
    if current_user <> 'authenticated' then raise exception 'Role emulation failed';end if;
    select count(*) into actual_weights from public.user_weight;
    select count(*) into actual_goals from public.coach_macro_goals;
    select count(*) into actual_devices from public.user_devices;
    select count(*) into actual_profile from public.users where id=subject.id;
    execute 'reset role';
    if (actual_weights,actual_goals,actual_devices,actual_profile) is distinct from
        (expected_weights,expected_goals,expected_devices,expected_profile) then
      raise exception 'Read scope regression: expected %, got %',
        row(expected_weights,expected_goals,expected_devices,expected_profile),
        row(actual_weights,actual_goals,actual_devices,actual_profile);
    end if;
  end loop;
  perform set_config('request.jwt.claim.sub',coalesce(original_subject,''),true);
  if original_role='none' then execute 'reset role';
  else execute format('set local role %I',original_role);end if;
exception when others then
  execute 'reset role';
  perform set_config('request.jwt.claim.sub',coalesce(original_subject,''),true);
  raise;
end
$read_checks$;
