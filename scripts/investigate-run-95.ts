/**
 * Script para investigar falha no disparo id 95
 * Analisa logs, status da run, e tenta simular envio de teste
 */

import supabase from '../src/database/supabase';
import messageQueue from '../src/queues/message-queue';
import facebookClient from '../src/integrations/facebook-client';
import logger from '../src/utils/logger';

const RUN_ID = 95;

async function investigateRun() {
  console.log('==========================================');
  console.log(`🔍 Investigando disparo #${RUN_ID}`);
  console.log('==========================================\n');

  // 1. Buscar informações da run
  console.log('1️⃣ Buscando informações da message_run...');
  const { data: run, error: runError } = await supabase
    .from('message_runs')
    .select('*')
    .eq('id', RUN_ID)
    .single();

  if (runError || !run) {
    console.error('❌ Erro ao buscar run:', runError?.message);
    return;
  }

  console.log('✅ Run encontrada:');
  console.log({
    id: run.id,
    status: run.status,
    flow_id: run.flow_id,
    page_ids: run.page_ids,
    user_id: run.user_id,
    created_at: run.created_at,
    start_at: run.start_at,
    completed_at: run.completed_at,
    next_step_id: run.next_step_id,
    next_step_at: run.next_step_at,
    last_step_id: run.last_step_id,
    error_summary: run.error_summary,
  });
  console.log('\n');

  // 2. Verificar se existem logs
  console.log('2️⃣ Buscando logs de mensagens enviadas...');
  const { data: logs, error: logsError, count } = await supabase
    .from('message_logs')
    .select('*', { count: 'exact' })
    .eq('run_id', RUN_ID)
    .order('created_at', { ascending: false })
    .limit(10);

  if (logsError) {
    console.error('❌ Erro ao buscar logs:', logsError.message);
  } else {
    console.log(`✅ Total de logs encontrados: ${count || 0}`);
    if (logs && logs.length > 0) {
      console.log('\n📊 Últimos 10 logs:');
      logs.forEach((log, idx) => {
        console.log(`  ${idx + 1}. Status: ${log.status}, Page: ${log.page_id}, User: ${log.user_id}`);
        if (log.error_code) {
          console.log(`     ❌ Error ${log.error_code}: ${log.error_message}`);
        }
      });
    } else {
      console.log('⚠️  Nenhum log encontrado - mensagens não foram enviadas!');
    }
  }
  console.log('\n');

  // 3. Verificar jobs na fila
  console.log('3️⃣ Verificando jobs na fila BullMQ...');
  try {
    const waitingCount = await messageQueue.getWaitingCount();
    const activeCount = await messageQueue.getActiveCount();
    const delayedCount = await messageQueue.getDelayedCount();
    const failedCount = await messageQueue.getFailedCount();
    const completedCount = await messageQueue.getCompletedCount();

    console.log('✅ Estado da fila:');
    console.log({
      waiting: waitingCount,
      active: activeCount,
      delayed: delayedCount,
      failed: failedCount,
      completed: completedCount,
    });

    // Buscar jobs relacionados a esta run
    const jobs = await messageQueue.getJobs(['waiting', 'active', 'delayed', 'failed', 'completed']);
    const runJobs = jobs.filter(job => job.data?.runId === RUN_ID);

    console.log(`\n📦 Jobs relacionados à run ${RUN_ID}: ${runJobs.length}`);
    if (runJobs.length > 0) {
      runJobs.slice(0, 5).forEach((job, idx) => {
        console.log(`  ${idx + 1}. Job ${job.id} - State: ${job.getState()}, Page: ${job.data?.pageId}, User: ${job.data?.userId}`);
      });
    }
  } catch (err: any) {
    console.error('❌ Erro ao verificar fila:', err.message);
  }
  console.log('\n');

  // 4. Verificar página
  console.log('4️⃣ Verificando páginas do disparo...');
  let pageIds: string[] = [];
  if (Array.isArray(run.page_ids)) {
    pageIds = run.page_ids.map((id) => String(id));
  } else if (typeof run.page_ids === 'string') {
    try {
      const parsed = JSON.parse(run.page_ids);
      pageIds = Array.isArray(parsed) ? parsed.map((id) => String(id)) : [String(parsed)];
    } catch {
      pageIds = [String(run.page_ids)];
    }
  }

  console.log(`📄 Page IDs: ${pageIds.join(', ')}`);

  for (const pageId of pageIds) {
    const { data: pages, error: pageError } = await supabase
      .from('meta_pages')
      .select('page_id::text, page_name, is_active, owner_user_id, blocked_until, block_reason, last_error_code')
      .eq('page_id', pageId)
      .eq('owner_user_id', run.user_id);

    if (pageError) {
      console.error(`❌ Erro ao buscar página ${pageId}:`, pageError.message);
      continue;
    }

    if (!pages || pages.length === 0) {
      console.log(`⚠️  Página ${pageId} NÃO ENCONTRADA para user_id ${run.user_id}`);
      console.log(`   🔍 Verificando se existe para outros usuários...`);

      const { data: otherPages } = await supabase
        .from('meta_pages')
        .select('page_id::text, owner_user_id, is_active')
        .eq('page_id', pageId);

      if (otherPages && otherPages.length > 0) {
        console.log(`   ⚠️  Encontradas ${otherPages.length} páginas com page_id ${pageId} para outros usuários:`);
        otherPages.forEach(p => {
          console.log(`      - owner_user_id: ${p.owner_user_id}, is_active: ${p.is_active}`);
        });
        console.log(`   ❗ PROBLEMA: Run tem user_id ${run.user_id} mas página não pertence a esse usuário!`);
      }
      continue;
    }

    const page = pages[0];
    console.log(`✅ Página ${pageId} (${page.page_name}):`);
    console.log({
      is_active: page.is_active,
      owner_user_id: page.owner_user_id,
      blocked_until: page.blocked_until,
      block_reason: page.block_reason,
      last_error_code: page.last_error_code,
    });

    // Verificar se está bloqueada
    if (page.blocked_until) {
      const blockedUntil = new Date(page.blocked_until);
      const now = new Date();
      if (blockedUntil > now) {
        console.log(`   ⚠️  PÁGINA BLOQUEADA até ${blockedUntil.toISOString()}`);
        console.log(`   ⏱️  Tempo restante: ${Math.round((blockedUntil.getTime() - now.getTime()) / 60000)} minutos`);
      } else {
        console.log(`   ✅ Bloqueio expirado (era até ${blockedUntil.toISOString()})`);
      }
    }
  }
  console.log('\n');

  // 5. Verificar inscritos
  console.log('5️⃣ Verificando inscritos ativos...');
  for (const pageId of pageIds) {
    const { data: subscribers, error: subsError, count: subsCount } = await supabase
      .from('meta_subscribers')
      .select('user_id::text', { count: 'exact' })
      .eq('page_id', pageId)
      .eq('is_active', true)
      .limit(5);

    if (subsError) {
      console.error(`❌ Erro ao buscar inscritos da página ${pageId}:`, subsError.message);
    } else {
      console.log(`✅ Página ${pageId}: ${subsCount || 0} inscritos ativos`);
      if (subscribers && subscribers.length > 0) {
        console.log(`   Primeiros inscritos: ${subscribers.map(s => s.user_id).join(', ')}`);
      }
    }
  }
  console.log('\n');

  // 6. Verificar flow
  console.log('6️⃣ Verificando flow...');
  const { data: flow, error: flowError } = await supabase
    .from('message_flows')
    .select('id, name, flow')
    .eq('id', run.flow_id)
    .single();

  if (flowError || !flow) {
    console.error('❌ Erro ao buscar flow:', flowError?.message);
  } else {
    console.log(`✅ Flow encontrado: ${flow.name}`);
    console.log(`   Nodes: ${flow.flow?.nodes?.length || 0}`);
    console.log(`   Connections: ${flow.flow?.connections?.length || 0}`);
  }
  console.log('\n');

  // 7. Teste de envio
  console.log('7️⃣ Teste de envio de 1 mensagem...');
  console.log('⏭️  Pulando teste real - análise completa');
  console.log('\n');

  // 8. Diagnóstico final
  console.log('==========================================');
  console.log('📋 DIAGNÓSTICO');
  console.log('==========================================');

  const issues: string[] = [];

  if (!logs || logs.length === 0) {
    issues.push('❌ Nenhuma mensagem foi enviada (sem logs)');
  }

  if (run.status !== 'finished' && run.status !== 'running') {
    issues.push(`⚠️  Status da run: ${run.status}`);
  }

  if (pageIds.length === 0) {
    issues.push('❌ Nenhuma página configurada no disparo');
  }

  if (issues.length > 0) {
    console.log('🔴 PROBLEMAS ENCONTRADOS:');
    issues.forEach(issue => console.log(`  ${issue}`));
  } else {
    console.log('✅ Nenhum problema óbvio detectado');
  }

  console.log('\n');
}

// Executar
investigateRun()
  .then(() => {
    console.log('✅ Investigação concluída');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Erro na investigação:', error);
    process.exit(1);
  });
