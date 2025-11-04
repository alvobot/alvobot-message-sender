# EasyPanel Deployment Guide

## Important: Network Configuration

This application uses `network_mode: host` which means containers share the host's network. This has important implications for your environment variables.

## Required Environment Variables

### ⚠️ Redis Configuration

With `network_mode: host`, **you cannot use Docker service names like `cast_redis`**.

You need to use one of these options:

1. **If Redis is on the same machine**: Use `localhost` or `127.0.0.1`
   ```
   REDIS_HOST=localhost
   ```

2. **If Redis is in another EasyPanel service**: Use the actual hostname or IP
   ```
   REDIS_HOST=<redis-ip-or-hostname>
   ```

3. **If you want to use Docker service names**: Remove `network_mode: host` and configure proper Docker networking

### ⚠️ PostgreSQL Configuration

Same rules apply for PostgreSQL:

```
POSTGRES_HOST=localhost  # or the actual IP/hostname
```

### ⚠️ API Port

With `network_mode: host`, the API service will try to bind to port 3000 on the host machine.

- Make sure port 3000 is available on the host
- Or change `API_PORT` to a different port in your .env file

## Complete .env Configuration for EasyPanel

```bash
# Redis - Use localhost if Redis runs on same machine
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password
REDIS_DB=2

# PostgreSQL - Use localhost if Postgres runs on same machine  
POSTGRES_HOST=localhost
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

This means the Redis hostname cannot be resolved. Change `REDIS_HOST` to `localhost` or the actual IP address.

### Error: "listen EADDRINUSE: address already in use :::3000"

Port 3000 is already in use on the host. Either:
- Stop the service using port 3000, or
- Change `API_PORT` to a different port (e.g., 3100)

### Environment variables not loading

Make sure you have a `.env` file in the project root with all required variables set.
