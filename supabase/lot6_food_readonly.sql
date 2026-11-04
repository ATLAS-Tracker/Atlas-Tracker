-- LOCAL VALIDATION ONLY. Review the production schema and grants before approval.
begin;
set local lock_timeout='3s';
set local statement_timeout='15s';

do $security$
declare
  relation text;
  column_name text;
begin
  foreach relation in array array['fdc_food', 'fdc_portions', 'fdc_nutrients'] loop
    if to_regclass('public.' || relation) is null then
      raise exception 'Missing public.%: inspect the schema before proceeding', relation;
    end if;
    execute format('alter table public.%I enable row level security', relation);
    execute format('revoke all privileges on table public.%I from public, anon, authenticated', relation);
    -- Table revocation does not remove independently granted column privileges.
    for column_name in
      select attname from pg_attribute
      where attrelid = to_regclass('public.' || relation) and attnum > 0 and not attisdropped
    loop
      execute format('revoke insert (%I), update (%I), references (%I) on public.%I from public, anon, authenticated',
          column_name, column_name, column_name, relation);
    end loop;
    execute format('drop policy if exists atlas_food_readonly on public.%I', relation);
    execute format('create policy atlas_food_readonly on public.%I for select to anon, authenticated using (true)', relation);
    execute format('grant select on public.%I to anon, authenticated', relation);
  end loop;
end
$security$;

commit;
