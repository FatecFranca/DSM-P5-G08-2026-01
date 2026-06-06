# Infraestrutura e Hospedagem — Vitalis

Documento de decisão arquitetural para banco de dados, hospedagem na Azure e deploy de todos os componentes do PI.

**Projeto:** Vitalis · FATEC Franca · DSM 5º semestre  
**Data:** maio/2026  
**Status:** proposta aprovada para implementação

---

## 1. Resumo executivo

| Decisão | Escolha |
|---------|---------|
| Banco de dados | **PostgreSQL 16** (mantém Prisma atual) |
| Onde hospedar o banco (produção) | **Azure Database for PostgreSQL — Flexible Server** |
| Supabase? | **Não em produção** — opcional só para dev/staging da equipe |
| API Node.js | **Azure App Service** (Linux, Node 20) |
| Serviço ML (Python) | **Azure App Service** ou **Container Apps** |
| Web (Next.js) | **Azure Static Web Apps** ou **App Service** |
| Mobile (Flutter) | **Não hospeda backend** — APK/IPA apontando para a API na Azure |
| Desenvolvimento local | **pgAdmin / PostgreSQL 17** ou Docker Compose — ver [BANCO-LOCAL.md](./BANCO-LOCAL.md) |

**Por quê tudo na Azure?** A proposta do PI já prevê *"Backend Node.js na Azure + PostgreSQL"*. Manter banco, API e ML na mesma nuvem simplifica rede, billing, apresentação e credenciais acadêmicas (Azure for Students).

---

## 2. O banco: PostgreSQL

### 2.1 Confirmação técnica

O projeto **já está 100% preparado para PostgreSQL**:

- Prisma com `provider = "postgresql"`
- Schema completo: users, assessments, classifications, recommendations, reminders, gamification, clusters
- Docker Compose local (`postgres:16-alpine`)
- Migrations + seed prontos
- Connection string via `DATABASE_URL`

**Não há motivo para trocar de SGBD.** MySQL, SQLite ou MongoDB exigiriam refatoração desnecessária.

### 2.2 O que o banco armazena

| Dado | Sensibilidade |
|------|---------------|
| Credenciais (hash bcrypt) | Alta |
| Avaliações de saúde/hábitos | Média |
| Classificações ML | Baixa |
| Templates de recomendação | Baixa |
| Gamificação, lembretes | Baixa |

Não armazenamos prontuário médico — apenas perfil comportamental. Mesmo assim, usar **SSL obrigatório** e **senhas fortes** em produção.

---

## 3. Supabase vs Azure PostgreSQL vs outras opções

### 3.1 Comparativo

| Critério | **Azure PostgreSQL** | **Supabase** | **Neon / Railway** | **Postgres no Docker na VM** |
|----------|---------------------|--------------|----------------------|------------------------------|
| Compatível com Prisma | Sim | Sim | Sim | Sim |
| Região Brasil | Brazil South | São Paulo (sa-east-1) | EUA (sem BR) | Depende da VM |
| Alinhado à proposta PI (Azure) | **Sim** | Não | Não | Parcial |
| Mesma conta/rede que a API | **Sim** (VNet, firewall) | Não (outro provedor) | Não | Sim (manual) |
| Custo PI (~) | R$ 50–80/mês (B1ms) | Grátis (500 MB) ou ~R$ 130/mês (Pro) | Grátis limitado | VM ~R$ 30+ |
| Setup | Médio | Fácil | Fácil | Difícil |
| Backups automáticos | Sim (configurável) | Sim | Sim | Manual |
| Extras (Auth, Storage, Realtime) | Não usa | Inclusos (não precisamos) | Não | Não |
| Dashboard SQL | Portal Azure | Muito bom | Bom | pgAdmin manual |
| Connection pooling | PgBouncer externo ou driver | Supavisor incluso | Incluso | Manual |

### 3.2 Por que NÃO usar Supabase como banco principal

1. **Auth duplicado** — o Vitalis já tem JWT próprio (`register`, `login`, `refresh`). Supabase Auth seria retrabalho.
2. **Dois provedores** — API na Azure + banco no Supabase = duas contas, firewall cruzado, latência entre clouds, mais difícil de explicar na defesa.
3. **Proposta acadêmica** — backlog e documentação já apontam Azure; professor espera ver recurso Azure no portal.
4. **Features extras não usadas** — Realtime, Storage, Edge Functions não fazem parte do escopo.

### 3.3 Quando Supabase faz sentido (opcional)

