# Mobile (Flutter)

App principal do Vitalis em Flutter.

## Rodar

```bash
cd mobile
flutter pub get
flutter run
```

Tambem funciona pelo script do monorepo:

```bash
pnpm mobile:dev
```

## URL da API

O app permite editar a URL na tela de login. Valores comuns:

```text
Windows/macOS/Linux ou Flutter web: http://localhost:3333
Emulador Android: http://10.0.2.2:3333
Aparelho fisico: http://IP_DA_SUA_MAQUINA:3333
```

Tambem da para passar a URL no build/run:

```bash
flutter run --dart-define=API_URL=http://10.0.2.2:3333
```

## Fluxos implementados

- Login e cadastro
- Dashboard
- Avaliacao de saude
- Recomendacoes, plano alimentar e rotina semanal
- Lembretes do dia com conclusao
- Gamificacao e conquistas
