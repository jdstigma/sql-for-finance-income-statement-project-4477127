#!/usr/bin/env bash
# Load the course dataset into PostgreSQL.
set -euo pipefail

DUMP=".devcontainer/setup-postgresql.sql"
export PGPASSWORD=postgres
PSQL="psql -h db -U postgres -d postgres -v ON_ERROR_STOP=1"

if [ ! -f "$DUMP" ]; then
    echo "No dump found at $DUMP - nothing to load."
    exit 0
fi

# depends_on/service_healthy covers container start ordering, but a Codespace
# resume can still bring this script up before the DB is answering. Retry.
echo "Waiting for PostgreSQL to accept connections..."
for i in $(seq 1 30); do
    if pg_isready -h db -U postgres -d postgres -q; then
        echo "PostgreSQL is ready."
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "PostgreSQL did not become ready in time." >&2
        exit 1
    fi
    sleep 2
done

# The dump has no DROP TABLE guards, so a second run would fail with
# "relation already exists". Skip if the data is already loaded.
if $PSQL -tAc "SELECT to_regclass('public.payments')" | grep -q payments; then
    echo "Dataset already loaded - skipping."
    exit 0
fi

echo "Loading dataset..."
$PSQL -q -f "$DUMP"
echo "Dataset loaded: loans, payments, purchases, sales."
