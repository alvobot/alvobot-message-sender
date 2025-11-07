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
    this.worker.on('completed', async (job, result) => {
      logger.debug('Job completed', {
        job_id: job.id,
        run_id: job.data.runId,
        page_id: job.data.pageId,
        user_id: job.data.userId,
        success: result.success,
      });

      // Check if all jobs for this run are completed
      await this.checkRunCompletion(job.data.runId);
    });

    this.worker.on('failed', async (job, error) => {
      logger.error('Job failed permanently', {
        job_id: job?.id,
        run_id: job?.data.runId,
        page_id: job?.data.pageId,
        user_id: job?.data.userId,
        error: error.message,
        attempts: job?.attemptsMade,
      });

      // Check if all jobs for this run are completed (including failed ones)
      if (job?.data.runId) {
        await this.checkRunCompletion(job.data.runId);
      }
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

        // Deactivate subscriber if error 551 (user not available)
        if (shouldDeactivateSubscriber(result.error.code)) {
          await this.deactivateSubscriber(pageId, userId);
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
   * Check if all jobs for a run are completed and update completed_at
   */
  private async checkRunCompletion(runId: number): Promise<void> {
    try {
      const { default: messageQueue } = await import('../queues/message-queue');

      // Get all jobs for this run that are still pending
      const [waiting, active, delayed] = await Promise.all([
        messageQueue.getJobs(['waiting']),
        messageQueue.getJobs(['active']),
        messageQueue.getJobs(['delayed']),
      ]);

      const allPendingJobs = [...waiting, ...active, ...delayed];
      const runPendingJobs = allPendingJobs.filter((job: any) => job.data.runId === runId);

      // If no more pending jobs for this run, mark as completed
      if (runPendingJobs.length === 0) {
        const { error } = await supabase
          .from('message_runs')
          .update({ completed_at: new Date().toISOString() })
          .eq('id', runId)
          .is('completed_at', null); // Only update if not already set

        if (error) {
          logger.error('Failed to update completed_at', {
            run_id: runId,
            error: error.message,
          });
        } else {
          logger.info('✅ Run completed - all messages sent', {
            run_id: runId,
            completed_at: new Date().toISOString(),
          });
        }
      }
    } catch (error: any) {
      logger.error('Error checking run completion', {
        run_id: runId,
        error: error.message,
      });
    }
  }

  /**
   * Deactivate a subscriber in the database
   * Called when error 551 (user not available) is received
   */
  private async deactivateSubscriber(pageId: string, userId: string): Promise<void> {
    try {
      const { error } = await supabase
        .from('meta_subscribers')
        .update({
          is_active: false,
          updated_at: new Date().toISOString(),
        })
        .eq('page_id', pageId)
        .eq('user_id', userId);

      if (error) {
        logger.error('Failed to deactivate subscriber', {
          page_id: pageId,
          user_id: userId,
          error: error.message,
        });
      } else {
        logger.info('Subscriber deactivated due to error 551', {
          page_id: pageId,
          user_id: userId,
        });
      }
    } catch (error: any) {
      logger.error('Exception deactivating subscriber', {
        page_id: pageId,
        user_id: userId,
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
