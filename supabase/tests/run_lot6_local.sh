#!/usr/bin/env bash
# Creates synthetic data in a fresh socket-only cluster. No hosted connection.
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/../.." && pwd)
cluster=$(mktemp -d /tmp/atlas-lot6-check.XXXXXX)
cleanup() {
  pg_ctl -D "$cluster/data" stop -m fast >/dev/null 2>&1 || true
}
trap cleanup EXIT
mkdir "$cluster/socket"
initdb -D "$cluster/data" --auth=trust --no-locale >"$cluster/init.log"
pg_ctl -D "$cluster/data" -l "$cluster/server.log" \
  -o "-h '' -k '$cluster/socket' -p 55439" start >/dev/null
run_sql() {
  psql -X -h "$cluster/socket" -p 55439 -U "$(id -un)" -d postgres \
    -v ON_ERROR_STOP=1 "$@"
}
run_sql -f "$repo_root/supabase/tests/lot6_fixture.sql" >"$cluster/fixture.log" 2>&1
run_sql -f "$repo_root/supabase/journal_remote_sync.sql" >"$cluster/journal.log" 2>&1
run_sql -f "$repo_root/supabase/lot6_food_readonly.sql" >"$cluster/food.log" 2>&1
run_sql -f "$repo_root/supabase/lot6_integrity.sql" >"$cluster/integrity.log" 2>&1
# Replaying the review scripts must preserve data and policies.
run_sql -f "$repo_root/supabase/lot6_food_readonly.sql" >>"$cluster/food.log" 2>&1
run_sql -f "$repo_root/supabase/lot6_integrity.sql" >>"$cluster/integrity.log" 2>&1
run_sql -f "$repo_root/supabase/tests/lot6_assertions.sql" >"$cluster/assertions.log" 2>&1
run_sql -c 'create unique index legacy_global_day on public.tracked_days(day)' >/dev/null
if run_sql -f "$repo_root/supabase/lot6_integrity.sql" >"$cluster/preflight.log" 2>&1; then
  echo 'FAIL: legacy global uniqueness was not rejected' >&2
  exit 1
fi
rg -q 'Review global unique tracked_days.day' "$cluster/preflight.log"
echo "PASS: policies, validation, versions, deletions, totals, goals, replay and preflight. Logs: $cluster"
