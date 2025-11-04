# Deployment Guide - EasyPanel

Complete guide to deploy Newar Message Sender on EasyPanel.

## Prerequisites

✅ EasyPanel server with:
- PostgreSQL installed
- Redis installed
- Docker support

✅ Access credentials:
- PostgreSQL connection details
- Redis connection details
- Supabase URL and Service Role Key

## Step-by-Step Deployment

### 1. Clone Repository

```bash
cd /path/to/your/projects
git clone <repository-url> newar-message-sender
cd newar-message-sender
```

### 2. Install Dependencies Locally (for migrations)

```bash
npm install
```

### 3. Configure Environment

```bash
cp .env.example .env
nano .env
```

Edit the following values:

```bash
# Redis (from EasyPanel)
REDIS_HOST=cast_redis
REDIS_PORT=6379
REDIS_PASSWORD=48612a2f97fcf9e63ef4
REDIS_DB=2

# PostgreSQL (from EasyPanel)
POSTGRES_HOST=cast_postgres
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=7cf30548ff5ca1588482
POSTGRES_DB=n8n-cast
POSTGRES_SCHEMA=message_logs

# Supabase
SUPABASE_URL=https://qbmbokpbcyempnaravaw.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...8tyQ

# Worker Configuration
WORKER_CONCURRENCY=50
MAX_SOCKETS=500

# Logging
LOG_RETENTION_DAYS=7
```

### 4. Run Database Migrations

```bash
./scripts/run-migrations.sh
```

Expected output:
```
🚀 Running PostgreSQL migrations...
📝 Running 001_create_schema.sql...
✅ 001_create_schema.sql completed successfully
📝 Running 002_create_tables.sql...
✅ 002_create_tables.sql completed successfully
...
✅ All migrations completed successfully!
```

Verify partitions were created:
```bash
psql -h cast_postgres -U postgres -d n8n-cast \
  -c "SELECT * FROM message_logs.get_partition_stats();"
```

### 5. Build Docker Image

```bash
docker-compose build
```

### 6. Start Services

```bash
docker-compose up -d
```

This will start:
- 1× Run Processor
- 2× Message Workers (replicas)
- 1× API Server

### 7. Verify Deployment

```bash
# Check container status
docker-compose ps

# Check logs
docker-compose logs -f

# Test health endpoint
curl http://localhost:3100/health

# Expected response:
# {"status":"healthy","timestamp":"2025-11-04T...","service":"api"}
```

### 8. Access Bull Board UI

Open in browser:
```
http://your-server-ip:3100/admin/queues
```

You should see:
- Queue: `messages`
- Job counts
- Real-time updates

### 9. Test Message Processing

Trigger a run in Supabase (or your application):

```sql
-- In Supabase SQL Editor
INSERT INTO message_runs (user_id, flow_id, page_ids, status)
VALUES ('your-user-id', 'your-flow-id', ARRAY[123456789], 'pending');
```

Monitor in Bull Board UI:
- Jobs should appear in the queue
- Workers will process them
- Check completed/failed counts

## Network Configuration

### EasyPanel Network

The docker-compose.yml is configured to use EasyPanel's default network:

```yaml
networks:
  easypanel_default:
    external: true
```

If your EasyPanel uses a different network name, update this section.

### Port Mapping

By default, the API server is exposed on port **3100**:

```yaml
ports:
  - "3100:3000"
```

If port 3100 is already in use, change it:

```yaml
ports:
  - "3200:3000"  # Use port 3200 instead
```

## Scaling

### Horizontal Scaling (More Workers)

Edit `docker-compose.yml`:

```yaml
message-worker:
  # ... other config ...
  deploy:
    replicas: 4  # Increase from 2 to 4
```

Then:
```bash
docker-compose up -d --scale message-worker=4
```

### Vertical Scaling (More Concurrency)

Edit `.env`:

```bash
WORKER_CONCURRENCY=75  # Increase from 50
```

Restart workers:
```bash
docker-compose restart message-worker
```

### Resource Limits

Add resource limits to `docker-compose.yml`:

```yaml
message-worker:
  # ... other config ...
  deploy:
    replicas: 2
    resources:
      limits:
        cpus: '1.0'
        memory: 2G
      reservations:
        cpus: '0.5'
        memory: 1G
```

## Monitoring Setup

### 1. Set up Cron Jobs

Create cron jobs for maintenance:

```bash
crontab -e
```

Add:
```bash
# Cleanup old log partitions daily at 2 AM
0 2 * * * cd /path/to/newar-message-sender && ./scripts/cleanup-old-logs.sh 7

# Create future partitions monthly on the 1st at 3 AM
0 3 1 * * cd /path/to/newar-message-sender && ./scripts/create-future-partitions.sh 30
```

