# Auditoria Completa — Vitalis (VM + API + Flutter)

**Data:** 06/06/2026  
**Escopo:** Infraestrutura VM Azure, API Node, serviço ML, app Flutter mobile, aderência ao Design System (34 telas).

---

## 1. Resumo executivo

| Camada | Status | Nota |
|--------|--------|------|
| **VM (4.229.233.225)** | Operacional | Postgres + ML no Docker; API via systemd na porta 3333 |
| **API REST** | Funcional | Health, auth, assessments, ML integrado |
| **ML** | Funcional | `ml-v1.0`, acurácia ~78,5% |
| **App Flutter** | MVP parcial | ~9 telas reais vs 34 do protótipo; erros de conexão esperados sem configuração |

**Causa raiz dos erros no mobile:** o app usa `http://localhost:3333` por padrão, não há UI para alterar a URL (apesar do README dizer que há), builds **release Android** podem não ter permissão `INTERNET`, HTTP cleartext não está liberado para a VM, JWT expira em 15 min sem refresh automático, e o SDK Flutter local (3.11.4) está abaixo do exigido (^3.11.5).

**Porta 3333:** confirmada acessível externamente (`/health/ready` retorna `ready`).

---

## 2. Infraestrutura VM

### 2.1 Estado atual (verificado)

```
vitalis-postgres   Up (healthy)   5432
vitalis-ml         Up             8000
vitalis-api        active         3333 (systemd)
```

| Teste | Resultado |
|-------|-----------|
| `GET /health` | `{"status":"ok","service":"vitalis-api","version":"0.2.0"}` |
| `GET /health/ready` | DB connected, ML available |
| `POST /auth/register` + `/assessments` | OK na VM (perfil Moderado, ml-v1.0) |
| Acesso externo `:3333` | OK (após regra NSG Vitalis-API) |

### 2.2 Arquitetura em produção (VM)

```
Internet → :3333 → Node API (host)
                    ├── localhost:5432 → Postgres (Docker)
                    └── localhost:8000 → ML FastAPI (Docker)
```

**Observação:** API **não** roda em Docker (build Prisma + pnpm 10 falha). Workaround estável: API nativa + systemd.

### 2.3 Problemas VM / DevOps

| ID | Severidade | Problema | Impacto |
|----|------------|----------|---------|
| VM-01 | Alta | Senha SSH exposta no chat | Risco de acesso não autorizado |
| VM-02 | Média | Postgres/ML expostos em 5432/8000 no host | Superfície de ataque desnecessária |
| VM-03 | Média | Credenciais padrão `vitalis/vitalis` | Inseguro se 5432 vazar |
| VM-04 | Baixa | Duas migrations `init` duplicadas no repo | `migrate deploy` falha em DB limpo |
| VM-05 | Baixa | `api/dist/api/src/server.js` (path anômalo) | Confusão no deploy |
| VM-06 | Baixa | Fix ML Dockerfile (`cd src && uvicorn`) só na VM | Perde-se no próximo `git pull` sem commit |

### 2.4 Ações VM recomendadas

1. Rotacionar senha SSH e JWT_SECRET / ADMIN_API_KEY.
2. Remover `docker-compose.override.yml` de portas públicas 5432/8000 (API usa localhost interno).
3. Commitar fixes: `ai/Dockerfile`, remover migration duplicada, corrigir `api/Dockerfile` (futuro).
4. Configurar backup do volume Postgres.

---

## 3. API Backend

### 3.1 Endpoints principais

| Grupo | Rotas | Auth |
|-------|-------|------|
| Health | `/health`, `/health/ready`, `/health/questionnaire` | Público |
| Auth | `/auth/register`, `/login`, `/refresh`, `/me`, … | JWT |
| Assessments | `POST /`, `GET /latest`, `/evolution`, `/compare` | JWT |
| Dashboard | `GET /dashboard` | JWT |
| Recommendations | `/`, `/meal-plan`, `/weekly-routine` | JWT |
| Reminders | `/today`, `POST /:id/complete`, CRUD | JWT |
| Gamification | `/`, `/achievements`, `/leaderboard` | JWT |
| Clusters | `/clusters/me`, `/clusters/me/stats` | JWT |
| Docs | `GET /docs` | Público |

