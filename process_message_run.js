// @deno-types="npm:@types/node"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
// ============================================
// TRANSFORM RUN (PARTE 1)
// ============================================
function transformRun(runData) {
  const runItems = [];
  let pageIds = [];
  if (Array.isArray(runData.page_ids)) {
    pageIds = runData.page_ids;
  } else if (typeof runData.page_ids === 'string') {
    try {
      pageIds = JSON.parse(runData.page_ids);
    } catch  {
      pageIds = [
        runData.page_ids
      ];
    }
  }
  for (const pageId of pageIds){
    runItems.push({
      id: runData.id,
      status: runData.status,
      flow_id: runData.flow_id,
      user_id: runData.user_id,
      start_at: runData.start_at,
      created_at: runData.created_at,
      trigger_id: runData.trigger_id,
      updated_at: runData.updated_at,
      last_step_id: runData.last_step_id,
      next_step_at: runData.next_step_at,
      next_step_id: runData.next_step_id,
      page_id: String(pageId),
      all_page_ids: pageIds
    });
  }
  return runItems;
}
// ============================================
// PROCESS FLOW (PARTE 3)
// ============================================
function assembleMessages(flowData, runItem) {
  const nodes = flowData.flow.nodes;
  const connections = flowData.flow.connections;
  console.log('[DEBUG] Flow data:', JSON.stringify({
    total_nodes: nodes.length,
    total_connections: connections.length,
    node_types: nodes.map((n)=>({
        id: n.id,
        type: n.type
      }))
  }));
  const messages = [];
  let currentNodeId = null;
  let nextStepId = null;
  let nextStepAt = null;
  let lastStepId = null;
  let isComplete = false;
  const startNode = nodes.find((node)=>node.type === "start");
  if (!startNode) {
    throw new Error("Flow must have a start node");
  }
  console.log('[DEBUG] Start node found:', startNode.id);
  console.log('[DEBUG] runItem.next_step_id:', runItem.next_step_id);
  currentNodeId = runItem.next_step_id || startNode.id;
  console.log('[DEBUG] Starting from node:', currentNodeId);
  let currentNode = nodes.find((node)=>node.id === currentNodeId);
  let processedNodes = new Set();
  console.log('[DEBUG] Current node:', currentNode ? currentNode.id : 'NOT FOUND');
  while(currentNode && !processedNodes.has(currentNode.id)){
    console.log('[DEBUG] Processing node:', currentNode.id, 'type:', currentNode.type);
    processedNodes.add(currentNode.id);
    switch(currentNode.type){
      case "start":
        break;
      case "text":
        console.log('[DEBUG] Building text message for node:', currentNode.id);
        const textMessage = buildMetaMessage(currentNode);
        messages.push(textMessage);
        lastStepId = currentNode.id;
        console.log('[DEBUG] Text message added. Total messages:', messages.length);
        break;
      case "card":
        console.log('[DEBUG] Building card message for node:', currentNode.id);
        const cardMessage = buildMetaMessage(currentNode);
        messages.push(cardMessage);
        lastStepId = currentNode.id;
        console.log('[DEBUG] Card message added. Total messages:', messages.length);
        break;
      case "wait":
        nextStepAt = calculateNextStepTime(currentNode);
        nextStepId = getNextNodeId(currentNode.id, connections);
        return {
          messages,
          nextStepId,
          nextStepAt,
          lastStepId,
          isComplete: false
        };
      case "traffic":
        const selectedRoute = selectTrafficRoute(currentNode);
        if (selectedRoute) {
          currentNodeId = selectedRoute;
          currentNode = nodes.find((node)=>node.id === currentNodeId);
          continue;
        }
        break;
      case "end":
        isComplete = true;
        return {
          messages,
          nextStepId: null,
          nextStepAt: null,
          lastStepId,
          isComplete: true
        };
    }
    const nextNodeId = getNextNodeId(currentNode.id, connections);
    console.log('[DEBUG] Next node ID from connections:', nextNodeId);
    if (!nextNodeId) {
      console.log('[DEBUG] No more nodes, marking as complete');
      isComplete = true;
      break;
    }
    currentNodeId = nextNodeId;
    currentNode = nodes.find((node)=>node.id === currentNodeId);
    console.log('[DEBUG] Moving to next node:', currentNode ? currentNode.id : 'NOT FOUND');
  }
  console.log('[DEBUG] Final result:', {
    messages_count: messages.length,
    isComplete,
    nextStepId,
    nextStepAt,
    lastStepId
  });
  return {
    messages,
    nextStepId,
    nextStepAt,
    lastStepId,
    isComplete
  };
}
function buildMetaMessage(node) {
  const messageType = node.data.messageType || "ACCOUNT_UPDATE";
  const message = {
    messaging_type: "MESSAGE_TAG",
    tag: messageType,
    message: {}
  };
  switch(node.type){
    case "text":
      if (node.data.buttons && node.data.buttons.length > 0) {
        const buttons = node.data.buttons.map((button)=>{
          if (button.action === "send_message") {
            return {
              type: "postback",
              title: button.label,
              payload: button.message || ""
            };
          } else {
            return {
              type: "web_url",
              url: button.url || "",
              title: button.label
            };
          }
        });
        const buttonTemplate = {
          template_type: "button",
          text: node.data.text || "",
          buttons: buttons
        };
        message.message = {
          attachment: {
            type: "template",
            payload: buttonTemplate
          }
        };
      } else {
        message.message = {
          text: node.data.text || ""
        };
      }
      break;
    case "card":
      const element = {
        title: node.data.title || "",
        image_url: node.data.imageUrl,
        subtitle: node.data.subtitle
      };
      if (node.data.url) {
        element.default_action = {
          type: "web_url",
          url: node.data.url,
          webview_height_ratio: "tall"
        };
      }
      if (node.data.buttons && node.data.buttons.length > 0) {
        element.buttons = node.data.buttons.map((button)=>{
          if (button.action === "send_message") {
            return {
              type: "postback",
              title: button.label,
              payload: button.message || ""
            };
          } else {
            return {
              type: "web_url",
              url: button.url || node.data.url || "",
              title: button.label
            };
          }
        });
      }
      if (!element.subtitle) delete element.subtitle;
      if (!element.default_action) delete element.default_action;
      if (!element.buttons) delete element.buttons;
      if (!element.image_url) delete element.image_url;
      const genericTemplate = {
        template_type: "generic",
        elements: [
          element
        ]
      };
      message.message = {
        attachment: {
          type: "template",
          payload: genericTemplate
        }
      };
      break;
  }
  return message;
}
function calculateNextStepTime(node) {
  const waitTime = node.data.waitTime || 0;
  const waitUnit = node.data.waitUnit || "minutes";
  const now = new Date();
  let milliseconds = 0;
  switch(waitUnit){
    case "minutes":
      milliseconds = waitTime * 60 * 1000;
      break;
    case "hours":
      milliseconds = waitTime * 60 * 60 * 1000;
      break;
    case "days":
      milliseconds = waitTime * 24 * 60 * 60 * 1000;
      break;
  }
  const nextTime = new Date(now.getTime() + milliseconds);
  return nextTime.toISOString();
}
function selectTrafficRoute(node) {
  if (!node.data.routes || node.data.routes.length === 0) {
    return null;
  }
  const random = Math.random() * 100;
  let accumulated = 0;
  for (const route of node.data.routes){
    accumulated += route.percentage;
    if (random <= accumulated) {
      return route.targetNodeId;
    }
  }
  return node.data.routes[node.data.routes.length - 1].targetNodeId;
}
function getNextNodeId(currentNodeId, connections) {
  const connection = connections.find((conn)=>conn.from === currentNodeId);
  return connection ? connection.to : null;
}
// ============================================
// QUEUE MESSAGES (VERSÃO OTIMIZADA COM RPC)
// ============================================
async function enqueueSubscriberMessages(supabaseClient, runItem, messages) {
  console.log(`[QUEUE] Starting enqueue process for page ${runItem.page_id}`);
  // 1. Buscar dados da página
  const { data: pageData, error: pageError } = await supabaseClient.from('meta_pages').select('page_id::text, page_name, access_token, connection_id').eq('page_id', runItem.page_id).single();
  if (pageError || !pageData) {
    throw new Error(`Failed to fetch page data: ${pageError?.message || 'Page not found'}`);
  }
  console.log(`[QUEUE] Page found: ${pageData.page_name} (${pageData.page_id})`);
  // 2. Preparar mensagens com recipient placeholder (será substituído no RPC)
  const messagesForQueue = messages.map((msg)=>({
      ...msg,
      recipient: {
        id: "{{USER_ID}}"
      } // Placeholder que será substituído no RPC
    }));
  console.log(`[QUEUE] Calling RPC to enqueue messages for all subscribers...`);
  const startTime = Date.now();
  // 3. Chamar RPC que processa tudo no banco de dados
  const { data, error } = await supabaseClient.rpc('enqueue_messages_bulk', {
    p_queue_name: 'alvocast-messages',
    p_page_id: runItem.page_id,
    p_flow_id: String(runItem.flow_id),
    p_run_id: String(runItem.id),
    p_messages: messagesForQueue,
    p_page_data: pageData
  });
  const duration = Date.now() - startTime;
  if (error) {
    console.error(`[QUEUE] RPC failed:`, error);
    throw new Error(`Failed to enqueue messages: ${error.message}`);
  }
  const result = Array.isArray(data) ? data[0] : data;
  console.log(`[QUEUE] ✅ Completed in ${duration}ms: ${result.queued}/${result.total} messages queued`);
  return {
    total: result.total,
    queued: result.queued,
    duration_ms: duration
  };
}
// ============================================
// MAIN HANDLER
// ============================================
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};
serve(async (req)=>{
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders
    });
  }
  try {
    const supabaseClient = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '', {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    });
    const { run_id } = await req.json();
    if (!run_id) {
      return new Response(JSON.stringify({
        error: 'run_id is required'
      }), {
        status: 400,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      });
    }
    console.log(`[MAIN] Processing run_id: ${run_id}`);
    // 1. Buscar run
    const { data: runData, error: fetchError } = await supabaseClient.from('message_runs').select('*').eq('id', run_id).single();
    if (fetchError || !runData) {
      console.error('[MAIN] Failed to fetch run:', fetchError);
      return new Response(JSON.stringify({
        error: 'Run not found',
        details: fetchError?.message
      }), {
        status: 404,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      });
    }
    console.log(`[MAIN] Run found: ${runData.id}, flow_id: ${runData.flow_id}, pages: ${runData.page_ids}`);
    // 2. Transform (split page_ids)
    const runItems = transformRun(runData);
    console.log(`[MAIN] Transformed into ${runItems.length} run items`);
    const results = [];
    // 3. Processar cada page_id
    for (const item of runItems){
      console.log(`[MAIN] Processing page_id: ${item.page_id}`);
      try {
        // 3a. Buscar flow
        const { data: flowData, error: flowError } = await supabaseClient.from('message_flows').select('*').eq('id', item.flow_id).single();
        if (flowError || !flowData) {
          console.error(`[MAIN] Failed to fetch flow ${item.flow_id}:`, flowError);
          results.push({
            page_id: item.page_id,
            success: false,
            error: 'Flow not found'
          });
          continue;
        }
        console.log(`[MAIN] Flow found: ${flowData.id}`);
        // 3b. Processar flow
        const result = assembleMessages(flowData, item);
        console.log(`[MAIN] Assembled ${result.messages.length} messages, isComplete: ${result.isComplete}`);
        // 3c. Atualizar run
        const { error: updateError } = await supabaseClient.from('message_runs').update({
          status: result.isComplete ? 'finished' : 'running',
          next_step_at: result.nextStepAt,
          next_step_id: result.nextStepId,
          last_step_id: result.lastStepId,
          updated_at: new Date().toISOString()
        }).eq('id', item.id);
        if (updateError) {
          console.error(`[MAIN] Failed to update run ${item.id}:`, updateError);
        } else {
          console.log(`[MAIN] Run ${item.id} updated successfully`);
        }
        // 3d. Enfileirar usando RPC otimizada
        if (result.messages.length > 0) {
          const queueResult = await enqueueSubscriberMessages(supabaseClient, item, result.messages);
          results.push({
            page_id: item.page_id,
            success: true,
            messages_count: result.messages.length,
            subscribers_total: queueResult.total,
            subscribers_queued: queueResult.queued,
            duration_ms: queueResult.duration_ms,
            is_complete: result.isComplete,
            next_step_at: result.nextStepAt,
            next_step_id: result.nextStepId
          });
          console.log(`[MAIN] Page ${item.page_id}: ${queueResult.queued}/${queueResult.total} subscribers queued in ${queueResult.duration_ms}ms`);
        } else {
          results.push({
            page_id: item.page_id,
            success: true,
            messages_count: 0,
            note: 'No messages to send (possibly waiting or complete)',
            is_complete: result.isComplete,
            next_step_at: result.nextStepAt,
            next_step_id: result.nextStepId
          });
        }
      } catch (error) {
        console.error(`[MAIN] Error processing page ${item.page_id}:`, error);
        const errorMessage = error instanceof Error ? error.message : String(error);
        results.push({
          page_id: item.page_id,
          success: false,
          error: errorMessage
        });
      }
    }
    return new Response(JSON.stringify({
      success: true,
      run_id: run_id,
      results: results
    }), {
      status: 200,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    });
  } catch (error) {
    console.error('[MAIN] Unexpected error:', error);
    const errorMessage = error instanceof Error ? error.message : String(error);
    const errorStack = error instanceof Error ? error.stack : undefined;
    return new Response(JSON.stringify({
      success: false,
      error: errorMessage,
      stack: errorStack
    }), {
      status: 500,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    });
  }
});
