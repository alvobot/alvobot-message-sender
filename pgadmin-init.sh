#!/bin/bash
# Create pgpass file for automatic authentication
mkdir -p /tmp
echo "postgres:5432:*:postgres:${POSTGRES_PASSWORD}" > /tmp/pgpassfile
chmod 600 /tmp/pgpassfile
