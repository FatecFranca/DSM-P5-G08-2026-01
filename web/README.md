# Web (Next.js)

Landing page e painel admin basico do Vitalis.

```bash
pnpm web:dev
```

Acesse:
- Landing: http://localhost:3000
- Admin: http://localhost:3000/admin

Por padrao, o web usa a mesma API da VM configurada no mobile:

```text
http://4.229.233.225:3333
```

Para sobrescrever, configure `NEXT_PUBLIC_API_URL` no `.env` da raiz ou em `web/.env.local`.
