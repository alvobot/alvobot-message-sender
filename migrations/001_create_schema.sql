-- Migration 001: Create schema
-- Creates a dedicated schema for message logs

CREATE SCHEMA IF NOT EXISTS message_logs;

GRANT ALL ON SCHEMA message_logs TO postgres;

COMMENT ON SCHEMA message_logs IS 'Schema for Facebook Messenger message logs (separate from Supabase)';
