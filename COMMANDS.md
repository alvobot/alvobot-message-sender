# Useful Commands

Quick reference for common operations.

## 🚀 Deployment

```bash
# Run migrations
./scripts/run-migrations.sh

# Build and start
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all
docker-compose down

# Restart specific service
docker-compose restart message-worker
```

## 📊 Monitoring

```bash
# Health check
curl http://localhost:3100/health

# Queue stats
curl http://localhost:3100/stats/queue | jq

# Performance metrics
curl http://localhost:3100/stats/performance | jq

# HTTP client stats
curl http://localhost:3100/stats/http-client | jq

# Circuit breaker status
curl http://localhost:3100/stats/circuit-breaker | jq

# Log writer stats
curl http://localhost:3100/stats/log-writer | jq
```

## 🗄️ Database

```bash
# Connect to PostgreSQL
psql -h cast_postgres -U postgres -d n8n-cast

# Check partitions
psql -h cast_postgres -U postgres -d n8n-cast \
  -c "SELECT * FROM message_logs.get_partition_stats();"

# Create future partitions
./scripts/create-future-partitions.sh 30

# Cleanup old partitions
./scripts/cleanup-old-logs.sh 7

# Count logs
psql -h cast_postgres -U postgres -d n8n-cast \
  -c "SELECT COUNT(*) FROM message_logs.message_logs;"

# Count by status
psql -h cast_postgres -U postgres -d n8n-cast \
  -c "SELECT status, COUNT(*) FROM message_logs.message_logs GROUP BY status;"
```

## 🔧 Redis

```bash
# Connect to Redis
redis-cli -h cast_redis -p 6379 -a 48612a2f97fcf9e63ef4

# Select database
SELECT 2

# List all keys
KEYS *

# Get queue size
LLEN bull:messages:wait

# Clear specific queue (⚠️ dangerous!)
DEL bull:messages:wait
```

## 🐳 Docker

```bash
# View running containers
docker-compose ps

# View logs for specific service
docker-compose logs -f run-processor
docker-compose logs -f message-worker
docker-compose logs -f api

# Rebuild and restart
docker-compose up -d --build

# Scale workers
docker-compose up -d --scale message-worker=4

# Remove all containers and volumes (⚠️ dangerous!)
docker-compose down -v

# View resource usage
docker stats
```

## 🔄 Circuit Breaker

```bash
# Reset circuit for a page
curl -X POST http://localhost:3100/circuit-breaker/reset/123456789

# Check circuit states
curl http://localhost:3100/stats/circuit-breaker | jq '.circuits'
```

## 📝 Development

```bash
# Install dependencies
npm install

# Build TypeScript
npm run build

# Run in development mode
npm run dev

# Run specific service locally
SERVICE_TYPE=run-processor npm run dev
SERVICE_TYPE=message-worker npm run dev
SERVICE_TYPE=api npm run dev
```

## 🧪 Testing

```bash
# Create test run in Supabase
psql -h qbmbokpbcyempnaravaw.supabase.co -U postgres \
  -c "INSERT INTO message_runs (user_id, flow_id, page_ids, status) VALUES ('test', 'test-flow-id', ARRAY[123456789], 'queued');"

# Monitor Bull Board
open http://localhost:3100/admin/queues

# Watch logs in real-time
docker-compose logs -f | grep -i error
```

## 🧹 Cleanup

```bash
# Remove old Docker images
docker image prune -a

# Remove unused volumes
docker volume prune

# Clear Redis cache (⚠️ dangerous!)
redis-cli -h cast_redis -p 6379 -a 48612a2f97fcf9e63ef4 FLUSHDB

# Drop all message_logs (⚠️ dangerous!)
psql -h cast_postgres -U postgres -d n8n-cast \
  -c "DROP SCHEMA message_logs CASCADE;"
```

## 📊 Performance Testing

```bash
# Monitor messages per second
watch -n 1 'curl -s http://localhost:3100/stats/performance | jq ".queue.completed"'

# Monitor socket reuse
watch -n 1 'curl -s http://localhost:3100/stats/http-client | jq ".performance.socketReuseRate"'

# Monitor queue size
watch -n 1 'curl -s http://localhost:3100/stats/queue | jq ".counts.waiting"'
```

## 🔐 Security

```bash
# Generate strong password
openssl rand -base64 32

# Check open ports
netstat -tuln | grep 3100

# View Docker network
docker network inspect easypanel_default
```

## 📦 Backup & Restore

```bash
# Backup message_logs schema
pg_dump -h cast_postgres -U postgres -d n8n-cast \
  --schema=message_logs \
  --file=message_logs_backup_$(date +%Y%m%d).sql

# Restore message_logs schema
psql -h cast_postgres -U postgres -d n8n-cast \
  -f message_logs_backup_20251104.sql

# Backup .env file
cp .env .env.backup.$(date +%Y%m%d)
```

## 🚨 Emergency

```bash
# Stop all services immediately
docker-compose down

# Kill specific service
docker-compose kill message-worker

# Restart everything
docker-compose restart

# Check system resources
htop
df -h
free -h

# View recent errors
docker-compose logs --tail=100 | grep -i error
```

## 📈 Cron Jobs

```bash
# Edit crontab
crontab -e

# List current cron jobs
crontab -l

# Recommended cron jobs:

# Daily cleanup (2 AM)
0 2 * * * cd /path/to/newar-message-sender && ./scripts/cleanup-old-logs.sh 7

# Monthly partition creation (1st of month, 3 AM)
0 3 1 * * cd /path/to/newar-message-sender && ./scripts/create-future-partitions.sh 30

# Hourly health check
0 * * * * curl -f http://localhost:3100/health || echo "Health check failed" | mail -s "Alert" admin@example.com
```

## 🎯 Quick Fixes

### Service won't start
```bash
docker-compose logs <service-name>
docker-compose restart <service-name>
```

### Queue stuck
```bash
# Check Bull Board
open http://localhost:3100/admin/queues

# Manually retry failed jobs in UI
```

### High memory usage
```bash
# Reduce worker concurrency
echo "WORKER_CONCURRENCY=25" >> .env
docker-compose restart message-worker
```

### Database connection issues
```bash
# Test connection
psql -h cast_postgres -U postgres -d n8n-cast -c "SELECT 1;"

# Check health
curl http://localhost:3100/health
```
