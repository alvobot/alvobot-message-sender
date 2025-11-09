// Flow processor - migrated from process_message_run.js
import { Flow, FlowNode, FlowConnection } from '../types';
import logger from './logger';

export interface FlowProcessingResult {
  messages: any[];
  nextStepId: string | null;
  nextStepAt: string | null;
  lastStepId: string | null;
  isComplete: boolean;
}

/**
 * Process a flow graph and assemble messages to be sent
 * Migrated from assembleMessages() function
 */
export function assembleMessages(
  flow: Flow,
  currentStepId: string | null
): FlowProcessingResult {
  const nodes = flow.nodes;
  const connections = flow.connections;

  logger.debug('Processing flow', {
    total_nodes: nodes.length,
    total_connections: connections.length,
    current_step: currentStepId,
  });

  const messages: any[] = [];
  let nextStepId: string | null = null;
  let nextStepAt: string | null = null;
  let lastStepId: string | null = null;
  let isComplete = false;

  // Find start node
  const startNode = nodes.find((node) => node.type === 'start');
  if (!startNode) {
    throw new Error('Flow must have a start node');
  }

  // Determine starting point
  let currentNodeId = currentStepId || startNode.id;
  let currentNode = nodes.find((node) => node.id === currentNodeId);
  const processedNodes = new Set<string>();

  logger.debug('Starting flow traversal', { starting_node: currentNodeId });

  while (currentNode && !processedNodes.has(currentNode.id)) {
    logger.debug('Processing node', {
      id: currentNode.id,
      type: currentNode.type,
    });

    processedNodes.add(currentNode.id);

    switch (currentNode.type) {
      case 'start':
        // Start node - just move to next
        break;

      case 'text':
      case 'card':
        // Build Meta/Facebook message
        const message = buildMetaMessage(currentNode);
        messages.push(message);
        lastStepId = currentNode.id;
        logger.debug('Message added', {
          node_id: currentNode.id,
          type: currentNode.type,
          total_messages: messages.length,
        });
        break;

      case 'wait':
        // Wait node - stop here and schedule next execution
        nextStepAt = calculateNextStepTime(currentNode);
        nextStepId = getNextNodeId(currentNode.id, connections);
        return {
          messages,
          nextStepId,
          nextStepAt,
          lastStepId,
          isComplete: false,
        };

      case 'traffic':
        // Traffic split (A/B testing)
        const selectedRoute = selectTrafficRoute(currentNode, connections);
        if (selectedRoute) {
          currentNodeId = selectedRoute;
          currentNode = nodes.find((node) => node.id === currentNodeId);
          continue;
        }
        break;

      case 'end':
        // End node - mark as complete
        isComplete = true;
        return {
          messages,
          nextStepId: null,
          nextStepAt: null,
          lastStepId,
          isComplete: true,
        };
    }

    // Move to next node
    const nextNodeId = getNextNodeId(currentNode.id, connections);
    if (!nextNodeId) {
      logger.debug('No more nodes, marking as complete');
      isComplete = true;
      break;
    }

    currentNodeId = nextNodeId;
    currentNode = nodes.find((node) => node.id === currentNodeId);
  }

  logger.debug('Flow processing complete', {
    messages_count: messages.length,
    is_complete: isComplete,
    next_step_id: nextStepId,
    last_step_id: lastStepId,
  });

  return {
    messages,
    nextStepId,
    nextStepAt,
    lastStepId,
    isComplete,
  };
}

/**
 * Build a Facebook Messenger message from a flow node
 */
function buildMetaMessage(node: FlowNode): any {
  const messageType = node.data.messageType || 'ACCOUNT_UPDATE';

  const message: any = {
    messaging_type: 'MESSAGE_TAG',
    tag: messageType,
    message: {},
  };

  switch (node.type) {
    case 'text':
      if (node.data.buttons && node.data.buttons.length > 0) {
        // Text with buttons (button template)
        const buttons = node.data.buttons.map((button: any) => {
          if (button.action === 'send_message') {
            return {
              type: 'postback',
              title: button.label,
              payload: button.message || '',
            };
          } else {
            return {
              type: 'web_url',
              url: button.url || '',
              title: button.label,
            };
          }
        });

        message.message = {
          attachment: {
            type: 'template',
            payload: {
              template_type: 'button',
              text: node.data.text || '',
              buttons: buttons,
            },
          },
        };
      } else {
        // Simple text message
        message.message = {
          text: node.data.text || '',
        };
      }
      break;

    case 'card':
      // Generic template (card)
      const element: any = {
        title: node.data.title || '',
      };

      if (node.data.imageUrl) {
        element.image_url = node.data.imageUrl;
      }

      if (node.data.subtitle) {
        element.subtitle = node.data.subtitle;
      }

      if (node.data.url) {
        element.default_action = {
          type: 'web_url',
          url: node.data.url,
          webview_height_ratio: 'tall',
        };
      }

      if (node.data.buttons && node.data.buttons.length > 0) {
        element.buttons = node.data.buttons.map((button: any) => {
          if (button.action === 'send_message') {
            return {
              type: 'postback',
              title: button.label,
              payload: button.message || '',
            };
          } else {
            return {
              type: 'web_url',
              url: button.url || node.data.url || '',
              title: button.label,
            };
          }
        });
      }

      // Clean up undefined fields
      if (!element.subtitle) delete element.subtitle;
      if (!element.default_action) delete element.default_action;
      if (!element.buttons) delete element.buttons;
      if (!element.image_url) delete element.image_url;

      message.message = {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'generic',
            image_aspect_ratio: node.data.imageAspectRatio || 'square',
            elements: [element],
          },
        },
      };
      break;
  }

  return message;
}

