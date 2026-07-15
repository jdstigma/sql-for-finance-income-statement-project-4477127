# Run an initial setup script for the MariaDB database
if [ -f .devcontainer/setup-postgresql.sql ]; then
    PGPASSWORD=postgres psql -h db -U postgres postgres < .devcontainer/setup-postgresql.sql
fi
