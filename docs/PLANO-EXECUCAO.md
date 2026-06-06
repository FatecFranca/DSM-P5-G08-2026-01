# Plano de Execução — Back-end + IA 100%

Roadmap por etapas para deixar **API Node**, **ML Python**, **Gemini** e **Azure** funcionais **sem depender do Flutter**. Use este doc como checklist de sprint.

**Relacionados:** [PLANO-IA-ML.md](./PLANO-IA-ML.md) · [BANCO-LOCAL.md](./BANCO-LOCAL.md) · [HOSPEDAGEM.md](./HOSPEDAGEM.md)

---

## 0. Diagnóstico — onde estamos hoje

### Back-end API (`api/`)

| Item | Status | Observação |
|------|--------|------------|
| Arquitetura em camadas | ✅ 100% | routes → controllers → services → repositories |
| Auth (register, login, refresh, logout) | ✅ 100% | JWT + refresh tokens |
| POST `/assessments` (fluxo principal) | ✅ 90% | Funciona com **rules-v1**, ML ainda não ligado |
| Dashboard, clusters, recommendations | ✅ 100% | Endpoints prontos |
| Lembretes + gamificação | ✅ 100% | CRUD + complete |
| Admin | ✅ 100% | X-Admin-Key ou role ADMIN |
| Prisma + migrations | ✅ 100% | Migration `init` aplicada local |
| Banco local PostgreSQL | ✅ 100% | `vitalis` no pgAdmin |
| Integração ML (`ML_SERVICE_URL`) | ⚠️ 50% | Código pronto, **env comentado**, serviço não sobe |
| Gemini | ❌ 0% | Só documentado, zero código |
| Swagger/OpenAPI | ❌ 0% | Manual PI pede documentação API |
| Testes E2E script | ❌ 0% | Testar sem mobile |
| Dockerfile API | ✅ 100% | `api/Dockerfile` existe |
| Deploy Azure | ❌ 0% | Doc pronta, não executado |

### IA Python (`ai/`)

| Item | Status | Observação |
|------|--------|------------|
| Dataset | ✅ 100% | `ai/data/dataset_preprocessado.csv` (~1000 linhas) |
| `train.py` | ⚠️ 60% | Treina LR + K-Means, **sem scaler**, **sem métricas JSON** |
| `serve.py` | ⚠️ 50% | FastAPI ok, **usa valores brutos** (bug crítico) |
| Modelos `.pkl` | ❌ 0% | Pasta `models/` vazia — **nunca treinou** |
| Notebooks AM | ❌ 0% | Pasta `notebooks/` não existe — **entrega obrigatória** |
| `preprocess.py` compartilhado | ❌ 0% | Lógica duplicada / inconsistente |
| `evaluate.py` | ❌ 0% | Métricas só no print do train |
| Dockerfile ML | ❌ 0% | Necessário para Azure |
| Deploy Azure ML | ❌ 0% | — |

### Integração API ↔ ML ↔ Gemini

```
HOJE:
Mobile (incompleto) → API → rules-v1 (fallback)
                         ✗ ML_SERVICE_URL desligado
                         ✗ Gemini inexistente

META:
Postman/curl → API → Python ML (sklearn) → perfil + cluster
                  → Gemini (texto) → explicação amigável
                  → PostgreSQL → persistência
```

---

## Visão das 7 etapas

```
Etapa 1 ──► IA Python corrigida + treinada + servindo
Etapa 2 ──► API integrada ao ML (E2E local)
Etapa 3 ──► Notebooks + relatórios (entrega AM)
Etapa 4 ──► Gemini integrado na API
Etapa 5 ──► Back-end polido (Swagger, scripts teste, logs)
Etapa 6 ──► Azure (Postgres + API + ML)
Etapa 7 ──► Validação final PI (checklist manual)
```

**Ordem obrigatória:** 1 → 2 → 3 (paralelo possível com 4) → 4 → 5 → 6 → 7

---

## Etapa 1 — IA Python 100% (local)

**Objetivo:** modelos treinados, inferência correta, serviço FastAPI respondendo.

**Duração estimada:** 2–3 dias

### 1.1 Corrigir pipeline de features

**Problema:** CSV tem valores **normalizados** (0–1), mas `serve.py` recebe dados **brutos** do questionário.

**Solução:** salvar metadados de normalização no treino.

