# Vitalis

Sistema de análise de perfil de saúde e recomendação de hábitos com Machine Learning.

**PI · FATEC Franca · DSM 5º semestre · Aprendizagem de Máquina**

## Estrutura do monorepo

```
vitalis/
├── api/          # Backend Node.js + PostgreSQL (REST)
├── mobile/       # App Flutter (iOS + Android)
├── ai/           # Python ML (classificação + clusterização)
├── web/          # Landing page + admin básico (Next.js)
└── packages/
    └── shared/   # Tipos TypeScript compartilhados
```

## Fluxo

```
Mobile (questionário) → API Node → AI Python (classificação + cluster)
                              ↓              ↓ (opcional)
                    Recomendações      Gemini (texto natural)
                    Lembretes + Gamificação
```

## Documentação

| Doc | Conteúdo |
|-----|----------|
| [docs/PLANO-IA-ML.md](docs/PLANO-IA-ML.md) | ML, Gemini, notebooks |
| [docs/PLANO-EXECUCAO.md](docs/PLANO-EXECUCAO.md) | Roadmap back + IA |
| [docs/CREDENCIAIS.md](docs/CREDENCIAIS.md) | Variáveis e chaves |
| [docs/HOSPEDAGEM-VM.md](docs/HOSPEDAGEM-VM.md) | Deploy na VM Azure |
| [docs/AUDITORIA-COMPLETA.md](docs/AUDITORIA-COMPLETA.md) | Auditoria e plano de correções |
| [mobile/README.md](mobile/README.md) | App Flutter |

## Como rodar (local)

```bash
pnpm install
cp .env.example .env

# Banco
pnpm db:up
pnpm db:migrate
pnpm db:seed

# Backend
pnpm api:dev          # :3333

# ML
cd ai && python -m venv .venv && .venv/Scripts/activate  # Windows
pip install -r requirements.txt
python src/train.py
uvicorn src.serve:app --reload --port 8000

# Mobile (VM ou local)
cd mobile
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:3333   # emulador Android
# flutter run --dart-define=API_URL=http://4.229.233.225:3333  # VM produção
```

## Produção (VM Azure)

- **API:** `http://4.229.233.225:3333`
- **Health:** `http://4.229.233.225:3333/health/ready`
- **Deploy:** `bash scripts/deploy-vm.sh` (na VM)

## Classes de perfil

| Classe | Descrição |
|--------|-----------|
| Saudavel_Ativo | Bons hábitos, ativo |
| Moderado | Hábitos intermediários |
| Sedentario | Baixa atividade |
| Em_Risco | Combinação de fatores de risco |

## Disclaimer

Não realiza diagnóstico médico. Apenas classificação de perfil comportamental.
