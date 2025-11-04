-- Migration 004: Create initial partitions
-- Creates partitions for current day + next 30 days

DO $$
DECLARE
    partition_date DATE;
    partition_name TEXT;
    partition_start TEXT;
    partition_end TEXT;
    i INT;
BEGIN
    FOR i IN 0..30 LOOP
        partition_date := CURRENT_DATE + i;
        partition_name := 'message_logs_' || to_char(partition_date, 'YYYY_MM_DD');
        partition_start := to_char(partition_date, 'YYYY-MM-DD');
        partition_end := to_char(partition_date + 1, 'YYYY-MM-DD');

        -- Create partition if it doesn't exist
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS message_logs.%I PARTITION OF message_logs.message_logs FOR VALUES FROM (%L) TO (%L)',
            partition_name,
            partition_start,
            partition_end
        );

        RAISE NOTICE 'Created partition: %', partition_name;
    END LOOP;
END $$;