/**
 * Calculate the timestamp for the next step based on wait time
 */
function calculateNextStepTime(node: FlowNode): string {
  // Support both 'duration' and 'waitTime' for backwards compatibility
  const waitTime = node.data.duration || node.data.waitTime || 0;
  // Support both 'timeUnit' and 'waitUnit' for backwards compatibility
  const waitUnit = node.data.timeUnit || node.data.waitUnit || 'minutes';

  const now = new Date();
  let milliseconds = 0;

  switch (waitUnit) {
    case 'minutes':
      milliseconds = waitTime * 60 * 1000;
      break;
    case 'hours':
      milliseconds = waitTime * 60 * 60 * 1000;
      break;
    case 'days':
      milliseconds = waitTime * 24 * 60 * 60 * 1000;
      break;
  }

  const nextTime = new Date(now.getTime() + milliseconds);

  logger.debug('Calculated next step time for wait node', {
    node_id: node.id,
    waitTime,
    waitUnit,
    nextTime: nextTime.toISOString(),
  });

  return nextTime.toISOString();
}

/**
 * Select a route based on traffic split percentages (A/B testing)
 */
function selectTrafficRoute(node: FlowNode, connections: FlowConnection[]): string | null {
  // Support both 'branches' and 'routes' for backwards compatibility
  const branches = node.data.branches || node.data.routes;

  if (!branches || branches.length === 0) {
    logger.warn('Traffic node has no branches', { node_id: node.id });
    return null;
  }

  // Generate random number for selection (0-100)
  const random = Math.random() * 100;
  let accumulated = 0;

  logger.debug('Traffic split selection', {
    node_id: node.id,
    random_value: random.toFixed(2),
    branches_count: branches.length,
  });

  // Select branch based on percentage
  let selectedBranch = null;
  for (let i = 0; i < branches.length; i++) {
    const branch = branches[i];
    accumulated += branch.percentage;

    if (random <= accumulated) {
      selectedBranch = branch;
      logger.debug('Branch selected', {
        branch_index: i,
        branch_label: branch.label,
        branch_percentage: branch.percentage,
      });
      break;
    }
  }

  // Fallback to last branch if none selected
  if (!selectedBranch) {
    selectedBranch = branches[branches.length - 1];
    logger.debug('Using fallback branch', {
      branch_label: selectedBranch.label,
    });
  }

  // If branch has targetNodeId, use it directly
  if (selectedBranch.targetNodeId) {
    return selectedBranch.targetNodeId;
  }

  // Otherwise, find the connection using sourceHandle
  // Connections from traffic nodes use sourceHandle like "nodeId-output-0", "nodeId-output-1", etc.
  const branchIndex = branches.indexOf(selectedBranch);
  const sourceHandle = `${node.id}-output-${branchIndex}`;

  const connection = connections.find(
    (conn: any) => conn.from === node.id && conn.sourceHandle === sourceHandle
  );

  if (connection) {
    const targetId = (connection as any).to || connection.target;
    logger.debug('Found connection for branch', {
      source_handle: sourceHandle,
      target_node: targetId,
    });
    return targetId;
  }

  logger.warn('No connection found for selected branch', {
    node_id: node.id,
    branch_index: branchIndex,
    source_handle: sourceHandle,
  });

  return null;
}

/**
 * Get the next node ID based on connections
 * Note: Connections use 'from' and 'to' instead of 'source' and 'target'
 */
function getNextNodeId(
  currentNodeId: string,
  connections: FlowConnection[]
): string | null {
  // Try with 'from'/'to' first (current format)
  let connection = connections.find(
    (conn: any) => conn.from === currentNodeId
  );

  // Fallback to 'source'/'target' if needed
  if (!connection) {
    connection = connections.find((conn) => conn.source === currentNodeId);
  }

  if (connection) {
    return (connection as any).to || connection.target || null;
  }

  return null;
}
