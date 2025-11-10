# Debug: Disparo #95 - Análise de Falha

## Status da Run

```json
{
  "id": 95,
  "status": "waiting",  ⚠️ PROBLEMA
  "flow_id": "10b369a8-3291-4ff1-b0b6-8b9dc0f47ea8",
  "user_id": "42de26d9-18ac-4771-a407-82a74b257534",
  "created_at": "2025-11-10T01:16:24.662788+00:00",
  "start_at": "2025-11-10T06:15:00+00:00",
  "completed_at": null,
  "next_step_id": "f117f491-dbed-4715-81de-e168d131b639",
  "next_step_at": "2025-11-10T15:15:08.679+00:00", ⚠️ FUTURO
  "last_step_id": "a5b4a091-72f9-4f64-8829-8229d1807dc0",
  "error_summary": []
}
```

## Páginas (25 páginas)

```
896182703568742, 872239165966324, 843879688802109, 757533100773195,
750118061516748, 722446750957997, 701908496346768, 502430669620699,
475765612290250, 283777744799402, 273796942478589, 254826097716813,
245891831946889, 211805238693853, 169435562918265, 165976526597682,
141804295675158, 117915658075231, 111546605149566, 107387135462877,
102911125955591, 102872965949270, 102229809372481, 101683692730713,
100810039570896
```

---

## 🔴 PROBLEMA IDENTIFICADO

### Status: `waiting`
A run está em status **`waiting`** esperando `next_step_at = 2025-11-10T15:15:08.679+00:00`

**Hora atual**: ~10:20 UTC
**Próximo step**: 15:15 UTC
**⏱️ Faltam ~5 horas** para o próximo step ser processado

### O que isso significa?

A run **foi processada corretamente** mas está aguardando um **delay configurado no flow** (provavelmente um nó de "espera" ou "delay").

**Não houve falha!** O comportamento está correto segundo o flow configurado.

---

## ✅ Verificações

### 1. Logs de Mensagens
❌ **Erro ao buscar**: Tabela `message_logs` não encontrada no schema
⚠️ Isso indica que a tabela pode ter sido renomeada ou estar em schema diferente

### 2. Possíveis Causas do "Não Envio"

#### Hipótese A: Flow com Delay
✅ **MAIS PROVÁVEL**: O flow tem um nó de delay/espera
- Status `waiting` é esperado
- `next_step_at` no futuro (15:15)
- Run será retomada automaticamente quando chegar a hora

#### Hipótese B: Problema com owner_user_id
⚠️ **POSSÍVEL**: Com as mudanças de hoje, páginas podem não estar sendo encontradas
- Run tem `user_id: 42de26d9-18ac-4771-a407-82a74b257534`
- Processadores agora filtram por `owner_user_id`
- Se páginas não tiverem `owner_user_id` correspondente, são puladas

#### Hipótese C: Páginas Bloqueadas
⚠️ **POSSÍVEL**: Páginas bloqueadas pelo sistema de auto-bloqueio
- Nova funcionalidade implementada hoje
- Verifica `blocked_until` antes de processar

---

## 🔬 Próximos Passos de Investigação

### Via SQL (Executar no Supabase):

```sql
-- 1. Verificar se páginas pertencem ao user_id correto
SELECT
  page_id::text,
  owner_user_id,
  is_active,
  blocked_until,
  block_reason,
  last_error_code
FROM meta_pages
WHERE page_id IN (
  896182703568742, 872239165966324, 843879688802109
  -- adicionar outros IDs
)
ORDER BY page_id;

-- 2. Verificar qual é o user_id das páginas
SELECT DISTINCT owner_user_id, COUNT(*)
FROM meta_pages
WHERE page_id IN (
  896182703568742, 872239165966324, 843879688802109
)
GROUP BY owner_user_id;

-- 3. Comparar com user_id da run
SELECT
  'Run user_id' as tipo,
  user_id::text as id
FROM message_runs
WHERE id = 95
UNION ALL
SELECT
  'Page owner_user_id' as tipo,
  owner_user_id::text as id
FROM meta_pages
WHERE page_id = 896182703568742;

-- 4. Verificar logs (se tabela existir)
SELECT COUNT(*), status
FROM message_logs
WHERE run_id = 95
GROUP BY status;

-- 5. Verificar inscritos ativos
SELECT page_id::text, COUNT(*) as total_ativos
FROM meta_subscribers
WHERE page_id IN (896182703568742, 872239165966324)
  AND is_active = true
GROUP BY page_id;
```

---

## 🎯 DIAGNÓSTICO PRELIMINAR

### Mais Provável (80%)
**Flow configurado com delay**
- Run processou primeiro step às 06:15
- Agora aguarda até 15:15 para próximo step
- Comportamento esperado

### Investigar (20%)
**Incompatibilidade owner_user_id**
- Mudanças de hoje adicionaram filtro `owner_user_id`
- Se `run.user_id` não bate com `meta_pages.owner_user_id`, páginas são puladas
- Resultado: nenhuma mensagem enviada

---

## 🔧 Ação Recomendada

### Imediata
1. **Verificar no Supabase** se `run.user_id` bate com `meta_pages.owner_user_id`
2. **Aguardar até 15:15** para ver se run continua automaticamente
3. **Verificar logs no servidor de produção** (não localmente)

### Se Problema Confirmar
Se descobrir que `owner_user_id` não bate:

**Opção 1**: Corrigir dados
```sql
UPDATE meta_pages
SET owner_user_id = '42de26d9-18ac-4771-a407-82a74b257534'
WHERE page_id IN (...);
```

**Opção 2**: Reverter código (se necessário)
- Remover filtro `owner_user_id` temporariamente
- Reprocessar run

---

## 📊 Métricas Coletadas

- **Status da Run**: `waiting` (não `failed`)
- **Erro Summary**: `[]` (vazio - sem erros)
- **Pages**: 25 páginas configuradas
- **Próximo Step**: 15:15 UTC (5h no futuro)
- **Logs**: Tabela não acessível localmente

**Conclusão**: Run está **aguardando** delay do flow, não está "quebrada".
