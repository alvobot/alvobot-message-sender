-- Migration 006: Add trigger_run_id column to message_logs
-- This enables tracking messages sent from trigger_runs (individual user triggers)
-- vs messages sent from message_runs (bulk campaigns)

-- IMPORTANT: trigger_runs table lives in Supabase, not in this database
-- So we don't create foreign key constraints

-- Add trigger_run_id column to message_logs table
ALTER TABLE message_logs.message_logs
ADD COLUMN IF NOT EXISTS trigger_run_id BIGINT NULL;

-- Create index for efficient queries by trigger_run_id
CREATE INDEX IF NOT EXISTS idx_message_logs_trigger_run_id
ON message_logs.message_logs(trigger_run_id)
WHERE trigger_run_id IS NOT NULL;

-- Allow run_id to be NULL (for trigger messages)
ALTER TABLE message_logs.message_logs
ALTER COLUMN run_id DROP NOT NULL;

-- Add comments explaining the usage
COMMENT ON COLUMN message_logs.message_logs.run_id IS
'References message_runs.id (Supabase) for bulk campaigns. NULL for trigger messages.';

COMMENT ON COLUMN message_logs.message_logs.trigger_run_id IS
'References trigger_runs.id (Supabase) for individual triggers. NULL for bulk campaigns. Either run_id or trigger_run_id will be populated, but not both.';
