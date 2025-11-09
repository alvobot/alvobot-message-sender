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
import { isRateLimitError, isPermanentError, isAuthError, shouldDeactivateSubscriber } from '../utils/helpers';
import { supabase } from '../database/supabase';

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
        trigger_run_id: job.data.triggerRunId,
        page_id: job.data.pageId,
        user_id: job.data.userId,
        success: result.success,
      });
    });

    this.worker.on('failed', (job, error) => {
      logger.error('Job failed permanently', {
        job_id: job?.id,
        run_id: job?.data.runId,
        trigger_run_id: job?.data.triggerRunId,
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
    const { runId, triggerRunId, pageId, userId, pageAccessToken, message } = job.data;

    // Check circuit breaker
    if (circuitBreaker.isCircuitOpen(pageId)) {
      logger.warn('Circuit breaker open, skipping job', {
        job_id: job.id,
        page_id: pageId,
      });

      // Log as auth_error
      await logBatchWriter.add({
        run_id: runId,
        trigger_run_id: triggerRunId,
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
      trigger_run_id: triggerRunId,
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

        // Deactivate subscriber if error 551 (user not available)
        // Also cancel trigger_run if this is from a trigger (not bulk campaign)
        // Run async without await to not block job processing
        if (shouldDeactivateSubscriber(result.error.code)) {
          // Convert triggerRunId to string (it comes as number from queue)
          const triggerRunIdStr = triggerRunId ? String(triggerRunId) : null;
          this.handleUnavailableUser(pageId, userId, triggerRunIdStr, result.error).catch((err) => {
            logger.error('Background deactivation/cancellation failed', {
              page_id: pageId,
              user_id: userId,
              trigger_run_id: triggerRunId,
              error: err.message,
            });
          });
        }
      } else {
        // Retry other errors
        logger.warn('Retrying job due to error', {
          job_id: job.id,
          page_id: pageId,
          user_id: userId,
          error_code: result.error.code,
          error_message: result.error.message,
          error_type: result.error.type,
        });
        throw new Error(`Facebook API error: ${result.error.code} - ${result.error.message}`);
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

  /**
   * Handle unavailable user (blocked, deleted account, etc)
   * 1. Deactivates subscriber in database
   * 2. Cancels trigger_run if this is from a trigger (not bulk campaign)
   *
   * Called when Facebook returns errors like:
   * - 551: User is unavailable
   * - 10: User does not exist
   * - 200: User has blocked the page
   */
  private async handleUnavailableUser(
    pageId: string,
    userId: string,
    triggerRunId: string | null | undefined,
    error: { code: string; message: string }
  ): Promise<void> {
    try {
      // 1. Deactivate subscriber
      const { error: subscriberError } = await supabase
        .from('meta_subscribers')
        .update({
          is_active: false,
          updated_at: new Date().toISOString(),
        })
        .eq('page_id', pageId)
        .eq('user_id', userId);

      if (subscriberError) {
        logger.error('Failed to deactivate subscriber', {
          page_id: pageId,
          user_id: userId,
          error: subscriberError.message,
        });
      } else {
        logger.info('Subscriber deactivated due to Facebook error', {
          page_id: pageId,
          user_id: userId,
          error_code: error.code,
          error_message: error.message,
        });
      }

      // 2. Cancel trigger_run if this is from a trigger (not bulk campaign)
      if (triggerRunId) {
        const { error: triggerRunError } = await supabase
          .from('trigger_runs')
          .update({
            status: 'cancelled',
            error_details: {
              reason: `User unavailable: ${error.message}`,
              facebook_error_code: error.code,
              timestamp: new Date().toISOString(),
            },
            updated_at: new Date().toISOString(),
          })
          .eq('id', triggerRunId);

        if (triggerRunError) {
          logger.error('Failed to cancel trigger_run', {
            trigger_run_id: triggerRunId,
            error: triggerRunError.message,
          });
        } else {
          logger.info('Trigger_run cancelled due to unavailable user', {
            trigger_run_id: triggerRunId,
            page_id: pageId,
            user_id: userId,
            facebook_error_code: error.code,
          });
        }
      }
    } catch (error: any) {
      logger.error('Exception handling unavailable user', {
        page_id: pageId,
        user_id: userId,
        trigger_run_id: triggerRunId,
        error: error.message,
      });
    }
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
