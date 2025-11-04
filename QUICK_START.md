# Quick Start Guide

Get Newar Message Sender running in 5 minutes.

## 1. Run Migrations

```bash
./scripts/run-migrations.sh
```

## 2. Start Services

```bash
docker-compose up -d
```

## 3. Verify

```bash
# Check status
docker-compose ps

# Check health
curl http://localhost:3100/health

# Open Bull Board
open http://localhost:3100/admin/queues
```

## 4. Monitor

```bash
# View logs
docker-compose logs -f

# Check performance
curl http://localhost:3100/stats/performance | jq
```

## 5. Test

Create a test run in Supabase:

```sql
INSERT INTO message_runs (user_id, flow_id, page_ids, status)
VALUES ('test-user', 'test-flow-id', ARRAY[123456789], 'pending');
```

Watch it process in Bull Board UI!

## Troubleshooting

- **Services won't start**: Check `docker-compose logs`
- **No messages processing**: Verify `.env` credentials
- **Database errors**: Run migrations again

## Next Steps

- Read [README.md](README.md) for full documentation
- See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for detailed deployment guide
- Set up cron jobs for log cleanup (see README)

## Support

Having issues? Check:
1. Health endpoint: `curl http://localhost:3100/health`
2. Queue stats: `curl http://localhost:3100/stats/queue`
3. Logs: `docker-compose logs -f`
