// Trigger Run Processor Service
// Polls Supabase for pending trigger_runs and enqueues messages in BullMQ
// Processes individual user triggers (keywords, events, etc.) with high priority

import supabase from '../database/supabase';
import messageQueue from '../queues/message-queue';
import logger from '../utils/logger';
import env from '../config/env';
import { assembleMessages } from '../utils/flow-processor';
import { replacePlaceholders } from '../utils/helpers';

interface TriggerRun {
  id: number;
  trigger_id: number;
  recipient_user_id: string;
  page_id: number | null;
  flow_id: string | null;
  status: string;
  start_at: string | null;
  completed_at: string | null;
  created_at: string;
  updated_at: string | null;
  next_step_at: string | null;
  next_step_id: string | null;
  last_step_id: string | null;
  trigger_context: any;
  message_dispatches: any[];
  error_details: any;
  owner_user_id: string;
}

class TriggerRunProcessor {
  private pollIntervalMs: number;
  private isRunning = false;
  private isProcessing = false;
  private pollTimer: NodeJS.Timeout | null = null;

  constructor() {
    this.pollIntervalMs = env.pollIntervalMs;
  }

  async start() {
    if (this.isRunning) {
      logger.warn('Trigger run processor already running');
      return;
    }

    this.isRunning = true;
    logger.info('🚀 Trigger Run Processor started', {
      poll_interval_ms: this.pollIntervalMs,
    });

    // Start polling
    this.poll();
  }

  async stop() {
    this.isRunning = false;

    if (this.pollTimer) {
      clearTimeout(this.pollTimer);
      this.pollTimer = null;
    }

    logger.info('🛑 Trigger Run Processor stopped');
  }

  private async poll() {
    if (!this.isRunning) return;

    // Prevent concurrent processing - skip if previous poll is still running
    if (this.isProcessing) {
      logger.warn('Previous poll cycle still running, skipping this cycle', {
        poll_interval_ms: this.pollIntervalMs,
      });
      this.pollTimer = setTimeout(() => this.poll(), this.pollIntervalMs);
      return;
    }

    try {
      this.isProcessing = true;
      await this.processPendingTriggerRuns();
    } catch (error: any) {
      logger.error('Error in trigger poll cycle', { error: error.message });
    } finally {
      this.isProcessing = false;
    }

    // Schedule next poll
    this.pollTimer = setTimeout(() => this.poll(), this.pollIntervalMs);
  }

  private async processPendingTriggerRuns() {
    const now = new Date().toISOString();

    // Fetch trigger_runs that are ready to process
    // OPTIMIZATION: Filter by time conditions directly in SQL query instead of
    // fetching all and filtering in code. This is much more efficient.
    //
    // Status nomenclature: queued, running, waiting, finished, failed, cancelled
    //
    // NOTE: We don't query for 'running' status to prevent duplicate processing.
    // Runs are marked as 'running' immediately after being fetched, so they won't
    // be picked up again in the next poll cycle. If a process crashes while a run
    // is 'running', manual recovery will be needed (change status back to 'queued').
    const { data: runs, error } = await supabase
      .from('trigger_runs')
      .select('*, recipient_user_id::text')
      .or(
        `and(status.eq.queued,or(start_at.is.null,start_at.lte.${now})),` +
        `and(status.eq.waiting,next_step_at.lte.${now})`
      )
      .order('created_at', { ascending: true })
      .limit(1000); // Process up to 1000 ready trigger runs per cycle

    if (error) {
      logger.error('Failed to fetch trigger runs', { error: error.message });
      return;
    }

    if (!runs || runs.length === 0) {
      logger.debug('No trigger runs ready to process');
      return;
    }

    logger.info(`Processing ${runs.length} trigger runs`, {
      trigger_runs_count: runs.length,
    });

    // Process each run
    for (const run of runs) {
      try {
        await this.processTriggerRun(run);
      } catch (error: any) {
        logger.error('Failed to process trigger run', {
          trigger_run_id: run.id,
          error: error.message,
        });

        // Mark run as failed
        await supabase
          .from('trigger_runs')
          .update({
            status: 'failed',
            error_details: {
              message: error.message,
              timestamp: new Date().toISOString(),
            },
            updated_at: new Date().toISOString(),
          })
          .eq('id', run.id);
      }
    }
  }

