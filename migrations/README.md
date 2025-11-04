# Database Migrations

PostgreSQL migrations for message logs schema.

## Files

1. **001_create_schema.sql** - Creates `message_logs` schema
2. **002_create_tables.sql** - Creates partitioned `message_logs` table
3. **003_create_indexes.sql** - Creates indexes for performance
4. **004_create_partitions.sql** - Creates initial partitions (30 days)
5. **005_create_functions.sql** - Creates utility functions

## Running Migrations

### Automatic (Recommended)

```bash
./scripts/run-migrations.sh
```

### Manual

```bash
export PGPASSWORD=your_password

psql -h cast_postgres -U postgres -d n8n-cast -f 001_create_schema.sql
psql -h cast_postgres -U postgres -d n8n-cast -f 002_create_tables.sql
psql -h cast_postgres -U postgres -d n8n-cast -f 003_create_indexes.sql
psql -h cast_postgres -U postgres -d n8n-cast -f 004_create_partitions.sql
psql -h cast_postgres -U postgres -d n8n-cast -f 005_create_functions.sql
```

## Utility Functions

After running migrations, you'll have access to:

### Create Future Partitions

```sql
SELECT * FROM message_logs.create_future_partitions(30);
```

Creates partitions for the next N days.

### Cleanup Old Partitions

```sql
SELECT * FROM message_logs.cleanup_old_partitions(7);
```

Drops partitions older than N days.

### Get Partition Stats

```sql
SELECT * FROM message_logs.get_partition_stats();
```

Shows all partitions with row counts and sizes.

## Partition Naming

Partitions are named: `message_logs_YYYY_MM_DD`

Example:
- `message_logs_2025_11_04` (November 4, 2025)
- `message_logs_2025_11_05` (November 5, 2025)

## Maintenance

### Daily Cleanup (Cron)

Add to crontab:
```bash
0 2 * * * cd /path/to/project && ./scripts/cleanup-old-logs.sh 7
```

### Monthly Partition Creation (Cron)

Add to crontab:
```bash
0 3 1 * * cd /path/to/project && ./scripts/create-future-partitions.sh 30
```

## Rollback

To drop everything:

```sql
DROP SCHEMA message_logs CASCADE;
```

⚠️ **Warning**: This deletes all data!

## Verification

After migrations, verify:

```sql
-- Check schema exists
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'message_logs';

-- Check table exists
SELECT table_name FROM information_schema.tables WHERE table_schema = 'message_logs';

-- Check partitions
SELECT * FROM message_logs.get_partition_stats();

-- Check functions
SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'message_logs';
```

## Troubleshooting

### Permission Denied

```sql
GRANT ALL ON SCHEMA message_logs TO postgres;
GRANT ALL ON ALL TABLES IN SCHEMA message_logs TO postgres;
```

### Partition Already Exists

Safe to ignore. The migration scripts use `IF NOT EXISTS` clauses.

### No Partitions Created

Run manually:
```sql
SELECT * FROM message_logs.create_future_partitions(30);
```