**CORS:** `CORS_ORIGINS=*` na VM — OK para mobile.

**Não existe:** `GET /health/live` (retorna 404 HTML).

### 3.2 Contrato vs Flutter

| Campo API | Mobile | Status |
|-----------|--------|--------|
| `accessToken` / `token` | `SessionStore` aceita ambos | OK |
| Enums `Male`, `Yes`, `Em_Risco` | Mapeamento local em `helpers.dart` | OK |
| `template.title` aninhado | `RecommendationCard` com fallback | OK |
| `completedToday` em reminders | Usado em `/reminders/today` | OK |
| Gamification antes da 1ª avaliação | Dashboard retorna `null`; `/gamification` → 404 | Mobile usa `.catchError` |
| JWT 15 min | `refreshToken` salvo, **nunca usado** | Sessão expira silenciosamente |

### 3.3 Problemas API

| ID | Severidade | Problema |
|----|------------|----------|
| API-01 | Alta | Migrations duplicadas (`20260603235847_init` + `20260604003803_init`) |
| API-02 | Média | Swagger diz senha min 8; Zod aceita min 6 |
| API-03 | Média | Gamification só criado na 1ª avaliação → 404 em `/gamification` |
| API-04 | Baixa | Build Docker API quebrado (Prisma + pnpm 10) |
| API-05 | Baixa | Gemini desabilitado na VM (`GEMINI_ENABLED=false`) |

---

## 4. App Flutter — diagnóstico técnico

### 4.1 Stack

- **Framework:** Flutter (não React Native — prompt/descrição desatualizados)
- **Estado:** `SessionStore` (ChangeNotifier) + estado local por tela
- **Navegação:** `NavigationBar` com índice (sem go_router)
- **HTTP:** pacote `http`, respostas `Map<String, dynamic>` (sem models tipados)
- **SDK exigido:** `^3.11.5` — ambiente local tem **3.11.4** → `flutter pub get` falha

### 4.2 Por que “tudo retorna erro” no celular

| # | Causa | Evidência | Correção |
|---|-------|-----------|----------|
| **M-01** | URL padrão `localhost:3333` | `theme.dart` `defaultApiUrl` | `--dart-define=API_URL=http://4.229.233.225:3333` |
| **M-02** | Sem UI para editar URL | `saveApiUrl()` existe, nunca chamado; README incorreto | Campo na tela de login |
| **M-03** | Android release sem `INTERNET` | Permissão só em `debug/` e `profile/` manifest | Adicionar em `main/AndroidManifest.xml` |
| **M-04** | HTTP cleartext bloqueado (Android 9+) | VM usa `http://`, sem `usesCleartextTraffic` | `android:usesCleartextTraffic="true"` ou HTTPS |
| **M-05** | iOS ATS bloqueia HTTP | `Info.plist` sem exceção NSAppTransportSecurity | Adicionar exceção para IP/domínio |
| **M-06** | Token expira em 15 min | Sem interceptor 401 → `/auth/refresh` | Implementar refresh automático |
| **M-07** | SDK Flutter incompatível | `pubspec.yaml` `^3.11.5` vs 3.11.4 local | Atualizar Flutter ou relaxar constraint |
| **M-08** | Erros genéricos | `DataScaffold` mostra `error.toString()` cru | Mensagens amigáveis + tela #34 |

### 4.3 Comando para testar agora (aparelho físico)

```bash
cd mobile
flutter pub get   # após corrigir SDK ou constraint
flutter run --dart-define=API_URL=http://4.229.233.225:3333
```

Emulador Android:

```bash
flutter run --dart-define=API_URL=http://10.0.2.2:3333
```

---

## 5. Auditoria de telas (34 do protótipo vs Flutter)

Legenda: ✅ Implementada · 🟡 Parcial · ❌ Ausente

### A. Autenticação

| # | Tela | Status | Observação |
|---|------|--------|------------|
| 1 | Splash | ❌ | Vai direto para auth ou home |
| 2-4 | Onboarding 1-3 | ❌ | Fluxo não existe |
| 5 | Login | 🟡 | `auth_screen.dart` — sem “Esqueci senha” |
| 6 | Cadastro | 🟡 | Toggle login/cadastro na mesma tela |
| 7 | Login erro | 🟡 | Snackbar/dialog, não banner dedicado |

### B. Questionário

| # | Tela | Status | Observação |
|---|------|--------|------------|
| 8-11 | Steps 1-4 | ✅ | Sliders, toggles, stepper — alinhado ao protótipo |
| 12 | Loading IA | ❌ | Submit direto; sem animação de etapas |
| 13 | Resultado perfil | 🟡 | Bottom sheet (`_showResult`), não tela hero completa |

### C. Dashboard

| # | Tela | Status | Observação |
|---|------|--------|------------|
| 14 | Dashboard | 🟡 | Funcional; falta saudação, atalhos em grade, dica do dia, gamificação escura |

### D. Plano & Recomendações

| # | Tela | Status | Observação |
|---|------|--------|------------|
| 15 | Recomendações | 🟡 | Lista OK; faltam 2 cards hero no topo |
| 16 | Plano alimentar | 🟡 | Accordion básico; sem meta kcal/macros destacados |
| 17 | Rotina semanal | 🟡 | Sem seletor Seg–Dom visual; timeline simplificada |
| 18 | Detalhe recomendação | ❌ | Sem navegação para hero + “Como aplicar” |

### E. Cluster

| # | Tela | Status | Observação |
|---|------|--------|------------|
| 19 | Meu cluster | 🟡 | `ClusterStatsPanel` só no dashboard |

### F. Evolução

| # | Tela | Status |
|---|------|--------|
| 20 | Evolução score | ❌ |
| 21 | Comparar avaliações | ❌ |

### G. Lembretes

| # | Tela | Status | Observação |
|---|------|--------|------------|
| 22 | Gerenciar lembretes | ❌ | CRUD não implementado |
| 23 | Lembretes hoje | ✅ | Com confetti (`confetti` package) |
| 24 | Criar/editar | ❌ | Bottom sheet ausente |
| 25 | Feedback concluir | 🟡 | Toast básico |

### H. Gamificação

| # | Tela | Status | Observação |
|---|------|--------|------------|
| 26 | Gamificação | 🟡 | Métricas no perfil; sem ranking Top 7 |

### I. Perfil & Config

| # | Tela | Status |
|---|------|--------|
| 27 | Perfil | 🟡 |
| 28 | Editar perfil | ❌ |
| 29 | Alterar senha | ❌ |
| 30 | Sobre o app | ❌ |
| 31 | Logout confirmação | 🟡 (ícone direto) |

### J. Estados especiais

| # | Tela | Status | Observação |
|---|------|--------|------------|
| 32 | Empty state | ✅ | Componente `EmptyState` |
| 33 | Skeleton | ❌ | Só `CircularProgressIndicator` |
| 34 | Erro conexão | 🟡 | `DataScaffold` básico; sem “Sem conexão” dedicado |

**Score de cobertura:** ~9 telas completas, ~14 parciais, ~11 ausentes → **~35% fidelidade ao fluxo de 34 telas**.

---

## 6. Auditoria de Design System

### 6.1 O que está alinhado