  private async processTriggerRun(run: TriggerRun) {
    logger.info('Processing trigger run', {
      trigger_run_id: run.id,
      trigger_id: run.trigger_id,
      recipient_user_id: run.recipient_user_id,
      page_id: run.page_id,
      flow_id: run.flow_id,
      status: run.status,
    });

    // IMPORTANT: Immediately mark as 'running' to prevent duplicate processing
    // Use optimistic locking to ensure only one process updates this run
    if (run.status === 'queued') {
      const { error: lockError } = await supabase
        .from('trigger_runs')
        .update({
          status: 'running',
          updated_at: new Date().toISOString(),
        })
        .eq('id', run.id)
        .eq('status', 'queued'); // Only update if still queued (optimistic locking)

      if (lockError) {
        logger.error(`Failed to lock trigger run ${run.id}`, { error: lockError.message });
        throw new Error(`Failed to lock trigger run: ${lockError.message}`);
      }

      logger.info(`Trigger run ${run.id} locked (queued -> running)`);
    }

    // Validate required fields
    if (!run.page_id) {
      throw new Error('Trigger run missing page_id');
    }

    if (!run.flow_id) {
      throw new Error('Trigger run missing flow_id');
    }

    // Fetch page data with user_id filter and blocking check
    const now = new Date().toISOString();
    const { data: pages, error: pageError } = await supabase
      .from('meta_pages')
      .select('page_id::text, access_token, is_active')
      .eq('page_id', run.page_id)
      .eq('user_id', run.owner_user_id)
      .eq('is_active', true)
      .or(`blocked_until.is.null,blocked_until.lt.${now}`);

    if (pageError) {
      throw new Error(`Failed to fetch page ${run.page_id}: ${pageError.message}`);
    }

    if (!pages || pages.length === 0) {
      logger.warn('No active/unblocked page connection found, cancelling trigger run', {
        trigger_run_id: run.id,
        page_id: run.page_id,
        owner_user_id: run.owner_user_id,
      });

      // Mark as cancelled (not failed - this is a business rule, not an error)
      await supabase
        .from('trigger_runs')
        .update({
          status: 'cancelled',
          error_details: {
            reason: 'No active page connection found or page is blocked',
            timestamp: new Date().toISOString(),
          },
          updated_at: new Date().toISOString(),
        })
        .eq('id', run.id);

      return;
    }

    // Use first available page
    const page = pages[0];

    // NOTE: We don't validate subscriber status here (was removed for performance).
    // Instead, we let Facebook API tell us if the user is unavailable/blocked.
    // The message-worker will handle Facebook errors and update subscriber.is_active
    // and trigger_run status accordingly. This saves 1000s of SELECT queries per cycle.

    // Fetch flow
    const { data: flowData, error: flowError } = await supabase
      .from('message_flows')
      .select('*')
      .eq('id', run.flow_id)
      .single();

    if (flowError || !flowData) {
      throw new Error(`Failed to fetch flow ${run.flow_id}: ${flowError?.message}`);
    }

    // IMPORTANT: Flow structure is nested in flow.flow (same as run-processor)
    if (!flowData.flow) {
      throw new Error(`Flow ${run.flow_id} has no flow property`);
    }

    logger.debug('Flow structure validated', {
      trigger_run_id: run.id,
      nodes_count: flowData.flow.nodes?.length || 0,
      connections_count: flowData.flow.connections?.length || 0,
    });

    // Process flow to get messages (use flow.flow like run-processor does)
    // IMPORTANT: Use next_step_id (not last_step_id) - same as run-processor
    const result = await assembleMessages(flowData.flow, run.next_step_id);

    // Ensure messages array exists
    const messages = result.messages || [];

    logger.info('Flow processing complete', {
      trigger_run_id: run.id,
      flow_id: flowData.id,
      messages_count: messages.length,
      is_complete: result.isComplete,
      next_step_id: result.nextStepId,
      next_step_at: result.nextStepAt,
      last_step_id: result.lastStepId,
    });

    // Enqueue jobs for the single recipient
    await this.enqueueJobsForTrigger(run, page, flowData, messages);

    // Update run status based on flow result
    let newStatus = 'running';
    let completedAt: string | null = null;

    if (result.isComplete) {
      newStatus = 'finished';
      completedAt = new Date().toISOString();
    } else if (result.nextStepAt) {
      newStatus = 'waiting';
    } else if (messages.length === 0 && !result.nextStepId) {
      // If no messages and no next step, mark as finished
      // This prevents infinite loop when flow has no messages to send
      newStatus = 'finished';
      completedAt = new Date().toISOString();
      logger.warn('Flow returned 0 messages with no next step, marking as finished', {
        trigger_run_id: run.id,
        is_complete: result.isComplete,
        next_step_id: result.nextStepId,
      });
    }

    const { error: updateError } = await supabase
      .from('trigger_runs')
      .update({
        status: newStatus,
        next_step_id: result.nextStepId,
        next_step_at: result.nextStepAt,
        last_step_id: result.lastStepId,
        completed_at: completedAt,
        updated_at: new Date().toISOString(),
      })
      .eq('id', run.id);

    if (updateError) {
      logger.error('Failed to update trigger run', {
        trigger_run_id: run.id,
        error: updateError.message,
      });
    }

    logger.info(`✅ Trigger run ${run.id} processed successfully`, {
      new_status: newStatus,
      next_step_at: result.nextStepAt,
    });
  }