Use Supabase **apenas** se a equipe quiser um Postgres na nuvem **grátis para desenvolvimento compartilhado** enquanto a Azure ainda não está provisionada:

```
Dev local     → Docker (localhost:5432)     ← padrão atual
Dev compartilhado (opcional) → Supabase free tier
Produção / demo PI            → Azure PostgreSQL
```

Trocar entre eles é só alterar `DATABASE_URL` — Prisma funciona igual.

### 3.4 Decisão final do banco

| Ambiente | Onde |
|----------|------|
| **Local (cada dev)** | Docker Compose (`pnpm db:up`) |
| **Produção / apresentação PI** | **Azure Database for PostgreSQL Flexible Server** |
| **Staging (opcional)** | Mesmo servidor Azure com database `vitalis_staging` ou Supabase free |

---

## 4. Arquitetura completa na Azure

```
                         ┌─────────────────────────────────────────┐
                         │           Azure (Brazil South)         │
                         │         Resource Group: rg-vitalis-pi    │
                         └─────────────────────────────────────────┘

   ┌──────────────┐     HTTPS      ┌──────────────────────┐
   │ App Flutter  │ ──────────────►│  App Service         │
   │ (celular)    │                │  vitalis-api         │
   └──────────────┘                │  Node 20 · porta 443 │
                                   └──────────┬───────────┘
   ┌──────────────┐     HTTPS                 │
   │ Browser      │ ──────────────►           │ SQL (SSL)
   │ Landing/Admin│                ┌──────────▼───────────┐
   └──────────────┘                │  PostgreSQL Flexible │
        │                          │  Server              │
        ▼                          │  DB: vitalis         │
   ┌──────────────┐                └──────────────────────┘
   │ Static Web   │
   │ Apps / Web   │                ┌──────────────────────┐
   │ (Next.js)    │ ──HTTP interno►│  App Service         │
   └──────────────┘                │  vitalis-ml          │
                                   │  Python 3.12/FastAPI │
                                   └──────────────────────┘
                                            ▲
                                   ML_SERVICE_URL (API chama)
```

### 4.1 Componentes e onde hospedar

| Componente | Tecnologia | Hospedagem recomendada | URL exemplo |
|------------|------------|------------------------|-------------|
| **Banco** | PostgreSQL 16 | Azure Database for PostgreSQL Flexible Server (Burstable B1ms) | `vitalis-db.postgres.database.azure.com:5432` |
| **API REST** | Node.js + Express + Prisma | Azure App Service Linux B1 ou F1 | `https://vitalis-api.azurewebsites.net` |
| **ML** | Python FastAPI | Azure App Service Linux (Python 3.12) | `https://vitalis-ml.azurewebsites.net` |
| **Web** | Next.js 15 | Azure Static Web Apps **ou** App Service | `https://vitalis-web.azurewebsites.net` |
| **Mobile** | Flutter | Google Play / TestFlight / APK direto | consome `NEXT_PUBLIC_API_URL` / config no app |

> **Mobile não roda na Azure.** Só precisa da URL pública da API em produção (`https://vitalis-api.azurewebsites.net`).

### 4.2 Ordem de provisionamento (faça nesta sequência)

1. Criar **Resource Group** `rg-vitalis-pi` (Brazil South)
2. Criar **PostgreSQL Flexible Server** + database `vitalis`
3. Rodar **migrations + seed** apontando para a Azure (da máquina local ou CI)
4. Criar **App Service** `vitalis-api` + variáveis de ambiente
5. Deploy da API (GitHub Actions ou Docker)
6. Testar `/health` e `/health/ready`
7. Criar **App Service** `vitalis-ml` + deploy do `ai/`
8. Configurar `ML_SERVICE_URL` na API
9. Deploy da **Web** (landing + admin)
10. Atualizar **CORS** e URL no app mobile

---

## 5. Configuração do PostgreSQL na Azure

### 5.1 Parâmetros recomendados (PI)

| Config | Valor |
|--------|-------|
| Servidor | `vitalis-db` (nome único global) |
| Versão | PostgreSQL **16** |
| SKU | **Burstable B1ms** (1 vCore, 2 GB RAM) |
| Região | **Brazil South** |
| Storage | 32 GB (padrão, suficiente) |
| Backup | Retenção 7 dias (padrão) |
| High availability | Desligado (economia para PI) |

### 5.2 Connection string

```
postgresql://USUARIO:SENHA@vitalis-db.postgres.database.azure.com:5432/vitalis?sslmode=require
```

