#!/bin/bash

# Cleanup old log partitions
# Usage: ./scripts/cleanup-old-logs.sh [retention_days]
# Default: 7 days

set -e

RETENTION_DAYS=${1:-7}

# Load environment variables
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

echo "🧹 Cleaning up partitions older than $RETENTION_DAYS days..."

# Build connection string
PGPASSWORD=$POSTGRES_PASSWORD
export PGPASSWORD

psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -c "SELECT * FROM message_logs.cleanup_old_partitions($RETENTION_DAYS);"

if [ $? -eq 0 ]; then
  echo "✅ Cleanup completed successfully"
else
  echo "❌ Cleanup failed"
  exit 1
fi

# Show remaining partitions
echo ""
echo "📊 Remaining partitions:"
psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -c "SELECT * FROM message_logs.get_partition_stats();"

unset PGPASSWORD