  /**
   * Enqueue jobs for a single recipient (trigger)
   * Jobs are enqueued with priority 1 (high priority)
   */
  private async enqueueJobsForTrigger(
    run: TriggerRun,
    page: any,
    flow: any,
    messages: any[]
  ) {
    if (messages.length === 0) {
      logger.warn('No messages to send for trigger run', {
        trigger_run_id: run.id,
      });
      return;
    }

    const jobs: Array<{ name: string; data: any; opts?: any }> = [];
    const MESSAGE_DELAY_MS = 2000; // 2 seconds delay between messages for same user

    const userId = run.recipient_user_id;

    for (let i = 0; i < messages.length; i++) {
      const message = messages[i];

      // Replace placeholders in message
      // Use structuredClone to preserve object structure
      let messageWithReplacements = structuredClone(message);
      messageWithReplacements = this.replacePlaceholdersInMessage(
        messageWithReplacements,
        { USER_ID: userId }
      );

      // Calculate delay: each message after the first gets delayed
      // Message 0: no delay, Message 1: 2s delay, Message 2: 4s delay, etc.
      const delayMs = i * MESSAGE_DELAY_MS;

      jobs.push({
        name: `trigger_${run.id}_page_${run.page_id}_user_${userId}_msg_${i}`,
        data: {
          triggerRunId: run.id,
          flowId: flow.id,
          nodeId: 'unknown', // TODO: track node ID
          pageId: page.page_id, // Already a string from ::text cast
          userId: userId,
          pageAccessToken: page.access_token,
          message: messageWithReplacements,
          messageIndex: i, // Track message order
        },
        opts: {
          delay: delayMs > 0 ? delayMs : undefined,
          priority: 1, // HIGH PRIORITY for triggers
        },
      });
    }

    // Bulk add jobs to queue
    const startTime = Date.now();
    await messageQueue.addBulk(jobs);
    const duration = Date.now() - startTime;

    logger.info(`✅ Trigger jobs enqueued successfully`, {
      trigger_run_id: run.id,
      page_id: run.page_id,
      recipient_user_id: run.recipient_user_id,
      jobs_count: jobs.length,
      duration_ms: duration,
      priority: 1,
    });
  }

  /**
   * Replace placeholders in message (recursive for nested objects)
   */
  private replacePlaceholdersInMessage(message: any, context: Record<string, string>): any {
    if (typeof message === 'string') {
      return replacePlaceholders(message, context);
    }

    if (Array.isArray(message)) {
      return message.map((item) => this.replacePlaceholdersInMessage(item, context));
    }

    if (typeof message === 'object' && message !== null) {
      const result: any = {};
      for (const [key, value] of Object.entries(message)) {
        result[key] = this.replacePlaceholdersInMessage(value, context);
      }
      return result;
    }

    return message;
  }
}

// Export singleton
export const triggerRunProcessor = new TriggerRunProcessor();

// Auto-start if this is the entry point
if (env.serviceType === 'trigger-run-processor') {
  triggerRunProcessor.start().catch((error) => {
    logger.error('Failed to start trigger run processor', { error: error.message });
    process.exit(1);
  });

  // Graceful shutdown
  process.on('SIGTERM', async () => {
    await triggerRunProcessor.stop();
    process.exit(0);
  });

  process.on('SIGINT', async () => {
    await triggerRunProcessor.stop();
    process.exit(0);
  });
}

export default triggerRunProcessor;
