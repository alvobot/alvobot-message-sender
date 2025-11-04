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
      res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: env.serviceType,
      });
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

    // Reset circuit breaker for a page
    this.app.post('/circuit-breaker/reset/:pageId', (req: Request, res: Response) => {
      const pageId = parseInt(req.params.pageId, 10);
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
