#!/bin/bash

# Run PostgreSQL migrations
# Usage: ./scripts/run-migrations.sh

set -e

# Load environment variables
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

echo "🚀 Running PostgreSQL migrations..."

# Build connection string
PGPASSWORD=$POSTGRES_PASSWORD
export PGPASSWORD

# Run migrations in order
MIGRATIONS_DIR="./migrations"

for migration in "$MIGRATIONS_DIR"/*.sql; do
  echo "📝 Running $(basename "$migration")..."

  psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$migration"

  if [ $? -eq 0 ]; then
    echo "✅ $(basename "$migration") completed successfully"
  else
    echo "❌ $(basename "$migration") failed"
    exit 1
  fi
done

echo "✅ All migrations completed successfully!"

# Run partition stats
echo ""
echo "📊 Partition statistics:"
psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -c "SELECT * FROM message_logs.get_partition_stats();"

unset PGPASSWORD
