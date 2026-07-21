#!/usr/bin/env bash
# Load the course dataset (and calendar dimension) into PostgreSQL.
# The app container shares the db container's network (network_mode: service:db),
# so PostgreSQL is reachable on localhost.
set -euo pipefail

DUMP=".devcontainer/setup-postgresql.sql"
CALENDAR="calendar.sql"
export PGPASSWORD=postgres
PSQL="psql -h 127.0.0.1 -U postgres -d postgres -v ON_ERROR_STOP=1"

# depends_on/service_healthy covers container start ordering, but a Codespace
# resume can still bring this script up before the DB is answering. Retry.
echo "Waiting for PostgreSQL to accept connections..."
for i in $(seq 1 30); do
    if pg_isready -h 127.0.0.1 -U postgres -d postgres -q; then
        echo "PostgreSQL is ready."
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "PostgreSQL did not become ready in time." >&2
        exit 1
    fi
    sleep 2
done

# Base dataset. The dump has no DROP TABLE guards, so a second run would fail
# with "relation already exists" - skip if it's already loaded.
if [ ! -f "$DUMP" ]; then
    echo "No base dump found at $DUMP - skipping base load."
elif $PSQL -tAc "SELECT to_regclass('public.payments')" | grep -q payments; then
    echo "Base dataset already loaded - skipping."
else
    echo "Loading base dataset..."
    $PSQL -q -f "$DUMP"
    echo "Base dataset loaded: loans, payments, purchases, sales."
fi

# Calendar / date dimension. calendar.sql is idempotent on its own (it drops and
# recreates), but guard on the table so a resume doesn't rebuild it needlessly.
if [ ! -f "$CALENDAR" ]; then
    echo "No calendar script found at $CALENDAR - skipping calendar load."
elif $PSQL -tAc "SELECT to_regclass('public.calendar')" | grep -q calendar; then
    echo "Calendar table already present - skipping."
else
    echo "Loading calendar dimension..."
    $PSQL -q -f "$CALENDAR"
    echo "Calendar table loaded."
fi

# Coursework queries, run in order once the data + calendar are in place. The two
# CREATE MATERIALIZED VIEW files begin with DROP ... IF EXISTS, so this is safe to
# re-run. Result rows are suppressed to keep the startup log readable; ON_ERROR_STOP
# means a failing query aborts startup and surfaces which file broke.
QUERIES=(
    "queries/Cash Account.sql"
    "queries/account_accounts_receivable.sql"
    "queries/depreciation_dates.sql"
)
echo "Running coursework queries..."
for q in "${QUERIES[@]}"; do
    if [ -f "$q" ]; then
        echo "  - $q"
        $PSQL -q -f "$q" > /dev/null
    else
        echo "  - $q (missing, skipped)"
    fi
done
echo "Coursework queries complete."