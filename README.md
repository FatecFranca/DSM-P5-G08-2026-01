# Vitalis

App de **saúde, bem-estar e hábitos** que classifica o perfil comportamental do usuário com Machine Learning, gera recomendações personalizadas, lembretes e gamificação.

**PI · FATEC Franca · DSM 5º semestre · Aprendizagem de Máquina**

> O Vitalis oferece sugestões de bem-estar e **não substitui orientação médica**.

---

## Equipe

| Integrante | RM |
|------------|-----|
| *(preencher)* | |

---

## Tecnologias

| Camada | Stack |
|--------|--------|
| Mobile | Flutter (iOS + Android) |
| API | Node.js, Express, Prisma, PostgreSQL |
| IA/ML | Python, scikit-learn, FastAPI |
| Web | Next.js (landing + admin básico) |
| Infra | Docker, VM Azure (produção do PI) |

---

## Estrutura do monorepo

```
vitalis/
├── api/              # REST API (porta 3333)
├── mobile/           # App Flutter
├── ai/               # Treino + inferência ML
├── web/              # Landing Next.js
├── packages/shared/  # Tipos TypeScript compartilhados
└── scripts/          # E2E, deploy VM
```

---

## Arquitetura

```
Flutter (questionário)
        ↓
   API Node.js  ←→  PostgreSQL
        ↓
   ML Python (Logistic Regression + K-Means)
        ↓ (opcional)
   Google Gemini (explicação em texto)
        ↓
Recomendações · Lembretes · Gamificação
```

---

## Pré-requisitos

- **Node.js** 20+
- **pnpm** 10+
- **PostgreSQL** 16 (local ou Docker)
- **Python** 3.12+ (módulo `ai/`)
- **Flutter** 3.11+ (módulo `mobile/`)

---

## Como rodar (local)

### 1. Clonar e instalar

```bash
git clone https://github.com/FatecFranca/DSM-P5-G08-2026-01.git
cd DSM-P5-G08-2026-01
pnpm install
cp .env.example .env
# Edite .env com suas chaves (JWT, DATABASE_URL, etc.)
```

### 2. Banco de dados

```bash
pnpm db:up          # Postgres via Docker
pnpm db:migrate
pnpm db:seed
```

### 3. API

```bash
pnpm api:dev        # http://localhost:3333
```

Swagger: [http://localhost:3333/docs](http://localhost:3333/docs)

### 4. Serviço ML

```bash
cd ai
python -m venv .venv
# Windows: .venv\Scripts\activate
# Linux/macOS: source .venv/bin/activate
pip install -r requirements.txt
python src/train.py
uvicorn src.serve:app --reload --port 8000
```

Defina `ML_SERVICE_URL=http://localhost:8000` no `.env` da API.

### 5. Mobile

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:3333   # emulador Android
# flutter run --dart-define=API_URL=http://localhost:3333  # desktop / iOS sim
```

Detalhes do app: [mobile/README.md](mobile/README.md)

### 6. Web (opcional)

```bash
pnpm web:dev        # http://localhost:3000
```

---

## Variáveis de ambiente

Copie `.env.example` para `.env`. Principais variáveis:

| Variável | Descrição |
|----------|-----------|
| `DATABASE_URL` | Conexão PostgreSQL |
| `JWT_SECRET` | Chave JWT (mín. 32 caracteres) |
| `ML_SERVICE_URL` | URL do serviço Python (`http://localhost:8000`) |
| `GEMINI_API_KEY` | Google Gemini (opcional) |
| `GEMINI_ENABLED` | `true` / `false` |
| `CORS_ORIGINS` | Origens permitidas (`*` em dev) |

---

## Produção (VM Azure)

Stack do PI hospedada na VM do grupo:

| Serviço | Endereço |
|---------|----------|
| API pública | `http://4.229.233.225:3333` |
| Health check | `http://4.229.233.225:3333/health/ready` |
| Swagger | `http://4.229.233.225:3333/docs` |

O app Flutter já aponta para essa URL por padrão. Na tela de login use **Configurar URL da API** para alternar entre VM e ambiente local.

Deploy/atualização na VM:

```bash
bash scripts/deploy-vm.sh
```

---

## Classes de perfil (ML)

| Classe | Descrição |
|--------|-----------|
| `Saudavel_Ativo` | Bons hábitos, perfil ativo |
| `Moderado` | Hábitos intermediários |
| `Sedentario` | Baixa atividade física |
| `Em_Risco` | Combinação de fatores de atenção |

Modelo: **Logistic Regression** (classificação) + **K-Means** (clusterização) · versão `ml-v1.0`

---

## Scripts úteis

```bash
pnpm api:dev          # API em desenvolvimento
pnpm mobile:dev       # Flutter via monorepo
pnpm db:migrate       # Migrations Prisma
pnpm db:seed          # Dados iniciais
pnpm build            # Build turbo (api + web + shared)
```

Teste E2E local (PowerShell):

```powershell
.\scripts\test-e2e.ps1
```

---

## Endpoints principais

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/auth/register` | Cadastro |
| POST | `/auth/login` | Login |
| POST | `/assessments` | Enviar questionário + classificar |
| GET | `/dashboard` | Dados do início |
| GET | `/recommendations` | Recomendações ativas |
| GET | `/reminders/today` | Lembretes do dia |
| GET | `/gamification` | Pontos, nível, streak |
| GET | `/health/ready` | Status DB + ML |

---

## Licença e disclaimer

Projeto acadêmico — FATEC Franca, DSM 5º semestre.

O Vitalis **não realiza diagnóstico médico**. Classifica perfil comportamental e sugere hábitos de bem-estar. Em caso de dúvidas de saúde, consulte um profissional.
