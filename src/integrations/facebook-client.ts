// Facebook Graph API client with HTTP connection pooling
// Critical component for high-throughput message sending

import { HttpsAgent } from 'agentkeepalive';
import axios, { AxiosInstance, AxiosError } from 'axios';
import logger from '../utils/logger';
import env from '../config/env';
import { SendMessageResult, FacebookApiResponse } from '../types';

class FacebookClient {
  private static instance: FacebookClient;
  private agent: HttpsAgent;
  private axiosInstance: AxiosInstance;
  private requestCount = 0;
  private clientId: string;
  private createdAt: string;

  private constructor() {
    this.clientId = Math.random().toString(36).substring(7);
    this.createdAt = new Date().toISOString();

    // Configure HTTP agent with connection pooling
    // This is CRITICAL for performance: 500 sockets vs default 5-10
    this.agent = new HttpsAgent({
      keepAlive: true,
      keepAliveMsecs: 60000, // Keep alive for 60s
      maxSockets: env.worker.maxSockets, // 500 concurrent connections
      maxFreeSockets: 100, // Keep 100 idle sockets in pool
      timeout: 60000, // Socket timeout
      freeSocketTimeout: 30000, // Idle socket timeout
      socketActiveTTL: 0, // No TTL (reuse indefinitely)
    });

    // Create axios instance with agent
    // NOTE: Increased timeout from 30s to 60s to prevent ETIMEDOUT errors
    this.axiosInstance = axios.create({
      httpsAgent: this.agent,
      timeout: 60000, // Increased from 30000
      headers: {
        'Connection': 'keep-alive',
        'Content-Type': 'application/json',
      },
    });

    logger.info('🚀 FacebookClient initialized', {
      clientId: this.clientId,
      maxSockets: env.worker.maxSockets,
      createdAt: this.createdAt,
    });
  }

  static getInstance(): FacebookClient {
    if (!FacebookClient.instance) {
      FacebookClient.instance = new FacebookClient();
    }
    return FacebookClient.instance;
  }

  /**
   * Send a message to Facebook Messenger API (or debug endpoint if DEBUG=true)
   */
  async sendMessage(
    pageAccessToken: string,
    recipientId: string,
    message: any
  ): Promise<SendMessageResult> {
    this.requestCount++;
    const statsBefore = this.agent.getCurrentStatus();
    const startTime = Date.now();

    // Use debug endpoint if DEBUG mode is enabled
    const isDebugMode = env.debug.enabled && env.debug.postLink;
    const endpoint = isDebugMode
      ? env.debug.postLink!
      : 'https://graph.facebook.com/v21.0/me/messages';

    if (isDebugMode) {
      logger.info('🐛 DEBUG MODE: Sending to debug endpoint instead of Meta API', {
        debug_endpoint: endpoint,
        recipient_id: recipientId,
      });
    }

    try {
      const payload = {
        recipient: { id: recipientId },
        ...message, // Spread message object (contains messaging_type, tag, message)
      };

      const response = await this.axiosInstance.post<FacebookApiResponse>(
        endpoint,
        payload,
        isDebugMode
          ? {} // No params for debug endpoint
          : { params: { access_token: pageAccessToken } }
      );

      const duration = Date.now() - startTime;
      const statsAfter = this.agent.getCurrentStatus();

      const socketReused = (Number(statsBefore.sockets) || 0) > 0;

      // In debug mode, the response might not have message_id/recipient_id
      const messageId = isDebugMode
        ? `debug_${Date.now()}_${recipientId}`
        : response.data.message_id;
      const responseRecipientId = isDebugMode
        ? recipientId
        : response.data.recipient_id;

      logger.debug('Message sent successfully', {
        recipient_id: recipientId,
        message_id: messageId,
        duration_ms: duration,
        socket_reused: socketReused,
        debug_mode: isDebugMode,
      });

      return {
        success: true,
        messageId: messageId,
        recipientId: responseRecipientId,
        stats: {
          duration_ms: duration,
          socket_reused: socketReused,
          total_sockets: Number(statsAfter.sockets) || 0,
          free_sockets: Number(statsAfter.freeSockets) || 0,
        },
      };
    } catch (error: any) {
      const duration = Date.now() - startTime;
      const statsAfter = this.agent.getCurrentStatus();

      const axiosError = error as AxiosError<FacebookApiResponse>;
      const fbError = axiosError.response?.data?.error;

      if (fbError) {
        logger.warn('Facebook API error', {
          recipient_id: recipientId,
          error_code: fbError.code,
          error_message: fbError.message,
          error_type: fbError.type,
          error_subcode: fbError.error_subcode,
          fbtrace_id: fbError.fbtrace_id,
          duration_ms: duration,
          http_status: axiosError.response?.status,
        });

        return {
          success: false,
          error: {
            code: fbError.code?.toString() || 'UNKNOWN',
            message: fbError.message || 'Unknown error',
            type: fbError.type || 'UnknownError',
          },
          stats: {
            duration_ms: duration,
            socket_reused: (Number(statsBefore.sockets) || 0) > 0,
            total_sockets: Number(statsAfter.sockets) || 0,
            free_sockets: Number(statsAfter.freeSockets) || 0,
          },
        };
      }

      // Network or timeout error
      logger.error('Network error sending message', {
        recipient_id: recipientId,
        error: error.message,
        error_code: error.code,
        duration_ms: duration,
        http_status: axiosError.response?.status,
      });

      return {
        success: false,
        error: {
          code: 'NETWORK_ERROR',
          message: error.message,
          type: 'NetworkError',
        },
        stats: {
          duration_ms: duration,
          socket_reused: (Number(statsBefore.sockets) || 0) > 0,
          total_sockets: Number(statsAfter.sockets) || 0,
          free_sockets: Number(statsAfter.freeSockets) || 0,
        },
      };
    }
  }

