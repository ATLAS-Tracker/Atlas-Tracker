\set ON_ERROR_STOP on
begin;
set local timezone='Europe/Paris';
create function public.atlas_test_assert(ok boolean, message text) returns void
language plpgsql as $$begin if ok is distinct from true then raise exception 'ASSERT: %',message; end if; end$$;
create function public.atlas_test_intake(id text, amount numeric, day date) returns jsonb
language sql immutable as $$select jsonb_build_object('id',id,'amount',amount,'unit','g','type','lunch',
  'dateTime',day::text,'meal',jsonb_build_object('code','food','name','Aliment test','source','custom',
    'mealUnit','g','servingQuantity',null,'nutriments',jsonb_build_object('energyKcalPerQuantity',200,
      'carbohydratesPerQuantity',20,'fatPerQuantity',10,'proteinsPerQuantity',15,'mealOrRecipe','meal')))$$;

do $$declare relation text; actor text; privilege text;
begin
  foreach relation in array array['fdc_food','fdc_portions','fdc_nutrients'] loop
    foreach actor in array array['anon','authenticated'] loop
      perform public.atlas_test_assert(has_table_privilege(actor,'public.'||relation,'SELECT'),'food read granted');
      foreach privilege in array array['INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER'] loop
        perform public.atlas_test_assert(not has_table_privilege(actor,'public.'||relation,privilege),'food write privilege revoked');
      end loop;
    end loop;
  end loop;
  perform public.atlas_test_assert(not has_column_privilege('anon','public.fdc_food','description_fr','UPDATE'),'column grant revoked');
end$$;

set local role anon;
select public.atlas_test_assert((select count(*)=1 from public.fdc_food),'anonymous food read');
do $$begin
  begin insert into public.fdc_food values(2,'Forbidden'); raise exception 'anonymous insert allowed';
    exception when insufficient_privilege then null; end;
  begin update public.fdc_food set description_fr='Forbidden'; raise exception 'anonymous column update allowed';
    exception when insufficient_privilege then null; end;
  begin truncate public.fdc_food; raise exception 'anonymous truncate allowed';
    exception when insufficient_privilege then null; end;
  begin perform * from public.user_intakes; raise exception 'anonymous journal read allowed';
    exception when insufficient_privilege then null; end;
end$$;
reset role;

set local role authenticated;
set local request.jwt.claim.sub='00000000-0000-4000-8000-000000000001';
insert into public.user_intakes(user_id,record_id,payload,modified_at,updated_at)
 values(auth.uid(),'intake',public.atlas_test_intake('intake',100,current_date),
   clock_timestamp()-interval '5 seconds','1900-01-01');
select public.atlas_test_assert((select "caloriesTracked"=200 and "proteinTracked"=15
  from public.tracked_days where day=current_date),'server totals derive from intakes');
select public.atlas_test_assert((select updated_at>now()-interval '1 minute' from public.user_intakes
  where record_id='intake'),'updated_at is server supplied');
update public.user_intakes set payload=public.atlas_test_intake('intake',150,current_date),modified_at=clock_timestamp()
  where record_id='intake';
update public.user_intakes set payload=public.atlas_test_intake('intake',75,current_date),modified_at=now()-interval '1 day'
  where record_id='intake';
select public.atlas_test_assert((select (payload->>'amount')::numeric=150 from public.user_intakes
  where record_id='intake'),'stale edit cannot overwrite a newer edit');
update public.user_intakes set payload=public.atlas_test_intake('intake',150,current_date+1),modified_at=clock_timestamp()
  where record_id='intake';
select public.atlas_test_assert((select "caloriesTracked"=0 from public.tracked_days where day=current_date),'move repairs source day');
select public.atlas_test_assert((select "caloriesTracked"=300 from public.tracked_days where day=current_date+1),'move repairs destination');
do $$begin
  begin insert into public.user_intakes(user_id,record_id,payload,modified_at)
    values(auth.uid(),'bad',public.atlas_test_intake('bad',0,current_date),clock_timestamp());
    raise exception 'zero quantity accepted'; exception when invalid_parameter_value then null; end;
  begin insert into public.user_intakes(user_id,record_id,payload,modified_at)
    values(auth.uid(),'missing-date',public.atlas_test_intake('missing-date',100,current_date)-'dateTime',clock_timestamp());
    raise exception 'missing date accepted'; exception when invalid_parameter_value then null; end;
  begin insert into public.user_intakes(user_id,record_id,payload,modified_at)
    values(auth.uid(),'future',public.atlas_test_intake('future',100,current_date),now()+interval '1 day');
    raise exception 'future clock accepted'; exception when invalid_parameter_value then null; end;
  begin insert into public.user_weight(user_id,id,date,weight,modified_at)
    values(auth.uid(),'nan',current_date,'NaN'::float8,clock_timestamp());
    raise exception 'NaN weight accepted'; exception when invalid_parameter_value then null; end;
  begin insert into public.user_weight(user_id,id,date,weight,modified_at)
    values(auth.uid(),'heavy',current_date,401,clock_timestamp());
    raise exception 'implausible weight accepted'; exception when invalid_parameter_value then null; end;
end$$;
insert into public.user_weight(user_id,id,date,weight,modified_at)
  values(auth.uid(),'original-weight',current_date,80,clock_timestamp());