- Usuário Azure Postgres: formato `usuario@servidor` (ex: `vitalisadmin@vitalis-db`)
- **Sempre** `sslmode=require` em produção
- Colocar em **Application Settings** do App Service, nunca no código

### 5.3 Firewall / rede

| Fase | Configuração |
|------|--------------|
| Setup inicial | Permitir IP público + adicionar IP de cada dev |
| API na Azure | Habilitar **"Allow Azure services"** para App Service conectar |
| Produção ideal | VNet integration (opcional para PI — B1ms + IP allowlist basta) |

### 5.4 Migrations na Azure

Da máquina local (uma vez):

```bash
# .env temporário com DATABASE_URL da Azure
pnpm db:deploy    # prisma migrate deploy
pnpm db:seed      # seed de clusters e templates
```

Ou automaticamente no startup (já configurado no `api/Dockerfile`):

```bash
npx prisma migrate deploy && node dist/server.js
```

---

## 6. Variáveis de ambiente por serviço

### 6.1 API (`vitalis-api`)

| Variável | Exemplo produção |
|----------|------------------|
| `DATABASE_URL` | `postgresql://...@vitalis-db...?sslmode=require` |
| `JWT_SECRET` | string aleatória 64+ caracteres |
| `JWT_ACCESS_EXPIRES_IN` | `15m` |
| `JWT_REFRESH_EXPIRES_IN` | `7d` |
| `NODE_ENV` | `production` |
| `PORT` | `8080` |
| `CORS_ORIGINS` | `https://vitalis-web.azurewebsites.net` |
| `ML_SERVICE_URL` | `https://vitalis-ml.azurewebsites.net` |
| `ADMIN_API_KEY` | chave secreta para admin |

### 6.2 ML (`vitalis-ml`)

| Variável | Exemplo |
|----------|---------|
| `PORT` | `8000` |
| Modelos | arquivos `.pkl` em `ai/models/` no deploy |

Startup command:

```bash
uvicorn src.serve:app --host 0.0.0.0 --port 8000
```

### 6.3 Web (`vitalis-web`)

| Variável | Exemplo |
|----------|---------|
| `NEXT_PUBLIC_API_URL` | `https://vitalis-api.azurewebsites.net` |

### 6.4 Mobile (Flutter)

| Config | Valor produção |
|--------|----------------|
| `API_URL` (dart-define ou tela login) | `https://vitalis-api.azurewebsites.net` |

---

## 7. Deploy e CI/CD

### 7.1 Estratégia recomendada

| Serviço | Método |
|---------|--------|
| API | GitHub Actions → App Service (ou Deployment Center) |
| ML | GitHub Actions separado ou mesmo workflow |
| Web | Azure Static Web Apps (integração GitHub) ou `next build` + App Service |
| Banco | Migrations via CI ou startup da API |

### 7.2 Workflow mínimo (API)

```yaml
# .github/workflows/deploy-api.yml (sugestão)
on:
  push:
    branches: [main]
    paths: ['api/**', 'packages/shared/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - run: pnpm install --frozen-lockfile
      - run: pnpm --filter @vitalis/api build
      - run: pnpm --filter @vitalis/api exec prisma migrate deploy
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
      - uses: azure/webapps-deploy@v3
        with:
          app-name: vitalis-api
          publish-profile: ${{ secrets.AZURE_API_PUBLISH_PROFILE }}
          package: api
```

Guia passo a passo detalhado: [`api/docs/AZURE.md`](../api/docs/AZURE.md).

---

## 8. Custos estimados (PI)

### 8.1 Cenário mínimo (apresentação)

| Recurso | SKU | ~Custo/mês |
|---------|-----|------------|
| PostgreSQL Flexible Server | B1ms | R$ 50–80 |
| App Service API | F1 (free) ou B1 | R$ 0–70 |
| App Service ML | F1 ou B1 | R$ 0–70 |
| Static Web Apps | Free | R$ 0 |
| **Total** | | **R$ 50–220** |

### 8.2 Azure for Students

