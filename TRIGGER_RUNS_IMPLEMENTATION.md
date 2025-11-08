# Trigger Runs Implementation

## Overview

The trigger_runs feature enables individual message triggers (keywords, events, etc.) to be processed with **high priority** compared to bulk campaigns (message_runs).

---

## Architecture

### Services

1. **trigger-run-processor.ts**: Polls `trigger_runs` table and enqueues jobs with priority 1
2. **run-processor.ts**: Polls `message_runs` table and enqueues jobs with priority 100
3. **message-worker.ts**: Processes both types of jobs from the same queue
4. **api-server.ts**: New endpoint `/stats/trigger-run/:triggerRunId`

### Priority System

- **Triggers**: Priority **1** (high priority - processed first)
- **Bulk campaigns**: Priority **100** (low priority)
- BullMQ processes lower numbers first, ensuring triggers have preference

---

## Database Changes

### Migration: 006_add_trigger_run_id_to_message_logs.sql

```sql
ALTER TABLE message_logs.message_logs
ADD COLUMN trigger_run_id BIGINT NULL
REFERENCES public.trigger_runs(id) ON DELETE SET NULL;

CREATE INDEX idx_message_logs_trigger_run_id
ON message_logs.message_logs(trigger_run_id)
WHERE trigger_run_id IS NOT NULL;
```

### Log Differentiation

- `run_id` populated = bulk campaign (message_runs)
- `trigger_run_id` populated = individual trigger (trigger_runs)
- Both fields can be NULL (test messages, etc.)

---

## Deployment

### 1. Run Migration

Execute the migration in production:

```bash
psql -h <host> -U <user> -d <database> -f migrations/006_add_trigger_run_id_to_message_logs.sql
```

### 2. Deploy Code

Deploy the updated codebase with the new service.

### 3. Start Trigger Run Processor

Set environment variable and start the service:

```bash
SERVICE_TYPE=trigger-run-processor npm start
```

Or in your deployment config (EasyPanel, Docker Compose, etc.):

```yaml
services:
  trigger-run-processor:
    build: .
    environment:
      - SERVICE_TYPE=trigger-run-processor
      - POLL_INTERVAL_MS=10000
      # ... other env vars
```

### 4. Verify Services

Check that both processors are running:

```bash
# Check logs
docker logs <trigger-run-processor-container>
docker logs <run-processor-container>

# Should see:
# "🚀 Trigger Run Processor started"
# "🚀 Run Processor started"
```

---

## Usage

### Creating a Trigger Run

Insert a record into `trigger_runs`:

```sql
INSERT INTO trigger_runs (
  trigger_id,
  recipient_user_id,
  page_id,
  flow_id,
  status,
  trigger_context
) VALUES (
  1,
  '25164691176450778',
  1876373432431116,
  '2481e82d-6533-4b90-af57-bf48a8c0b7bf',
  'queued',
  '{"timestamp": "2025-11-08T11:22:32.729Z", "trigger_type": "keywords", "matched_keyword": "teste"}'::jsonb
);
```

### Monitoring

#### Get Trigger Run Stats

```bash
curl http://localhost:3000/stats/trigger-run/1
```

Response:

```json
{
  "trigger_run_id": 1,
  "trigger_id": 1,
  "recipient_user_id": "25164691176450778",
  "page_id": 1876373432431116,
  "flow_id": "2481e82d-6533-4b90-af57-bf48a8c0b7bf",
  "status": "finished",
  "trigger_context": { "trigger_type": "keywords", "matched_keyword": "teste" },
  "created_at": "2025-11-08T11:22:32.729Z",
  "completed_at": "2025-11-08T11:22:45.123Z",
  "stats": {
    "total_attempts": 3,
    "successful": 3,
    "failed": 0,
    "pending": 0,
    "success_rate": "100.00%"
  },
  "error_breakdown": [],
  "queue": {
    "waiting": 1234,
    "active": 50,
    "delayed": 100
  }
}
```

#### Check Queue Priority

Use Bull Board or query BullMQ directly to verify trigger jobs have priority 1.

---

## How It Works

### Flow Processing

1. **Trigger created**: Record inserted into `trigger_runs` with `status='queued'`
2. **Polling**: trigger-run-processor polls every 10 seconds
3. **Locking**: Uses optimistic locking (`eq('status', 'queued')`) to prevent duplicates
4. **Page validation**: Checks if `page.is_active = true`, skips if inactive
5. **Flow processing**: Uses `assembleMessages()` to get messages from flow graph
6. **Job enqueuing**: Creates jobs with `priority: 1` and 2-second delays between messages
7. **Status updates**:
   - `queued → running` when processing starts
   - `running → waiting` if flow has wait node
   - `waiting → running` when wait time expires
   - `running → finished` when flow completes

### Wait Nodes

If the flow has a wait node:

```json
{
  "type": "wait",
  "data": {
    "duration": 2,
    "timeUnit": "minutes"
  }
}
```

