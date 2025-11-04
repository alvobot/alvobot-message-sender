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
    this.axiosInstance = axios.create({
      httpsAgent: this.agent,
      timeout: 30000,
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
   * Send a message to Facebook Messenger API
   */
  async sendMessage(
    pageAccessToken: string,
    recipientId: string,
    message: any
  ): Promise<SendMessageResult> {
    this.requestCount++;
    const statsBefore = this.agent.getCurrentStatus();
    const startTime = Date.now();

    try {
      const response = await this.axiosInstance.post<FacebookApiResponse>(
        'https://graph.facebook.com/v21.0/me/messages',
        {
          recipient: { id: recipientId },
          ...message, // Spread message object (contains messaging_type, tag, message)
        },
        {
          params: { access_token: pageAccessToken },
        }
      );

      const duration = Date.now() - startTime;
      const statsAfter = this.agent.getCurrentStatus();

      const socketReused = (statsBefore.sockets || 0) > 0;

      logger.debug('Message sent successfully', {
        recipient_id: recipientId,
        message_id: response.data.message_id,
        duration_ms: duration,
        socket_reused: socketReused,
      });

      return {
        success: true,
        messageId: response.data.message_id,
        recipientId: response.data.recipient_id,
        stats: {
          duration_ms: duration,
          socket_reused: socketReused,
          total_sockets: statsAfter.sockets || 0,
          free_sockets: statsAfter.freeSockets || 0,
        },
      };
    } catch (error: any) {
      const duration = Date.now() - startTime;
      const statsAfter = this.agent.getCurrentStatus();

      const axiosError = error as AxiosError<FacebookApiResponse>;
      const fbError = axiosError.response?.data?.error;

      if (fbError) {
        logger.debug('Facebook API error', {
          recipient_id: recipientId,
          error_code: fbError.code,
          error_message: fbError.message,
          error_type: fbError.type,
          duration_ms: duration,
        });

        return {
          success: false,
          error: {
            code: fbError.code?.toString() || 'UNKNOWN',
            message: fbError.message,
            type: fbError.type,
          },
          stats: {
            duration_ms: duration,
            socket_reused: (statsBefore.sockets || 0) > 0,
            total_sockets: statsAfter.sockets || 0,
            free_sockets: statsAfter.freeSockets || 0,
          },
        };
      }

      // Network or timeout error
      logger.error('Network error sending message', {
        recipient_id: recipientId,
        error: error.message,
        duration_ms: duration,
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
          socket_reused: (statsBefore.sockets || 0) > 0,
          total_sockets: statsAfter.sockets || 0,
          free_sockets: statsAfter.freeSockets || 0,
        },
      };
    }
  }

  /**
   * Get client statistics
   */
  getStats() {
    const agentStatus = this.agent.getCurrentStatus();

    return {
      clientId: this.clientId,
      createdAt: this.createdAt,
      totalRequests: this.requestCount,
      agent: {
        sockets: agentStatus.sockets || 0,
        freeSockets: agentStatus.freeSockets || 0,
        createSocketCount: agentStatus.createSocketCount || 0,
        createSocketErrorCount: agentStatus.createSocketErrorCount || 0,
        closeSocketCount: agentStatus.closeSocketCount || 0,
        errorSocketCount: agentStatus.errorSocketCount || 0,
        timeoutSocketCount: agentStatus.timeoutSocketCount || 0,
        requestCount: agentStatus.requestCount || 0,
      },
      performance: {
        socketReuseRate:
          agentStatus.requestCount && agentStatus.createSocketCount
            ? (
                ((agentStatus.requestCount - agentStatus.createSocketCount) /
                  agentStatus.requestCount) *
                100
              ).toFixed(2) + '%'
            : '0%',
        avgSocketsPerRequest:
          this.requestCount > 0
            ? ((agentStatus.sockets || 0) / this.requestCount).toFixed(2)
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
