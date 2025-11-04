// Rate limiter using Redis
// Implements token bucket algorithm for per-page rate limiting

import Redis from 'ioredis';
import redisConnection from '../config/redis.config';
import logger from '../utils/logger';
import env from '../config/env';

class RateLimiter {
  private redis: Redis;
  private readonly maxPerPage: number;
  private readonly windowMs: number = 1000; // 1 second window

  constructor(redis: Redis) {
    this.redis = redis;
    this.maxPerPage = env.rateLimit.perPage;

    logger.info('🚦 Rate Limiter initialized', {
      max_per_page: this.maxPerPage,
      window_ms: this.windowMs,
    });
  }

  /**
   * Check if a request is allowed for a page
   * Returns true if allowed, false if rate limited
   */
  async isAllowed(pageId: number): Promise<boolean> {
    const key = `rate_limit:page:${pageId}`;
    const now = Date.now();
    const windowStart = now - this.windowMs;

    try {
      // Use Redis sorted set with timestamps as scores
      const multi = this.redis.multi();

      // Remove old entries outside the window
      multi.zremrangebyscore(key, '-inf', windowStart);

      // Count current entries in window
      multi.zcard(key);

      // Add current request with timestamp
      multi.zadd(key, now, `${now}:${Math.random()}`);

      // Set expiry on key
      multi.expire(key, 2);

      const results = await multi.exec();

      if (!results) {
        logger.error('Rate limiter multi command failed');
        return true; // Fail open
      }

      const count = results[1][1] as number;

      if (count >= this.maxPerPage) {
        logger.debug('Rate limit exceeded', {
          page_id: pageId,
          current_count: count,
          max_allowed: this.maxPerPage,
        });
        return false;
      }

      return true;
    } catch (error: any) {
      logger.error('Rate limiter error', {
        page_id: pageId,
        error: error.message,
      });
      return true; // Fail open (allow request on error)
    }
  }

  /**
   * Get current rate limit stats for a page
   */
  async getStats(pageId: number): Promise<{
    current: number;
    max: number;
    remaining: number;
  }> {
    const key = `rate_limit:page:${pageId}`;
    const now = Date.now();
    const windowStart = now - this.windowMs;

    try {
      await this.redis.zremrangebyscore(key, '-inf', windowStart);
      const count = await this.redis.zcard(key);

      return {
        current: count,
        max: this.maxPerPage,
        remaining: Math.max(0, this.maxPerPage - count),
      };
    } catch (error: any) {
      logger.error('Error getting rate limit stats', {
        page_id: pageId,
        error: error.message,
      });
      return {
        current: 0,
        max: this.maxPerPage,
        remaining: this.maxPerPage,
      };
    }
  }

  /**
   * Reset rate limit for a page
   */
  async reset(pageId: number): Promise<void> {
    const key = `rate_limit:page:${pageId}`;
    try {
      await this.redis.del(key);
      logger.debug('Rate limit reset', { page_id: pageId });
    } catch (error: any) {
      logger.error('Error resetting rate limit', {
        page_id: pageId,
        error: error.message,
      });
    }
  }
}

export const rateLimiter = new RateLimiter(redisConnection);
export default rateLimiter;