| Arquivo | Ação |
|---------|------|
| `ai/src/preprocess.py` | **CRIAR** — funções `build_features(raw)` e `fit_scaler(df)` |
| `ai/src/train.py` | **EDITAR** — salvar `scaler.pkl`, `feature_bounds.pkl` ou treinar com raw + scaler |
| `ai/src/serve.py` | **EDITAR** — carregar scaler, transformar antes de `predict` |
| `ai/src/evaluate.py` | **CRIAR** — acurácia, matriz confusão, silhouette → `reports/metrics.json` |

**Decisão técnica (escolher uma):**

| Opção | Prós | Contras |
|-------|------|---------|
| **A) Scaler no treino** — treinar com dados brutos reconstruídos do CSV | Inferência natural (API manda idade real) | Precisa reverter normalização do CSV ou ter CSV raw |
| **B) Manter CSV normalizado** — salvar min/max por coluna no treino | Rápido, usa CSV atual | `serve.py` normaliza input com min/max salvos |

**Recomendação:** Opção **B** para PI — CSV já preprocessado; salvar `scaler.pkl` (MinMaxScaler fit no dataset de treino).

### 1.2 Arquivos a gerar após treino

```
ai/models/
├── classifier.pkl
├── kmeans.pkl
├── scaler.pkl          ← NOVO
├── feature_cols.pkl
├── target_map.pkl
└── metrics.json        ← NOVO (via evaluate.py)

ai/reports/
├── confusion_matrix.png
├── cluster_scatter.png
└── metrics.json
```

### 1.3 Comandos

```bash
cd ai
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt

python src/train.py
# Esperado: Acuracia classificador: ~70-90%

python src/evaluate.py
# Gera reports/

uvicorn src.serve:app --reload --port 8000
```

### 1.4 Teste isolado do ML

```bash
curl http://localhost:8000/health

curl -X POST http://localhost:8000/predict ^
  -H "Content-Type: application/json" ^
  -d "{\"age\":28,\"gender\":\"Male\",\"heightCm\":175,\"weightKg\":80,\"dailySteps\":6500,\"caloriesIntake\":2200,\"hoursOfSleep\":7,\"exerciseHoursPerWeek\":2,\"smoker\":\"No\",\"alcoholPerWeek\":2,\"diabetic\":\"No\",\"heartDisease\":\"No\"}"
```

Resposta esperada: `profile`, `clusterId`, `confidence` > 0.

### ✅ Definition of Done — Etapa 1

- [ ] `python src/train.py` roda sem erro
- [ ] 5+ arquivos em `ai/models/` (incluindo `scaler.pkl`)
- [ ] `POST /predict` retorna perfil coerente (testar 3 casos diferentes)
- [ ] `GET /health` retorna 200
- [ ] `reports/metrics.json` com acurácia e silhouette

---

## Etapa 2 — API integrada ao ML (E2E local)

**Objetivo:** `POST /assessments` usa modelo treinado, persiste `modelVersion: "ml-v1.0"`.

**Duração estimada:** 1 dia

### 2.1 Configurar ambiente

**.env (raiz):**
```env
ML_SERVICE_URL=http://localhost:8000
ML_SERVICE_TIMEOUT_MS=5000
```

**Subir os dois serviços:**
```bash
# Terminal 1 — ML
cd ai && uvicorn src.serve:app --port 8000

# Terminal 2 — API
pnpm api:dev
```

### 2.2 Ajustes na API (se necessário)

| Arquivo | Ação |
|---------|------|
| `api/src/services/classification.service.ts` | Trocar `modelVersion: "ml-service"` → `"ml-v1.0"`; log quando ML falha |
| `api/src/services/dashboard.service.ts` | `/health/ready` já checa ML — validar resposta |
| `.env.example` | Descomentar `ML_SERVICE_URL` |

### 2.3 Fluxo de teste completo (sem Flutter)

