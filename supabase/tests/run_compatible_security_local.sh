#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/../.." && pwd)
cluster=$(mktemp -d /tmp/atlas-compatible-security.XXXXXX)
trap 'pg_ctl -D "$cluster/data" stop -m fast >/dev/null 2>&1 || true' EXIT
mkdir "$cluster/socket"
initdb -D "$cluster/data" --auth=trust --no-locale >"$cluster/init.log"
pg_ctl -D "$cluster/data" -l "$cluster/server.log" -o "-h '' -k '$cluster/socket' -p 55439" start >/dev/null
run_sql() {
  psql -X -h "$cluster/socket" -p 55439 -U "$(id -un)" -d postgres "$@"
}
run_sql -v ON_ERROR_STOP=1 -f "$repo_root/supabase/tests/compatible_security_fixture.sql" >"$cluster/fixture.log" 2>&1
run_sql -v ON_ERROR_STOP=1 -f "$repo_root/supabase/fdc_food_search.sql" >"$cluster/search.log" 2>&1
run_sql -v ON_ERROR_STOP=1 -c 'grant usage on schema extensions to anon,authenticated,service_role' >/dev/null
# Independent transactions expose all baseline regressions; they all roll back.
run_sql -v ON_ERROR_STOP=0 -f "$repo_root/supabase/tests/compatible_security_assertions.sql" >"$cluster/before.log" 2>&1
baseline_failures=$(rg 'ERROR:' "$cluster/before.log" | rg -vc 'current transaction is aborted')
if [ "$baseline_failures" -ne 7 ]; then
  echo "Unexpected baseline: $baseline_failures errors. Inspect $cluster/before.log" >&2
  exit 1
fi
run_sql -v ON_ERROR_STOP=1 -f "$repo_root/supabase/lot6_food_readonly.sql" >"$cluster/food.log" 2>&1
run_sql -v ON_ERROR_STOP=1 -f "$repo_root/supabase/production_compatible_security.sql" >"$cluster/hardening.log" 2>&1
run_sql -v ON_ERROR_STOP=1 -f "$repo_root/supabase/tests/compatible_security_read_checks.sql" >"$cluster/read_checks.log" 2>&1
run_sql -v ON_ERROR_STOP=1 -f "$repo_root/supabase/tests/compatible_security_assertions.sql" >"$cluster/after.log" 2>&1
run_sql -v ON_ERROR_STOP=1 -f "$repo_root/supabase/production_compatible_security.sql" >>"$cluster/hardening.log" 2>&1
run_sql -v ON_ERROR_STOP=1 -f "$repo_root/supabase/tests/compatible_security_assertions.sql" >>"$cluster/after.log" 2>&1
echo "PASS: 7 security regressions reproduced, deployed-client CRUD/subscriptions/notifications preserved, replay passed. Logs: $cluster"
