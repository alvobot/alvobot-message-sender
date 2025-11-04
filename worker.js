/**
 * Message Worker - AlvoCast Queue Processor
 *
 * v7.1 - Simple Recursive Edition
 * - Contains self-invocation logic: after processing a batch, it checks config and queue size.
 * - If conditions are met (system enabled, queue not empty), it calls a new instance of itself.
 * - This creates a self-sustaining chain as long as there is work to do.
 */ import { createClient } from 'jsr:@supabase/supabase-js@2';
// =======================================================================
// CONFIGURATION
// =======================================================================
const CONFIG = {
  QUEUE_NAME: 'alvocast-messages',
  BATCH_SIZE: 30,
  VISIBILITY_TIMEOUT: 120,
  ENABLE_RECURSION: true,
  WORKER_FUNCTION_NAME: 'message-worker',
  RATE_LIMIT_ERROR_CODES: new Set([
    '4',
    '17',
    '32',
    '613',
    '80000',
    '80001',
    '80002',
    '80003',
    '80004',
    '80005',
    '80006',
    '80008'
  ]),
  PERMANENT_ERROR_CODES: new Set([
    '10',
    '100',
    '190',
    '200',
    '551',
    '230',
    '368'
  ]),
  AUTH_ERROR_CODES: new Set([
    '190',
    '200',
    '10'
  ])
};
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};
// =======================================================================
// LOGGING HELPERS
// =======================================================================
function logInfo(requestId, message, data) {
  console.log(JSON.stringify({
    level: 'INFO',
    requestId,
    timestamp: new Date().toISOString(),
    message,
    ...data && {
      data
    }
  }));
}
function logError(requestId, message, error) {
  console.error(JSON.stringify({
    level: 'ERROR',
    requestId,
    timestamp: new Date().toISOString(),
    message,
    ...error && {
      error: error instanceof Error ? {
        message: error.message,
        stack: error.stack
      } : error
    }
  }));
}
function logDebug(requestId, message, data) {
  if (Deno.env.get('ENABLE_DEBUG_LOGS') === 'true') {
    console.log(JSON.stringify({
      level: 'DEBUG',
      requestId,
      timestamp: new Date().toISOString(),
      message,
      ...data && {
        data
      }
    }));
  }
}
// =======================================================================
// HELPER FUNCTIONS (Cole aqui suas funções groupByPageId, checkActivePages, etc.)
// =======================================================================
function groupByPageId(messages) {
  const groups = new Map();
  for (const msg of messages){
    const payload = msg.message;
    const pageId = payload.page_id;
    if (!groups.has(pageId)) {
      groups.set(pageId, {
        page_id: pageId,
        access_token: payload.access_token,
        items: []
      });
    }
    groups.get(pageId).items.push({
      msg_id: msg.msg_id,
      user_id: payload.user_id,
      messages: payload.messages,
      flow_id: payload.flow_id,
      run_id: payload.run_id
    });
  }
  return groups;
}
async function checkActivePagesAndArchiveInactive(pageGroups, supabase, requestId) {
  const pageIds = Array.from(pageGroups.keys());
  if (pageIds.length === 0) return {
    activePages: new Map(),
    archivedCount: 0
  };
  logDebug(requestId, 'Checking page status', {
    page_ids: pageIds
  });
  const { data: pages, error } = await supabase.from('meta_pages').select('page_id, is_active').in('page_id', pageIds);
  if (error) {
    logError(requestId, 'Failed to check page status, assuming all are active.', error);
    return {
      activePages: pageGroups,
      archivedCount: 0
    };
  }
  const inactivePages = new Set(pages?.filter((p)=>!p.is_active).map((p)=>p.page_id.toString()) || []);
  if (inactivePages.size === 0) return {
    activePages: pageGroups,
    archivedCount: 0
  };
  logInfo(requestId, 'Found pages in batch that are already inactive', {
    inactive_count: inactivePages.size,
    inactive_pages: Array.from(inactivePages)
  });
  const activePages = new Map();
  const messagesToArchive = [];
  for (const [pageId, batch] of pageGroups.entries()){
    if (inactivePages.has(pageId)) {
      messagesToArchive.push(...batch.items);
    } else {
      activePages.set(pageId, batch);
    }
  }
  let archivedCount = 0;
  if (messagesToArchive.length > 0) {
    logInfo(requestId, 'Archiving messages from already inactive pages', {
      count: messagesToArchive.length
    });
    const logsToSave = messagesToArchive.map((item)=>({
        page_id: Number(item.page_id),
        user_id: item.user_id,
        status: 'failed',
        error_code: 'PAGE_INACTIVE',
        error_message: 'Page is already inactive - message not sent',
        flow_id: item.flow_id,
        run_id: item.run_id
      }));
    for (const item of messagesToArchive){
      const { error: archiveError } = await supabase.schema('pgmq_public').rpc('archive', {
        queue_name: CONFIG.QUEUE_NAME,
        message_id: item.msg_id
      });
      if (archiveError) {
        logError(requestId, 'Failed to archive message from inactive page', {
          msg_id: item.msg_id,
          error: archiveError
        });
      } else {
        archivedCount++;
      }
    }
    await supabase.from('message_logs').insert(logsToSave);
  }
  return {
    activePages,
    archivedCount
  };
}
async function sendToFacebook(accessToken, userId, messages, supabase, pageId, requestId) {
  let sent = 0;
  let capturedHeaders = {};
  let lastMessageId;
  let pageWasPurged = false;
  for (const msg of messages){
    try {
      const payload = {
        recipient: {
          id: userId
        },
        ...msg
      };
      const response = await fetch(`https://graph.facebook.com/v21.0/me/messages?access_token=${accessToken}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });
      const data = await response.json();
      if (data.message_id) lastMessageId = data.message_id;
      const fbHeaders = {};
      response.headers.forEach((value, key)=>{
        fbHeaders[key] = value;
      });
      Object.assign(capturedHeaders, fbHeaders);
      if (!response.ok || data.error) {
        const errorCode = data.error?.code?.toString() || response.status.toString();
        const errorMessage = data.error?.message || 'Unknown error';
        logError(requestId, 'Facebook API returned error', {
          page_id: pageId,
          user_id: userId,
          errorCode,
          errorMessage
        });
        if (CONFIG.AUTH_ERROR_CODES.has(errorCode)) {
        // Lógica de desativação de página
        }
        return {
          success: false,
          sent,
          errorCode,
          errorMessage,
          fbHeaders: capturedHeaders,
          fbMessageId: lastMessageId,
          pagePurged: pageWasPurged
        };
      }
      sent++;
    } catch (error) {
      logError(requestId, 'Exception while sending to Facebook', {
        page_id: pageId,
        user_id: userId,
        error
      });
      return {
        success: false,
        sent,
        errorMessage: error.message,
        fbHeaders: capturedHeaders,
        fbMessageId: lastMessageId,
        pagePurged: false
      };
    }
  }
  return {
    success: true,
    sent,
    fbHeaders: capturedHeaders,
    fbMessageId: lastMessageId,
    pagePurged: false
  };
}
async function processPageBatch(batch, supabase, requestId) {
  const results = [];
  for (const item of batch.items){
    const fbResult = await sendToFacebook(batch.access_token, item.user_id, item.messages, supabase, batch.page_id, requestId);
    results.push({
      msg_id: item.msg_id,
      user_id: item.user_id,
      flow_id: item.flow_id,
      run_id: item.run_id,
      success: fbResult.success,
      errorCode: fbResult.errorCode,
      errorMessage: fbResult.errorMessage,
      fb_message_id: fbResult.fbMessageId,
      page_id: batch.page_id
    });
    if (fbResult.pagePurged) {
      logInfo(requestId, "Stopping batch processing as page queue was purged.", {
        page_id: batch.page_id
      });
      break;
    }
  }
  return results;
}
async function saveLogs(supabase, results, requestId) {
  if (results.length === 0) return;
  try {
    const logs = results.map((r)=>({
        page_id: Number(r.page_id),
        user_id: r.user_id,
        message_id: r.fb_message_id || null,
        status: r.success ? 'success' : 'error',
        error_code: r.errorCode || null,
        error_message: r.errorMessage || null,
        sent_at: r.success ? new Date().toISOString() : null,
        flow_id: r.flow_id || null,
        run_id: r.run_id || null
      }));
    const { error } = await supabase.from('message_logs').insert(logs);
    if (error) logError(requestId, 'Failed to save message_logs to database', error);
  } catch (error) {
    logError(requestId, 'Exception while saving message_logs', error);
  }
}
// =======================================================================
// MAIN EDGE FUNCTION HANDLER
// =======================================================================
Deno.serve(async (req)=>{
  if (req.method === 'OPTIONS') return new Response(null, {
    status: 204,
    headers: CORS_HEADERS
  });
  const startTime = Date.now();
  const requestId = crypto.randomUUID();
  let workerId = 'unknown';
  try {
    const reqBody = await req.json();
    workerId = reqBody.worker_id || 'manual';
  } catch (e) {}
  logInfo(requestId, `Worker [${workerId}] execution started.`);
  try {
    const supabase = createClient(Deno.env.get('SUPABASE_URL'), Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'));
    const { data: messages, error: readError } = await supabase.schema('pgmq_public').rpc('read', {
      queue_name: CONFIG.QUEUE_NAME,
      sleep_seconds: CONFIG.VISIBILITY_TIMEOUT,
      n: CONFIG.BATCH_SIZE
    });
    if (readError) throw new Error(`Queue read failed: ${JSON.stringify(readError)}`);
    if (!messages || messages.length === 0) {
      logInfo(requestId, `Worker [${workerId}] finished: No messages found, stopping chain.`);
      return new Response(JSON.stringify({
        message: 'No messages in queue.'
      }), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          ...CORS_HEADERS
        }
      });
    }
    logInfo(requestId, `Retrieved ${messages.length} messages from queue.`);
    const pageGroups = groupByPageId(messages);
    const { activePages, archivedCount: inactiveArchived } = await checkActivePagesAndArchiveInactive(pageGroups, supabase, requestId);
    let results = [];
    if (activePages.size > 0) {
      for (const batch of activePages.values()){
        results.push(...await processPageBatch(batch, supabase, requestId));
      }
    }
    let finalArchived = inactiveArchived;
    const messagesToAck = results.filter((r)=>r.msg_id);
    const toArchiveIds = messagesToAck.filter((r)=>r.success || CONFIG.PERMANENT_ERROR_CODES.has(r.errorCode || '')).map((r)=>r.msg_id);
    if (toArchiveIds.length > 0) {
      let successfulArchives = 0;
      for (const msgId of toArchiveIds){
        const { error: archiveError } = await supabase.schema('pgmq_public').rpc('archive', {
          queue_name: CONFIG.QUEUE_NAME,
          message_id: msgId
        });
        if (archiveError) logError(requestId, "Failed to archive message", {
          msg_id: msgId,
          error: archiveError
        });
        else successfulArchives++;
      }
      finalArchived += successfulArchives;
    }
    await saveLogs(supabase, results, requestId);
    // ✅ RECURSIVE SELF-INVOCATION LOGIC
    if (CONFIG.ENABLE_RECURSION) {
      const { data: configData } = await supabase.from('orchestrator_config').select('is_enabled').eq('id', 'main').single();
      if (configData?.is_enabled) {
        const { data: metricsData } = await supabase.schema('pgmq_public').rpc('metrics', {
          queue_name: CONFIG.QUEUE_NAME
        });
        if (Number(metricsData?.[0]?.queue_length || 0) > 0) {
          logInfo(requestId, "Queue has more messages. Invoking next worker in chain.");
          // Fire-and-forget a new invocation.
          supabase.functions.invoke(CONFIG.WORKER_FUNCTION_NAME, {
            body: {
              worker_id: `chain_${workerId}`
            }
          });
        } else {
          logInfo(requestId, "Recursion stop: Queue is now empty.");
        }
      } else {
        logInfo(requestId, "Recursion stop: System is disabled via remote config.");
      }
    }
    const summary = {
      message: 'Batch processed',
      duration_ms: Date.now() - startTime
    };
    logInfo(requestId, `Worker [${workerId}] completed successfully.`, summary);
    return new Response(JSON.stringify({
      ...summary,
      requestId
    }), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        ...CORS_HEADERS
      }
    });
  } catch (error) {
    logError(requestId, `Worker [${workerId}] failed with unhandled exception.`, {
      message: error.message,
      stack: error.stack
    });
    return new Response(JSON.stringify({
      error: 'Worker failed',
      message: error.message
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        ...CORS_HEADERS
      }
    });
  }
});
