# Banco de Dados Local — Vitalis

Guia para configurar PostgreSQL local, desenvolver com Prisma e manter os mesmos padrões de arquitetura até o deploy na Azure.

**Projeto:** Vitalis · FATEC Franca · DSM 5º semestre  
**Estratégia:** banco local agora → Azure PostgreSQL depois (só troca `DATABASE_URL`)

Documentos relacionados:
- [HOSPEDAGEM.md](./HOSPEDAGEM.md) — visão cloud e Azure
- [api/docs/AZURE.md](../api/docs/AZURE.md) — deploy produção

---

## 1. Resumo

| Item | Decisão |
|------|---------|
| SGBD | **PostgreSQL** (17 local, 16 na Azure — compatível) |
| ORM | **Prisma** |
| Dev local (sua máquina) | **pgAdmin + PostgreSQL 17** (já instalado) |
| Alternativa | Docker Compose (`pnpm db:up`) |
| Produção (depois) | Azure Database for PostgreSQL Flexible Server |
| Schema | `api/prisma/schema.prisma` |
| Dados iniciais | `api/prisma/seed.ts` |

**Regra de ouro:** local e Azure usam o **mesmo schema Prisma**. Nada de SQL manual por ambiente — migrations versionadas no Git.

---

## 2. Arquitetura de dados e backend

### 2.1 Camadas da API (padrão do projeto)

```
HTTP Request
    ↓
Routes          → define rotas e middlewares (auth, rate-limit)
    ↓
Controllers     → valida input (Zod), chama service, retorna HTTP
    ↓
Services        → regras de negócio, orquestração, transações
    ↓
Repositories    → acesso ao banco (Prisma), sem lógica de negócio
    ↓
Prisma Client   → PostgreSQL
```

**Design patterns usados:**

| Pattern | Onde | Por quê |
|---------|------|---------|
| **Layered Architecture** | `routes/` → `controllers/` → `services/` → `repositories/` | Separação de responsabilidades, testável |
| **Repository Pattern** | `repositories/*.repository.ts` | Isola Prisma; services não conhecem SQL |
| **Service Layer** | `services/*.service.ts` | Regras de negócio centralizadas |
| **DTO / Validation** | `schemas/` + Zod nos controllers | Contrato da API na borda |
| **Domain Model** | `domain/` | Constantes e regras puras (sem DB) |
| **Middleware Chain** | `middleware/` | Auth, errors, logging, rate limit |
| **Singleton** | `lib/prisma.ts` | Uma instância PrismaClient |
| **Factory** | `createApp()` em `app.ts` | App Express configurável |

### 2.2 Fluxo de dependências (regra)

```
routes → controllers → services → repositories → prisma
                ↓
            domain/ (pode ser usado por services)
            schemas/ (usado por controllers)
```

**Proibido na arquitetura Vitalis:**
- Controller acessando Prisma direto
- Repository com regra de negócio
- Route com lógica além de wiring

### 2.3 Convenções do banco (Prisma)

| Convenção | Exemplo |
|-----------|---------|
| Tabelas | `snake_case` via `@@map("users")` |
| Colunas | `snake_case` via `@map("password_hash")` |
| Código TS | `camelCase` (Prisma Client) |
| PK | UUID (`@default(uuid())`) |
| FK | `@relation` + `onDelete: Cascade` onde faz sentido |
| Enums | PascalCase no Prisma, valores alinhados ao `@vitalis/shared` |
| Índices | Em FKs e queries frequentes (`userId`, `createdAt`) |
| Seed | Idempotente (`upsert`) — clusters, templates, achievements |

### 2.4 Modelo de dados (visão)

```
users
  ├── health_assessments → health_classifications
  ├── user_recommendations → recommendation_templates
  ├── reminders → reminder_completions
  ├── gamification_profiles
  ├── user_achievements → achievements
  └── refresh_tokens

cluster_definitions (dados de referencia, seed)
recommendation_templates (dados de referencia, seed)
achievements (dados de referencia, seed)
```

---

## 3. Setup local com pgAdmin (recomendado para você)

Você já tem **PostgreSQL 17** no pgAdmin. Vamos criar o database `vitalis` separado dos outros (`abtest`, `performly_db`, etc.).

