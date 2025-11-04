#!/bin/bash

# Create future partitions
# Usage: ./scripts/create-future-partitions.sh [days_ahead]
# Default: 30 days

set -e

DAYS_AHEAD=${1:-30}

# Load environment variables
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

echo "🚀 Creating partitions for next $DAYS_AHEAD days..."

# Build connection string
PGPASSWORD=$POSTGRES_PASSWORD
export PGPASSWORD

psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -c "SELECT * FROM message_logs.create_future_partitions($DAYS_AHEAD);"

if [ $? -eq 0 ]; then
  echo "✅ Partitions created successfully"
else
  echo "❌ Failed to create partitions"
  exit 1
fi

unset PGPASSWORD
