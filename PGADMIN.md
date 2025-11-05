# pgAdmin - PostgreSQL Database Viewer

O pgAdmin é uma interface web para visualizar e gerenciar o banco de dados PostgreSQL.

## Acesso em Produção

**URL:** https://message.s3.alvobot.com/pgadmin

**Credenciais:**
- Email: `admin@admin.com`
- Senha: `admin` (ou a senha configurada no `.env` via `PGADMIN_PASSWORD`)

O pgAdmin roda automaticamente junto com os outros serviços e está sempre disponível.

## Acesso Local (Desenvolvimento)

Abra no navegador: **http://localhost:3000/pgadmin**

**Credenciais:**
- Email: `admin@admin.com`
- Senha: `admin`

## Como usar

Após fazer login:

1. No menu lateral esquerdo, expanda: **Servers → Message Sender DB**
2. Ele vai pedir a senha do postgres (a mesma do seu `.env` - `POSTGRES_PASSWORD`)
3. Navegue até: **Databases → message_sender → Schemas → message_logs → Tables → message_logs**
4. Click com botão direito na tabela → **View/Edit Data → All Rows**

## Queries úteis

Para executar queries SQL:

1. Click com botão direito em **message_sender** → **Query Tool**
2. Digite sua query:

```sql
-- Ver últimos 100 logs
SELECT * FROM message_logs.message_logs
ORDER BY created_at DESC
LIMIT 100;

-- Contar logs por status
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
```

## Configuração

Você pode customizar as variáveis de ambiente no `.env`:

```env
# pgAdmin configuration
PGADMIN_EMAIL=seu-email@example.com
PGADMIN_PASSWORD=sua-senha-segura
PGADMIN_PORT=5050
```

## Gerenciamento

O pgAdmin roda automaticamente com o docker-compose. Para parar/reiniciar:

```bash
# Parar apenas o pgAdmin
docker compose stop pgadmin

# Reiniciar apenas o pgAdmin
docker compose restart pgadmin

# Ver logs do pgAdmin
docker compose logs -f pgadmin
```

## Troubleshooting

**Problema: "Could not connect to server"**
- Verifique se o postgres está rodando: `docker ps | grep postgres`
- Verifique a senha do postgres no `.env` (variável `POSTGRES_PASSWORD`)

**Problema: "Server definition not found"**
- O servidor já vem pré-configurado. Se não aparecer, recarregue a página (F5)
- Caso persista, veja os logs: `docker logs alvobot-message-sender-pgadmin-1`