update public.user_weight set weight=0,deleted_at=clock_timestamp(),modified_at=clock_timestamp() where date=current_date;
update public.user_weight set weight=70,deleted_at=null,modified_at=now()-interval '1 day' where date=current_date;
select public.atlas_test_assert((select deleted_at is not null from public.user_weight where date=current_date),'weight deletion resists stale writes');
update public.user_weight set id='replacement-id',weight=81,deleted_at=null,modified_at=clock_timestamp() where date=current_date;
select public.atlas_test_assert((select id='original-weight' and weight=81 from public.user_weight where date=current_date),'weight undo preserves identity');

insert into public.user_recipes(user_id,record_id,payload,modified_at)
  values(auth.uid(),'food',jsonb_build_object('recipe',public.atlas_test_intake('x',100,current_date)->'meal','ingredients','[]'::jsonb),clock_timestamp());
update public.user_recipes set payload=jsonb_set(payload,'{recipe,name}','"Version récente"'),modified_at=clock_timestamp()
  where record_id='food';
update public.user_recipes set payload=jsonb_set(payload,'{recipe,name}','"Ancienne version"'),modified_at=now()-interval '1 day'
  where record_id='food';
select public.atlas_test_assert((select payload->'recipe'->>'name'='Version récente' from public.user_recipes),'newest recipe wins');
update public.user_recipes set deleted_at=clock_timestamp(),modified_at=clock_timestamp() where record_id='food';
update public.user_recipes set deleted_at=null,modified_at=now()-interval '1 day' where record_id='food';
select public.atlas_test_assert((select deleted_at is not null from public.user_recipes),'recipe tombstone defeats stale device');
reset role;

-- A second student can use the same date, but cannot see or change the first.
set local role authenticated;
set local request.jwt.claim.sub='00000000-0000-4000-8000-000000000002';
select public.atlas_test_assert((select count(*)=0 from public.user_intakes),'other student cannot read intake');
select public.atlas_test_assert((select count(*)=0 from public.user_weight),'other student cannot read weight');
select public.atlas_test_assert((select count(*)=0 from public.user_recipes),'other student cannot read recipe');
insert into public.user_weight(user_id,id,date,weight,modified_at)
  values(auth.uid(),'second-weight',current_date,70,clock_timestamp());
do $$begin
  begin insert into public.user_weight(user_id,id,date,weight,modified_at)
    values('00000000-0000-4000-8000-000000000001','foreign',current_date+1,90,clock_timestamp());
    raise exception 'cross-owner write accepted'; exception when insufficient_privilege then null; end;
  begin update public.users set role='coach' where id=auth.uid();
    raise exception 'profile role elevation accepted'; exception when insufficient_privilege then null; end;
  begin perform public.atlas_set_macro_goal(auth.uid(),current_date,200,60,120);
    raise exception 'student self-appointed as coach'; exception when insufficient_privilege then null; end;
end$$;
reset role;

set local role authenticated;
set local request.jwt.claim.sub='00000000-0000-4000-8000-000000000003';
select public.atlas_test_assert((select count(*)=1 from public.user_intakes),'assigned coach reads student foods');
select public.atlas_test_assert((select count(*)=1 from public.user_weight),'assigned coach cannot read unrelated student');
select public.atlas_set_macro_goal('00000000-0000-4000-8000-000000000001',current_date,250,60,115);
select public.atlas_set_macro_goal('00000000-0000-4000-8000-000000000001',current_date+3,300,70,150);
select public.atlas_test_assert((select count(*)=2 from public.coach_macro_goals),'future goal preserves current goal');
select public.atlas_test_assert((select "calorieGoal"=2000 from public.tracked_days where day=current_date+1),'future goal does not alter current target');
do $$begin
  begin perform public.atlas_set_macro_goal('00000000-0000-4000-8000-000000000002',current_date,200,60,120);
    raise exception 'unassigned coach write accepted'; exception when insufficient_privilege then null; end;
end$$;
reset role;

set local role authenticated;
set local request.jwt.claim.sub='00000000-0000-4000-8000-000000000001';
update public.tracked_days set "calorieGoal"=9999,"caloriesTracked"=9999,modified_at=clock_timestamp()
  where day=current_date+1;
select public.atlas_test_assert((select "calorieGoal"=2000 and "caloriesTracked"=300
  from public.tracked_days where day=current_date+1),'local row cannot overwrite coach goal or totals');
update public.user_intakes set payload='{}',deleted_at=clock_timestamp(),modified_at=clock_timestamp() where record_id='intake';
select public.atlas_test_assert((select "caloriesTracked"=0 from public.tracked_days where day=current_date+1),'deletion repairs totals');
update public.user_intakes set payload=public.atlas_test_intake('intake',150,current_date+1),deleted_at=null,
  modified_at=now()-interval '1 day' where record_id='intake';
select public.atlas_test_assert((select deleted_at is not null from public.user_intakes where record_id='intake'),'deleted food cannot resurrect from stale device');
update public.user_intakes set payload=public.atlas_test_intake('intake',150,current_date+1),deleted_at=null,
  modified_at=clock_timestamp() where record_id='intake';
select public.atlas_test_assert((select "caloriesTracked"=300 from public.tracked_days where day=current_date+1),'explicit later undo restores totals');
reset role;
rollback;
\echo 'Lot 6: all local PostgreSQL assertions passed'