Estudantes FATEC podem ter **créditos gratuitos Azure** (verificar em [azure.microsoft.com/free/students](https://azure.microsoft.com/free/students)). Com créditos, o PI pode rodar **meses sem pagar**.

### 8.3 Cenário econômico alternativo (não recomendado para defesa)

| Recurso | Onde | Custo |
|---------|------|-------|
| Banco | Supabase free | R$ 0 |
| API | Render/Railway free | R$ 0 |
| ML | Render free | R$ 0 |

Funciona tecnicamente, mas **não atende a proposta Azure** e free tiers dormem/desligam — ruim para demo ao vivo.

---

## 9. Ambientes

| Ambiente | Banco | API | Uso |
|----------|-------|-----|-----|
| **local** | Docker `localhost:5432` | `:3333` | Desenvolvimento diário |
| **staging** (opcional) | DB `vitalis_staging` na Azure | `vitalis-api-staging` | Testes antes da apresentação |
| **production** | DB `vitalis` | `vitalis-api` | Demo PI + mobile em produção |

Regra: **nunca** apontar mobile de produção para banco local.

---

## 10. Segurança (checklist)

- [ ] `DATABASE_URL` só em secrets (App Service / GitHub Secrets)
- [ ] `sslmode=require` no Postgres Azure
- [ ] `JWT_SECRET` único e longo (64+ chars)
- [ ] CORS restrito às URLs reais (não `*` em produção)
- [ ] Firewall Postgres: só Azure services + IPs da equipe
- [ ] `ADMIN_API_KEY` ou role ADMIN para rotas admin
- [ ] HTTPS em todos os endpoints públicos (App Service já fornece)
- [ ] Backups automáticos do Postgres habilitados
- [ ] `.env` no `.gitignore` (já está)

---

## 11. Plano de ação — próximos passos

### Fase 1 — Banco (1–2 horas)

- [ ] Criar conta Azure / ativar Azure for Students
- [ ] Criar Resource Group `rg-vitalis-pi`
- [ ] Provisionar PostgreSQL Flexible Server
- [ ] Criar database `vitalis`
- [ ] Configurar firewall (Azure services + IP da equipe)
- [ ] Testar conexão local: `pnpm db:deploy` + `pnpm db:seed`

### Fase 2 — API (2–4 horas)

- [ ] Criar App Service `vitalis-api`
- [ ] Configurar Application Settings
- [ ] Deploy (Docker ou GitHub Actions)
- [ ] Validar: `GET /health`, `GET /health/ready`
- [ ] Testar register + login + assessment

### Fase 3 — ML (1–2 horas)

- [ ] Treinar modelos (`python ai/src/train.py`)
- [ ] Deploy App Service Python
- [ ] Configurar `ML_SERVICE_URL` na API
- [ ] Testar POST `/assessments` com classificação ML real

### Fase 4 — Web + Mobile (1–2 horas)

- [ ] Deploy Next.js (Static Web Apps)
- [ ] Atualizar `NEXT_PUBLIC_API_URL`
- [ ] Configurar URL da API no app Flutter
- [ ] Teste end-to-end: mobile → API Azure → ML → Postgres Azure

### Fase 5 — Apresentação

- [ ] Documentar URLs no README
- [ ] Screenshot do portal Azure (recursos criados)
- [ ] Demo com dados reais no banco cloud

---

## 12. FAQ

**Posso usar Supabase só pro banco e Azure pro resto?**  
Sim, tecnicamente. Só muda `DATABASE_URL`. Não recomendamos para o PI porque fragmenta a infra e foge da proposta.

**Preciso pagar cartão na Azure?**  
Azure for Students pode não exigir cartão. Conta normal pede cartão para verificação (não cobra se ficar no free tier/créditos).

**E se o Postgres Azure ficar caro?**  
Desligue após a apresentação ou use B1ms + pare o servidor quando não estiver demonstrando. Supabase free pode ser fallback temporário.

**O mobile precisa de hospedagem?**  
Não. Gera APK/IPA. Só precisa da URL HTTPS da API.

**Docker Compose some?**  
Não. Continua sendo o ambiente local padrão (`pnpm db:up`).

---

## 13. Referências internas

| Documento | Conteúdo |
|-----------|----------|
| [`api/docs/AZURE.md`](../api/docs/AZURE.md) | Passo a passo deploy API + Postgres |
| [`api/docs/BACKLOG.md`](../api/docs/BACKLOG.md) | Escopo backend e prioridades |
| [`docs/BANCO-LOCAL.md`](./BANCO-LOCAL.md) | Setup PostgreSQL local + padrões Prisma |
| [`docker-compose.yml`](../docker-compose.yml) | Postgres local (alternativa Docker) |
| [`.env.example`](../.env.example) | Variáveis de ambiente |

---

*Documento Vitalis — Infraestrutura e hospedagem. Decisão: PostgreSQL na Azure + App Services para API, ML e Web.*
