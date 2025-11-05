#!/bin/bash
set -e

# Wait for PostgreSQL to be ready
until pg_isready -h postgres -U "${POSTGRES_USER:-postgres}" > /dev/null 2>&1; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

echo "PostgreSQL is ready! Running initialization script..."

# Run the SQL script
PGPASSWORD="${POSTGRES_PASSWORD:-your_postgres_password}" psql -v ON_ERROR_STOP=1 -h postgres -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-message_sender}" <<-EOSQL
  -- Create schema if not exists
  CREATE SCHEMA IF NOT EXISTS message_logs;

  -- Set search_path to use the schema
  SET search_path TO message_logs, public;

  -- Create table with simple name (will be in message_logs schema due to search_path)
  -- This creates message_logs.message_logs table
  CREATE TABLE IF NOT EXISTS message_logs (
    id SERIAL PRIMARY KEY,
    run_id INTEGER NOT NULL,
    page_id VARCHAR(50) NOT NULL,
    user_id VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    error_code VARCHAR(50),
    error_message TEXT,
    sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  -- Indexes for common queries
  CREATE INDEX IF NOT EXISTS idx_run_id ON message_logs(run_id);
  CREATE INDEX IF NOT EXISTS idx_page_id ON message_logs(page_id);
  CREATE INDEX IF NOT EXISTS idx_user_id ON message_logs(user_id);
  CREATE INDEX IF NOT EXISTS idx_status ON message_logs(status);
  CREATE INDEX IF NOT EXISTS idx_created_at ON message_logs(created_at);

  -- Verify table was created
  SELECT 'Table message_logs.message_logs created successfully' AS status;
EOSQL

echo "✅ Database initialized successfully!"
