// Batch log writer for optimized PostgreSQL inserts
// Batches logs in memory and bulk inserts every N logs or N seconds

import pool from './postgres';
import logger from '../utils/logger';
import env from '../config/env';
import { MessageLog } from '../types';

class LogBatchWriter {
  private buffer: MessageLog[] = [];
  private readonly batchSize: number;
  private readonly batchIntervalMs: number;
  private flushTimer: NodeJS.Timeout | null = null;
  private isShuttingDown = false;

  constructor() {
    this.batchSize = env.log.batchSize;
    this.batchIntervalMs = env.log.batchIntervalMs;

    this.startFlushTimer();

    logger.info('📝 Log Batch Writer initialized', {
      batch_size: this.batchSize,
      batch_interval_ms: this.batchIntervalMs,
    });

    // Graceful shutdown
    process.on('SIGTERM', () => this.shutdown());
    process.on('SIGINT', () => this.shutdown());
  }

  /**
   * Add a log to the buffer
   */
  async add(log: MessageLog): Promise<void> {
    if (this.isShuttingDown) {
      // During shutdown, flush immediately
      await this.flush();
      return;
    }

    this.buffer.push(log);

    // Flush if buffer is full
    if (this.buffer.length >= this.batchSize) {
      await this.flush();
    }
  }

  /**
   * Add multiple logs to the buffer
   */
  async addMany(logs: MessageLog[]): Promise<void> {
    for (const log of logs) {
      await this.add(log);
    }
  }

  /**
   * Flush buffer to database
   */
  async flush(): Promise<void> {
    if (this.buffer.length === 0) return;

    const logsToInsert = [...this.buffer];
    this.buffer = [];

    try {
      const startTime = Date.now();

      // Build bulk INSERT query
      const values: any[] = [];
      const placeholders: string[] = [];

      logsToInsert.forEach((log, index) => {
        const offset = index * 6;
        placeholders.push(
          `($${offset + 1}, $${offset + 2}, $${offset + 3}, $${offset + 4}, $${offset + 5}, $${offset + 6})`
        );

        values.push(
          log.run_id,
          log.page_id,
          log.user_id,
          log.status,
          log.error_code || null,
          log.error_message || null
        );
      });

      const query = `
        INSERT INTO message_logs.message_logs (run_id, page_id, user_id, status, error_code, error_message)
        VALUES ${placeholders.join(', ')}
      `;

      await pool.query(query, values);

      const duration = Date.now() - startTime;

      logger.debug('Logs flushed to database', {
        count: logsToInsert.length,
        duration_ms: duration,
        logs_per_second: Math.round((logsToInsert.length / duration) * 1000),
      });
    } catch (error: any) {
      logger.error('❌ Failed to flush logs to database', {
        error: error.message,
        count: logsToInsert.length,
      });

      // Put logs back in buffer to retry
      this.buffer.unshift(...logsToInsert);
    }
  }

  /**
   * Start periodic flush timer
   */
  private startFlushTimer(): void {
    this.flushTimer = setInterval(() => {
      this.flush().catch((error) => {
        logger.error('Error in flush timer', { error: error.message });
      });
    }, this.batchIntervalMs);
  }

  /**
   * Stop flush timer
   */
  private stopFlushTimer(): void {
    if (this.flushTimer) {
      clearInterval(this.flushTimer);
      this.flushTimer = null;
    }
  }

  /**
   * Get current buffer statistics
   */
  getStats() {
    return {
      buffered_logs: this.buffer.length,
      batch_size: this.batchSize,
      batch_interval_ms: this.batchIntervalMs,
      fill_percentage: ((this.buffer.length / this.batchSize) * 100).toFixed(2) + '%',
    };
  }

  /**
   * Graceful shutdown
   */
  async shutdown(): Promise<void> {
    if (this.isShuttingDown) return;

    this.isShuttingDown = true;
    logger.info('🛑 Log Batch Writer shutting down...');

    this.stopFlushTimer();

    // Flush remaining logs
    if (this.buffer.length > 0) {
      logger.info('Flushing remaining logs', { count: this.buffer.length });
      await this.flush();
    }

    logger.info('✅ Log Batch Writer shutdown complete');
  }
}

export const logBatchWriter = new LogBatchWriter();
export default logBatchWriter;
