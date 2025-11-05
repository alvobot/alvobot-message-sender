// Database types

export interface MetaPage {
  page_id: string; // Changed from number to string to preserve precision of large IDs
  page_name: string;
  access_token: string;
  is_active: boolean;
  user_id: string;
  connection_id: string;
  created_at: string;
  updated_at: string;
}

export interface MetaSubscriber {
  page_id: string; // Changed from number to string to preserve precision of large IDs
  user_id: string;
  user_name: string | null;
  is_active: boolean;
  can_reply: boolean;
  window_expires_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface QueueMetrics {
  queue_name: string;
  pending_count: number;
  active_count: number;
  completed_count: number;
  failed_count: number;
  delayed_count: number;
  waiting_count: number;
  timestamp: Date;
}
