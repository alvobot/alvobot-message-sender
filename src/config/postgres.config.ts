// PostgreSQL connection configuration
import { Pool, PoolConfig } from 'pg';
import env from './env';
import logger from '../utils/logger';

const poolConfig: PoolConfig = {
  host: env.postgres.host,
  port: env.postgres.port,
  user: env.postgres.user,
  password: env.postgres.password,
  database: env.postgres.database,
  max: 20, // Maximum pool size
  min: 2, // Minimum pool size
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
};

export const pool = new Pool(poolConfig);

// Set search_path to message_logs schema
pool.on('connect', async (client) => {
  await client.query(`SET search_path TO ${env.postgres.schema}, public`);
});

pool.on('error', (error) => {
  logger.error('❌ PostgreSQL pool error', { error: error.message });
});

pool.on('connect', () => {
  logger.debug('PostgreSQL client connected to pool');
});

pool.on('remove', () => {
  logger.debug('PostgreSQL client removed from pool');
});

// Test connection on startup
export async function testPostgresConnection(): Promise<void> {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    client.release();

    logger.info('✅ PostgreSQL connected', {
      host: env.postgres.host,
      port: env.postgres.port,
      database: env.postgres.database,
      schema: env.postgres.schema,
      serverTime: result.rows[0].now,
    });
  } catch (error: any) {
    logger.error('❌ PostgreSQL connection failed', { error: error.message });
    throw error;
  }
}

// Graceful shutdown
export async function closePostgresPool(): Promise<void> {
  await pool.end();
  logger.info('PostgreSQL pool closed');
}

export default pool;
