# Backlog de Implementacao — Backend Vitalis

Documento de referencia para o que ja existe na API e o que ainda pode ser implementado, alinhado a proposta do PI.

---

## 1. Proposta do projeto (resumo)

**Vitalis** e um sistema mobile de analise de habitos e bem-estar com Machine Learning.

| Pilar | Descricao |
|-------|-----------|
| Entrada | Usuario responde questionario (sono, alimentacao, atividade, etc.) |
| Classificacao | IA classifica perfil: `Saudavel_Ativo`, `Moderado`, `Sedentario`, `Em_Risco` |
| Clusterizacao | K-Means agrupa usuarios com habitos semelhantes |
| Saida | Recomendacoes de rotina, alimentacao, lembretes (agua, refeicao, sono) |
| Gamificacao | Pontos, niveis, streaks para engajar o usuario |
| Infra | Backend Node.js na Azure + PostgreSQL + servico Python ML |

**Importante:** o sistema nao faz diagnostico medico — apenas perfil comportamental.

---

## 2. O que ja esta implementado

### Infraestrutura e arquitetura
- Monorepo com pasta `api/` isolada
- Camadas: routes → controllers → services → repositories
- Prisma + PostgreSQL (schema completo)
- Seed de clusters e templates de recomendacao
- Validacao Zod, JWT, error handler, request logger
- Dockerfile + guia Azure (`docs/AZURE.md`)

### Modulos funcionais

| Modulo | Status | Detalhe |
|--------|--------|---------|
| Auth | Pronto | register, login, me |
| Questionario | Pronto | schema em `/health/questionnaire` |
| Avaliacao | Pronto | POST `/assessments` com fluxo completo |
| Classificacao | Parcial | Regras locais OK; ML Python ainda nao integrado de fato |
| Recomendacoes | Pronto | Por perfil, toggle on/off |
| Lembretes | Pronto | CRUD + complete com pontos |
| Gamificacao | Pronto | pontos, nivel, streak, badges basicos, leaderboard |
| Dashboard | Pronto | GET `/dashboard` agrega tudo para o mobile |
| Admin | Basico | GET `/admin/stats` sem autenticacao |

---

## 3. O que ainda pode ser implementado

Organizado por prioridade para o PI.

---

### Prioridade ALTA — necessario para o app funcionar bem

#### 3.1 Integracao real com o servico ML (Python)

**Situacao atual:** a API usa fallback por regras (mesmo criterio do notebook). O servico `ai/` existe mas nao esta conectado com normalizacao correta.

**Implementar:**
- Salvar `MinMaxScaler` no treino Python e aplicar no `serve.py`
- Endpoint interno ou health check que valida se o ML esta online
- Campo `modelVersion` e `confidence` sempre preenchidos na resposta
- Timeout e retry ao chamar `ML_SERVICE_URL`
- Fallback documentado quando ML cair (ja existe, melhorar logs)

**Endpoints afetados:** `POST /assessments`

**Valor para o PI:** prova que classificacao + clusterizacao sao reais, nao so regras fixas.

---

#### 3.2 Historico e evolucao do perfil

**Situacao atual:** guarda todas as avaliacoes, mas nao compara evolucao.

**Implementar:**
- `GET /assessments/history` — lista com paginacao
- `GET /assessments/compare?from=&to=` — diff entre duas avaliacoes
- `GET /assessments/evolution` — grafico de score ao longo do tempo (array de datas + scores)
- Regra: usuario so ve proprio historico

**Tabelas:** nenhuma nova (usa `health_assessments` + `health_classifications`)

**Valor para o PI:** mostra progresso do usuario — forte na apresentacao.

---

#### 3.3 Perfil do usuario editavel

**Situacao atual:** so nome/email no cadastro. Sem atualizacao de perfil.

**Implementar:**
- `PATCH /auth/me` — atualizar nome
- `PATCH /auth/password` — trocar senha (senha atual + nova)
- Campos opcionais futuros: foto, meta diaria de agua, horario preferido de lembretes

**Tabelas:** pode estender `users` com `avatarUrl`, `timezone`, `dailyWaterGoalMl`

---

#### 3.4 Refresh token / sessao mais segura

**Situacao atual:** JWT unico com expiracao de 7 dias.

**Implementar:**
- Access token curto (15min) + refresh token (7 dias)
- `POST /auth/refresh`
- `POST /auth/logout` — invalidar refresh token
- Tabela `refresh_tokens`

**Valor:** boa pratica para mobile + Azure; pontua em seguranca na apresentacao.