```bash
# 1. Health
curl http://localhost:3333/health/ready

# 2. Register
curl -X POST http://localhost:3333/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Teste PI\",\"email\":\"teste@vitalis.com\",\"password\":\"12345678\"}"

# 3. Login (guardar accessToken)
curl -X POST http://localhost:3333/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"teste@vitalis.com\",\"password\":\"12345678\"}"

# 4. Assessment (substituir TOKEN)
curl -X POST http://localhost:3333/assessments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d "{\"age\":28,\"gender\":\"Male\",\"heightCm\":175,\"weightKg\":80,\"dailySteps\":6500,\"caloriesIntake\":2200,\"hoursOfSleep\":7,\"exerciseHoursPerWeek\":2,\"smoker\":\"No\",\"alcoholPerWeek\":2,\"diabetic\":\"No\",\"heartDisease\":\"No\"}"

# 5. Dashboard
curl http://localhost:3333/dashboard -H "Authorization: Bearer TOKEN"

# 6. Evolution
curl http://localhost:3333/assessments/evolution -H "Authorization: Bearer TOKEN"
```

### 2.4 Verificar no banco (Prisma Studio)

```bash
pnpm --filter @vitalis/api exec prisma studio
```

Tabela `health_classifications`:
- `model_version` = **`ml-v1.0`** (não `rules-v1`)
- `confidence` preenchido
- `profile` coerente

### ✅ Definition of Done — Etapa 2

- [ ] `/health/ready` mostra `ml: { available: true }`
- [ ] Assessment retorna perfil via ML
- [ ] Banco grava `model_version = ml-v1.0`
- [ ] Dashboard agrega última classificação
- [ ] Fallback: parar ML → assessment ainda funciona com `rules-v1`

---

## Etapa 3 — Notebooks e entregáveis AM

**Objetivo:** arquivos que o professor de Aprendizagem de Máquina exige.

**Duração estimada:** 3–5 dias (pode overlap com etapa 2)

### 3.1 Notebooks obrigatórios

```
ai/notebooks/
├── 01_exploracao_eda.ipynb
├── 02_preprocessamento.ipynb
├── 03_treinamento_logistic_regression.ipynb
├── 04_clusterizacao_kmeans.ipynb
└── 05_avaliacao_metricas.ipynb
```

| Notebook | Conteúdo mínimo |
|----------|-----------------|
| 01 | Distribuição classes, correlação, missing values, gráficos |
| 02 | Encoding, MinMaxScaler, export CSV (documentar origem Kaggle) |
| 03 | Train/test split, Logistic Regression, matriz confusão, acurácia |
| 04 | Elbow method, K=4, Silhouette, interpretação clusters |
| 05 | Resumo métricas, limitações, disclaimer não-médico |

### 3.2 Sincronizar notebook ↔ código

O `train.py` deve reproduzir o notebook 03+04. Comentário no README:

> *"Os notebooks documentam o processo; `train.py` reproduz o treino para CI/deploy."*

### 3.3 requirements.txt — adicionar

```
matplotlib>=3.8.0
seaborn>=0.13.0
jupyter>=1.0.0
scikit-learn>=1.5.0
```

### ✅ Definition of Done — Etapa 3

- [ ] 5 notebooks commitados no GitHub
- [ ] Gráficos exportados em `ai/reports/`
- [ ] `ai/README.md` atualizado com métricas finais
- [ ] Fonte do dataset citada (Kaggle Health & Lifestyle ou similar)

---

## Etapa 4 — Integração Gemini

**Objetivo:** LLM enriquece explicação **depois** do sklearn decidir o perfil.

**Duração estimada:** 2 dias

### 4.1 Arquitetura (não confundir)

```
sklearn  →  decide profile + cluster  (OBRIGATÓRIO PI)
Gemini   →  reescreve explicação      (COMPLEMENTO UX)
rules    →  fatores +/- estruturados  (SEMPRE, independente Gemini)
```

### 4.2 Arquivos a criar

| Arquivo | Responsabilidade |
|---------|------------------|
| `api/src/services/gemini.service.ts` | Client HTTP Google Generative AI |
| `api/src/config/env.ts` | `GEMINI_API_KEY`, `GEMINI_ENABLED`, `GEMINI_MODEL` |
| `api/src/services/assessment.service.ts` | Chamar Gemini após classificação |

### 4.3 Variáveis de ambiente

```env
GEMINI_API_KEY=sua-chave-aistudio.google.com
GEMINI_MODEL=gemini-2.0-flash
GEMINI_ENABLED=true
```