The trigger_run will:
1. Set `status='waiting'`
2. Set `next_step_at` to calculated future timestamp
3. Set `next_step_id` to next node
4. Wait until `next_step_at` before resuming

---

## Differences from message_runs

| Feature | message_runs | trigger_runs |
|---------|-------------|--------------|
| **Recipients** | All active subscribers for page | Single user (recipient_user_id) |
| **Priority** | 100 (low) | 1 (high) |
| **Job naming** | `run_{runId}_page_{pageId}_user_{userId}_msg_{i}` | `trigger_{triggerRunId}_page_{pageId}_user_{userId}_msg_{i}` |
| **Logs** | `run_id` populated | `trigger_run_id` populated |
| **Subscriber check** | Verifies `is_active = true` | No verification (uses recipient_user_id directly) |
| **Volume** | High (100k+ subscribers) | Low (1 user) |
| **Use case** | Bulk campaigns | Keyword triggers, events |

---

## Performance Considerations

### Priority Impact

- Adding jobs with priority is **O(log n)** vs **O(1)** without priority
- For 1 user (trigger), this is negligible (~1ms)
- For 100k users (bulk campaign), adds ~2-3 seconds total

### Worker Concurrency

With `WORKER_CONCURRENCY=50`:
- 50 workers process jobs concurrently
- Triggers get picked first when available
- Bulk campaigns still process when no triggers in queue

If trigger volume is very high:
- Increase `WORKER_CONCURRENCY` to 100+
- Add more worker replicas
- Monitor Meta API rate limits

---

## Troubleshooting

### Trigger not processing

**Check status**:
```sql
SELECT * FROM trigger_runs WHERE id = 1;
```

**Verify processor is running**:
```bash
docker logs trigger-run-processor-container | grep "Trigger Run Processor started"
```

**Check for errors**:
```bash
docker logs trigger-run-processor-container | grep ERROR
```

### Jobs not being processed

**Check circuit breaker**:
```bash
curl http://localhost:3000/stats/circuit-breaker
```

**Check page is active**:
```sql
SELECT page_id, is_active FROM meta_pages WHERE page_id = 1876373432431116;
```

**Check queue**:
```bash
curl http://localhost:3000/stats/queue
```

### No logs in message_logs

**Check trigger_run status**:
- If `status='failed'`, check `error_details` field
- If `status='queued'`, processor hasn't picked it up yet
- If `status='waiting'`, check `next_step_at` timestamp

**Verify jobs were created**:
- Check Bull Board at `http://localhost:3000/admin/queues`
- Look for jobs with name pattern `trigger_{triggerRunId}_*`

---

## Testing

### 1. Create Test Trigger Run

```sql
INSERT INTO trigger_runs (
  trigger_id,
  recipient_user_id,
  page_id,
  flow_id,
  status
) VALUES (
  999,
  '<test_user_id>',
  <test_page_id>,
  '<test_flow_id>',
  'queued'
);
```

### 2. Verify Processing

```bash
# Check trigger_runs table
SELECT * FROM trigger_runs WHERE trigger_id = 999;

# Should see status change: queued → running → finished
```

### 3. Check Logs

```bash
# Check message_logs
SELECT * FROM message_logs.message_logs WHERE trigger_run_id = <id>;

# Should see entries with trigger_run_id populated
```

### 4. Verify Priority

1. Create 1000 bulk campaign jobs (priority 100)
2. Create 10 trigger jobs (priority 1)
3. Check Bull Board - triggers should process first

---

## Environment Variables

No new environment variables needed. Uses existing:

- `SERVICE_TYPE=trigger-run-processor` (to start this service)
- `POLL_INTERVAL_MS=10000` (same as run-processor)
- `WORKER_CONCURRENCY=50` (workers process both types)

---

## Future Enhancements

### 1. Dynamic Priority

Allow triggers to specify priority:

```sql
ALTER TABLE trigger_runs ADD COLUMN priority INTEGER DEFAULT 1;
```

Then use `run.priority` when enqueuing jobs.

### 2. Dedicated Workers

Create separate workers for triggers:

```yaml
trigger-worker:
  environment:
    - SERVICE_TYPE=message-worker
    - QUEUE_NAME=trigger-messages  # New queue
    - WORKER_CONCURRENCY=20
```

### 3. Rate Limiting per Trigger

Implement per-trigger rate limits to prevent abuse.

### 4. Metrics Dashboard

Add Grafana dashboard tracking:
- Trigger processing time
- Queue size by priority
- Success/failure rates by trigger_id

---

## Summary

The trigger_runs implementation provides:

✅ High-priority processing for individual user triggers
✅ Same flow engine and workers as bulk campaigns
✅ Isolated polling and logging
✅ Full stats and monitoring via API
✅ Production-ready with optimistic locking and error handling

Deploy with confidence! 🚀
