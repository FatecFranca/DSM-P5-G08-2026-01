# Plano de IA / Machine Learning — Vitalis

Documento mestre para treinamento, integração com a API, uso do Gemini e entregáveis da disciplina **Aprendizagem de Máquina** (PI 5º semestre DSM).

**Referências:**
- Manual PI 5º semestre — [`MANUAL PI - DSM 2023-2-1.pdf`](../MANUAL%20PI%20-%20DSM%202023-2-1.pdf)
- Dataset: [`ai/dataset_preprocessado.csv`](../ai/dataset_preprocessado.csv)
- Hospedagem: [`docs/HOSPEDAGEM.md`](./HOSPEDAGEM.md)

---

## 1. Resumo executivo — sem confusão

O Vitalis usa **duas inteligências com papéis diferentes**. Não competem; complementam.

| Camada | Tecnologia | Papel | Obrigatório no PI? |
|--------|------------|-------|-------------------|
| **Classificação + Clusterização** | scikit-learn (Logistic Regression + K-Means) | Perfil de saúde (`Em_Risco`, `Moderado`…) e grupo (cluster) | **SIM** — exigência do manual |
| **Explicação em linguagem natural** | Gemini API (Google) | Texto amigável, dicas motivacionais, resumo do plano | **NÃO** — diferencial / UX |
| **Fallback** | Regras na API Node (`rules-v1`) | Se ML offline, app continua funcionando | Recomendado |

```
Mobile (Flutter)
      │  POST /assessments
      ▼
API Node.js  ──────────────────►  PostgreSQL
      │
      │  ① POST /predict (JSON)
      ▼
Serviço Python ML  ← sklearn treinado no dataset
      │
      │  retorna: profile, clusterId, confidence
      ▼
API Node.js  ──►  ② (opcional) Gemini
      │              enriquece texto da explicação
      ▼
Mobile recebe perfil + score + cluster + explicação
```

**Regra de ouro:** o professor de **Aprendizagem de Máquina** precisa ver **algoritmos clássicos treinados no dataset** (supervisionado + não supervisionado). O Gemini **não substitui** isso — só melhora textos para o usuário.

---

## 2. O que o Manual do PI exige (5º semestre)

Trecho oficial (Manual, p. 16–18):

> *Desenvolvimento de um sistema composto por front end mobile, Back-End RESTFul consumindo banco de dados, o **Back-End será um classificador ou clusterizador**, utilizando **algoritmos de aprendizado de máquina**. Com exceção do Front-End, toda estrutura deverá ser **hospedada em nuvem pública**.*

### Checklist obrigatório vs Vitalis

| Requisito PI | Vitalis | Status |
|--------------|---------|--------|
| Front-end mobile | Flutter (`mobile/`) | Em dev |
| Back-end REST JSON | API Node (`api/`) | Pronto |
| **Classificador OU clusterizador ML** | Logistic Regression **+** K-Means | Parcial — código existe, treino incompleto |
| Banco em nuvem | PostgreSQL Azure | Planejado |
| Back-end na nuvem | App Service Azure | Planejado |
| Só back-end acessa DB | Mobile → API → DB | OK |
| Versionamento Git | GitHub FatecFranca | Pendente commits |
| Documentação API | README + docs | Parcial |
| Metodologia ágil | Sprints no doc | A definir |

### Disciplina Aprendizagem de Máquina (Manual, p. 18)

| Competência | Como entregar no Vitalis |
|-------------|--------------------------|
| Paradigmas de AM | Supervisionado (classificação) + Não supervisionado (clustering) |
| Algoritmos e técnicas | Logistic Regression, K-Means, normalização, train/test split |
| Linguagem de programação | Python (notebooks + `train.py` + `serve.py`) |

---

## 3. Dataset — o que temos

**Arquivo:** `ai/dataset_preprocessado.csv` (~1000 linhas)

### Colunas originais (negócio)

| Coluna | Tipo | Uso |
|--------|------|-----|
| Age, Gender, Height_cm, Weight_kg | Demográfico | Features |
| BMI, Daily_Steps, Calories_Intake | Hábitos | Features |
| Hours_of_Sleep, Exercise_Hours_per_Week | Hábitos | Features |
| Heart_Rate, Blood_Pressure | Saúde | Feature (HR); BP pode ser derivada |
| Smoker, Alcohol, Diabetic, Heart_Disease | Risco | Features (encoded) |
| **Health_Profile** | **Target** | `Em_Risco`, `Sedentario`, `Moderado`, `Saudavel_Ativo` |

