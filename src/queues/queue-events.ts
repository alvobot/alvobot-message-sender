// BullMQ queue events listener
import { QueueEvents } from 'bullmq';
import { MESSAGE_QUEUE_NAME } from './message-queue';
import redisConnection from '../config/redis.config';
import logger from '../utils/logger';

export const queueEvents = new QueueEvents(MESSAGE_QUEUE_NAME, {
  connection: redisConnection,
});

queueEvents.on('completed', ({ jobId, returnvalue }) => {
  logger.debug('Job completed', {
    job_id: jobId,
    success: returnvalue?.success,
  });
});

queueEvents.on('failed', ({ jobId, failedReason }) => {
  logger.warn('Job failed', {
    job_id: jobId,
    reason: failedReason,
  });
});

queueEvents.on('progress', ({ jobId, data }) => {
  logger.debug('Job progress', {
    job_id: jobId,
    progress: data,
  });
});

queueEvents.on('stalled', ({ jobId }) => {
  logger.warn('⚠️  Job stalled', { job_id: jobId });
});

logger.info('✅ Queue events listener initialized');

export default queueEvents;
