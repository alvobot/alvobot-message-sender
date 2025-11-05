# Conectar ao PostgreSQL com TablePlus

Este guia mostra como conectar ao banco de dados PostgreSQL usando TablePlus.

## Pré-requisitos

1. [TablePlus](https://tableplus.com/) instalado
2. Postgres rodando (porta 5432 exposta)

## Importante: PostgreSQL NÃO está exposto externamente

Por questões de segurança e para evitar conflitos no EasyPanel, a porta do PostgreSQL **não** está exposta publicamente.

Para conectar no TablePlus, você tem **2 opções**:

### Opção 1: SSH Tunnel (Recomendado) 🔒
### Opção 2: pgAdmin Web UI (Mais fácil) 🌐

---

## Opção 1: Conectar via SSH Tunnel (Recomendado) 🔒

### Passo 1: Configure acesso SSH ao servidor

Você precisa ter acesso SSH ao servidor do EasyPanel:

```bash
# Teste a conexão SSH primeiro
ssh root@seu-servidor.com
```

Se funcionar, você pode usar SSH tunnel!

### Passo 2: Configurar conexão no TablePlus

1. Abra o TablePlus
2. Click em **Create a new connection**
3. Selecione **PostgreSQL**
4. Preencha os campos:

**Aba "General":**
```
Name:         Message Sender DB (Production)
Host:         localhost
Port:         5432
User:         postgres
Password:     [sua senha do POSTGRES_PASSWORD no .env]
Database:     message_sender
```

**Aba "SSH":** ✅ Enable SSH tunnel
```
SSH Host:     seu-servidor.com (ou IP do servidor)
SSH Port:     22
SSH User:     root (ou seu usuário SSH)
SSH Password: [sua senha SSH] (ou use SSH Key)
```

5. Click em **Test** → Deve conectar!
6. Click em **Connect**

### Como funciona:

```
TablePlus → SSH Tunnel → Servidor → Docker → PostgreSQL
(localhost:5432)         (porta 22)   (container postgres:5432)
```

O SSH cria um túnel seguro e o TablePlus se conecta ao banco através dele!

---

## Opção 2: Usar pgAdmin Web (Mais fácil) 🌐

Se você não tem acesso SSH ou prefere interface web:

1. Acesse: **https://message.s3.alvobot.com/pgadmin**
2. Login: `admin@admin.com` / `admin`
3. O banco já vem pré-configurado!

**Vantagens:**
- ✅ Não precisa SSH
- ✅ Acessa de qualquer lugar
- ✅ Não expõe porta do banco
- ✅ Já vem configurado

---

## Desenvolvimento Local

Para conectar no banco local (docker-compose rodando na sua máquina):

```
Name:         Message Sender DB (Local)
Host:         localhost
Port:         5432
User:         postgres
Password:     postgres
Database:     message_sender
```

Não precisa SSH tunnel para conexões locais!

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
