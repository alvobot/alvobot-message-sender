// Flow graph types (migrated from existing code)

export interface FlowNode {
  id: string;
  type: 'start' | 'text' | 'card' | 'wait' | 'traffic' | 'call-flow' | 'end';
  data: Record<string, any>;
  position?: { x: number; y: number };
}

export interface CallFlowNodeData {
  label: string;
  selectedFlowId: string;
}

export interface FlowConnection {
  id: string;
  source: string;
  target: string;
  sourceHandle?: string;
  targetHandle?: string;
}

export interface Flow {
  nodes: FlowNode[];
  connections: FlowConnection[];
}

export interface MessageRun {
  id: number;
  user_id: string;
  trigger_id: number;
  page_ids: string[]; // Changed from number[] to string[] to preserve precision of large IDs
  flow_id: string;
  status: string;
  start_at: string;
  next_step_at: string | null;
  next_step_id: string | null;
  last_step_id: string | null;
  total_messages: number;
  success_count: number;
  failure_count: number;
  error_summary: Record<string, any> | null;
  created_at: string;
  updated_at: string;
}

export interface MessageFlow {
  id: string;
  name: string;
  project_id: number;
  status: string;
  flow: Flow;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface AssembledMessage {
  type: 'text' | 'card' | 'wait';
  nodeId: string;
  content: any;
  waitDuration?: number;
}

export interface TrafficSplit {
  percentage: number;
  targetNodeId: string;
}
