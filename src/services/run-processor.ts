// Run Processor Service
// Polls Supabase for pending runs and enqueues messages in BullMQ

import supabase from '../database/supabase';
import messageQueue from '../queues/message-queue';
import logger from '../utils/logger';
import env from '../config/env';
import { assembleMessages } from '../utils/flow-processor';
import { MessageRun, MessageFlow } from '../types';
import { replacePlaceholders } from '../utils/helpers';

class RunProcessor {
  private pollIntervalMs: number;
  private isRunning = false;
  private isProcessing = false;
  private pollTimer: NodeJS.Timeout | null = null;

  constructor() {
    this.pollIntervalMs = env.pollIntervalMs;
  }

  async start() {
    if (this.isRunning) {
      logger.warn('Run processor already running');
      return;
    }

    this.isRunning = true;
    logger.info('🚀 Run Processor started', {
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

    logger.info('🛑 Run Processor stopped');
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
      await this.processPendingRuns();
    } catch (error: any) {
      logger.error('Error in poll cycle', { error: error.message });
    } finally {
      this.isProcessing = false;
    }

    // Schedule next poll
    this.pollTimer = setTimeout(() => this.poll(), this.pollIntervalMs);
  }

  private async processPendingRuns() {
    const now = new Date().toISOString();

    // Fetch runs that are ready to process
    // Status nomenclature: queued, running, waiting, finished, failed
    //
    // Important: For 'waiting' status, ONLY process if next_step_at has arrived
    // For 'queued' status, process if start_at has arrived or is null
    // For 'running' status, process if next_step_at has arrived or is null
    const { data: runs, error } = await supabase
      .from('message_runs')
      .select('*')
      .in('status', ['queued', 'running', 'waiting'])
      .limit(10); // Process max 10 runs per cycle

    if (error) {
      logger.error('Failed to fetch runs', { error: error.message });
      return;
    }

    if (!runs || runs.length === 0) {
      logger.debug('No runs to process');
      return;
    }

    // Filter runs based on time conditions
    const readyRuns = runs.filter((run) => {
      if (run.status === 'queued') {
        // Process if start_at is null or has passed
        return !run.start_at || new Date(run.start_at) <= new Date(now);
      } else if (run.status === 'waiting') {
        // IMPORTANT: Only process if next_step_at has arrived
        return run.next_step_at && new Date(run.next_step_at) <= new Date(now);
      } else if (run.status === 'running') {
        // Process if next_step_at is null or has passed
        return !run.next_step_at || new Date(run.next_step_at) <= new Date(now);
      }
      return false;
    });

    if (readyRuns.length === 0) {
      logger.debug('No runs ready to process', {
        total_fetched: runs.length,
        filtered_out: runs.length,
      });
      return;
    }

    logger.info(`Found ${readyRuns.length} runs to process`, {
      total_fetched: runs.length,
      ready: readyRuns.length,
    });

    // Process each ready run
    for (const run of readyRuns) {
      try {
        await this.processRun(run as MessageRun);
      } catch (error: any) {
        logger.error('Failed to process run', {
          run_id: run.id,
          error: error.message,
        });

        // Update run status to failed
        await supabase
          .from('message_runs')
          .update({
            status: 'failed',
            error_summary: { error: error.message },
            updated_at: new Date().toISOString(),
          })
          .eq('id', run.id);
      }
    }
  }

  private async processRun(run: MessageRun) {
    logger.info(`Processing run ${run.id}`, {
      run_id: run.id,
      flow_id: run.flow_id,
      status: run.status,
      next_step_id: run.next_step_id,
    });

    // IMPORTANT: Immediately mark as 'running' to prevent duplicate processing
    // This is critical for runs with many subscribers that take time to enqueue
    if (run.status === 'queued') {
      const { error: lockError } = await supabase
        .from('message_runs')
        .update({
          status: 'running',
          updated_at: new Date().toISOString(),
        })
        .eq('id', run.id)
        .eq('status', 'queued'); // Only update if still queued (optimistic locking)

      if (lockError) {
        logger.error(`Failed to lock run ${run.id}`, { error: lockError.message });
        throw new Error(`Failed to lock run: ${lockError.message}`);
      }

      logger.info(`Run ${run.id} locked (queued -> running)`);
    }

    // Fetch flow
    const { data: flow, error: flowError } = await supabase
      .from('message_flows')
      .select('*')
      .eq('id', run.flow_id)
      .single();

    if (flowError || !flow) {
      throw new Error(`Failed to fetch flow: ${flowError?.message || 'Not found'}`);
    }

    // Process flow and assemble messages
    const result = assembleMessages(flow.flow, run.next_step_id);

    logger.info(`Flow processing complete`, {
      run_id: run.id,
      messages_count: result.messages.length,
      is_complete: result.isComplete,
      next_step_id: result.nextStepId,
      next_step_at: result.nextStepAt,
      last_step_id: result.lastStepId,
    });

    // Transform page_ids array
    let pageIds: string[] = [];
    if (Array.isArray(run.page_ids)) {
      // Convert to strings to preserve precision of large IDs
      pageIds = run.page_ids.map((id) => String(id));
    } else if (typeof run.page_ids === 'string') {
      try {
        const parsed = JSON.parse(run.page_ids);
        pageIds = Array.isArray(parsed) ? parsed.map((id) => String(id)) : [String(parsed)];
      } catch {
        pageIds = [String(run.page_ids)];
      }
    }

    // Enqueue messages for each page
    for (const pageId of pageIds) {
      await this.enqueueMessagesForPage(run, pageId, flow, result.messages);
    }

    // Update run status
    // If complete -> 'finished'
    // If has nextStepAt (waiting for time) -> 'waiting'
    // Otherwise -> 'running'
    let newStatus = 'running';
    if (result.isComplete) {
      newStatus = 'finished';
    } else if (result.nextStepAt) {
      newStatus = 'waiting';
    }

    const updateData: any = {
      status: newStatus,
      next_step_id: result.nextStepId,
      next_step_at: result.nextStepAt,
      last_step_id: result.lastStepId,
      updated_at: new Date().toISOString(),
    };

    if (result.isComplete) {
      updateData.completed_at = new Date().toISOString();
    }

    logger.info(`Updating run ${run.id}`, {
      status: newStatus,
      next_step_id: result.nextStepId,
      next_step_at: result.nextStepAt,
      last_step_id: result.lastStepId,
    });

    const { error: updateError } = await supabase
      .from('message_runs')
      .update(updateData)
      .eq('id', run.id);

    if (updateError) {
      logger.error(`Failed to update run ${run.id}`, {
        error: updateError.message,
        updateData,
      });
      throw new Error(`Failed to update run: ${updateError.message}`);
    }

    logger.info(`Run ${run.id} updated successfully`, {
      status: updateData.status,
      next_step_at: updateData.next_step_at,
    });
  }

  private async enqueueMessagesForPage(
    run: MessageRun,
    pageId: string,
    flow: MessageFlow,
    messages: any[]
  ) {
    // Fetch page data with user_id filter and blocking check
    const now = new Date().toISOString();
    const { data: pages, error: pageError } = await supabase
      .from('meta_pages')
      .select('page_id::text, page_name, access_token, is_active, user_id, connection_id, created_at, updated_at')
      .eq('page_id', pageId)
      .eq('user_id', run.user_id)
      .eq('is_active', true)
      .or(`blocked_until.is.null,blocked_until.lt.${now}`);

    if (pageError) {
      logger.error('Failed to fetch page', {
        page_id: pageId,
        user_id: run.user_id,
        error: pageError.message,
      });
      return;
    }

    if (!pages || pages.length === 0) {
      logger.warn('No active/unblocked page connection found, skipping', {
        page_id: pageId,
        user_id: run.user_id,
      });
      return;
    }

    // Use first available page
    const page = pages[0];

    // Fetch ALL active subscribers for this page (with pagination to handle large lists)
    // Supabase has a default limit of 1000 rows, so we need to paginate
    const subscribers: any[] = [];
    const pageSize = 1000;
    let pageNumber = 0;
    let hasMore = true;

    while (hasMore) {
      const { data, error } = await supabase
        .from('meta_subscribers')
        .select('page_id::text, user_id::text')
        .eq('page_id', pageId)
        .eq('is_active', true)
        .range(pageNumber * pageSize, (pageNumber + 1) * pageSize - 1);

      if (error) {
        logger.error('Failed to fetch subscribers', {
          page_id: pageId,
          pageNumber,
          error: error.message,
        });
        return;
      }

      if (!data || data.length === 0) {
        hasMore = false;
      } else {
        subscribers.push(...data);
        hasMore = data.length === pageSize; // If we got a full page, there might be more
        pageNumber++;

        logger.debug('Fetched subscriber page', {
          page_id: pageId,
          pageNumber: pageNumber,
          count: data.length,
          total_so_far: subscribers.length,
        });
      }
    }

    if (subscribers.length === 0) {
      logger.warn('No active subscribers for page', { page_id: pageId });
      return;
    }

    logger.info('Fetched all subscribers for page', {
      page_id: pageId,
      total_subscribers: subscribers.length,
      pages_fetched: page,
    });

    logger.info(`Enqueuing messages for page ${pageId}`, {
      subscribers_count: subscribers.length,
      messages_count: messages.length,
      total_jobs: subscribers.length * messages.length,
    });

    // Enqueue a job for each subscriber × message combination
    // IMPORTANT: Add delay between messages to ensure correct order
    const jobs: Array<{ name: string; data: any; opts?: any }> = [];
    const MESSAGE_DELAY_MS = 2000; // 2 seconds delay between messages for same user

    for (const subscriber of subscribers) {
      // IDs already come as strings from ::text cast
      const userIdStr = subscriber.user_id;

      for (let i = 0; i < messages.length; i++) {
        const message = messages[i];

        // Replace placeholders in message
        // Use structuredClone to preserve object structure
        let messageWithReplacements = structuredClone(message);
        messageWithReplacements = this.replacePlaceholdersInMessage(
          messageWithReplacements,
          { USER_ID: userIdStr }
        );

        // Calculate delay: each message after the first gets delayed
        // Message 0: no delay, Message 1: 2s delay, Message 2: 4s delay, etc.
        const delayMs = i * MESSAGE_DELAY_MS;

        jobs.push({
          name: `run_${run.id}_page_${pageId}_user_${userIdStr}_msg_${i}`,
          data: {
            runId: run.id,
            flowId: flow.id,
            nodeId: 'unknown', // TODO: track node ID
            pageId: page.page_id, // Already a string from ::text cast
            userId: userIdStr,
            pageAccessToken: page.access_token,
            message: messageWithReplacements,
            messageIndex: i, // Track message order
          },
          opts: {
            delay: delayMs > 0 ? delayMs : undefined,
            priority: 100, // Low priority for bulk campaigns
          },
        });
      }
    }

    // Bulk add jobs to queue
    const startTime = Date.now();
    await messageQueue.addBulk(jobs);
    const duration = Date.now() - startTime;

    logger.info(`✅ Jobs enqueued successfully`, {
      page_id: pageId,
      jobs_count: jobs.length,
      duration_ms: duration,
    });
  }

  private replacePlaceholdersInMessage(message: any, replacements: Record<string, string>): any {
    // Custom replacer to handle BigInt serialization
    const bigIntReplacer = (_key: string, value: any) =>
      typeof value === 'bigint' ? value.toString() : value;

    const messageStr = JSON.stringify(message, bigIntReplacer);
    const replaced = replacePlaceholders(messageStr, replacements);
    return JSON.parse(replaced);
  }
}

// Export singleton
export const runProcessor = new RunProcessor();

// Auto-start if this is the entry point
if (env.serviceType === 'run-processor') {
  runProcessor.start().catch((error) => {
    logger.error('Failed to start run processor', { error: error.message });
    process.exit(1);
  });

  // Graceful shutdown
  process.on('SIGTERM', async () => {
    await runProcessor.stop();
    process.exit(0);
  });

  process.on('SIGINT', async () => {
    await runProcessor.stop();
    process.exit(0);
  });
}

export default runProcessor;