---

#### 3.5 Migrations aplicadas + ambiente Azure funcional

**Situacao atual:** schema existe, migrations podem nao estar commitadas; deploy Azure manual.

**Implementar:**
- Commit da migration inicial no repo
- GitHub Action: build + deploy + `prisma migrate deploy`
- Health check que testa conexao com banco: `GET /health/ready`

---

### Prioridade MEDIA — diferencial na apresentacao

#### 3.6 Plano alimentar e rotina mais ricos

**Situacao atual:** recomendacoes sao textos genericos por perfil (templates fixos).

**Implementar:**
- Templates com `mealType` (cafe, almoco, jantar, lanche)
- `GET /recommendations/meal-plan` — sugestoes agrupadas por refeicao
- `GET /recommendations/weekly-routine` — rotina semanal (seg-dom)
- Motor de regras: perfil + cluster → combina templates + personaliza titulo

**Tabelas sugeridas:**
```
MealPlanTemplate (profile, mealType, title, description, caloriesHint)
WeeklyRoutineItem (profile, dayOfWeek, activity, durationMin)
```

**Valor:** atende "dieta sustentavel" e "rotina" da proposta sem ser prescricao medica.

---

#### 3.7 Explicabilidade da IA (por que classificou assim)

**Situacao atual:** `explanation` e array de strings basicas.

**Implementar:**
- Retornar fatores com peso: `{ factor: "sono", impact: "negativo", weight: 0.3 }`
- `GET /assessments/:id/explanation` — detalhamento da ultima classificacao
- Comparar com media do cluster: "Usuarios do seu grupo dormem em media 7h; voce: 5h"

**Valor:** professor de ML valoriza interpretabilidade.

---

#### 3.8 Cluster e comparacao social (anonima)

**Situacao atual:** retorna `clusterId` e `clusterLabel` na classificacao.

**Implementar:**
- `GET /clusters/me` — perfil do cluster do usuario + descricao
- `GET /clusters/me/stats` — medias anonimas do grupo (passos, sono, score)
- Regra: nunca expor dados individuais de outros usuarios

**Valor:** cumpre requisito de clusterizacao de forma visivel no app.

---

#### 3.9 Gamificacao avancada

**Situacao atual:** pontos, nivel, streak, 3 badges, leaderboard top 10.

**Implementar:**
- Tabela `achievements` + `user_achievements`
- Conquistas: "7 dias de streak", "3 avaliacoes", "10 lembretes concluidos"
- `GET /gamification/achievements` — todas + desbloqueadas
- Desafios semanais: "Beba agua 5 dias seguidos" (+ bonus pontos)
- Ranking por turma/grupo (filtro opcional para demo do PI)

**Tabelas sugeridas:**
```
Achievement (id, code, title, description, pointsReward)
UserAchievement (userId, achievementId, unlockedAt)
WeeklyChallenge (id, title, target, pointsReward, weekStart)
```

---

#### 3.10 Lembretes inteligentes

**Situacao atual:** lembretes fixos por perfil + CRUD manual.

**Implementar:**
- Registro de conclusao por dia: `ReminderCompletion (reminderId, userId, completedAt)`
- Streak por tipo de lembrete (agua vs exercicio)
- `GET /reminders/today` — lembretes do dia com status concluido/pendente
- Push notification token: `POST /devices/register` (FCM/APNs token para mobile)
- Job agendado (Azure Function ou cron) para disparar notificacoes

**Tabelas sugeridas:**
```
ReminderCompletion
DeviceToken (userId, token, platform)
```

---

#### 3.11 Admin com autenticacao

**Situacao atual:** `/admin/stats` aberto, sem protecao.

**Implementar:**
- Role `ADMIN` no usuario ou tabela separada
- Login admin ou middleware `adminOnly`
- `GET /admin/users` — listagem paginada
- `GET /admin/assessments` — avaliacoes recentes (dados anonimizados)
- `GET /admin/profile-distribution` — grafico de classes
- CRUD de `RecommendationTemplate` pelo admin (editar textos sem redeploy)

---

### Prioridade BAIXA — polish e qualidade tecnica

#### 3.12 Documentacao da API

- Swagger/OpenAPI em `/docs` (swagger-ui-express)
- Exemplos de request/response para mobile
- Collection Postman/Insomnia exportada

---

#### 3.13 Testes automatizados

- Unit tests: services (classificacao, gamificacao, assessment flow)
- Integration tests: auth + assessments com banco de teste
- CI no GitHub Actions rodando testes antes do deploy

