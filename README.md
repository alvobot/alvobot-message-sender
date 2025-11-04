# Newar Message Sender

High-performance Facebook Messenger message sender with BullMQ, HTTP connection pooling, and optimized database logging.

## 🚀 Features

- ✅ **High Performance**: 200-300 messages/second (vs 50 msgs/s with edge functions)
- ✅ **HTTP Connection Pooling**: 500 concurrent sockets with `agentkeepalive` (eliminates connection overhead)
- ✅ **BullMQ Queue System**: Reliable message queue with Redis
- ✅ **Optimized Logging**: Batch writes + PostgreSQL partitioning with auto-cleanup (7 days retention)
- ✅ **Circuit Breaker**: Auto-pause pages with authentication errors
- ✅ **Rate Limiting**: Per-page and global rate limiting
- ✅ **Bull Board UI**: Real-time queue monitoring dashboard
- ✅ **Docker Compose**: Easy deployment on EasyPanel or any Docker host
- ✅ **Graceful Shutdown**: Proper cleanup on SIGTERM/SIGINT

## 📊 Architecture

```
Supabase (Cloud)
  - message_runs (read-only)
  - message_flows (read-only)
  - meta_pages (read-only)
  - meta_subscribers (read-only)
        ↓
Run Processor Service
  - Polls for pending runs every 10s
  - Processes flow graphs
  - Enqueues messages to BullMQ
        ↓
Redis + BullMQ
  - Message queue
  - Dead letter queue
        ↓
Message Worker Service (2 replicas × 50 concurrency = 100 workers)
  - Consumes queue
  - HTTP pooling (500 sockets)
  - Sends to Facebook API
  - Batch logs to PostgreSQL
        ↓
PostgreSQL (Local)
  - message_logs schema
  - Partitioned by date
  - Auto-cleanup after 7 days
```

## 🛠️ Tech Stack

- **Language**: Node.js 20 + TypeScript
- **Queue**: BullMQ (Redis)
- **Database**: PostgreSQL (partitioned logs)
- **HTTP Client**: Axios + agentkeepalive
- **Monitoring**: Bull Board UI
- **Logging**: Winston
- **Deployment**: Docker Compose

## 📦 Installation

### Prerequisites

- Node.js 20+
- Docker & Docker Compose (for deployment)
- PostgreSQL (provided by EasyPanel)
- Redis (provided by EasyPanel)
- Supabase account

### Local Development

```bash
# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your credentials
nano .env

# Run migrations
./scripts/run-migrations.sh

# Build TypeScript
npm run build

# Run services (choose one)
npm run run-processor  # Run processor
npm run message-worker  # Message worker
npm run api            # API server
```

## 🚀 Deployment (EasyPanel)

### 1. Run Migrations

First, run the PostgreSQL migrations to create the schema and tables:

```bash
./scripts/run-migrations.sh
```

This will:
- Create `message_logs` schema
- Create partitioned `message_logs` table
- Create indexes
- Create 30 days of partitions
- Create utility functions

### 2. Deploy with Docker Compose

