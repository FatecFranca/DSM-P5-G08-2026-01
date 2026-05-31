# API Vitalis

Backend REST com arquitetura em camadas.

## Endpoints

| Metodo | Rota | Auth | Descricao |
|--------|------|------|-----------|
| GET | `/health` | - | Status |
| GET | `/health/ready` | - | DB + ML health |
| GET | `/health/questionnaire` | - | Schema do formulario |
| POST | `/auth/register` | - | Cadastro (+ refresh token) |
| POST | `/auth/login` | - | Login |
| POST | `/auth/refresh` | - | Renovar access token |
| POST | `/auth/logout` | - | Revogar refresh token |
| PATCH | `/auth/me` | JWT | Atualizar nome |
| PATCH | `/auth/password` | JWT | Trocar senha |
| GET | `/dashboard` | JWT | Home agregada do app |
| POST | `/assessments` | JWT | Questionario + classificacao |
| GET | `/assessments/evolution` | JWT | Historico de scores |
| GET | `/assessments/compare?from=&to=` | JWT | Comparar avaliacoes |
| GET | `/assessments/:id/explanation` | JWT | Explicabilidade da IA |
| GET | `/clusters/me` | JWT | Cluster do usuario |
| GET | `/clusters/me/stats` | JWT | Medias anonimas do grupo |
| GET | `/recommendations/meal-plan` | JWT | Plano alimentar |
| GET | `/recommendations/weekly-routine` | JWT | Rotina semanal |
| GET | `/reminders/today` | JWT | Lembretes do dia |
| GET | `/gamification/achievements` | JWT | Conquistas |
| GET | `/admin/stats` | Admin | Stats do sistema |
| GET | `/admin/users` | Admin | Listar usuarios |

Admin: header `X-Admin-Key` ou JWT com role `ADMIN`.

## Desenvolvimento

```bash
pnpm db:up
pnpm --filter @vitalis/api exec prisma db push
pnpm db:seed
pnpm api:dev
```

## Azure

Veja [docs/AZURE.md](./docs/AZURE.md)