### 2. Log Rotation

Docker logs can grow large. Configure log rotation in `docker-compose.yml`:

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### 3. Health Checks

Set up external monitoring to ping:
```
http://your-server:3100/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2025-11-04T...",
  "service": "api"
}
```

### 4. Performance Monitoring

Monitor performance metrics:
```bash
curl http://your-server:3100/stats/performance | jq
```

## Troubleshooting

### Service won't start

Check logs:
```bash
docker-compose logs <service-name>
```

Common issues:
- **Network error**: Ensure `easypanel_default` network exists
- **Environment variables**: Verify `.env` file is correct
- **Port conflict**: Change port 3100 to another port

### Can't connect to PostgreSQL

Test connection manually:
```bash
psql -h cast_postgres -U postgres -d n8n-cast -c "SELECT 1;"
```

If this fails:
- Verify PostgreSQL is running: `docker ps | grep postgres`
- Check network connectivity
- Verify credentials in `.env`

### Can't connect to Redis

Test Redis connection:
```bash
redis-cli -h cast_redis -p 6379 -a 48612a2f97fcf9e63ef4 PING
```

Expected output: `PONG`

### Workers not processing

Check Redis queue:
```bash
redis-cli -h cast_redis -p 6379 -a 48612a2f97fcf9e63ef4
> SELECT 2
> KEYS bull:*
```

Check worker logs:
```bash
docker-compose logs message-worker
```

### High memory usage

Reduce concurrency:
```bash
# .env
WORKER_CONCURRENCY=25
LOG_BATCH_SIZE=100
```

Restart:
```bash
docker-compose restart message-worker
```

## Backup & Recovery

### Backup Message Logs

```bash
# Dump message_logs schema
pg_dump -h cast_postgres -U postgres -d n8n-cast \
  --schema=message_logs \
  --file=message_logs_backup_$(date +%Y%m%d).sql
```

### Restore Message Logs

```bash
psql -h cast_postgres -U postgres -d n8n-cast \
  -f message_logs_backup_20251104.sql
```

## Updates & Rollbacks

### Update to New Version

```bash
# Pull latest code
git pull origin main

# Rebuild images
docker-compose build

# Restart services (zero-downtime with rolling update)
docker-compose up -d --no-deps --build message-worker
docker-compose up -d --no-deps --build run-processor
docker-compose up -d --no-deps --build api
```

### Rollback

```bash
# Checkout previous version
git checkout <previous-commit-hash>

# Rebuild and restart
docker-compose build
docker-compose up -d
```

## Security

### Environment Variables

Never commit `.env` to git. It's already in `.gitignore`.

### PostgreSQL Access

Restrict PostgreSQL access to localhost or specific IPs:

```bash
# In PostgreSQL pg_hba.conf
host    n8n-cast    postgres    172.16.0.0/12   md5
```

### Redis Password

Ensure Redis has a strong password and is not exposed to the internet.

### API Server

If exposing API server publicly, add authentication:

```typescript
// src/services/api-server.ts
app.use((req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  if (apiKey !== process.env.API_KEY) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
});
```

## Performance Tuning

### Optimize PostgreSQL

```sql
-- Increase shared_buffers for better performance
ALTER SYSTEM SET shared_buffers = '2GB';
ALTER SYSTEM SET effective_cache_size = '8GB';
ALTER SYSTEM SET maintenance_work_mem = '512MB';

-- Reload configuration
SELECT pg_reload_conf();
```

### Optimize Redis

```bash
# In redis.conf
maxmemory 4gb
maxmemory-policy allkeys-lru
```

### Optimize Workers

Monitor HTTP client stats:
```bash
curl http://your-server:3100/stats/http-client
```

If `socket_reuse_rate` is low (<95%), investigate network issues.

## Complete Deployment Checklist

- [ ] Clone repository
- [ ] Install dependencies
- [ ] Configure `.env` file
- [ ] Run migrations (`./scripts/run-migrations.sh`)
- [ ] Verify partitions created
- [ ] Build Docker images (`docker-compose build`)
- [ ] Start services (`docker-compose up -d`)
- [ ] Verify health check (`curl http://localhost:3100/health`)
- [ ] Access Bull Board UI
- [ ] Set up cron jobs for maintenance
- [ ] Configure log rotation
- [ ] Set up external monitoring
- [ ] Test message processing
- [ ] Document credentials securely

## Support

For issues during deployment:
1. Check logs: `docker-compose logs -f`
2. Check health: `curl http://localhost:3100/health`
3. Check queue stats: `curl http://localhost:3100/stats/queue`
4. Review troubleshooting section above