### Colunas já preprocessadas

| Coluna | Significado |
|--------|-------------|
| `Gender_enc`, `Smoker_enc`, `Diabetic_enc`, `Heart_Disease_enc` | Label encoding 0/1 |
| `Health_Profile_enc` | Target numérico: 0=Em_Risco, 1=Sedentario, 2=Moderado, 3=Saudavel_Ativo |
| Valores 0–1 em Age, BMI, Steps… | **MinMaxScaler já aplicado no notebook** |

### Problema crítico atual

O `serve.py` envia **valores brutos** (idade real, passos reais), mas o modelo foi treinado com **valores normalizados**. Isso faz predições erradas.

**Correção obrigatória no Sprint 1:**
1. Salvar `MinMaxScaler` no treino (`scaler.pkl`)
2. Aplicar mesma transformação no `serve.py` antes de `predict`

---

## 4. Arquitetura ML — camadas e responsabilidades

```
┌─────────────────────────────────────────────────────────────┐
│  CAMADA 1 — Ciência de Dados (offline, notebooks)           │
│  Exploração → Pré-processamento → Treino → Avaliação        │
│  Entrega: .ipynb + métricas + gráficos                      │
└──────────────────────────┬──────────────────────────────────┘
                           │ gera
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  CAMADA 2 — Pipeline de treino (ai/src/train.py)            │
│  Lê CSV → treina → salva .pkl em ai/models/                 │
└──────────────────────────┬──────────────────────────────────┘
                           │ deploy
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  CAMADA 3 — Inferência (ai/src/serve.py — FastAPI)          │
│  POST /predict → normaliza → classifica + clusteriza        │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTP
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  CAMADA 4 — Orquestração (api/src/services/                │
│              classification.service.ts)                     │
│  Chama ML → merge explicação → fallback rules               │
└──────────────────────────┬──────────────────────────────────┘
                           │ opcional
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  CAMADA 5 — Gemini (api/src/services/gemini.service.ts)     │
│  POST avaliação → texto natural para o usuário              │
└─────────────────────────────────────────────────────────────┘
```

### Design patterns aplicados

| Pattern | Onde | Por quê |
|---------|------|---------|
| **Microserviço ML** | Python separado da API | Manual exige ML no back-end; Python é padrão AM |
| **Adapter** | `classification.service.ts` → `/predict` | API Node não conhece sklearn |
| **Fallback / Circuit breaker** | Rules se ML offline | Resiliência na demo |
| **Repository** | Dados persistidos via Prisma | Só API acessa DB |
| **Strategy** | `ml-service` vs `rules-v1` vs `gemini-enriched` | `modelVersion` no banco |

---

## 5. Algoritmos escolhidos (justificativa para o PI)

### 5.1 Classificação — Regressão Logística (supervisionado)

- **Target:** `Health_Profile` (4 classes)
- **Por quê:** interpretável, baseline sólido, rápido, atende "classificador" do manual
- **Métricas a reportar:** acurácia, matriz de confusão, F1 por classe, `classification_report`

### 5.2 Clusterização — K-Means (não supervisionado)

- **Input:** mesmas features (sem usar o label)
- **K = 4** (alinhado aos 4 clusters do seed do banco)
- **Métricas:** Silhouette Score, Elbow (K=2..8), descrição de cada cluster

### 5.3 Por que NÃO usar Gemini para classificar

- Gemini é LLM generativo — **não é modelo treinado no seu dataset**
- Professor de AM avalia: notebook, métricas, `.pkl`, código Python
- Usar Gemini como classificador = **risco de reprovação na disciplina-chave de ML**

### 5.4 Onde o Gemini entra (complemento)

| Uso | Endpoint | Exemplo |
|-----|----------|---------|
| Explicação amigável | Após classificação | "Seu perfil Moderado indica…" |
| Plano motivacional | GET recommendations | Texto personalizado por perfil |
| Disclaimer | Sempre | "Não substitui orientação médica" |

Gemini recebe **resultado do sklearn** + dados do usuário — **nunca decide o perfil sozinho**.

---

