// Entry point - routes to appropriate service based on SERVICE_TYPE env var
import env from './config/env';
import logger from './utils/logger';

logger.info('🚀 Starting Newar Message Sender', {
  service_type: env.serviceType,
  node_env: env.nodeEnv,
});

async function main() {
  try {
    switch (env.serviceType) {
      case 'run-processor':
        logger.info('Initializing Run Processor Service...');
        await import('./services/run-processor');
        break;

      case 'message-worker':
        logger.info('Initializing Message Worker Service...');
        await import('./services/message-worker');
        break;

      case 'api':
        logger.info('Initializing API Service...');
        await import('./services/api-server');
        break;

      default:
        throw new Error(`Unknown SERVICE_TYPE: ${env.serviceType}`);
    }
  } catch (error: any) {
    logger.error('Failed to start service', {
      service_type: env.serviceType,
      error: error.message,
      stack: error.stack,
    });
    process.exit(1);
  }
}

// Handle uncaught errors
process.on('uncaughtException', (error) => {
  logger.error('Uncaught exception', {
    error: error.message,
    stack: error.stack,
  });
  process.exit(1);
});

process.on('unhandledRejection', (reason: any) => {
  logger.error('Unhandled rejection', {
    reason: reason?.message || reason,
    stack: reason?.stack,
  });
  process.exit(1);
});

// Start the application
main();
