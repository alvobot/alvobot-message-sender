# Migração do Supabase - Corrigir Tipos de ID

## Problema

Os IDs do Facebook (`page_id` e `user_id`) são números muito grandes (>53 bits) que perdem precisão quando armazenados como `int8`/`BIGINT` e retornados pelo Supabase JS client como JavaScript `number`.

**Exemplo de ID arredondado:**
- Original: `1876373432431116`
- Depois de arredondar: `1876373432431120` (perdeu precisão)

## Solução

Alterar as colunas de `int8`/`BIGINT` para `text` nas seguintes tabelas:

### 1. Tabela `public.meta_pages`

```sql
-- Alterar tipo da coluna page_id
ALTER TABLE public.meta_pages
ALTER COLUMN page_id TYPE text
USING page_id::text;
```

### 2. Tabela `public.meta_subscribers`

```sql
-- Alterar tipo das colunas page_id e user_id
ALTER TABLE public.meta_subscribers
ALTER COLUMN page_id TYPE text
USING page_id::text;

ALTER TABLE public.meta_subscribers
ALTER COLUMN user_id TYPE text
USING user_id::text;
```

### 3. Tabela `public.message_runs`

```sql
-- Alterar tipo da coluna page_ids (array)
ALTER TABLE public.message_runs
ALTER COLUMN page_ids TYPE text[]
USING page_ids::text[];
```

## Como Executar

### Opção 1: Via SQL Editor do Supabase

1. Abra o Supabase Dashboard
2. Vá em **SQL Editor**
3. Cole e execute cada comando SQL acima **um por vez**
4. Verifique se não há erros

### Opção 2: Via Migrations (Recomendado para produção)

1. Crie uma nova migration no Supabase
2. Cole todos os comandos SQL
3. Execute a migration
4. Teste em staging antes de aplicar em produção

## ⚠️ Avisos Importantes

1. **Backup**: Faça backup das tabelas antes de alterar
2. **Downtime**: Esta operação pode causar downtime curto
3. **Foreign Keys**: Se houver foreign keys, podem precisar ser recriadas
4. **Outras aplicações**: Verifique se outras apps usam essas tabelas

## Verificação Pós-Migração

Após executar, verifique os tipos:

```sql
-- Verificar tipos das colunas
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('meta_pages', 'meta_subscribers', 'message_runs')
  AND column_name IN ('page_id', 'user_id', 'page_ids');
```

Deve retornar `text` ou `ARRAY` (para page_ids).

## Teste

Após a migração, insira um ID grande para testar:

```sql
-- Teste com ID real do Facebook
INSERT INTO public.meta_pages (page_id, page_name, access_token, is_active, user_id, connection_id)
VALUES ('1876373432431116', 'Test Page', 'test_token', true, 'test_user', 'test_conn');

-- Verificar se manteve a precisão
SELECT page_id FROM public.meta_pages WHERE page_id = '1876373432431116';
```