## 6. Fluxo completo — do questionário ao resultado

```
1. Usuário preenche questionário no mobile
2. Mobile → POST /assessments (JWT)
3. API valida (Zod), calcula BMI
4. API → POST ML_SERVICE_URL/predict
   Body: { age, gender, dailySteps, ... bmi }
5. serve.py:
   a. Encode gender/smoker/diabetic/heartDisease
   b. scaler.transform(features)
   c. classifier.predict → profile
   d. kmeans.predict → clusterId
   e. predict_proba → confidence
6. API recebe JSON do ML
7. API aplica classifyByRules → explanationPayload (fatores +/-)
8. (Opcional) API → Gemini → enriquece messages[]
9. API persiste:
   - health_assessments
   - health_classifications (modelVersion: "ml-v1.0")
   - recommendations, reminders, gamification
10. Mobile exibe perfil + score + cluster + explicação
```

### Contrato HTTP — ML Service

**POST `/predict`**

Request (igual ao que a API já envia):
```json
{
  "age": 28,
  "gender": "Male",
  "heightCm": 175,
  "weightKg": 80,
  "dailySteps": 6500,
  "caloriesIntake": 2200,
  "hoursOfSleep": 7,
  "exerciseHoursPerWeek": 2,
  "smoker": "No",
  "alcoholPerWeek": 2,
  "diabetic": "No",
  "heartDisease": "No"
}
```

Response:
```json
{
  "profile": "Moderado",
  "profileScore": 65,
  "clusterId": 2,
  "clusterLabel": "Grupo Moderado Misto",
  "confidence": 0.82,
  "explanation": ["Classificacao gerada pelo modelo Logistic Regression."]
}
```

**Variável de ambiente na API:**
```env
ML_SERVICE_URL=http://localhost:8000
```

---

## 7. Estrutura de arquivos — entregáveis AM

Organização final da pasta `ai/` (o que deve ir pro GitHub):

```
ai/
├── README.md
├── requirements.txt
├── data/
│   ├── dataset_preprocessado.csv      ← mover para cá (padrão train.py)
│   └── dataset_original.csv           ← opcional: CSV bruto antes do preprocess
├── notebooks/                         ← ENTREGA PRINCIPAL AM
│   01_exploracao_eda.ipynb
│   02_preprocessamento_features.ipynb
│   03_treinamento_classificador.ipynb
│   04_clusterizacao_kmeans.ipynb
│   05_avaliacao_e_metricas.ipynb
├── models/                            ← gerados pelo train.py (gitignore ou LFS)
│   ├── classifier.pkl
│   ├── kmeans.pkl
│   ├── scaler.pkl                     ← A CRIAR
│   ├── feature_cols.pkl
│   └── target_map.pkl
├── reports/                           ← gráficos exportados dos notebooks
│   ├── confusion_matrix.png
│   ├── cluster_plot.png
│   └── metrics.json
└── src/
    ├── train.py                       ← pipeline reproduzível
    ├── serve.py                       ← inferência FastAPI
    ├── preprocess.py                  ← A CRIAR: mesma lógica do notebook
    └── evaluate.py                    ← A CRIAR: métricas em script
```

### O que cada notebook deve conter (para o professor)

| Notebook | Conteúdo mínimo |
|----------|-----------------|
| **01_exploracao_eda** | Head, info, describe, distribuição das classes, correlação, gráficos |
| **02_preprocessamento** | Encoding, MinMaxScaler, criação de `Health_Profile`, export CSV |
| **03_treinamento_classificador** | Train/test split, Logistic Regression, matriz confusão, acurácia |
| **04_clusterizacao_kmeans** | Elbow, K-Means k=4, Silhouette, interpretação dos clusters |
| **05_avaliacao** | Comparativo final, conclusões, limitações, disclaimer |

> **Importante:** o CSV atual (`dataset_preprocessado.csv`) provavelmente veio do notebook 02. Vocês precisam **commitar os notebooks** mesmo que o CSV já exista — o professor quer ver o processo.

---

## 8. Código Python — o que corrigir e implementar

### 8.1 `train.py` — melhorias necessárias

