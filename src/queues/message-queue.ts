// BullMQ message queue setup
import { Queue } from 'bullmq';
import { queueConfig } from './queue-config';
import logger from '../utils/logger';
import { QueueMessagePayload } from '../types';

export const MESSAGE_QUEUE_NAME = 'messages';

export const messageQueue = new Queue<QueueMessagePayload>(
  MESSAGE_QUEUE_NAME,
  queueConfig
);

messageQueue.on('error', (error) => {
  logger.error('❌ Message queue error', { error: error.message });
});

messageQueue.on('waiting', (job) => {
  logger.debug('Job waiting', { job_id: job?.id || 'unknown' });
});

logger.info('✅ Message queue initialized', {
  queue_name: MESSAGE_QUEUE_NAME,
});

export default messageQueue;
