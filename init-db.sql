-- Database initialization script
-- Creates the message_logs schema and table for storing message delivery logs

-- Create schema
CREATE SCHEMA IF NOT EXISTS message_logs;

-- Create table (schema-qualified)
CREATE TABLE IF NOT EXISTS message_logs.message_logs (
  id SERIAL PRIMARY KEY,
  run_id INTEGER NULL,  -- For bulk campaigns (message_runs)
  trigger_run_id BIGINT NULL,  -- For individual triggers (trigger_runs)
  page_id VARCHAR(50) NOT NULL,  -- Using VARCHAR to preserve precision of large Facebook IDs
  user_id VARCHAR(50) NOT NULL,  -- Using VARCHAR to preserve precision of large Facebook IDs
  status VARCHAR(50) NOT NULL,
  error_code VARCHAR(50),
  error_message TEXT,
  sent_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_run_id ON message_logs.message_logs(run_id);
CREATE INDEX IF NOT EXISTS idx_trigger_run_id ON message_logs.message_logs(trigger_run_id) WHERE trigger_run_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_page_id ON message_logs.message_logs(page_id);
CREATE INDEX IF NOT EXISTS idx_user_id ON message_logs.message_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_status ON message_logs.message_logs(status);
CREATE INDEX IF NOT EXISTS idx_created_at ON message_logs.message_logs(created_at);

-- Add comments
COMMENT ON COLUMN message_logs.message_logs.run_id IS 'References message_runs.id for bulk campaigns. NULL for trigger messages.';
COMMENT ON COLUMN message_logs.message_logs.trigger_run_id IS 'References trigger_runs.id for individual triggers. NULL for bulk campaigns.';