### 3.1 Criar database no pgAdmin (interface)

1. Abra **pgAdmin 4**
2. Expanda **Servers → PostgreSQL 17**
3. Clique direito em **Databases → Create → Database**
4. Preencha:
   - **Database:** `vitalis`
   - **Owner:** `postgres` (ou role `vitalis` se criou)
5. Save

### 3.2 Criar role dedicada (opcional, recomendado para equipe)

No **Query Tool** conectado ao servidor (database `postgres`):

```sql
CREATE ROLE vitalis WITH LOGIN PASSWORD 'vitalis';
GRANT ALL PRIVILEGES ON DATABASE vitalis TO vitalis;
```

Depois, conectado ao database `vitalis`:

```sql
GRANT ALL ON SCHEMA public TO vitalis;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO vitalis;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO vitalis;
```

Script pronto: [`api/prisma/sql/init-local.sql`](../api/prisma/sql/init-local.sql)

### 3.3 Connection strings

**Com role `vitalis` (padrão do projeto):**
```
postgresql://vitalis:vitalis@localhost:5432/vitalis?schema=public
```

**Com superuser `postgres` (dev rápido):**
```
postgresql://postgres:SUA_SENHA@localhost:5432/vitalis?schema=public
```

> Porta padrão: `5432`. Se seu Postgres usa outra, ajuste na URL.

---

## 4. Configurar o projeto

### 4.1 Arquivos `.env`

O Prisma le a variavel na pasta `api/`:

```bash
cp .env.example .env          # raiz do monorepo (API + scripts)
# copie DATABASE_URL para api/.env tambem (Prisma CLI)
```

`.env` na raiz:

```env
# pgAdmin / PostgreSQL local
DATABASE_URL="postgresql://vitalis:vitalis@localhost:5432/vitalis?schema=public"

PORT=3333
NODE_ENV=development
JWT_SECRET="dev-local-chave-segura-com-pelo-menos-32-caracteres-aqui"
JWT_ACCESS_EXPIRES_IN="15m"
JWT_REFRESH_EXPIRES_IN="7d"
CORS_ORIGINS="*"
NEXT_PUBLIC_API_URL="http://localhost:3333"
```

`api/.env` (mesma `DATABASE_URL`):

```env
DATABASE_URL="postgresql://vitalis:vitalis@localhost:5432/vitalis?schema=public"
```

### 4.2 Instalar dependências

```bash
pnpm install
```

### 4.3 Aplicar schema no banco (primeira vez)

**Opção A — Migration versionada (recomendado para equipe + Azure):**

```bash
pnpm --filter @vitalis/api exec prisma migrate dev --name init
pnpm db:seed
```

Isso cria `api/prisma/migrations/` e deve ser **commitado no Git**.

**Opção B — Push rápido (só dev solo, sem histórico):**

```bash
pnpm --filter @vitalis/api db:push
pnpm db:seed
```

### 4.4 Verificar

```bash
pnpm api:dev
```

Testes:

```bash
curl http://localhost:3333/health
curl http://localhost:3333/health/ready
```

`health/ready` confirma conexão com o PostgreSQL.

### 4.5 Prisma Studio (visualizar dados)

```bash
pnpm --filter @vitalis/api exec prisma studio
```

Abre em `http://localhost:5555` — útil para ver users, assessments, etc.

---

## 5. Alternativa: Docker Compose

Se preferir isolar o Postgres (ou não quiser usar o pgAdmin):

```bash
pnpm db:up          # sobe postgres:16 na porta 5432
pnpm db:migrate     # ou db:push
pnpm db:seed
```

**Atenção:** se o PostgreSQL 17 do pgAdmin **já usa a porta 5432**, pare um dos dois antes de subir o Docker, ou mude a porta no `docker-compose.yml`:

```yaml
ports:
  - "5433:5432"   # Docker na 5433
```

Connection string Docker na 5433:
```
postgresql://vitalis:vitalis@localhost:5433/vitalis?schema=public
```

---

## 6. Workflow diário de desenvolvimento

