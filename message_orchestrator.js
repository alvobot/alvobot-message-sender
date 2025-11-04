/**
 * Message Orchestrator - AlvoCast Queue Coordinator
 *
 * v6.1 - Simple Burst Spawner
 * - This orchestrator acts as a simple, periodic "burst" spawner.
 * - It reads `max_workers` and `is_enabled` from the 'orchestrator_config' table.
 * - If the system is enabled AND the queue has messages, it spawns exactly `max_workers` new workers.
 * - It does NOT check for already active workers. Its job is simply to inject a new batch of workers periodically.
 */ import { createClient } from 'jsr:@supabase/supabase-js@2';
const CONFIG = {
  QUEUE_NAME: 'alvocast-messages',
  WORKER_FUNCTION_NAME: 'message-worker',
  MIN_QUEUE_SIZE_TO_PROCESS: 1
};
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};
Deno.serve(async (req)=>{
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: CORS_HEADERS,
      status: 204
    });
  }
  const startTime = Date.now();
  try {
    const supabase = createClient(Deno.env.get('SUPABASE_URL'), Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'));
    // 1. Fetch remote config
    const { data: configData, error: configError } = await supabase.from('orchestrator_config').select('is_enabled, max_workers, delay_between_workers_ms').eq('id', 'main').single();
    if (configError) throw new Error(`Failed to read remote config: ${configError.message}`);
    // 2. Check if enabled
    if (!configData.is_enabled) {
      console.log('[Orchestrator-Burst] Skipping: System is disabled via remote config.');
      return new Response(JSON.stringify({
        message: 'Skipping: System disabled.'
      }), {
        status: 200
      });
    }
    // 3. Check if queue has work
    const { data: metricsData } = await supabase.schema('pgmq_public').rpc('metrics', {
      queue_name: CONFIG.QUEUE_NAME
    });
    const queueLength = Number(metricsData?.[0]?.queue_length || 0);
    if (queueLength < CONFIG.MIN_QUEUE_SIZE_TO_PROCESS) {
      console.log('[Orchestrator-Burst] Skipping: Queue is empty.');
      return new Response(JSON.stringify({
        message: 'Skipping: Queue empty.'
      }), {
        status: 200
      });
    }
    // 4. Spawn the configured number of workers
    const workersToSpawn = configData.max_workers || 0;
    if (workersToSpawn <= 0) {
      console.log('[Orchestrator-Burst] Skipping: max_workers is set to 0.');
      return new Response(JSON.stringify({
        message: 'Skipping: max_workers is 0.'
      }), {
        status: 200
      });
    }
    console.log(`[Orchestrator-Burst] ACTION: Queue has ${queueLength} messages. Spawning a burst of ${workersToSpawn} worker(s).`);
    const invocations = [];
    for(let i = 0; i < workersToSpawn; i++){
      const workerId = `burst_${new Date().toISOString().slice(11, 23)}_${i + 1}`;
      invocations.push(supabase.functions.invoke(CONFIG.WORKER_FUNCTION_NAME, {
        body: {
          worker_id: workerId
        }
      }));
      // Apply delay if configured
      if (i < workersToSpawn - 1 && configData.delay_between_workers_ms > 0) {
        await new Promise((resolve)=>setTimeout(resolve, configData.delay_between_workers_ms));
      }
    }
    // We don't need to wait for them to finish, just fire and forget.
    Promise.allSettled(invocations);
    const summary = {
      success: true,
      message: `Successfully launched a burst of ${workersToSpawn} workers.`,
      duration_ms: Date.now() - startTime
    };
    console.log(`[Orchestrator-Burst] SUCCESS: ${summary.message}`);
    return new Response(JSON.stringify(summary), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        ...CORS_HEADERS
      }
    });
  } catch (error) {
    console.error(`[Orchestrator-Burst] FAILED: ${error.message}`);
    return new Response(JSON.stringify({
      error: 'Orchestrator failed',
      message: error.message
    }), {
      status: 500
    });
  }
});