---

#### 3.14 Seguranca e rate limiting

- Rate limit em `/auth/login` e `/auth/register` (anti brute-force)
- Helmet ja ativo; revisar CORS em producao
- Sanitizacao de inputs
- Audit log de acoes sensiveis

---

#### 3.15 Observabilidade (Azure)

- Application Insights integrado
- Logs estruturados (JSON)
- Metricas: tempo de resposta, taxa de erro, chamadas ao ML

---

#### 3.16 Soft delete e LGPD basico

- `DELETE /auth/me` — excluir conta (soft delete)
- Exportar dados do usuario: `GET /auth/me/export`
- Politica de retencao de avaliacoes antigas

---

## 4. Mapa proposta → backend

| Funcionalidade da proposta | Backend atual | Proximo passo |
|---------------------------|---------------|---------------|
| Cadastro / login | OK | Refresh token |
| Questionario de habitos | OK | Validacoes condicionais |
| Classificacao ML | Parcial | Integrar Python + scaler |
| Clusterizacao | Parcial | Endpoint `/clusters/me` |
| Sugestoes alimentares | Basico | Meal plan por refeicao |
| Sugestoes de rotina/treino | Basico | Rotina semanal |
| Lembretes agua/refeicao/sono | OK | Push + historico diario |
| Gamificacao | OK | Achievements + desafios |
| Score visual 0–100 | OK | Endpoint evolution |
| Explicabilidade | Basico | Fatores com peso |
| Azure deploy | Doc pronto | CI/CD + health ready |
| Admin web | Basico | Auth + CRUD templates |
| Nao e diagnostico medico | Disclaimer OK | Reforcar em todos endpoints |

---

## 5. Sugestao de ordem de implementacao (sprints)

### Sprint 1 — App consegue usar tudo (1–2 semanas)
1. Migrations commitadas + Azure deploy funcionando
2. Integracao ML Python com normalizacao
3. `GET /dashboard` testado end-to-end
4. Swagger basico

### Sprint 2 — Diferencial na apresentacao (1 semana)
5. Historico e evolucao de score
6. `/clusters/me` com stats anonimas
7. Explicabilidade detalhada
8. Meal plan + rotina semanal

### Sprint 3 — Engajamento (1 semana)
9. Achievements e desafios semanais
10. Lembretes do dia + historico de conclusao
11. Push token (preparar mobile)

### Sprint 4 — Admin e qualidade (1 semana)
12. Admin autenticado + CRUD templates
13. Testes dos services principais
14. Rate limit + health/ready

---

## 6. Endpoints futuros (visao consolidada)

```
Auth
  PATCH  /auth/me
  PATCH  /auth/password
  POST   /auth/refresh
  POST   /auth/logout
  DELETE /auth/me

Assessments
  GET    /assessments/history?page=1
  GET    /assessments/evolution
  GET    /assessments/compare?from=&to=
  GET    /assessments/:id/explanation

Clusters
  GET    /clusters/me
  GET    /clusters/me/stats

Recommendations
  GET    /recommendations/meal-plan
  GET    /recommendations/weekly-routine

Reminders
  GET    /reminders/today
  POST   /devices/register

Gamification
  GET    /gamification/achievements
  GET    /gamification/challenges

Admin (auth)
  GET    /admin/users
  GET    /admin/assessments
  CRUD   /admin/templates

Health
  GET    /health/ready
  GET    /docs
```

---

## 7. O que NAO implementar no backend (evitar escopo inflado)

- Diagnostico medico ou prescricao
- Chatbot generico com LLM como core do PI
- Calculo nutricional complexo (TACO, macros detalhados)
- Integracao com wearables (Apple Health, Google Fit) — nice-to-have, nao essencial
- Pagamento / assinatura
- Rede social completa

Manter foco: **questionario → ML → perfil → plano → lembretes → gamificacao**.

---

## 8. Conclusao

O backend ja cobre o **fluxo principal** do PI. O que falta para ficar apresentavel e defensavel:

1. **ML de verdade** conectado (nao so regras)
2. **Evolucao e explicabilidade** (mostrar que a IA "pensa")
3. **Cluster visivel** para o usuario
4. **Deploy Azure** rodando
5. **Gamificacao e lembretes** um nivel acima do basico

Com Sprint 1 + Sprint 2 o backend ja sustenta o mobile e a apresentacao do PI com folga.

---

*Documento gerado com base no estado atual do repositorio e na proposta Vitalis — FATEC Franca, DSM P5 G08.*
