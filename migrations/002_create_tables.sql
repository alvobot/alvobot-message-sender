-- Migration 002: Create tables
-- Creates the message_logs table with partitioning

CREATE TABLE IF NOT EXISTS message_logs.message_logs (
    id BIGSERIAL,
    run_id BIGINT NOT NULL,
    page_id BIGINT NOT NULL,
    user_id TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('sent', 'failed', 'rate_limited', 'auth_error')),
    error_code TEXT,
    error_message TEXT,
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Add comments
COMMENT ON TABLE message_logs.message_logs IS 'Message send logs with automatic partitioning by date';
COMMENT ON COLUMN message_logs.message_logs.run_id IS 'FK to message_runs in Supabase';
COMMENT ON COLUMN message_logs.message_logs.page_id IS 'Facebook page ID';
COMMENT ON COLUMN message_logs.message_logs.user_id IS 'Facebook user (recipient) ID';
COMMENT ON COLUMN message_logs.message_logs.status IS 'sent | failed | rate_limited | auth_error';
COMMENT ON COLUMN message_logs.message_logs.error_code IS 'Facebook API error code (if failed)';
COMMENT ON COLUMN message_logs.message_logs.error_message IS 'Error message (if failed)';
COMMENT ON COLUMN message_logs.message_logs.sent_at IS 'Timestamp when message was successfully sent';
COMMENT ON COLUMN message_logs.message_logs.created_at IS 'Timestamp when log was created (partition key)';
