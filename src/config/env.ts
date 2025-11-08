// Environment variable validation and configuration
import dotenv from 'dotenv';

dotenv.config();

interface EnvironmentConfig {
  // Service
  serviceType: 'run-processor' | 'trigger-run-processor' | 'message-worker' | 'api';
  nodeEnv: 'development' | 'production' | 'test';

  // Redis
  redis: {
    host: string;
    port: number;
    password: string;
    db: number;
  };

  // PostgreSQL
  postgres: {
    host: string;
    port: number;
    user: string;
    password: string;
    database: string;
    schema: string;
  };

  // Supabase
  supabase: {
    url: string;
    serviceRoleKey: string;
  };

  // Worker
  worker: {
    concurrency: number;
    maxSockets: number;
  };

  // Polling
  pollIntervalMs: number;

  // Logging
  log: {
    level: string;
    batchSize: number;
    batchIntervalMs: number;
    retentionDays: number;
  };

  // Rate Limiting
  rateLimit: {
    maxJobsPerSecond: number;
    perPage: number;
  };

  // Circuit Breaker
  circuitBreaker: {
    enabled: boolean;
    threshold: number;
    timeoutMs: number;
  };

  // API
  api: {
    port: number;
    enableBullBoard: boolean;
  };

  // Debug
  debug: {
    enabled: boolean;
    postLink: string | null;
  };
}

function getEnv(key: string, defaultValue?: string): string {
  const value = process.env[key] || defaultValue;
  if (!value) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value;
}

function getEnvNumber(key: string, defaultValue?: number): number {
  const value = process.env[key];
  if (!value && defaultValue === undefined) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value ? parseInt(value, 10) : defaultValue!;
}

function getEnvBoolean(key: string, defaultValue: boolean = false): boolean {
  const value = process.env[key];
  if (!value) return defaultValue;
  return value.toLowerCase() === 'true' || value === '1';
}

export const env: EnvironmentConfig = {
  // Service
  serviceType: getEnv('SERVICE_TYPE', 'run-processor') as any,
  nodeEnv: getEnv('NODE_ENV', 'development') as any,

  // Redis
  redis: {
    host: getEnv('REDIS_HOST'),
    port: getEnvNumber('REDIS_PORT', 6379),
    password: getEnv('REDIS_PASSWORD'),
    db: getEnvNumber('REDIS_DB', 2),
  },

  // PostgreSQL
  postgres: {
    host: getEnv('POSTGRES_HOST'),
    port: getEnvNumber('POSTGRES_PORT', 5432),
    user: getEnv('POSTGRES_USER'),
    password: getEnv('POSTGRES_PASSWORD'),
    database: getEnv('POSTGRES_DB'),
    schema: getEnv('POSTGRES_SCHEMA', 'message_logs'),
  },

  // Supabase
  supabase: {
    url: getEnv('SUPABASE_URL'),
    serviceRoleKey: getEnv('SUPABASE_SERVICE_ROLE_KEY'),
  },

  // Worker
  worker: {
    concurrency: getEnvNumber('WORKER_CONCURRENCY', 50),
    maxSockets: getEnvNumber('MAX_SOCKETS', 500),
  },

  // Polling
  pollIntervalMs: getEnvNumber('POLL_INTERVAL_MS', 10000),

  // Logging
  log: {
    level: getEnv('LOG_LEVEL', 'info'),
    batchSize: getEnvNumber('LOG_BATCH_SIZE', 200),
    batchIntervalMs: getEnvNumber('LOG_BATCH_INTERVAL_MS', 2000),
    retentionDays: getEnvNumber('LOG_RETENTION_DAYS', 7),
  },

  // Rate Limiting
  rateLimit: {
    maxJobsPerSecond: getEnvNumber('RATE_LIMIT_MAX_JOBS_PER_SECOND', 100),
    perPage: getEnvNumber('RATE_LIMIT_PER_PAGE', 50),
  },

  // Circuit Breaker
  circuitBreaker: {
    enabled: getEnvBoolean('CIRCUIT_BREAKER_ENABLED', true),
    threshold: getEnvNumber('CIRCUIT_BREAKER_THRESHOLD', 5),
    timeoutMs: getEnvNumber('CIRCUIT_BREAKER_TIMEOUT_MS', 300000),
  },

  // API
  api: {
    port: getEnvNumber('API_PORT', 3000),
    enableBullBoard: getEnvBoolean('API_ENABLE_BULL_BOARD', true),
  },

  // Debug
  debug: {
    enabled: getEnvBoolean('DEBUG', false),
    postLink: process.env.DEBUG_POST_LINK || null,
  },
};

// Validate service type
const validServiceTypes = ['run-processor', 'trigger-run-processor', 'message-worker', 'api'];
if (!validServiceTypes.includes(env.serviceType)) {
  throw new Error(
    `Invalid SERVICE_TYPE: ${env.serviceType}. Must be one of: ${validServiceTypes.join(', ')}`
  );
}

export default env;
