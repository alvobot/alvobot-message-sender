# Conectar ao PostgreSQL com TablePlus

Este guia mostra como conectar ao banco de dados PostgreSQL usando TablePlus.

## Pré-requisitos

1. [TablePlus](https://tableplus.com/) instalado
2. Postgres rodando (porta 5432 exposta)

## Configuração no EasyPanel

Para expor a porta do PostgreSQL no EasyPanel:

1. Acesse o projeto no EasyPanel
2. Vá em **Services → postgres**
3. Em **Ports**, adicione:
   - **Container Port:** 5432
   - **Published Port:** 5432 (ou outra porta disponível)
   - **Protocol:** TCP
4. Salve e aguarde o restart

## Conectar no TablePlus

### 1. Abrir nova conexão

- Abra o TablePlus
- Click em **Create a new connection**
- Selecione **PostgreSQL**

### 2. Configurar conexão

Preencha os campos:

**Para servidor remoto (EasyPanel):**
```
Name:         Message Sender DB (Production)
Host:         seu-servidor.com (ou IP do servidor)
Port:         5432
User:         postgres
Password:     [sua senha do POSTGRES_PASSWORD no .env]
Database:     message_sender
```

**Para local (desenvolvimento):**
```
Name:         Message Sender DB (Local)
Host:         localhost
Port:         5432
User:         postgres
Password:     postgres (ou a senha do seu .env local)
Database:     message_sender
```

### 3. Testar conexão

- Click em **Test** para verificar se conecta
- Se der certo, click em **Connect**

### 4. Navegar no banco

Após conectar:

1. No painel esquerdo, expanda: **Schemas → message_logs**
2. Click em **Tables → message_logs**
3. Você verá todos os logs de mensagens!

## Queries úteis

Você pode executar queries SQL diretamente no TablePlus:

```sql
-- Ver últimos 100 logs
SELECT * FROM message_logs.message_logs
ORDER BY created_at DESC
LIMIT 100;

-- Contar por status
SELECT status, COUNT(*) as total
FROM message_logs.message_logs
GROUP BY status;

-- Ver logs de um run específico
SELECT * FROM message_logs.message_logs
WHERE run_id = 77
ORDER BY created_at DESC;

-- Ver apenas erros
SELECT * FROM message_logs.message_logs
WHERE status = 'failed'
ORDER BY created_at DESC;

-- Ver IDs preservando precisão
SELECT
  id,
  run_id,
  page_id,  -- VARCHAR(50) - preserva todos os dígitos
  user_id,  -- VARCHAR(50) - preserva todos os dígitos
  status,
  created_at
FROM message_logs.message_logs
ORDER BY created_at DESC
LIMIT 20;
```

## Troubleshooting

### "Could not connect to server"

**Causa:** Porta não está exposta ou firewall bloqueando.

**Solução:**
1. Verifique se a porta 5432 está exposta no docker-compose
2. No servidor, verifique o firewall: `sudo ufw allow 5432/tcp`
3. No EasyPanel, verifique se a porta está publicada

### "password authentication failed"

**Causa:** Senha incorreta.

**Solução:**
- Verifique o valor de `POSTGRES_PASSWORD` no arquivo `.env`
- Use exatamente a mesma senha no TablePlus

### "database does not exist"

**Causa:** Nome do database incorreto.

**Solução:**
- Use `message_sender` como nome do database
- Verifique o valor de `POSTGRES_DB` no `.env`

## Segurança em Produção

⚠️ **IMPORTANTE:** Expor a porta 5432 publicamente é um risco de segurança!

### Recomendações:

1. **Use SSH Tunnel (recomendado):**
   - Não exponha a porta 5432 publicamente
   - Crie um túnel SSH: `ssh -L 5432:localhost:5432 user@servidor`
   - Conecte no TablePlus usando `localhost:5432`

2. **Restrinja por IP:**
   - Configure firewall para aceitar apenas seu IP
   - `sudo ufw allow from SEU_IP to any port 5432`

3. **Use senha forte:**
   - Gere senha complexa para `POSTGRES_PASSWORD`
   - Nunca use senhas padrão em produção

4. **SSL/TLS:**
   - Configure SSL no PostgreSQL para conexões criptografadas

## Alternativa: pgAdmin

Se preferir interface web em vez de desktop:
- Acesse: https://message.s3.alvobot.com/pgadmin
- Login: admin@admin.com / admin
- Não precisa expor porta 5432!