```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

### 3. Access Services

- **Bull Board UI**: http://your-server:3100/admin/queues
- **Health Check**: http://your-server:3100/health
- **Performance Stats**: http://your-server:3100/stats/performance
- **HTTP Client Stats**: http://your-server:3100/stats/http-client

## ⚙️ Configuration

All configuration is done via environment variables in `.env`:

### Service Configuration
```bash
SERVICE_TYPE=run-processor  # or message-worker, or api
NODE_ENV=production
```

### Redis
```bash
REDIS_HOST=cast_redis
REDIS_PORT=6379
REDIS_PASSWORD=your_password
REDIS_DB=2  # Using DB 2 (n8n uses DB 1)
```

### PostgreSQL
```bash
POSTGRES_HOST=cast_postgres
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_password
POSTGRES_DB=n8n-cast
POSTGRES_SCHEMA=message_logs
```

### Supabase
```bash
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJxxx...
```

### Worker Configuration
```bash
WORKER_CONCURRENCY=50  # Jobs per worker
MAX_SOCKETS=500       # HTTP connection pool size
POLL_INTERVAL_MS=10000  # Run processor polling interval
```

### Logging
```bash
LOG_LEVEL=info
LOG_BATCH_SIZE=200
LOG_BATCH_INTERVAL_MS=2000
LOG_RETENTION_DAYS=7
```

### Rate Limiting
```bash
RATE_LIMIT_MAX_JOBS_PER_SECOND=100
RATE_LIMIT_PER_PAGE=50
```

### Circuit Breaker
```bash
CIRCUIT_BREAKER_ENABLED=true
CIRCUIT_BREAKER_THRESHOLD=5
CIRCUIT_BREAKER_TIMEOUT_MS=300000
```

## 📊 Monitoring

### Bull Board UI

Access the Bull Board UI to monitor queues in real-time:

http://your-server:3100/admin/queues

Features:
- View queue size and job counts
- Inspect job details
- Retry failed jobs
- View job logs
- Monitor throughput

### Performance Stats

```bash
curl http://your-server:3100/stats/performance
```

Returns:
```json
{
  "timestamp": "2025-11-04T...",
  "queue": {
    "waiting": 1234,
    "active": 50,
    "completed": 45678,
    "failed": 12
  },
  "http_client": {
    "total_requests": 50000,
    "active_sockets": 487,
    "free_sockets": 13,
    "socket_reuse_rate": "99.96%"
  },
  "log_writer": {
    "buffered": 125,
    "fill_percentage": "62.50%"
  },
  "circuit_breaker": {
    "open_circuits": 0,
    "total_circuits": 5
  }
}
```

## 🧹 Maintenance

### Create Future Partitions

Run monthly to create partitions for the next 30 days:

```bash
./scripts/create-future-partitions.sh 30
```

### Cleanup Old Logs

Run daily to remove partitions older than 7 days:

```bash
./scripts/cleanup-old-logs.sh 7
```

### Set up Cron Job

```bash
# Add to crontab
crontab -e

# Run cleanup daily at 2 AM
0 2 * * * /path/to/newar-message-sender/scripts/cleanup-old-logs.sh 7

# Create future partitions monthly
0 3 1 * * /path/to/newar-message-sender/scripts/create-future-partitions.sh 30
```

### Reset Circuit Breaker

If a page's circuit breaker is open and you've fixed the issue:

```bash
curl -X POST http://your-server:3100/circuit-breaker/reset/123456789
```

## 📈 Performance

### Expected Throughput

| Metric | Old (Edge Functions) | New (Standalone) | Improvement |
|--------|---------------------|------------------|-------------|
| **Messages/second** | 50 | 200-300 | **4-6x** |
| **Latency P50** | 200ms | 50-80ms | **2.5-4x** |
| **Latency P95** | 500ms | 150ms | **3.3x** |
| **Daily capacity** | 4.3M | 17-25M | **4-6x** |
| **HTTP connections** | ~10 | 500 | **50x** |
| **Socket reuse** | 0% | >99% | **∞** |

### Resource Usage

- **CPU**: ~2 vCPUs (2 workers × 50 concurrency)
- **RAM**: ~4GB total
  - Run processor: ~512MB
  - Message worker (×2): ~1.5GB each
  - API server: ~512MB
- **Disk**: Logs grow ~100MB/day (auto-cleanup after 7 days)

## 🐛 Troubleshooting

### Queue not processing messages

Check worker status:
```bash
docker-compose logs message-worker
```

Check queue stats:
```bash
curl http://your-server:3100/stats/queue
```

### High error rate

Check circuit breaker status:
```bash
curl http://your-server:3100/stats/circuit-breaker
```

Check failed jobs in Bull Board UI.

### Database connection errors

Test PostgreSQL connection:
```bash
curl http://your-server:3100/health
```

Check PostgreSQL logs:
```bash
docker-compose logs postgres
```

### Memory issues

Reduce worker concurrency in `.env`:
```bash
WORKER_CONCURRENCY=25  # Reduce from 50
```

Or reduce number of worker replicas in `docker-compose.yml`.

## 📝 License

MIT

## 🤝 Contributing

Contributions welcome! Please open an issue or PR.

## 📧 Support

For issues, please open a GitHub issue or contact the development team.
