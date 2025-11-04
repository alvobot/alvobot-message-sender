// Message Worker Service
// Consumes queue and sends messages to Facebook Messenger

import { Worker, Job } from 'bullmq';
import { MESSAGE_QUEUE_NAME } from '../queues/message-queue';
import { workerConfig } from '../queues/queue-config';
import facebookClient from '../integrations/facebook-client';
import circuitBreaker from '../integrations/circuit-breaker';
import logBatchWriter from '../database/log-batch-writer';
import logger from '../utils/logger';
import env from '../config/env';
import { QueueMessagePayload, MessageLog } from '../types';
import { isRateLimitError, isPermanentError, isAuthError } from '../utils/helpers';

class MessageWorkerService {
  private worker: Worker<QueueMessagePayload> | null = null;

  async start() {
    if (this.worker) {
      logger.warn('Message worker already running');
      return;
    }

    logger.info('🚀 Message Worker started', {
      concurrency: workerConfig.concurrency,
      rate_limit: workerConfig.limiter,
    });

    this.worker = new Worker<QueueMessagePayload>(
      MESSAGE_QUEUE_NAME,
      async (job: Job<QueueMessagePayload>) => {
        return await this.processJob(job);
      },
      workerConfig
    );

    // Worker event handlers
    this.worker.on('completed', (job, result) => {
      logger.debug('Job completed', {
        job_id: job.id,
        run_id: job.data.runId,
        page_id: job.data.pageId,
        user_id: job.data.userId,
        success: result.success,
      });
    });

    this.worker.on('failed', (job, error) => {
      logger.error('Job failed permanently', {
        job_id: job?.id,
        run_id: job?.data.runId,
        page_id: job?.data.pageId,
        user_id: job?.data.userId,
        error: error.message,
        attempts: job?.attemptsMade,
      });
    });

    this.worker.on('error', (error) => {
      logger.error('Worker error', { error: error.message });
    });

    this.worker.on('stalled', (jobId) => {
      logger.warn('Job stalled', { job_id: jobId });
    });

    logger.info('✅ Message Worker initialized successfully');
  }

  async stop() {
    if (!this.worker) return;

    logger.info('🛑 Message Worker stopping...');

    await this.worker.close();
    this.worker = null;

    logger.info('✅ Message Worker stopped');
  }

  private async processJob(job: Job<QueueMessagePayload>) {
    const { runId, pageId, userId, pageAccessToken, message } = job.data;

    // Check circuit breaker
    if (circuitBreaker.isCircuitOpen(pageId)) {
      logger.warn('Circuit breaker open, skipping job', {
        job_id: job.id,
        page_id: pageId,
      });

      // Log as auth_error
      await logBatchWriter.add({
        run_id: runId,
        page_id: pageId,
        user_id: userId,
        status: 'auth_error',
        error_code: 'CIRCUIT_OPEN',
        error_message: 'Circuit breaker is open for this page',
      });

      return {
        success: false,
        skipped: true,
        reason: 'circuit_breaker_open',
      };
    }

    // Send message via Facebook API
    const result = await facebookClient.sendMessage(pageAccessToken, userId, message);

    // Create log entry
    const logEntry: MessageLog = {
      run_id: runId,
      page_id: pageId,
      user_id: userId,
      status: result.success ? 'sent' : 'failed',
    };

    if (!result.success && result.error) {
      logEntry.error_code = result.error.code;
      logEntry.error_message = result.error.message;

      // Handle different error types
      if (isRateLimitError(result.error.code)) {
        logEntry.status = 'rate_limited';

        // Retry the job (throw error to trigger BullMQ retry)
        throw new Error(`Rate limited: ${result.error.message}`);
      } else if (isAuthError(result.error.code)) {
        logEntry.status = 'auth_error';

        // Record circuit breaker failure
        circuitBreaker.recordFailure(pageId, result.error.code);

        // Don't retry auth errors
        logger.warn('Auth error, not retrying', {
          page_id: pageId,
          error_code: result.error.code,
          error_message: result.error.message,
        });
      } else if (isPermanentError(result.error.code)) {
        // Don't retry permanent errors
        logger.warn('Permanent error, not retrying', {
          user_id: userId,
          error_code: result.error.code,
          error_message: result.error.message,
        });
      } else {
        // Retry other errors
        throw new Error(`Facebook API error: ${result.error.message}`);
      }
    } else if (result.success) {
      // Record circuit breaker success
      circuitBreaker.recordSuccess(pageId);
      logEntry.sent_at = new Date();
    }

    // Add log to batch writer
    await logBatchWriter.add(logEntry);

    return result;
  }
}

// Export singleton
export const messageWorker = new MessageWorkerService();

// Auto-start if this is the entry point
if (env.serviceType === 'message-worker') {
  messageWorker.start().catch((error) => {
    logger.error('Failed to start message worker', { error: error.message });
    process.exit(1);
  });

  // Graceful shutdown
  process.on('SIGTERM', async () => {
    await messageWorker.stop();
    await logBatchWriter.shutdown();
    process.exit(0);
  });

  process.on('SIGINT', async () => {
    await messageWorker.stop();
    await logBatchWriter.shutdown();
    process.exit(0);
  });
}

export default messageWorker;
