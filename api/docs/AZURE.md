# Deploy no Azure - Vitalis API

Guia passo a passo para hospedar backend + PostgreSQL na Azure (nivel PI).

## Arquitetura recomendada

```
Azure App Service (Linux)  →  API Node.js (:443)
Azure Database for PostgreSQL Flexible Server  →  Banco
Azure App Service (Python) ou Container  →  ML service (opcional)
```

## 1. Criar PostgreSQL na Azure

1. Portal Azure → **Create a resource** → **Azure Database for PostgreSQL Flexible Server**
2. Configuracao basica:
   - Resource group: `rg-vitalis-pi`
   - Server name: `vitalis-db` (unico globalmente)
   - Region: Brazil South
   - PostgreSQL version: 16
   - Compute: Burstable B1ms (barato para PI)
3. **Authentication**: senha forte anote em local seguro
4. **Networking**: em dev, permita acesso publico + adicione seu IP. Em producao, use VNet.
5. Crie o banco `vitalis` se nao existir (Database → Create → `vitalis`)

### Connection string

Em **Connection strings** do servidor, copie a URI e ajuste:

```
postgresql://USUARIO:SENHA@vitalis-db.postgres.database.azure.com:5432/vitalis?sslmode=require
```

## 2. Criar App Service para a API

1. **Create a resource** → **Web App**
2. Publish: **Code**
3. Runtime: **Node 20 LTS**
4. OS: **Linux**
5. Plano: B1 (basico) ou F1 (free tier limitado)

### Variaveis de ambiente (Configuration → Application settings)

| Nome | Valor |
|------|-------|
| `DATABASE_URL` | connection string do PostgreSQL |
| `JWT_SECRET` | string aleatoria 64+ chars |
| `JWT_EXPIRES_IN` | `7d` |
| `NODE_ENV` | `production` |
| `PORT` | `8080` (Azure injeta automaticamente) |
| `CORS_ORIGINS` | URL do app mobile/web |
| `ML_SERVICE_URL` | URL do servico Python (quando existir) |

## 3. Deploy da API

### Opcao A: GitHub Actions (recomendado)

Conecte o repositorio no App Service → Deployment Center → GitHub.

Build command na raiz do monorepo:

```bash
pnpm install
pnpm --filter @vitalis/api build
```

Startup command no App Service:

```bash
node api/dist/server.js
```

Ou use o script:

```bash
cd api && npm run start:prod
```

### Opcao B: Docker

```bash
docker build -t vitalis-api -f api/Dockerfile .
docker run -p 3333:8080 --env-file .env vitalis-api
```

## 4. Rodar migrations na Azure

No **SSH** do App Service ou via GitHub Action:

```bash
cd api
npx prisma migrate deploy
npx prisma db seed
```

O script `start:prod` ja executa `migrate deploy` antes de subir.

## 5. Testar

```bash
curl https://vitalis-api.azurewebsites.net/health
```

## 6. Servico ML (Python) - opcional

Crie outro App Service com runtime Python 3.12:

- Startup: `uvicorn src.serve:app --host 0.0.0.0 --port 8000`
- Configure `ML_SERVICE_URL` na API apontando para essa URL

## Checklist PI

- [ ] PostgreSQL criado e acessivel
- [ ] `DATABASE_URL` com `sslmode=require`
- [ ] Migrations aplicadas
- [ ] Seed executado (templates + clusters)
- [ ] `/health` respondendo 200
- [ ] Register + login funcionando
- [ ] POST `/assessments` retorna perfil + plano

## Custo estimado (dev/PI)

| Recurso | ~Custo/mes |
|---------|------------|
| PostgreSQL B1ms | R$ 50-80 |
| App Service B1 | R$ 50-70 |
| App Service F1 (free) | R$ 0 (limitado) |

Para apresentacao, o free tier + Postgres burstable e suficiente.