| Token / componente | Protótipo | Flutter |
|--------------------|-----------|---------|
| Plus Jakarta Sans | ✅ | `google_fonts` |
| JetBrains Mono (números) | ✅ | `monoStyle()` em helpers |
| Teal primário `#0D9488` | ✅ | `teal600` |
| ScoreRing animado | ✅ | `ScoreRing` + `CustomPainter`, 1100ms |
| Cores perfil (Moderado, etc.) | ✅ | `profileColor()` em helpers |
| Light / Dark | ✅ | Toggle no perfil |
| Cards arredondados | ✅ | `panelDecoration`, radius ~16-18 |
| Disclaimer médico | 🟡 | Presente em assessment; falta em mais telas |
| Confetti lembretes | ✅ | Package `confetti` |

### 6.2 Gaps de design (vs protótipo anexo)

| Área | Protótipo | App atual | Prioridade |
|------|-----------|-----------|------------|
| **Navegação inferior** | 4 abas: Início / Plano / Lembretes / Perfil | 5 abas; labels em inglês (“Home”); Avaliação como aba | Alta |
| **Ícones** | Lucide outline | Material Icons | Média |
| **Splash / Onboarding** | Gradiente teal escuro, ilustrações | Ausente | Alta (1ª impressão) |
| **Tela Resultado (#13)** | Hero glow, fatores +/-, confiança 87% | Bottom sheet compacto | Alta |
| **Dashboard (#14)** | Faixa gamificação escura, 4 atalhos | Lista utilitária | Média |
| **Recomendações (#15)** | 2 cards grandes no topo | Lista única | Média |
| **Rotina (#17)** | Chips Seg–Dom; timeline colorida | Texto simples; contraste fraco no protótipo | Média |
| **Detalhe (#18)** | Hero por categoria + passos numerados | Não existe | Alta |
| **Animações** | Micro-escala press, translateY entrada | Mínimas | Baixa |
| **Acessibilidade** | WCAG AA, touch ≥ 44px | Parcial; alguns targets pequenos | Média |
| **Gradiente bg** | `#F4F7FA` + radial verde topo | Cor sólida | Baixa |

### 6.3 Inconsistências de copy (PT-BR)

- Acentos omitidos: “Faca”, “Avaliacao”, “Recomendacoes”, “Nenhum” → padronizar UTF-8.
- Bottom nav mistura EN/PT.

---

## 7. Matriz de integração Mobile ↔ API

| Endpoint | Usado | Tela |
|----------|-------|------|
| `POST /auth/register` | ✅ | Auth |
| `POST /auth/login` | ✅ | Auth |
| `POST /auth/refresh` | ❌ | — |
| `GET /dashboard` | ✅ | Dashboard |
| `GET /health/ready` | ✅ | Dashboard (ML status) |
| `GET /assessments/latest` | ✅ | Dashboard |
| `GET /assessments/:id/explanation` | ✅ | Dashboard |
| `POST /assessments` | ✅ | Assessment |
| `GET /recommendations` | ✅ | Recommendations |
| `GET /recommendations/meal-plan` | ✅ | Recommendations |
| `GET /recommendations/weekly-routine` | ✅ | Recommendations |
| `GET /reminders/today` | ✅ | Reminders |
| `POST /reminders/:id/complete` | ✅ | Reminders |
| `GET /gamification` | ✅ | Profile |
| `GET /gamification/achievements` | ✅ | Profile |
| `GET /clusters/me/stats` | ✅ | Dashboard |
| `GET /assessments/evolution` | ❌ | — |
| `GET /gamification/leaderboard` | ❌ | — |
| `GET /clusters/me` | ❌ | — |
| CRUD `/reminders` | ❌ | — |
| `PATCH /auth/me` | ❌ | — |

---

## 8. Plano de correções (priorizado)

### Fase 0 — Desbloquear conexão (1–2 h) 🔴

| Task | Arquivo / ação |
|------|----------------|
| Default API = VM | `mobile/lib/core/theme.dart` → `http://4.229.233.225:3333` ou env |
| Campo URL no login | `auth_screen.dart` + chamar `saveApiUrl()` |
| `INTERNET` no manifest main | `android/app/src/main/AndroidManifest.xml` |
| Cleartext HTTP Android | `android:usesCleartextTraffic="true"` no `<application>` |
| iOS ATS | `Info.plist` → `NSAppTransportSecurity` / `NSAllowsArbitraryLoads` ou exceção por domínio |
| Relaxar SDK | `pubspec.yaml` → `sdk: '>=3.11.0 <4.0.0'` |
| Documentar run | Atualizar `mobile/README.md` |

**Critério de aceite:** login + dashboard + assessment funcionando no celular físico contra a VM.

### Fase 1 — Estabilidade sessão (2–4 h) 🟠

| Task | Detalhe |
|------|---------|
| Refresh token | Interceptor 401 → `POST /auth/refresh` → retry |
| Tratamento 404 pré-avaliação | Não tratar como erro fatal |
| Mensagens de erro | Mapear `ApiException` → PT-BR amigável |
| Tela erro conexão (#34) | Substituir `error.toString()` por UI do DS |

### Fase 2 — Backend / VM (2–3 h) 🟠

| Task | Detalhe |
|------|---------|
| Remover migration duplicada | Manter uma só `init` |
| Gamification no register | Criar perfil vazio ao cadastrar |
| Commit fixes VM | `ai/Dockerfile`, scripts systemd doc |
| Fechar portas 5432/8000 | Remover override público |
| Rotacionar secrets | SSH, JWT, Postgres |

### Fase 3 — UX crítica do protótipo (1–2 semanas) 🟡

| Ordem | Entrega |
|-------|---------|
| 1 | Splash + Onboarding (telas 1–4) |
| 2 | Tela Resultado completa (#13) pós-questionário |
| 3 | Loading IA (#12) com steps animados |
| 4 | Reorganizar nav: 4 abas (Início/Plano/Lembretes/Perfil); assessment via fluxo |
| 5 | Detalhe recomendação (#18) |
| 6 | Tela Cluster dedicada (#19) |
| 7 | Evolução + gráfico (#20–21) |

### Fase 4 — Design System completo (1–2 semanas) 🟢

| Entrega |
|---------|
| Tokens centralizados (`theme.dart` expandido: perfis, categorias, raios, sombras) |
| Substituir Material Icons → `lucide_icons` ou similar |
| Skeleton shimmer (#33) |
| Bottom sheets: editar perfil, logout, criar lembrete |
| Gamificação + ranking (#26) |
| Perfil: editar, senha, sobre (#28–30) |
| Acessibilidade: contraste, semantics, min 44px |

### Fase 5 — Qualidade & entrega PI (contínuo) 🔵

- Models tipados (`freezed` + `json_serializable`)
- Testes integração API + widget tests principais
- CI: `flutter analyze` + test E2E apontando VM
- HTTPS na VM (Caddy + Let's Encrypt) — opcional pós-PI
- Corrigir build Docker API para stack 100% containerizada

---

## 9. Checklist rápido pós-pull

```bash
# 1. VM acessível?
curl http://4.229.233.225:3333/health/ready

# 2. Flutter com URL correta
cd mobile
flutter run --dart-define=API_URL=http://4.229.233.225:3333

# 3. Cadastro → Avaliação → Dashboard
# 4. Se falhar: verificar manifest Android + cleartext + URL
```

---

## 10. Referências

- VM: `docs/HOSPEDAGEM-VM.md`
- Credenciais: `docs/CREDENCIAIS.md`
- API local: `docs/BANCO-LOCAL.md`
- ML: `docs/PLANO-IA-ML.md`
- Mobile: `mobile/README.md`, `mobile/lib/`
- Scripts teste VM: `scripts/vm-test-api.sh`, `scripts/vm-test-assessment.sh`

---

*Documento gerado a partir de auditoria automatizada + testes na VM em 06/06/2026.*
