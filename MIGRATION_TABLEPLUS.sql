-- ==============================================================================
-- MIGRATION: Add trigger_run_id to message_logs
-- Rode este SQL no TablePlus conectado ao seu banco de produção
-- ==============================================================================

-- IMPORTANTE: Este script é idempotente (pode rodar múltiplas vezes sem erro)
-- Usa IF NOT EXISTS para evitar erros se já foi executado

BEGIN;

-- 1. Adicionar coluna trigger_run_id
ALTER TABLE message_logs.message_logs
ADD COLUMN IF NOT EXISTS trigger_run_id BIGINT NULL;

-- 2. Criar índice para queries eficientes
CREATE INDEX IF NOT EXISTS idx_message_logs_trigger_run_id
ON message_logs.message_logs(trigger_run_id)
WHERE trigger_run_id IS NOT NULL;

-- 3. Atualizar coluna run_id para aceitar NULL (caso ainda não aceite)
ALTER TABLE message_logs.message_logs
ALTER COLUMN run_id DROP NOT NULL;

-- 4. Adicionar comentários explicativos
COMMENT ON COLUMN message_logs.message_logs.run_id IS
'References message_runs.id (Supabase) for bulk campaigns. NULL for trigger messages.';

COMMENT ON COLUMN message_logs.message_logs.trigger_run_id IS
'References trigger_runs.id (Supabase) for individual triggers. NULL for bulk campaigns. Either run_id or trigger_run_id will be populated, but not both.';

COMMIT;

-- NOTA: Não criamos foreign key porque trigger_runs fica no Supabase, não neste banco.

-- ==============================================================================
-- VERIFICAÇÃO
-- Rode este SELECT para confirmar que a migration funcionou:
-- ==============================================================================

SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'message_logs'
  AND table_name = 'message_logs'
  AND column_name IN ('run_id', 'trigger_run_id')
ORDER BY ordinal_position;

-- Resultado esperado:
-- column_name      | data_type | is_nullable | column_default
-- -----------------+-----------+-------------+---------------
-- run_id           | integer   | YES         | NULL
-- trigger_run_id   | bigint    | YES         | NULL

-- ==============================================================================
-- TESTE (OPCIONAL)
-- Rode este INSERT para testar que tudo está funcionando:
-- ==============================================================================

-- Teste 1: Inserir log de bulk campaign (run_id preenchido)
INSERT INTO message_logs.message_logs (
  run_id,
  trigger_run_id,
  page_id,
  user_id,
  status
) VALUES (
  999,  -- run_id
  NULL, -- trigger_run_id
  '123456789',
  '987654321',
  'sent'
);

-- Teste 2: Inserir log de trigger (trigger_run_id preenchido)
INSERT INTO message_logs.message_logs (
  run_id,
  trigger_run_id,
  page_id,
  user_id,
  status
) VALUES (
  NULL, -- run_id
  1,    -- trigger_run_id (precisa existir em trigger_runs)
  '123456789',
  '987654321',
  'sent'
);

-- Verificar os logs de teste
SELECT id, run_id, trigger_run_id, page_id, user_id, status, created_at
FROM message_logs.message_logs
WHERE (run_id = 999 OR trigger_run_id = 1)
ORDER BY id DESC
LIMIT 2;

-- Limpar os logs de teste (OPCIONAL)
-- DELETE FROM message_logs.message_logs WHERE run_id = 999;
-- DELETE FROM message_logs.message_logs WHERE trigger_run_id = 1;

-- ==============================================================================
-- FIM DA MIGRATION
-- ==============================================================================
