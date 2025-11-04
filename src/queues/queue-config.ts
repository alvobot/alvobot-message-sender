// BullMQ queue configuration
import { QueueOptions, WorkerOptions } from 'bullmq';
import redisConnection from '../config/redis.config';
import env from '../config/env';

export const queueConfig: QueueOptions = {
  connection: redisConnection,
  defaultJobOptions: {
    attempts: 3, // Retry failed jobs 3 times
    backoff: {
      type: 'exponential',
      delay: 2000, // Start with 2s delay
    },
    removeOnComplete: {
      age: 3600, // Keep completed jobs for 1 hour
      count: 1000, // Keep max 1000 completed jobs
    },
    removeOnFail: {
      age: 86400, // Keep failed jobs for 24 hours
      count: 5000, // Keep max 5000 failed jobs
    },
  },
};

export const workerConfig: WorkerOptions = {
  connection: redisConnection,
  concurrency: env.worker.concurrency, // 50 concurrent jobs
  limiter: {
    max: env.rateLimit.maxJobsPerSecond, // 100 jobs per second global
    duration: 1000,
  },
  lockDuration: 30000, // 30 seconds lock (enough time to send message)
};
