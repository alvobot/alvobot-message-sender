// Message and queue types

export interface QueueMessagePayload {
  runId?: number; // For message_runs (bulk campaigns)
  triggerRunId?: number; // For trigger_runs (individual triggers)
  flowId: string;
  nodeId: string;
  pageId: string; // Changed from number to string to preserve precision of large IDs
  userId: string;
  pageAccessToken: string;
  message: FacebookMessage;
  messageIndex?: number;
  windowExpiresAt?: string; // ISO timestamp when 24-hour messaging window expires
  hasMessagingWindow?: boolean; // True if user is within 24-hour window
}

export interface FacebookMessage {
  text?: string;
  attachment?: {
    type: 'template' | 'image' | 'video' | 'audio' | 'file';
    payload: any;
  };
  quick_replies?: Array<{
    content_type: 'text' | 'user_phone_number' | 'user_email';
    title?: string;
    payload?: string;
    image_url?: string;
  }>;
}

export interface FacebookApiResponse {
  message_id?: string;
  recipient_id?: string;
  error?: {
    message: string;
    type: string;
    code: number;
    error_subcode?: number;
    fbtrace_id?: string;
  };
}

export interface SendMessageResult {
  success: boolean;
  messageId?: string;
  recipientId?: string;
  error?: {
    code: string;
    message: string;
    type: string;
  };
  stats: {
    duration_ms: number;
    socket_reused: boolean;
    total_sockets: number;
    free_sockets: number;
  };
}

export interface MessageLog {
  run_id?: number; // For message_runs (bulk campaigns)
  trigger_run_id?: number; // For trigger_runs (individual triggers)
  page_id: string; // Changed from number to string to preserve precision of large IDs
  user_id: string;
  status: 'sent' | 'failed' | 'rate_limited' | 'auth_error';
  error_code?: string;
  error_message?: string;
  sent_at?: Date;
}

export type MessageStatus = 'sent' | 'failed' | 'rate_limited' | 'auth_error';
