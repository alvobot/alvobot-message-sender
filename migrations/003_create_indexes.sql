-- Migration 003: Create indexes
-- Creates indexes for common query patterns

-- Index on run_id (most common query: get logs by run)
CREATE INDEX IF NOT EXISTS idx_message_logs_run_id
ON message_logs.message_logs(run_id);

-- Index on page_id (query logs by page)
CREATE INDEX IF NOT EXISTS idx_message_logs_page_id
ON message_logs.message_logs(page_id);

-- Index on status (filter by status)
CREATE INDEX IF NOT EXISTS idx_message_logs_status
ON message_logs.message_logs(status);

-- Index on created_at descending (recent logs first)
CREATE INDEX IF NOT EXISTS idx_message_logs_created_at
ON message_logs.message_logs(created_at DESC);

-- Composite index for run_id + status (common filter combination)
CREATE INDEX IF NOT EXISTS idx_message_logs_run_status
ON message_logs.message_logs(run_id, status);

COMMENT ON INDEX message_logs.idx_message_logs_run_id IS 'Query logs by run_id';
COMMENT ON INDEX message_logs.idx_message_logs_page_id IS 'Query logs by page_id';
COMMENT ON INDEX message_logs.idx_message_logs_status IS 'Filter logs by status';
COMMENT ON INDEX message_logs.idx_message_logs_created_at IS 'Sort logs by date (recent first)';
COMMENT ON INDEX message_logs.idx_message_logs_run_status IS 'Query logs by run_id and status';
