// Winston logger configuration
import winston from 'winston';
import env from '../config/env';

const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.splat(),
  winston.format.json()
);

const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    let msg = `${timestamp} [${level}]: ${message}`;
    if (Object.keys(meta).length > 0) {
      // Custom replacer to handle BigInt serialization in logs
      const bigIntReplacer = (_key: string, value: any) =>
        typeof value === 'bigint' ? value.toString() : value;
      msg += ` ${JSON.stringify(meta, bigIntReplacer)}`;
    }
    return msg;
  })
);

const logger = winston.createLogger({
  level: env.log.level,
  format: logFormat,
  defaultMeta: {
    service: env.serviceType,
    env: env.nodeEnv,
  },
  transports: [
    // Console transport with colors (for development)
    new winston.transports.Console({
      format: env.nodeEnv === 'production' ? logFormat : consoleFormat,
    }),
  ],
});

// Add file transports in production
if (env.nodeEnv === 'production') {
  logger.add(
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error',
      maxsize: 10485760, // 10MB
      maxFiles: 5,
    })
  );

  logger.add(
    new winston.transports.File({
      filename: 'logs/combined.log',
      maxsize: 10485760, // 10MB
      maxFiles: 5,
    })
  );
}

export default logger;