```python
# Adicionar:
from sklearn.preprocessing import MinMaxScaler

scaler = MinMaxScaler()
X_scaled = scaler.fit_transform(X_train)
# treinar classifier em X_scaled
joblib.dump(scaler, MODELS_DIR / "scaler.pkl")

# Salvar métricas
metrics = {
  "accuracy": acc,
  "silhouette": silhouette_score(X_scaled, kmeans.labels_),
  "model_version": "ml-v1.0",
}
json.dump(metrics, open(MODELS_DIR / "metrics.json", "w"))
```

### 8.2 `serve.py` — normalização

```python
scaler = joblib.load(MODELS_DIR / "scaler.pkl")
X_raw = build_feature_vector(body)
X = scaler.transform([X_raw])
profile_enc = classifier.predict(X)[0]
```

### 8.3 `preprocess.py` — função compartilhada

Uma função usada por `train.py` e `serve.py` para garantir **mesmas transformações** (DRY).

### 8.4 Dataset path

Mover `ai/dataset_preprocessado.csv` → `ai/data/dataset_preprocessado.csv`  
(ou ajustar `DATA_PATH` no `train.py` — hoje aponta para `data/`)

---

## 9. Integração Gemini — plano separado

### 9.1 Novo serviço na API (não no Python ML)

```
api/src/services/gemini.service.ts
```

**Por quê na API Node e não no Python?**
- Chaves de API centralizadas no App Service
- Gemini não faz parte do pipeline sklearn
- Mais fácil cache/log no mesmo lugar da persistência

### 9.2 Variáveis de ambiente

```env
GEMINI_API_KEY=sua-chave-google-ai-studio
GEMINI_MODEL=gemini-2.0-flash
GEMINI_ENABLED=true
```

### 9.3 Quando chamar

| Momento | Chama Gemini? | Fallback |
|---------|---------------|----------|
| ML offline | Não | Rules |
| ML online, Gemini off | Não | explanationPayload da API |
| ML online, Gemini on | Sim | Texto das rules |

### 9.4 Prompt exemplo (explicação)

```
Você é assistente de bem-estar do app Vitalis. NÃO faça diagnóstico médico.
Perfil classificado pelo modelo ML: {profile} (confiança {confidence}%).
Fatores: {factors_json}.
Escreva 2-3 frases motivacionais em português BR para o usuário.
```

### 9.5 Campo no banco

Manter em `health_classifications`:
- `modelVersion`: `"ml-v1.0"` ou `"rules-v1"`
- `explanation`: JSON com `messages` + `factors` (ML/rules) + opcional `geminiSummary`

---

## 10. Plano de sprints — ML + integração

### Sprint 1 — ML funcional (prioridade máxima) — ~1 semana

| # | Tarefa | Responsável sugerido |
|---|--------|---------------------|
| 1 | Mover CSV para `ai/data/` | AM |
| 2 | Notebook 01 EDA + notebook 02 preprocess (documentar) | AM |
| 3 | Corrigir `train.py` (scaler + métricas) | AM |
| 4 | Corrigir `serve.py` (scaler na inferência) | AM |
| 5 | Rodar treino: `python src/train.py` | AM |
| 6 | Subir ML: `uvicorn src.serve:app --port 8000` | AM |
| 7 | Configurar `ML_SERVICE_URL` no `.env` | Backend |
| 8 | Testar POST `/assessments` end-to-end | Todos |
| 9 | Verificar `modelVersion: ml-service` no banco | Backend |

**Critério de aceite:** avaliação no mobile retorna perfil do **modelo treinado**, não `rules-v1`.

### Sprint 2 — Notebooks de avaliação + relatório AM — ~1 semana

| # | Tarefa |
|---|--------|
| 1 | Notebooks 03, 04, 05 com gráficos |
| 2 | Exportar `reports/metrics.json` e PNGs |
| 3 | Documentar acurácia e Silhouette no README do `ai/` |
| 4 | Vídeo PI: mostrar notebook + app classificando |

### Sprint 3 — Gemini (diferencial) — ~3 dias

| # | Tarefa |
|---|--------|
| 1 | `gemini.service.ts` na API |
| 2 | Integrar em `assessment.service.ts` (opcional flag) |
| 3 | Testes com Gemini desligado (fallback) |
| 4 | Documentar no README que ML ≠ Gemini |

### Sprint 4 — Azure + demo PI — ~1 semana

