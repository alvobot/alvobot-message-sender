-- Migration 006: Add trigger_run_id column to message_logs
-- This enables tracking messages sent from trigger_runs (individual user triggers)
-- vs messages sent from message_runs (bulk campaigns)

-- Add trigger_run_id column to message_logs table
ALTER TABLE message_logs.message_logs
ADD COLUMN IF NOT EXISTS trigger_run_id BIGINT NULL;

-- Add foreign key constraint to trigger_runs table
ALTER TABLE message_logs.message_logs
ADD CONSTRAINT message_logs_trigger_run_id_fkey
FOREIGN KEY (trigger_run_id)
REFERENCES public.trigger_runs(id)
ON DELETE SET NULL;

-- Create index for efficient queries by trigger_run_id
CREATE INDEX IF NOT EXISTS idx_message_logs_trigger_run_id
ON message_logs.message_logs(trigger_run_id)
WHERE trigger_run_id IS NOT NULL;

-- Add comment explaining the usage
COMMENT ON COLUMN message_logs.message_logs.trigger_run_id IS
'References trigger_runs.id for messages sent via triggers. NULL for bulk campaign messages (message_runs). Either run_id or trigger_run_id will be populated, but not both.';
