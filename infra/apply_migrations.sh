#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

COMPOSE_COMMAND="docker compose"
DB_SERVICE="db"
DB_USER="${DB_USER:-postgres}"
DB_NAME="${DB_NAME:-ai_delivery}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"

export PGPASSWORD="$DB_PASSWORD"

if ! $COMPOSE_COMMAND ps -q "$DB_SERVICE" >/dev/null 2>&1; then
  echo "Starting ${DB_SERVICE} service..."
  $COMPOSE_COMMAND up -d "$DB_SERVICE"
fi

echo "Applying migration scripts..."
cat migrations/*.sql | $COMPOSE_COMMAND exec -T "$DB_SERVICE" psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1

echo "Applying seed data..."
cat seed_data.sql | $COMPOSE_COMMAND exec -T "$DB_SERVICE" psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1

echo "Migration and seed execution completed."
