// API Service
// Provides Bull Board UI, health checks, and metrics endpoints

import express, { Request, Response } from 'express';
import { createBullBoard } from '@bull-board/api';
import { BullMQAdapter } from '@bull-board/api/bullMQAdapter';
import { ExpressAdapter } from '@bull-board/express';
import messageQueue from '../queues/message-queue';
import facebookClient from '../integrations/facebook-client';
import circuitBreaker from '../integrations/circuit-breaker';
import logBatchWriter from '../database/log-batch-writer';
import { testPostgresConnection } from '../config/postgres.config';
import logger from '../utils/logger';
import env from '../config/env';

class ApiServer {
  private app: express.Application;
  private server: any = null;

  constructor() {
    this.app = express();
    this.setupMiddleware();
    this.setupRoutes();
    this.setupBullBoard();
  }

  private setupMiddleware() {
    this.app.use(express.json());

    // Request logging
    this.app.use((req, _res, next) => {
      logger.debug('API request', {
        method: req.method,
        path: req.path,
      });
      next();
    });
  }

  private setupRoutes() {
    // Basic health check (always returns 200 if server is running)
    this.app.get('/health', (_req: Request, res: Response) => {
      res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: env.serviceType,
      });
    });

    // Simple OK endpoint for platforms that prefer plain text
    this.app.get('/healthz', (_req: Request, res: Response) => {
      res.status(200).send('OK');
    });

    // Detailed health check (includes database connection test)
    this.app.get('/health/detailed', async (_req: Request, res: Response) => {
      try {
        // Test PostgreSQL connection
        await testPostgresConnection();

        res.json({
          status: 'healthy',
          timestamp: new Date().toISOString(),
          service: env.serviceType,
          database: 'connected',
        });
      } catch (error: any) {
        res.status(503).json({
          status: 'unhealthy',
          error: error.message,
          timestamp: new Date().toISOString(),
          database: 'disconnected',
        });
      }
    });

    // Debug endpoint: Check if message_logs table exists
    this.app.get('/debug/postgres', async (_req: Request, res: Response) => {
      try {
        const { default: pool } = await import('../database/postgres');

        // Check if table exists
        const tableCheck = await pool.query(`
          SELECT EXISTS (
            SELECT FROM information_schema.tables
            WHERE table_schema = 'message_logs'
            AND table_name = 'message_logs'
          ) as table_exists;
        `);

        // Check current search_path
        const searchPath = await pool.query('SHOW search_path;');

        // Try to count rows (will fail if table doesn't exist)
        let rowCount = null;
        try {
          const countResult = await pool.query('SELECT COUNT(*) FROM message_logs.message_logs;');
          rowCount = countResult.rows[0].count;
        } catch (e: any) {
          rowCount = `Error: ${e.message}`;
        }

        return res.json({
          table_exists: tableCheck.rows[0].table_exists,
          search_path: searchPath.rows[0].search_path,
          row_count: rowCount,
          schema: env.postgres.schema,
        });
      } catch (error: any) {
        return res.status(500).json({ error: error.message, stack: error.stack });
      }
    });

    // View message logs from database
    this.app.get('/logs/messages', async (req: Request, res: Response) => {
      try {
        const { default: pool } = await import('../database/postgres');

        const limit = parseInt(req.query.limit as string) || 100;
        const runId = req.query.run_id as string;
        const status = req.query.status as string;

        let query = 'SELECT * FROM message_logs.message_logs WHERE 1=1';
        const params: any[] = [];
        let paramIndex = 1;

        if (runId) {
          query += ` AND run_id = $${paramIndex}`;
          params.push(parseInt(runId));
          paramIndex++;
        }

        if (status) {
          query += ` AND status = $${paramIndex}`;
          params.push(status);
          paramIndex++;
        }

        query += ` ORDER BY created_at DESC LIMIT $${paramIndex}`;
        params.push(limit);

        const result = await pool.query(query, params);

        return res.json({
          count: result.rows.length,
          logs: result.rows,
        });
      } catch (error: any) {
        return res.status(500).json({ error: error.message });
      }
    });

    // Queue stats
    this.app.get('/stats/queue', async (_req: Request, res: Response) => {
      try {
        const counts = await messageQueue.getJobCounts();
        const metrics = await messageQueue.getMetrics('completed', 0, Date.now());

        res.json({
          queue_name: messageQueue.name,
          counts,
          metrics: {
            completed_last_hour: metrics.count,
          },
        });
      } catch (error: any) {
        res.status(500).json({ error: error.message });
      }
    });

    // Run statistics - detailed stats for a specific run
    this.app.get('/stats/run/:runId', async (req: Request, res: Response) => {
      try {
        const { default: pool } = await import('../database/postgres');
        const runId = parseInt(req.params.runId);

        if (isNaN(runId)) {
          return res.status(400).json({ error: 'Invalid run_id' });
        }

        // Get stats from database
        const statsQuery = `
          SELECT
            COUNT(*) as total_attempts,
            COUNT(*) FILTER (WHERE status = 'sent') as successful,
            COUNT(*) FILTER (WHERE status = 'failed') as failed,
            COUNT(*) FILTER (WHERE status = 'pending') as pending
          FROM message_logs.message_logs
          WHERE run_id = $1
        `;

        const errorBreakdownQuery = `
          SELECT
            error_code,
            error_message,
            COUNT(*) as count
          FROM message_logs.message_logs
          WHERE run_id = $1 AND status = 'failed'
          GROUP BY error_code, error_message
          ORDER BY count DESC
        `;

        // Count unique subscribers who received at least one successful message
        const uniqueSubscribersQuery = `
          SELECT
            COUNT(DISTINCT user_id) as unique_subscribers
          FROM message_logs.message_logs
          WHERE run_id = $1 AND status = 'sent'
        `;

        const [statsResult, errorResult, subscribersResult] = await Promise.all([
          pool.query(statsQuery, [runId]),
          pool.query(errorBreakdownQuery, [runId]),
          pool.query(uniqueSubscribersQuery, [runId]),
        ]);

        const stats = statsResult.rows[0];
        const subscribers = subscribersResult.rows[0];

        // Get queue stats - OPTIMIZATION: use counts only, don't fetch all jobs
        // Fetching all jobs when there are 100k+ is too expensive and slow
        const counts = await messageQueue.getJobCounts('waiting', 'active', 'delayed');

        return res.json({
          run_id: runId,
          total_attempts: parseInt(stats.total_attempts) || 0,
          successful: parseInt(stats.successful) || 0,
          failed: parseInt(stats.failed) || 0,
          pending: parseInt(stats.pending) || 0,
          unique_subscribers: parseInt(subscribers.unique_subscribers) || 0,
          success_rate: stats.total_attempts > 0
            ? ((parseInt(stats.successful) / parseInt(stats.total_attempts)) * 100).toFixed(2) + '%'
            : '0%',
          error_breakdown: errorResult.rows.map(row => ({
            error_code: row.error_code,
            error_message: row.error_message,
            count: parseInt(row.count),
          })),
          queue: {
            // Note: These are TOTAL queue counts, not specific to this run
            // Filtering by runId would require fetching all jobs which is too slow
            waiting: counts.waiting || 0,
            active: counts.active || 0,
            delayed: counts.delayed || 0,
          },
        });
      } catch (error: any) {
        return res.status(500).json({ error: error.message });
      }
    });

    // Facebook client stats
    this.app.get('/stats/http-client', (_req: Request, res: Response) => {
      const stats = facebookClient.getStats();
      res.json(stats);
    });

    // Circuit breaker stats
    this.app.get('/stats/circuit-breaker', (_req: Request, res: Response) => {
      const states = circuitBreaker.getCircuitStates();
      res.json({
        enabled: env.circuitBreaker.enabled,
        threshold: env.circuitBreaker.threshold,
        timeout_ms: env.circuitBreaker.timeoutMs,
        circuits: states,
      });
    });

    // Log batch writer stats
    this.app.get('/stats/log-writer', (_req: Request, res: Response) => {
      const stats = logBatchWriter.getStats();
      res.json(stats);
    });

    // Network diagnostics - test connection to multiple endpoints
    this.app.get('/diagnostics/network', async (_req: Request, res: Response) => {
      const axios = require('axios');
      const results: any = {};

      // Test Facebook API
      const fbStart = Date.now();
      try {
        await axios.get('https://graph.facebook.com/v21.0/', { timeout: 10000 });
        results.facebook = { success: true, duration_ms: Date.now() - fbStart };
      } catch (error: any) {
        const duration = Date.now() - fbStart;
        // Facebook returns error 100 for invalid requests, but that means connection works!
        if (error.response?.status === 400 && error.response?.data?.error?.code === 100) {
          results.facebook = {
            success: true,
            duration_ms: duration,
            note: 'Connection successful (received expected Facebook API error)',
          };
        } else {
          results.facebook = {
            success: false,
            error: error.message,
            error_code: error.code,
            duration_ms: duration,
            http_status: error.response?.status,
          };
        }
      }

      // Test Google (general internet connectivity)
      try {
        const start = Date.now();
        await axios.get('https://www.google.com/', { timeout: 10000 });
        results.google = { success: true, duration_ms: Date.now() - start };
      } catch (error: any) {
        results.google = {
          success: false,
          error: error.message,
          error_code: error.code,
        };
      }

      // Test Supabase (if configured)
      if (env.supabase?.url) {
        try {
          const start = Date.now();
          await axios.get(env.supabase.url + '/rest/v1/', {
            timeout: 10000,
            headers: { apikey: env.supabase.serviceRoleKey },
          });
          results.supabase = { success: true, duration_ms: Date.now() - start };
        } catch (error: any) {
          results.supabase = {
            success: false,
            error: error.message,
            error_code: error.code,
          };
        }
      }

      const allSuccess = Object.values(results).every((r: any) => r.success);
      res.status(allSuccess ? 200 : 500).json(results);
    });

    // Test endpoint: Get subscriber by user_id with BigInt casting
    this.app.get('/test/subscriber/:userId', async (req: Request, res: Response) => {
      try {
        const { default: supabase } = await import('../database/supabase');
        const userId = req.params.userId;

        const { data, error } = await supabase
          .from('meta_subscribers')
          .select('user_id::text, page_id::text, user_name, is_active, can_reply, is_subscribed, last_interaction_at, window_expires_at, created_at, updated_at')
          .eq('user_id', userId)
          .single();

        if (error) {
          return res.status(500).json({ error: error.message });
        }

        if (!data) {
          return res.status(404).json({ error: 'Subscriber not found' });
        }

        // IDs already come as text from ::text cast
        const result = {
          user_id: data.user_id,
          page_id: data.page_id,
          user_name: data.user_name,
          is_active: data.is_active,
          can_reply: data.can_reply,
          is_subscribed: data.is_subscribed,
          last_interaction_at: data.last_interaction_at,
          window_expires_at: data.window_expires_at,
          created_at: data.created_at,
          updated_at: data.updated_at,
          // Show the type for debugging
          debug: {
            user_id_type: typeof data.user_id,
            page_id_type: typeof data.page_id,
            user_id_value: data.user_id,
            page_id_value: data.page_id,
          },
        };

        // Use custom replacer to handle BigInt in response
        const bigIntReplacer = (_key: string, value: any) =>
          typeof value === 'bigint' ? value.toString() : value;

        res.setHeader('Content-Type', 'application/json');
        return res.send(JSON.stringify(result, bigIntReplacer, 2));
      } catch (error: any) {
        return res.status(500).json({ error: error.message, stack: error.stack });
      }
    });

    // Reset circuit breaker for a page
    this.app.post('/circuit-breaker/reset/:pageId', (req: Request, res: Response) => {
      const pageId = req.params.pageId; // Keep as string for large Facebook page IDs
      const success = circuitBreaker.manualReset(pageId);

      if (success) {
        res.json({ success: true, message: 'Circuit breaker reset', page_id: pageId });
      } else {
        res.status(404).json({ success: false, message: 'No circuit found for this page' });
      }
    });

    // Performance metrics
    this.app.get('/stats/performance', async (_req: Request, res: Response) => {
      try {
        const queueCounts = await messageQueue.getJobCounts();
        const httpStats = facebookClient.getStats();
        const logStats = logBatchWriter.getStats();
        const circuitStates = circuitBreaker.getCircuitStates();

        res.json({
          timestamp: new Date().toISOString(),
          queue: {
            waiting: queueCounts.waiting,
            active: queueCounts.active,
            completed: queueCounts.completed,
            failed: queueCounts.failed,
            delayed: queueCounts.delayed,
          },
          http_client: {
            total_requests: httpStats.totalRequests,
            active_sockets: httpStats.agent.sockets,
            free_sockets: httpStats.agent.freeSockets,
            socket_reuse_rate: httpStats.performance.socketReuseRate,
          },
          log_writer: {
            buffered: logStats.buffered_logs,
            fill_percentage: logStats.fill_percentage,
          },
          circuit_breaker: {
            open_circuits: circuitStates.filter((c) => c.isOpen).length,
            total_circuits: circuitStates.length,
          },
        });
      } catch (error: any) {
        res.status(500).json({ error: error.message });
      }
    });
  }

  private setupBullBoard() {
    if (!env.api.enableBullBoard) {
      logger.info('Bull Board disabled');
      return;
    }

    const serverAdapter = new ExpressAdapter();
    serverAdapter.setBasePath('/admin/queues');

    createBullBoard({
      queues: [new BullMQAdapter(messageQueue) as any],
      serverAdapter: serverAdapter,
    });

    this.app.use('/admin/queues', serverAdapter.getRouter());

    logger.info('✅ Bull Board UI enabled at /admin/queues');
  }

  async start() {
    const port = env.api.port;

    return new Promise<void>((resolve) => {
      this.server = this.app.listen(port, () => {
        logger.info(`🚀 API Server started on port ${port}`, {
          bull_board: env.api.enableBullBoard ? `http://localhost:${port}/admin/queues` : 'disabled',
          health_check: `http://localhost:${port}/health`,
          stats: `http://localhost:${port}/stats/performance`,
        });
        resolve();
      });
    });
  }

  async stop() {
    if (!this.server) return;

    return new Promise<void>((resolve) => {
      this.server.close(() => {
        logger.info('🛑 API Server stopped');
        resolve();
      });
    });
  }
}

// Export singleton
export const apiServer = new ApiServer();

// Auto-start if this is the entry point
if (env.serviceType === 'api') {
  apiServer.start().catch((error) => {
    logger.error('Failed to start API server', { error: error.message });
    process.exit(1);
  });

  // Graceful shutdown
  process.on('SIGTERM', async () => {
    await apiServer.stop();
    process.exit(0);
  });

  process.on('SIGINT', async () => {
    await apiServer.stop();
    process.exit(0);
  });
}

export default apiServer;
