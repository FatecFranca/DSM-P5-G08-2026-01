# Vitalis

App de **saúde, bem-estar e hábitos** que classifica o perfil comportamental do usuário com Machine Learning, gera recomendações personalizadas, lembretes e gamificação.

**PI · FATEC Franca · DSM 5º semestre · Aprendizagem de Máquina · Grupo G08**

> O Vitalis oferece sugestões de bem-estar e **não substitui orientação médica**.

---

## Links rápidos (produção)

| Recurso | URL |
|---------|-----|
| **Swagger UI** | http://4.229.233.225:3333/docs |

Documentação interativa da API — faça login em `POST /auth/login`, copie o `accessToken` e clique em **Authorize** → `Bearer <token>`.

---

## Equipe

| Integrante |
|------------|
| Vitor Siqueira Simeao |
| Uriel Monte Paz de Araujo |
| Gabriel Aleixo |
| Dimerson Ferreira |

---

## Tecnologias

| Camada | Stack |
|--------|--------|
| Mobile | Flutter (iOS + Android) |
| API | Node.js, Express, Prisma, PostgreSQL, Swagger |
| IA/ML | Python, scikit-learn, FastAPI |
| Web | Next.js (landing + admin básico) |
| Infra | Docker, VM Azure (produção do PI) |

---

## Estrutura do monorepo

```
vitalis/
├── api/              # REST API + Swagger (/docs)
├── mobile/           # App Flutter
├── ai/               # Treino + inferência ML
├── web/              # Landing Next.js
├── packages/shared/  # Tipos TypeScript compartilhados
└── scripts/          # E2E, deploy VM
```

Documentação da API: [api/README.md](api/README.md) · Mobile: [mobile/README.md](mobile/README.md)

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

**Produção (VM Azure `4.229.233.225`):**

```
Internet → :3333 → API Node (systemd)
                    ├── :5432 → Postgres (Docker)
                    └── :8000 → ML FastAPI (Docker)
```

---

## Pré-requisitos

- **Node.js** 20+ · **pnpm** 10+
- **PostgreSQL** 16 (local ou Docker)
- **Python** 3.12+ (`ai/`)
- **Flutter** 3.11+ (`mobile/`)

---

## Como rodar (local)

### 1. Clonar e instalar

```bash
git clone https://github.com/FatecFranca/DSM-P5-G08-2026-01.git
cd DSM-P5-G08-2026-01
npm install -g pnpm
cp .env.example .env
```

### 2. Banco de dados

```bash
pnpm db:up
pnpm db:migrate
pnpm db:seed
```

### 3. API

```bash
pnpm api:dev        # http://localhost:3333
```

Swagger local: http://localhost:3333/docs

### 4. Serviço ML

```bash
cd ai
python -m venv .venv
# Windows: .venv\Scripts\activate
pip install -r requirements.txt
python src/train.py
uvicorn src.serve:app --reload --port 8000
```

No `.env`: `ML_SERVICE_URL=http://localhost:8000`

### 5. Mobile

```bash
cd mobile
flutter pub get
flutter run                              # padrão: VM 4.229.233.225:3333
flutter run --dart-define=API_URL=http://10.0.2.2:3333   # emulador + API local
```

Na tela de login: **Configurar URL da API** para alternar entre VM e local.

### 6. Web (opcional)

```bash
pnpm web:dev        # http://localhost:3000
```

---

## Variáveis de ambiente

Copie `.env.example` → `.env`.

| Variável | Descrição |
|----------|-----------|
| `DATABASE_URL` | PostgreSQL |
| `JWT_SECRET` | Chave JWT (mín. 32 caracteres) |
| `ML_SERVICE_URL` | Serviço Python (`http://localhost:8000`) |
| `GEMINI_API_KEY` | Google Gemini (opcional) |
| `GEMINI_ENABLED` | `true` / `false` |
| `CORS_ORIGINS` | Origens CORS (`*` em dev) |
| `API_PUBLIC_URL` | URL no Swagger (padrão: VM do PI) |
| `ADMIN_API_KEY` | Header `X-Admin-Key` para rotas admin |

---

## API — documentação Swagger

Todas as rotas estão documentadas em **9 tags**:

`Health` · `Auth` · `Dashboard` · `Assessments` · `Clusters` · `Recommendations` · `Reminders` · `Gamification` · `Admin`

Deploy na VM:

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

Modelo: **Logistic Regression** + **K-Means** · versão `ml-v1.0`

---

## Scripts úteis

```bash
pnpm api:dev          # API :3333
pnpm mobile:dev       # Flutter
pnpm db:migrate       # Prisma migrate
pnpm db:seed          # Seed
pnpm build            # Build monorepo
```

Teste E2E (PowerShell):

```powershell
.\scripts\test-e2e.ps1
# VM: .\scripts\test-e2e.ps1 com base URL alterada, ou use vm-test-api.sh na VM
```

---

## Licença e disclaimer

Projeto acadêmico — FATEC Franca, DSM 5º semestre.

O Vitalis **não realiza diagnóstico médico**. Classifica perfil comportamental e sugere hábitos de bem-estar. Em caso de dúvidas de saúde, consulte um profissional.
