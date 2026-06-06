# Vitalis

Sistema de analise de perfil de saude e recomendacao de habitos com Machine Learning.

**PI · FATEC Franca · DSM 5º semestre · Aprendizagem de Maquina**

## Estrutura do monorepo

```
vitalis/
├── api/          # Backend Node.js + PostgreSQL (REST)
├── mobile/       # App React Native (principal)
├── ai/           # Python ML (classificacao + clusterizacao)
├── web/          # Landing page + admin basico (Next.js)
└── packages/
    └── shared/   # Tipos TypeScript compartilhados
```

## Fluxo

```
Mobile (questionario) → API Node → AI Python (classificacao + cluster)
                              ↓              ↓ (opcional)
                    Recomendacoes      Gemini (texto natural)
                    Lembretes + Gamificacao
```

## Documentacao IA/ML

Plano completo (treino, API, Gemini, entregaveis AM): [docs/PLANO-IA-ML.md](../docs/PLANO-IA-ML.md)

**Roadmap por etapas (back + IA 100%):** [docs/PLANO-EXECUCAO.md](../docs/PLANO-EXECUCAO.md)

**Credenciais e API keys:** [docs/CREDENCIAIS.md](../docs/CREDENCIAIS.md)

## Como rodar

```bash
pnpm install
cp .env.example .env

# Banco
pnpm db:up
pnpm db:migrate
pnpm db:seed

# Backend
pnpm api:dev          # :3333

# Web (landing)
pnpm web:dev          # :3000

# ML (quando treinado)
cd ai && uvicorn src.serve:app --reload --port 8000
```

## Classes de perfil

| Classe | Descricao |
|--------|-----------|
| Saudavel_Ativo | Bons habitos, ativo |
| Moderado | Habitos intermediarios |
| Sedentario | Baixa atividade |
| Em_Risco | Combinacao de fatores de risco |

## Disclaimer

Nao realiza diagnostico medico. Apenas classificacao de perfil comportamental.
