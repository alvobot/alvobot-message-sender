// Redis connection configuration
import Redis from 'ioredis';
import env from './env';
import logger from '../utils/logger';

export function createRedisConnection(): Redis {
  const redis = new Redis({
    host: env.redis.host,
    port: env.redis.port,
    password: env.redis.password,
    db: env.redis.db,
    maxRetriesPerRequest: null, // Required for BullMQ
    enableReadyCheck: false,
    retryStrategy: (times: number) => {
      const delay = Math.min(times * 50, 2000);
      logger.warn(`Redis connection attempt ${times}, retrying in ${delay}ms`);
      return delay;
    },
  });

  redis.on('connect', () => {
    logger.info('✅ Redis connected', {
      host: env.redis.host,
      port: env.redis.port,
      db: env.redis.db,
    });
  });

  redis.on('error', (error) => {
    logger.error('❌ Redis connection error', { error: error.message });
  });

  redis.on('close', () => {
    logger.warn('⚠️  Redis connection closed');
  });

  return redis;
}

export const redisConnection = createRedisConnection();

export default redisConnection;
