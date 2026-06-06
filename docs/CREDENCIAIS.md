# Credenciais e chaves — Vitalis

Documento do que **você precisa obter/configurar** para rodar o projeto completo (local + Azure).

> **Nunca commite valores reais no Git.** Use `.env` local e **Application Settings / Secrets** na Azure.

---

## 1. Resumo rápido

| Variável | Obrigatório? | Onde obter | Usado em |
|----------|--------------|------------|----------|
| `DATABASE_URL` | **Sim** | Postgres local ou Azure | API |
| `JWT_SECRET` | **Sim** | Você gera (64+ chars) | API |
| `ML_SERVICE_URL` | **Sim** (ML) | URL do serviço Python | API |
| `GEMINI_API_KEY` | Opcional | Google AI Studio | API |
| `GEMINI_ENABLED` | Opcional | `true` / `false` | API |
| `ADMIN_API_KEY` | Recomendado | Você gera | API admin |
| `AZURE_*` / publish profiles | Deploy | Portal Azure | CI/CD |

---

## 2. Local — `.env` na raiz do monorepo

Copie:
```bash
cp .env.example .env
```

Também mantenha `api/.env` com a mesma `DATABASE_URL` (Prisma CLI).

### 2.1 PostgreSQL (`DATABASE_URL`)

**Local (pgAdmin):**
```env
DATABASE_URL="postgresql://vitalis:vitalis@localhost:5432/vitalis?schema=public"
```

**Azure (produção):**
```env
DATABASE_URL="postgresql://USUARIO:SENHA@vitalis-db.postgres.database.azure.com:5432/vitalis?sslmode=require"
```

Onde obter Azure: Portal → PostgreSQL Flexible Server → Connection strings.

---

### 2.2 JWT (`JWT_SECRET`)

Gere uma string aleatória longa (mínimo 32 caracteres):

```powershell
# PowerShell — exemplo
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 64 | ForEach-Object {[char]$_})
```

```env
JWT_SECRET="sua-chave-aleatoria-com-pelo-menos-32-caracteres"
JWT_ACCESS_EXPIRES_IN="15m"
JWT_REFRESH_EXPIRES_IN="7d"
```

---

### 2.3 Machine Learning (`ML_SERVICE_URL`)

**Local:**
```env
ML_SERVICE_URL=http://localhost:8000
ML_SERVICE_TIMEOUT_MS=5000
```

Subir o serviço:
```bash
cd ai/src
py -3 -m uvicorn serve:app --reload --port 8000
```

Antes, treine os modelos (se ainda não fez):
```bash
cd ai/src
py -3 train.py
```

**Azure (produção):**
```env
ML_SERVICE_URL=https://vitalis-ml.azurewebsites.net
```

> **Não precisa de API key** — o serviço ML é interno; só a API Node chama.

---

### 2.4 Google Gemini (`GEMINI_API_KEY`) — opcional

