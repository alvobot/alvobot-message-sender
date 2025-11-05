// Circuit breaker for Facebook pages
// Prevents wasting resources on pages with auth errors

import logger from '../utils/logger';
import env from '../config/env';

interface CircuitState {
  failures: number;
  lastFailureTime: number;
  isOpen: boolean;
}

class CircuitBreaker {
  private circuits: Map<string, CircuitState> = new Map(); // Changed to string for large page IDs
  private readonly threshold: number;
  private readonly timeout: number;
  private readonly enabled: boolean;

  constructor() {
    this.threshold = env.circuitBreaker.threshold;
    this.timeout = env.circuitBreaker.timeoutMs;
    this.enabled = env.circuitBreaker.enabled;

    if (this.enabled) {
      logger.info('🔌 Circuit Breaker enabled', {
        threshold: this.threshold,
        timeout_ms: this.timeout,
      });
    }
  }

  /**
   * Check if circuit is open for a page
   */
  isCircuitOpen(pageId: string): boolean {
    if (!this.enabled) return false;

    const circuit = this.circuits.get(pageId);
    if (!circuit || !circuit.isOpen) return false;

    // Check if timeout has elapsed
    const timeSinceFailure = Date.now() - circuit.lastFailureTime;
    if (timeSinceFailure > this.timeout) {
      // Reset circuit (half-open state)
      this.resetCircuit(pageId);
      logger.info('Circuit breaker reset (timeout elapsed)', {
        page_id: pageId,
        time_elapsed_ms: timeSinceFailure,
      });
      return false;
    }

    return true;
  }

  /**
   * Record a failure for a page
   */
  recordFailure(pageId: string, errorCode: string) {
    if (!this.enabled) return;

    // Only track auth errors that indicate permanent page issues
    const authErrors = ['190', '200'];
    if (!authErrors.includes(errorCode)) return;

    let circuit = this.circuits.get(pageId);

    if (!circuit) {
      circuit = {
        failures: 0,
        lastFailureTime: Date.now(),
        isOpen: false,
      };
      this.circuits.set(pageId, circuit);
    }

    circuit.failures++;
    circuit.lastFailureTime = Date.now();

    if (circuit.failures >= this.threshold && !circuit.isOpen) {
      circuit.isOpen = true;
      logger.warn('⚠️  Circuit breaker OPENED', {
        page_id: pageId,
        failures: circuit.failures,
        threshold: this.threshold,
        error_code: errorCode,
      });
    } else {
      logger.debug('Circuit breaker failure recorded', {
        page_id: pageId,
        failures: circuit.failures,
        threshold: this.threshold,
      });
    }
  }

  /**
   * Record a success for a page (reset failures)
   */
  recordSuccess(pageId: string) {
    if (!this.enabled) return;

    const circuit = this.circuits.get(pageId);
    if (circuit && circuit.failures > 0) {
      logger.debug('Circuit breaker success recorded, resetting failures', {
        page_id: pageId,
        previous_failures: circuit.failures,
      });
      this.resetCircuit(pageId);
    }
  }

  /**
   * Reset circuit for a page
   */
  private resetCircuit(pageId: string) {
    this.circuits.delete(pageId);
  }

  /**
   * Get all circuit states (for monitoring)
   */
  getCircuitStates() {
    const states: Array<{
      pageId: string;
      failures: number;
      isOpen: boolean;
      lastFailureTime: string;
    }> = [];

    for (const [pageId, circuit] of this.circuits.entries()) {
      states.push({
        pageId,
        failures: circuit.failures,
        isOpen: circuit.isOpen,
        lastFailureTime: new Date(circuit.lastFailureTime).toISOString(),
      });
    }

    return states;
  }

  /**
   * Manually reset a circuit for a page
   */
  manualReset(pageId: string) {
    const circuit = this.circuits.get(pageId);
    if (circuit) {
      logger.info('Circuit breaker manually reset', { page_id: pageId });
      this.resetCircuit(pageId);
      return true;
    }
    return false;
  }
}

export const circuitBreaker = new CircuitBreaker();
export default circuitBreaker;