| # | Tarefa |
|---|--------|
| 1 | Deploy ML Python (App Service) |
| 2 | Deploy API + Postgres Azure |
| 3 | `ML_SERVICE_URL` produção |
| 4 | Mobile apontando para API Azure |
| 5 | Vídeo YouTube ≤ 5 min (todos falam) |

---

## 11. Como rodar localmente (passo a passo)

```bash
# 1. Python ML
cd ai
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt

# 2. Dataset (se ainda na raiz ai/)
copy dataset_preprocessado.csv data\dataset_preprocessado.csv

# 3. Treinar
python src/train.py
# Saída esperada: Acuracia classificador: ~XX%

# 4. Servir
uvicorn src.serve:app --reload --port 8000

# 5. API (outro terminal, raiz do monorepo)
# .env com ML_SERVICE_URL=http://localhost:8000
pnpm api:dev

# 6. Teste ML direto
curl -X POST http://localhost:8000/predict -H "Content-Type: application/json" -d "{\"age\":28,\"gender\":\"Male\",\"heightCm\":175,\"weightKg\":80,\"dailySteps\":6500,\"caloriesIntake\":2200,\"hoursOfSleep\":7,\"exerciseHoursPerWeek\":2,\"smoker\":\"No\",\"alcoholPerWeek\":2,\"diabetic\":\"No\",\"heartDisease\":\"No\"}"
```

---

## 12. O que mostrar no vídeo / defesa do PI

Ordem sugerida (5 minutos):

1. **30s** — Problema: hábitos de saúde, ODS 3
2. **60s** — Mobile: questionário → resultado
3. **90s** — **Notebook AM:** dataset, treino, matriz de confusão, K-Means
4. **60s** — Arquitetura: API → ML Python → Postgres (Azure)
5. **30s** — Gemini enriquecendo texto (se implementado)
6. **30s** — Disclaimer: não é diagnóstico médico

---

## 13. Riscos e mitigações

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| ML prediz errado (sem scaler) | Alto | Sprint 1 — corrigir normalização |
| Professor não vê notebooks | Reprovação AM | Commitar `ai/notebooks/` |
| Só rules, sem ML na demo | Reprovação PI | `ML_SERVICE_URL` obrigatório na demo |
| Gemini como "a IA do PI" | Confusão na banca | Slides separando sklearn vs Gemini |
| ML não sobe na Azure | PI incompleto | Deploy App Service Python |
| Dataset sem origem documentada | Questão ética | Citar fonte no notebook (Kaggle Health & Lifestyle) |

---

## 14. Mapa de arquivos — quem entrega o quê

| Integrante / área | Entregáveis GitHub |
|-------------------|-------------------|
| **Aprendizagem de Máquina** | `ai/notebooks/*`, `ai/src/train.py`, `ai/reports/*`, `ai/README.md` |
| **Back-end** | Integração `classification.service.ts`, Gemini service, docs API |
| **Mobile** | Consumo `/assessments`, tela resultado com cluster |
| **Nuvem** | Azure ML + API + DB, `docs/HOSPEDAGEM.md` |
| **Todos** | Commits individuais, vídeo YouTube |

---

## 15. Próximos passos imediatos

1. **Mover** `dataset_preprocessado.csv` → `ai/data/`
2. **Criar** notebooks 01–05 (podem partir do trabalho já feito no preprocessamento)
3. **Corrigir** `train.py` + `serve.py` (scaler)
4. **Treinar** e testar `/predict`
5. **Ligar** `ML_SERVICE_URL` e validar fluxo completo
6. **Depois** integrar Gemini como camada de texto

---

## 16. Referências internas

| Arquivo | Descrição |
|---------|-----------|
| [`ai/src/train.py`](../ai/src/train.py) | Pipeline de treino atual |
| [`ai/src/serve.py`](../ai/src/serve.py) | API FastAPI inferência |
| [`api/src/services/classification.service.ts`](../api/src/services/classification.service.ts) | Orquestração ML + fallback |
| [`api/docs/BACKLOG.md`](../api/docs/BACKLOG.md) | Item 3.1 integração ML |
| [`docs/HOSPEDAGEM.md`](./HOSPEDAGEM.md) | Deploy Azure |

---

*Vitalis — Plano IA/ML alinhado ao Manual PI 5º semestre FATEC Franca. sklearn = core obrigatório; Gemini = complemento de linguagem natural.*