**Onde obter:**
1. Acesse [Google AI Studio](https://aistudio.google.com/apikey)
2. Faça login com conta Google
3. **Create API Key**
4. Copie a chave

```env
GEMINI_API_KEY="AIza..."
GEMINI_MODEL="gemini-2.0-flash"
GEMINI_ENABLED=true
```

| Config | Comportamento |
|--------|---------------|
| `GEMINI_ENABLED=false` | App funciona sem Gemini (ML + rules) |
| Sem `GEMINI_API_KEY` | Gemini desligado automaticamente |
| Com chave + `true` | Texto motivacional extra na explicação do assessment |

**Custo:** tier gratuito do AI Studio costuma bastar para PI/demo.

**Importante:** Gemini **não classifica** o perfil — só enriquece o texto. A classificação é do sklearn (Logistic Regression + K-Means).

---

### 2.5 Admin (`ADMIN_API_KEY`)

```env
ADMIN_API_KEY="sua-chave-admin-local"
```

Usar header nas rotas admin:
```
X-Admin-Key: sua-chave-admin-local
```

Ou JWT de usuário com `role: ADMIN`.

---

### 2.6 Web (opcional)

```env
NEXT_PUBLIC_API_URL="http://localhost:3333"
```

---

## 3. Azure — Application Settings

Configure no **App Service `vitalis-api`**:

| Setting | Valor |
|---------|-------|
| `DATABASE_URL` | Connection string Postgres Azure |
| `JWT_SECRET` | Secret forte |
| `ML_SERVICE_URL` | URL do App Service `vitalis-ml` |
| `GEMINI_API_KEY` | Secret (opcional) |
| `GEMINI_ENABLED` | `true` |
| `GEMINI_MODEL` | `gemini-2.0-flash` |
| `NODE_ENV` | `production` |
| `PORT` | `8080` |
| `CORS_ORIGINS` | URL do web/mobile |
| `ADMIN_API_KEY` | Secret |

App Service **`vitalis-ml`**:

| Setting | Valor |
|---------|-------|
| `PORT` | `8000` |

Modelos `.pkl` vão no deploy (`ai/models/`).

Guia completo: [HOSPEDAGEM.md](./HOSPEDAGEM.md) · [api/docs/AZURE.md](../api/docs/AZURE.md)

---

## 4. GitHub Actions — Secrets

Repositório → Settings → Secrets and variables → Actions:

| Secret | Descrição |
|--------|-----------|
| `DATABASE_URL` | Postgres Azure (para `prisma migrate deploy` no CI) |
| `AZURE_API_PUBLISH_PROFILE` | Publish profile do App Service API |
| `AZURE_ML_PUBLISH_PROFILE` | Publish profile do App Service ML |
| `JWT_SECRET` | Produção |
| `GEMINI_API_KEY` | Opcional |

**Como obter Publish Profile:** App Service → Overview → Download publish profile.

Workflows: `.github/workflows/deploy-api.yml` e `deploy-ml.yml`.

---

## 5. Azure for Students (recomendado PI)

- [Azure for Students](https://azure.microsoft.com/free/students/) — créditos gratuitos
- Pode exigir e-mail institucional ou verificação acadêmica

---

## 6. Checklist antes de demo / entrega

- [ ] `.env` local preenchido (DB + JWT + ML_SERVICE_URL)
- [ ] `py -3 train.py` executado (`ai/models/*.pkl` existem)
- [ ] ML rodando na porta 8000
- [ ] API rodando na 3333 (`pnpm api:dev`)
- [ ] `GET /health/ready` → DB ok, ML ok
- [ ] `powershell -File scripts/test-e2e.ps1` passa
- [ ] `GEMINI_API_KEY` (se quiser texto Gemini)
- [ ] Azure: Postgres + 2 App Services (API + ML)
- [ ] Secrets no GitHub para CI/CD

---

## 7. O que NÃO precisa de chave

| Item | Notas |
|------|-------|
| scikit-learn / treino local | Só Python + pip |
| Prisma / Postgres local | Usuário/senha do banco |
| FastAPI ML | Sem auth entre API e ML na rede interna |
| Flutter mobile | Só URL da API |

---

## 8. Exemplo `.env` local completo

```env
DATABASE_URL="postgresql://vitalis:vitalis@localhost:5432/vitalis?schema=public"

PORT=3333
NODE_ENV=development
JWT_SECRET="vitalis-dev-secret-key-min-32-chars!!"
JWT_ACCESS_EXPIRES_IN="15m"
JWT_REFRESH_EXPIRES_IN="7d"
CORS_ORIGINS="*"
ADMIN_API_KEY="vitalis-admin-dev-key-change-in-prod"

ML_SERVICE_URL="http://localhost:8000"
ML_SERVICE_TIMEOUT_MS=5000

# GEMINI_API_KEY="AIza..."
GEMINI_MODEL="gemini-2.0-flash"
GEMINI_ENABLED=false

NEXT_PUBLIC_API_URL="http://localhost:3333"
```

---

*Vitalis — preencha `.env` local primeiro; Azure e Gemini quando for deploy.*
