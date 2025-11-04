# EasyPanel Deployment Guide

## Network Configuration

This application uses standard Docker networking, allowing containers to communicate using Docker service names (like `cast_redis`, `cast_postgres`).

## Required Environment Variables

### Redis Configuration

EasyPanel provides a Redis connection URL like:
```
redis://default:48612a2f97fcf9e63ef4@cast_redis:6379
```

Extract these values:
- **Hostname**: `cast_redis` (the part after `@` and before `:`)
- **Password**: `48612a2f97fcf9e63ef4` (the part between `:` and `@`)
- **Port**: `6379` (the part after the last `:`)

Configure in your .env:
```bash
REDIS_HOST=cast_redis
REDIS_PORT=6379
REDIS_PASSWORD=48612a2f97fcf9e63ef4
REDIS_DB=2
```

### PostgreSQL Configuration

EasyPanel provides PostgreSQL connection details. Use the EasyPanel service name:

```bash
POSTGRES_HOST=cast_postgres
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_postgres_password
POSTGRES_DB=n8n-cast
POSTGRES_SCHEMA=message_logs
```

### API Port

The API is exposed on port **3100** externally (mapped from internal port 3000):

```bash
API_PORT=3000  # Internal port - keep as 3000
API_ENABLE_BULL_BOARD=true
```

Access the API at: `http://your-server:3100`

## Complete .env Configuration for EasyPanel

```bash
# Redis - Use EasyPanel's Docker service name
REDIS_HOST=cast_redis
REDIS_PORT=6379
REDIS_PASSWORD=48612a2f97fcf9e63ef4
REDIS_DB=2

# PostgreSQL - Use EasyPanel's Docker service name
POSTGRES_HOST=cast_postgres
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_postgres_password
POSTGRES_DB=n8n-cast
POSTGRES_SCHEMA=message_logs

# Supabase (Cloud)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Worker Configuration
WORKER_CONCURRENCY=50
MAX_SOCKETS=500
POLL_INTERVAL_MS=10000

# Logging
LOG_LEVEL=info
LOG_BATCH_SIZE=200
LOG_BATCH_INTERVAL_MS=2000

# Rate Limiting
RATE_LIMIT_MAX_JOBS_PER_SECOND=100
RATE_LIMIT_PER_PAGE=50

# Circuit Breaker
CIRCUIT_BREAKER_ENABLED=true
CIRCUIT_BREAKER_THRESHOLD=5
CIRCUIT_BREAKER_TIMEOUT_MS=300000

# API Server
API_PORT=3000
API_ENABLE_BULL_BOARD=true
```

## Troubleshooting

### Error: "getaddrinfo EAI_AGAIN cast_redis"

This means the Redis hostname cannot be resolved. Make sure:
- `REDIS_HOST=cast_redis` (use the exact service name from EasyPanel)
- The Redis service is running in EasyPanel
- Both services are in the same Docker network (EasyPanel handles this automatically)

### Error: "listen EADDRINUSE: address already in use :::3000"

Port 3000 is already in use. The API should use the port mapping `3100:3000` to expose on port 3100 externally.

### Environment variables not loading

Make sure you configure all environment variables in the EasyPanel interface:
1. Go to your service settings
2. Add all required variables listed above
3. Redeploy the service

### Containers can't connect to each other

Make sure all your EasyPanel services (Redis, PostgreSQL, this app) are using the default EasyPanel network or create a shared network.