Obter chave: [Google AI Studio](https://aistudio.google.com/apikey)

### 4.4 Dependência npm

```bash
pnpm --filter @vitalis/api add @google/generative-ai
```

### 4.5 Fluxo no `assessment.service.ts`

```typescript
// Pseudocódigo
const classification = await classificationService.classify(input);
// classification.explanationPayload já tem factors (rules)

if (env.GEMINI_ENABLED && env.GEMINI_API_KEY) {
  const geminiText = await geminiService.enrichExplanation({
    profile: classification.profile,
    confidence: classification.confidence,
    factors: classification.explanationPayload.factors,
    modelVersion: classification.modelVersion,
  });
  classification.explanationPayload.messages.unshift(geminiText);
}

// Persistir explanationPayload completo no JSON
```

### 4.6 Prompt Gemini (seguro)

```
Você é assistente de bem-estar do app Vitalis.
REGRAS: Não diagnostique. Não prescreva medicamentos.
O perfil JÁ foi definido pelo modelo ML: {profile} (confiança {confidence}%).
Fatores: {factors}.
Escreva 2-3 frases motivacionais em português BR.
```

### 4.7 Fallback

| Cenário | Comportamento |
|---------|---------------|
| Gemini off | Usa só `explanationPayload.messages` das rules |
| Gemini timeout/erro | Log warning, segue com rules |
| ML off + Gemini on | Rules classificam; Gemini enriquece texto |

### ✅ Definition of Done — Etapa 4

- [ ] Com `GEMINI_ENABLED=true`, assessment retorna texto natural extra
- [ ] Com `GEMINI_ENABLED=false`, fluxo idêntico ao atual
- [ ] `model_version` continua `ml-v1.0` (Gemini não altera)
- [ ] Chave API só em `.env`, nunca no Git

---

## Etapa 5 — Back-end polido (sem mobile)

**Objetivo:** API documentada, testável e pronta para Azure.

**Duração estimada:** 2 dias

### 5.1 Swagger / OpenAPI

| Ação | Detalhe |
|------|---------|
| Instalar | `swagger-ui-express` + `swagger-jsdoc` |
| Rota | `GET /docs` |
| Documentar | Auth, assessments, dashboard, health |

### 5.2 Script de teste E2E

| Arquivo | Ação |
|---------|------|
| `scripts/test-e2e.ps1` ou `scripts/test-e2e.sh` | Register → login → assessment → dashboard |
| `api/docs/postman/` | Collection exportada (opcional) |

### 5.3 Melhorias rápidas

| Item | Arquivo |
|------|---------|
| Log quando ML cai | `classification.service.ts` |
| `modelVersion` dinâmico do ML response | `classification.service.ts` |
| README API atualizado | `api/README.md` |
| CORS produção | `.env` Azure |

### 5.4 `.gitignore` — modelos

```
# ai/models/*.pkl  → commitar OU usar Git LFS
# Recomendação PI: commitar .pkl (~ poucos MB) para Azure não precisar retreinar
```

### ✅ Definition of Done — Etapa 5

- [ ] `/docs` acessível com endpoints principais
- [ ] Script E2E passa 100% local
- [ ] README com instruções completas
- [ ] Build passa: `pnpm build`

---

## Etapa 6 — Azure (tudo na nuvem)

**Objetivo:** cumprir manual PI — back-end + ML + DB na nuvem pública.

**Duração estimada:** 2–3 dias

**Referência:** [HOSPEDAGEM.md](./HOSPEDAGEM.md) + [api/docs/AZURE.md](../api/docs/AZURE.md)

### 6.1 Ordem de deploy

```
1. Resource Group rg-vitalis-pi (Brazil South)
2. PostgreSQL Flexible Server + DB vitalis
3. prisma migrate deploy + seed (DATABASE_URL Azure)
4. App Service vitalis-api (Node 20)
5. App Service vitalis-ml (Python 3.12)
6. (Opcional) Static Web Apps vitalis-web
```

### 6.2 Arquivos a criar

| Arquivo | Propósito |
|---------|-----------|
| `ai/Dockerfile` | Deploy ML na Azure |
| `.github/workflows/deploy-api.yml` | CI/CD API |
| `.github/workflows/deploy-ml.yml` | CI/CD ML |

### 6.3 `ai/Dockerfile` (esboço)

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src/ ./src/
COPY models/ ./models/
EXPOSE 8000
CMD ["uvicorn", "src.serve:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 6.4 Application Settings — API (Azure)

| Variável | Valor |
|----------|-------|
| `DATABASE_URL` | Postgres Azure + `sslmode=require` |
| `JWT_SECRET` | gerado |
| `ML_SERVICE_URL` | `https://vitalis-ml.azurewebsites.net` |
| `GEMINI_API_KEY` | secret |
| `GEMINI_ENABLED` | `true` |
| `CORS_ORIGINS` | `*` (dev) ou URL web |

### 6.5 Application Settings — ML (Azure)

| Variável | Valor |
|----------|-------|
| `PORT` | `8000` |
| Modelos | incluídos no deploy (`models/*.pkl`) |

### 6.6 Teste pós-deploy

```bash
curl https://vitalis-api.azurewebsites.net/health/ready
curl https://vitalis-ml.azurewebsites.net/health
# Assessment via Postman apontando para URL Azure
```

### ✅ Definition of Done — Etapa 6

- [ ] Postgres Azure acessível
- [ ] API Azure responde `/health/ready` com DB + ML ok
- [ ] ML Azure responde `/predict`
- [ ] Assessment na nuvem grava `ml-v1.0`
- [ ] Gemini funciona na Azure (key nos secrets)
- [ ] Screenshot portal Azure para apresentação

---

## Etapa 7 — Validação final PI

**Checklist manual (5º semestre):**

| Requisito Manual PI | Evidência |
|---------------------|-----------|
| Front mobile | Flutter — depois; por ora Postman/curl |
| Back-end REST JSON | `/assessments` retorna profile JSON |
| **Classificador ML** | Logistic Regression + notebooks |
| **Clusterizador ML** | K-Means + endpoint cluster |
| Banco na nuvem | PostgreSQL Azure |
| Back-end na nuvem | App Service API + ML |
| Só back-end acessa DB | Mobile nunca tem DATABASE_URL |
| GitHub versionado | FatecFranca org, commits de todos |
| Vídeo YouTube ≤ 5 min | Demo API + ML + notebook |
| Documentação | README + docs/ + Swagger |

---

## Cronograma sugerido (3 integrantes)

| Semana | Etapas | Entregável |
|--------|--------|------------|
| **1** | 1 + 2 | ML treinado + API integrada local |
| **2** | 3 + 4 | Notebooks + Gemini |
| **3** | 5 + 6 | Swagger + Azure |
| **4** | 7 + Flutter | Validação PI + mobile (paralelo) |

---

## Mapa de responsabilidades

| Pessoa / foco | Etapas principais |
|---------------|-------------------|
| **AM / IA** | 1, 3 — Python, notebooks, métricas |
| **Back-end** | 2, 4, 5 — API, Gemini, Swagger |
| **Infra / nuvem** | 6 — Azure, CI/CD, secrets |
| **Todos** | 7 — vídeo, commits, testes |

---

## Resumo — o que fazer AGORA (esta semana)

```
DIA 1-2  Etapa 1
         ├── Criar preprocess.py
         ├── Corrigir train.py + serve.py (scaler)
         ├── Rodar treino → models/*.pkl
         └── Testar POST /predict

DIA 3    Etapa 2
         ├── ML_SERVICE_URL no .env
         ├── Subir ML + API
         └── curl register → login → assessment
         └── Confirmar model_version = ml-v1.0 no banco

DIA 4-5  Etapa 3 (início notebooks 01-02)

DIA 6-7  Etapa 4 (Gemini) quando ML estiver estável
```

---

## Árvore de arquivos final (meta)

```
vitalis/
├── .env                          ML_SERVICE_URL + GEMINI_*
├── .github/workflows/
│   ├── deploy-api.yml
│   └── deploy-ml.yml
├── scripts/test-e2e.ps1
├── ai/
│   ├── Dockerfile
│   ├── data/dataset_preprocessado.csv
│   ├── notebooks/01..05.ipynb
│   ├── models/*.pkl
│   ├── reports/*.png + metrics.json
│   └── src/
│       ├── preprocess.py    ← criar
│       ├── train.py         ← corrigir
│       ├── serve.py         ← corrigir
│       └── evaluate.py      ← criar
├── api/
│   ├── src/services/
│   │   ├── classification.service.ts  ← ajustar modelVersion
│   │   └── gemini.service.ts          ← criar
│   └── docs/ + Swagger
└── docs/
    ├── PLANO-EXECUCAO.md    ← este arquivo
    ├── PLANO-IA-ML.md
    └── HOSPEDAGEM.md
```

---

*Vitalis — Plano de execução Back + IA. Foco: ML sklearn funcional → API integrada → Gemini → Azure. Flutter entra depois consumindo a mesma API.*
