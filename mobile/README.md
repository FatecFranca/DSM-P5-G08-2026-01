# Mobile (React Native)

App principal do Vitalis. Fluxo: cadastro, questionario, resultado do perfil, recomendacoes, lembretes e gamificacao.

## Setup (proxima etapa)

```bash
cd mobile
npx create-expo-app@latest . --template blank-typescript
pnpm install
```

## Config

Crie `mobile/.env`:

```
EXPO_PUBLIC_API_URL=http://localhost:3333
```

## Telas planejadas

- Login / Cadastro
- Onboarding (questionario de habitos)
- Resultado (perfil + score + cluster)
- Recomendacoes (dieta, rotina, exercicio)
- Lembretes (agua, refeicao, sono)
- Gamificacao (pontos, nivel, streak)

## API

Consome `api/` via REST. Schema do formulario em `GET /health/questionnaire`.
