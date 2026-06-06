# API Vitalis

Backend REST com arquitetura em camadas (controllers → services → repositories).

## Swagger (documentação completa)

| Ambiente | URL |
|----------|-----|
| **Produção (VM)** | [http://4.229.233.225:3333/docs](http://4.229.233.225:3333/docs) |
| **OpenAPI JSON** | `GET /docs.json` |
| Local | [http://localhost:3333/docs](http://localhost:3333/docs) |

No Swagger UI use **Authorize** com `Bearer <accessToken>` (obtido em `POST /auth/login`).

Servidor padrão no dropdown: VM Azure. Configure `API_PUBLIC_URL` no `.env` para outro host.

## Tags documentadas

- **Health** — status, readiness, questionário, clusters públicos
- **Auth** — register, login, refresh, logout, perfil, senha
- **Dashboard** — visão agregada do app
- **Assessments** — questionário, ML, evolução, comparação, explicação
- **Clusters** — grupo e comparativo anônimo
- **Recommendations** — plano alimentar, rotina, toggle
- **Reminders** — CRUD + concluir hoje
- **Gamification** — pontos, conquistas, ranking
- **Admin** — stats, usuários, clusters (`X-Admin-Key` ou JWT ADMIN)

## Desenvolvimento

```bash
cp .env.example .env   # ajuste DATABASE_URL

pnpm db:migrate
pnpm db:seed
pnpm api:dev           # :3333 — abra /docs
```

## ML + Gemini

```env
ML_SERVICE_URL=http://localhost:8000
GEMINI_ENABLED=false
GEMINI_API_KEY=         # opcional
```

Teste E2E: `powershell -File scripts/test-e2e.ps1`
