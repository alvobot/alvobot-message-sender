// Helper utility functions

/**
 * Sleep for a specified number of milliseconds
 */
export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Retry a function with exponential backoff
 */
export async function retry<T>(
  fn: () => Promise<T>,
  options: {
    maxAttempts?: number;
    delayMs?: number;
    exponential?: boolean;
  } = {}
): Promise<T> {
  const { maxAttempts = 3, delayMs = 1000, exponential = true } = options;

  let lastError: Error;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error: any) {
      lastError = error;

      if (attempt < maxAttempts) {
        const delay = exponential ? delayMs * Math.pow(2, attempt - 1) : delayMs;
        await sleep(delay);
      }
    }
  }

  throw lastError!;
}

/**
 * Chunk an array into smaller arrays of specified size
 */
export function chunk<T>(array: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

/**
 * Replace placeholders in a string (e.g., {{USER_ID}})
 */
export function replacePlaceholders(
  text: string,
  replacements: Record<string, string>
): string {
  let result = text;
  for (const [key, value] of Object.entries(replacements)) {
    const regex = new RegExp(`{{${key}}}`, 'g');
    result = result.replace(regex, value);
  }
  return result;
}

/**
 * Check if an error is a rate limit error from Facebook
 */
export function isRateLimitError(errorCode: string): boolean {
  const rateLimitCodes = ['4', '17', '32', '613', '80000', '80001', '80002', '80003', '80004', '80005', '80006', '80007', '80008'];
  return rateLimitCodes.includes(errorCode);
}

/**
 * Check if an error is a permanent error from Facebook
 */
export function isPermanentError(errorCode: string): boolean {
  const permanentCodes = ['10', '100', '190', '200', '551', '230', '368'];
  return permanentCodes.includes(errorCode);
}

/**
 * Check if an error is an auth error from Facebook
 */
export function isAuthError(errorCode: string): boolean {
  const authCodes = ['190', '200'];
  return authCodes.includes(errorCode);
}

/**
 * Check if an error should deactivate the subscriber
 * Error 551: This person isn't available right now
 */
export function shouldDeactivateSubscriber(errorCode: string): boolean {
  return errorCode === '551';
}

/**
 * Check if error code indicates messaging window has expired
 * These errors suggest the 24-hour messaging window is closed
 * and a MESSAGE_TAG is required instead of RESPONSE
 */
export function isMessagingWindowError(errorCode: string): boolean {
  const windowErrors = ['10', '200', '190', '368'];
  return windowErrors.includes(errorCode);
}

/**
 * Format bytes to human-readable string
 */
export function formatBytes(bytes: number, decimals: number = 2): string {
  if (bytes === 0) return '0 Bytes';

  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];

  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

/**
 * Calculate percentage
 */
export function percentage(value: number, total: number): string {
  if (total === 0) return '0.00%';
  return ((value / total) * 100).toFixed(2) + '%';
}