| Ação | Comando |
|------|---------|
| Subir API | `pnpm api:dev` |
| Alterar schema | editar `api/prisma/schema.prisma` |
| Aplicar mudança | `pnpm --filter @vitalis/api exec prisma migrate dev --name descricao` |
| Regenerar client | `pnpm --filter @vitalis/api db:generate` |
| Repopular dados base | `pnpm db:seed` |
| Reset total (cuidado!) | `pnpm --filter @vitalis/api exec prisma migrate reset` |

### 6.1 Quando alterar o schema

1. Edite `schema.prisma`
2. `prisma migrate dev --name o_que_mudou`
3. Ajuste repositories/services se necessário
4. Commit da migration junto com o código

**Nunca** altere tabelas manualmente no pgAdmin em produção — sempre via Prisma migrate.

---

## 7. Padrões para novos módulos

Ao adicionar funcionalidade que usa banco:

```
1. schema.prisma     → model + enums + indexes
2. migrate dev         → migration versionada
3. repository          → CRUD e queries
4. service             → regras de negócio
5. controller          → HTTP + Zod
6. routes              → rota + middleware
7. seed (se dado ref)  → upsert idempotente
```

Exemplo de estrutura de arquivo:

```
api/src/
├── repositories/foo.repository.ts   # prisma.foo.findMany(...)
├── services/foo.service.ts          # if/else, transações, AppError
├── controllers/foo.controller.ts    # req/res, schema.parse
└── routes/foo.routes.ts             # Router + authMiddleware
```

---

## 8. Ambientes: local → Azure (mesma arquitetura)

| Aspecto | Local (agora) | Azure (depois) |
|---------|---------------|----------------|
| Host | `localhost:5432` | `vitalis-db.postgres.database.azure.com:5432` |
| SSL | não obrigatório | `?sslmode=require` |
| Schema | Prisma migrations | **mesmas migrations** (`migrate deploy`) |
| Seed | `pnpm db:seed` | uma vez após deploy |
| Código API | idêntico | idêntico |
| Secrets | `.env` local | App Service Application Settings |

**Transição:** só muda `DATABASE_URL` e roda `pnpm db:deploy` na Azure. Zero refactor de repositories/services.

---

## 9. Checklist — primeira configuração

- [ ] Database `vitalis` criado no pgAdmin
- [ ] Role `vitalis` criada (ou usar `postgres`)
- [ ] `.env` na raiz com `DATABASE_URL` correto
- [ ] `pnpm install`
- [ ] `prisma migrate dev --name init` (ou `db:push`)
- [ ] `pnpm db:seed`
- [ ] `pnpm api:dev` → `/health/ready` OK
- [ ] Testar `POST /auth/register` e `POST /auth/login`
- [ ] Migration commitada no Git (se usou migrate dev)

---

## 10. Troubleshooting

| Problema | Solução |
|----------|---------|
| `ECONNREFUSED localhost:5432` | Postgres não está rodando — inicie o serviço Windows ou pgAdmin server |
| `password authentication failed` | Senha errada na `DATABASE_URL` |
| `database "vitalis" does not exist` | Crie o database no pgAdmin (seção 3.1) |
| Porta 5432 em uso | Docker + pgAdmin conflitando — use só um ou mude porta |
| `JWT_SECRET` too short | Mínimo 32 caracteres no `.env` |
| Prisma Client out of sync | `pnpm --filter @vitalis/api db:generate` |
| Seed duplica templates | Normal — seed usa upsert/findFirst, pode rodar várias vezes |

### Testar conexão via psql

```bash
psql -U vitalis -d vitalis -h localhost -p 5432
\dt
```

Deve listar tabelas: `users`, `health_assessments`, etc.

---

## 11. Segurança local

- `.env` **nunca** vai pro Git (já no `.gitignore`)
- Senha `vitalis/vitalis` é só para dev local
- Azure usará senha forte + SSL
- Dados de teste não devem ser dados reais de saúde de terceiros

---

## 12. Próximos passos

1. **Agora:** criar `vitalis` no pgAdmin e rodar migrate + seed
2. **Equipe:** todos usam mesma `DATABASE_URL` pattern + migrations no Git
3. **Depois:** seguir [HOSPEDAGEM.md](./HOSPEDAGEM.md) para Azure — eu ajudo nas configs quando chegar lá

---

*Vitalis — Banco local + padrões de arquitetura. PostgreSQL via Prisma; mesma base sobe na Azure sem mudar código.*
