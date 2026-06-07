# Mobile (Flutter)

App principal do Vitalis em **Flutter** (iOS + Android).

## Rodar

```bash
cd mobile
flutter pub get
flutter run
```

Pelo monorepo:

```bash
pnpm mobile:dev
```

## URL da API

Fixa no app (VM de produção do PI):

```text
http://4.229.233.225:3333
```

O usuário final **não configura** a URL — ela está embutida no código.

## Fluxos implementados

- Login e cadastro (com configuração de URL da API)
- Dashboard (Início)
- Avaliação de saúde (4 etapas, aberta pelo Início ou ícone no topo)
- Plano: recomendações, plano alimentar e rotina semanal
- Lembretes do dia com conclusão e confetti
- Perfil: gamificação, conquistas, tema claro/escuro
- Refresh token automático (sessão renovada após 401)

## Navegação

4 abas inferiores: **Início · Plano · Lembretes · Perfil**

A avaliação abre em tela cheia a partir do Início ou do botão no AppBar.

## Requisitos

- Flutter SDK >= 3.11.0
- Android: HTTP cleartext habilitado para a VM (já configurado)
- iOS: ATS liberado para HTTP (já configurado)

## Testar contra a VM

```bash
curl http://4.229.233.225:3333/health/ready
flutter run --dart-define=API_URL=http://4.229.233.225:3333
```
