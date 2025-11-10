-- Migração: Adicionar owner_user_id às tabelas
-- Data: 2025-11-10
-- Descrição: Adiciona suporte multi-usuário e campos de bloqueio

-- =====================================================
-- PARTE 1: Adicionar owner_user_id em meta_pages
-- =====================================================

-- Verificar se coluna já existe
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'meta_pages' AND column_name = 'owner_user_id'
  ) THEN
    -- Adicionar coluna (nullable primeiro)
    ALTER TABLE meta_pages ADD COLUMN owner_user_id uuid REFERENCES auth.users(id);
    RAISE NOTICE 'Coluna owner_user_id adicionada em meta_pages';
  ELSE
    RAISE NOTICE 'Coluna owner_user_id já existe em meta_pages';
  END IF;
END $$;

-- Preencher owner_user_id baseado em user_id existente (se a coluna user_id existir)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'meta_pages' AND column_name = 'user_id'
  ) THEN
    UPDATE meta_pages SET owner_user_id = user_id WHERE owner_user_id IS NULL;
    RAISE NOTICE 'owner_user_id preenchido com valores de user_id';
  ELSE
    RAISE NOTICE 'Coluna user_id não existe, pulando preenchimento automático';
  END IF;
END $$;

-- Tornar obrigatório apenas se todos os registros tiverem valor
DO $$
DECLARE
  null_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO null_count FROM meta_pages WHERE owner_user_id IS NULL;

  IF null_count = 0 THEN
    ALTER TABLE meta_pages ALTER COLUMN owner_user_id SET NOT NULL;
    RAISE NOTICE 'owner_user_id marcado como NOT NULL';
  ELSE
    RAISE WARNING 'Existem % registros com owner_user_id NULL - campo continua NULLABLE', null_count;
  END IF;
END $$;

-- =====================================================
-- PARTE 2: Adicionar owner_user_id em trigger_runs
-- =====================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'trigger_runs' AND column_name = 'owner_user_id'
  ) THEN
    ALTER TABLE trigger_runs ADD COLUMN owner_user_id uuid REFERENCES auth.users(id);
    RAISE NOTICE 'Coluna owner_user_id adicionada em trigger_runs';
  ELSE
    RAISE NOTICE 'Coluna owner_user_id já existe em trigger_runs';
  END IF;
END $$;

-- Preencher owner_user_id de trigger_runs baseado em message_triggers
UPDATE trigger_runs tr
SET owner_user_id = (
  SELECT mt.owner_user_id
  FROM message_triggers mt
  WHERE mt.id = tr.trigger_id
)
WHERE owner_user_id IS NULL;

-- Tornar obrigatório
DO $$
DECLARE
  null_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO null_count FROM trigger_runs WHERE owner_user_id IS NULL;

  IF null_count = 0 THEN
    ALTER TABLE trigger_runs ALTER COLUMN owner_user_id SET NOT NULL;
    RAISE NOTICE 'trigger_runs.owner_user_id marcado como NOT NULL';
  ELSE
    RAISE WARNING 'Existem % trigger_runs com owner_user_id NULL - campo continua NULLABLE', null_count;
  END IF;
END $$;

-- =====================================================
-- PARTE 3: Adicionar campos de bloqueio em meta_pages
-- =====================================================

DO $$
BEGIN
  -- blocked_until
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'meta_pages' AND column_name = 'blocked_until'
  ) THEN
    ALTER TABLE meta_pages ADD COLUMN blocked_until timestamptz;
    RAISE NOTICE 'Coluna blocked_until adicionada';
  END IF;

  -- block_reason
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'meta_pages' AND column_name = 'block_reason'
  ) THEN
    ALTER TABLE meta_pages ADD COLUMN block_reason text;
    RAISE NOTICE 'Coluna block_reason adicionada';
  END IF;

  -- last_error_code
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'meta_pages' AND column_name = 'last_error_code'
  ) THEN
    ALTER TABLE meta_pages ADD COLUMN last_error_code text;
    RAISE NOTICE 'Coluna last_error_code adicionada';
  END IF;

  -- last_error_at
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'meta_pages' AND column_name = 'last_error_at'
  ) THEN
    ALTER TABLE meta_pages ADD COLUMN last_error_at timestamptz;
    RAISE NOTICE 'Coluna last_error_at adicionada';
  END IF;
END $$;

-- =====================================================
-- PARTE 4: Criar índices
-- =====================================================

-- Índice para verificação de bloqueio
CREATE INDEX IF NOT EXISTS idx_meta_pages_blocked
ON meta_pages(blocked_until)
WHERE blocked_until IS NOT NULL;

-- Índice para busca por owner_user_id + page_id
CREATE INDEX IF NOT EXISTS idx_meta_pages_owner_page
ON meta_pages(owner_user_id, page_id);

-- =====================================================
-- PARTE 5: Verificação final
-- =====================================================

DO $$
DECLARE
  pages_count INTEGER;
  trigger_runs_count INTEGER;
BEGIN
  -- Contar páginas
  SELECT COUNT(*) INTO pages_count FROM meta_pages;
  RAISE NOTICE '==================================';
  RAISE NOTICE 'Migração concluída!';
  RAISE NOTICE '==================================';
  RAISE NOTICE 'Total de páginas: %', pages_count;

  -- Verificar páginas sem owner_user_id
  SELECT COUNT(*) INTO pages_count FROM meta_pages WHERE owner_user_id IS NULL;
  IF pages_count > 0 THEN
    RAISE WARNING '⚠️  % páginas SEM owner_user_id - AÇÃO NECESSÁRIA!', pages_count;
  ELSE
    RAISE NOTICE '✅ Todas as páginas têm owner_user_id';
  END IF;

  -- Verificar trigger_runs
  SELECT COUNT(*) INTO trigger_runs_count FROM trigger_runs WHERE owner_user_id IS NULL;
  IF trigger_runs_count > 0 THEN
    RAISE WARNING '⚠️  % trigger_runs SEM owner_user_id - AÇÃO NECESSÁRIA!', trigger_runs_count;
  ELSE
    RAISE NOTICE '✅ Todas as trigger_runs têm owner_user_id';
  END IF;
END $$;
