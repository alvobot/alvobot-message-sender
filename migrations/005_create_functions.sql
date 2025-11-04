-- Migration 005: Create functions
-- Creates utility functions for partition management

-- Function to cleanup old partitions (older than retention_days)
CREATE OR REPLACE FUNCTION message_logs.cleanup_old_partitions(retention_days INT DEFAULT 7)
RETURNS TABLE(dropped_partition TEXT) AS $$
DECLARE
    partition_rec RECORD;
    cutoff_date DATE;
BEGIN
    cutoff_date := CURRENT_DATE - retention_days;

    RAISE NOTICE 'Cleaning up partitions older than % days (cutoff date: %)', retention_days, cutoff_date;

    FOR partition_rec IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'message_logs'
        AND tablename LIKE 'message_logs_%'
        AND tablename < 'message_logs_' || to_char(cutoff_date, 'YYYY_MM_DD')
    LOOP
        EXECUTE 'DROP TABLE IF EXISTS message_logs.' || partition_rec.tablename;
        dropped_partition := partition_rec.tablename;
        RAISE NOTICE 'Dropped partition: %', dropped_partition;
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION message_logs.cleanup_old_partitions IS 'Drop partitions older than N days (default 7)';

-- Function to create future partitions
CREATE OR REPLACE FUNCTION message_logs.create_future_partitions(days_ahead INT DEFAULT 30)
RETURNS TABLE(created_partition TEXT) AS $$
DECLARE
    i INT;
    partition_date DATE;
    partition_name TEXT;
    partition_start TEXT;
    partition_end TEXT;
BEGIN
    RAISE NOTICE 'Creating partitions for next % days', days_ahead;

    FOR i IN 0..days_ahead LOOP
        partition_date := CURRENT_DATE + i;
        partition_name := 'message_logs_' || to_char(partition_date, 'YYYY_MM_DD');
        partition_start := to_char(partition_date, 'YYYY-MM-DD');
        partition_end := to_char(partition_date + 1, 'YYYY-MM-DD');

        BEGIN
            EXECUTE format(
                'CREATE TABLE IF NOT EXISTS message_logs.%I PARTITION OF message_logs.message_logs FOR VALUES FROM (%L) TO (%L)',
                partition_name,
                partition_start,
                partition_end
            );
            created_partition := partition_name;
            RAISE NOTICE 'Created partition: %', created_partition;
            RETURN NEXT;
        EXCEPTION WHEN duplicate_table THEN
            -- Partition already exists, skip
            RAISE NOTICE 'Partition % already exists, skipping', partition_name;
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION message_logs.create_future_partitions IS 'Create partitions for next N days (default 30)';

-- Function to get partition stats
CREATE OR REPLACE FUNCTION message_logs.get_partition_stats()
RETURNS TABLE(
    partition_name TEXT,
    row_count BIGINT,
    size_bytes BIGINT,
    size_pretty TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        schemaname || '.' || tablename AS partition_name,
        n_live_tup AS row_count,
        pg_total_relation_size(schemaname || '.' || tablename) AS size_bytes,
        pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) AS size_pretty
    FROM pg_stat_user_tables
    WHERE schemaname = 'message_logs'
    AND tablename LIKE 'message_logs_%'
    ORDER BY tablename DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION message_logs.get_partition_stats IS 'Get statistics for all partitions (rows, size)';