  /**
   * Get client statistics
   */
  getStats(): {
    clientId: string;
    createdAt: string;
    totalRequests: number;
    agent: {
      sockets: number;
      freeSockets: number;
      createSocketCount: number;
      createSocketErrorCount: number;
      closeSocketCount: number;
      errorSocketCount: number;
      timeoutSocketCount: number;
      requestCount: number;
    };
    performance: {
      socketReuseRate: string;
      avgSocketsPerRequest: string;
    };
  } {
    const agentStatus = this.agent.getCurrentStatus();

    return {
      clientId: this.clientId,
      createdAt: this.createdAt,
      totalRequests: this.requestCount,
      agent: {
        sockets: Number(agentStatus.sockets) || 0,
        freeSockets: Number(agentStatus.freeSockets) || 0,
        createSocketCount: Number(agentStatus.createSocketCount) || 0,
        createSocketErrorCount: Number(agentStatus.createSocketErrorCount) || 0,
        closeSocketCount: Number(agentStatus.closeSocketCount) || 0,
        errorSocketCount: Number(agentStatus.errorSocketCount) || 0,
        timeoutSocketCount: Number(agentStatus.timeoutSocketCount) || 0,
        requestCount: Number(agentStatus.requestCount) || 0,
      },
      performance: {
        socketReuseRate:
          agentStatus.requestCount && agentStatus.createSocketCount
            ? (
                ((Number(agentStatus.requestCount) - Number(agentStatus.createSocketCount)) /
                  Number(agentStatus.requestCount)) *
                100
              ).toFixed(2) + '%'
            : '0%',
        avgSocketsPerRequest:
          this.requestCount > 0
            ? ((Number(agentStatus.sockets) || 0) / this.requestCount).toFixed(2)
            : '0',
      },
    };
  }

  /**
   * Destroy client and cleanup connections
   */
  destroy() {
    logger.info('🧹 Destroying FacebookClient', {
      clientId: this.clientId,
      totalRequests: this.requestCount,
    });

    this.agent.destroy();
    FacebookClient.instance = null as any;
  }
}

// Singleton instance
export const facebookClient = FacebookClient.getInstance();

// Cleanup on process termination
process.on('SIGTERM', () => {
  facebookClient.destroy();
});

process.on('SIGINT', () => {
  facebookClient.destroy();
});

export default facebookClient;
