# PostgreSQL + API + ML na VM Azure (economico)

Para **Azure for Students (~US$ 100)** — roda tudo na VM `servidor` do grupo **PI5**, sem PostgreSQL gerenciado (caro).

**Manual PI:** back-end + banco na nuvem publica — VM Azure conta.

---

## Custo comparativo

| Opcao | Custo aprox./mes | PI $100 |
|-------|------------------|---------|
| PostgreSQL Flexible Server + 2 App Services | US$ 80–150+ | Estoura rapido |
| **Tudo na VM (Docker)** | US$ 15–35 (se ligada) | **Recomendado** |
| VM **parada** (desalocada) | So disco (~US$ 2–5) | Economiza |

**Dica:** ligue a VM so para dev/demo/apresentacao. Parada desalocada = nao paga CPU/RAM.

---

## Arquitetura na VM (atual)

```
VM "servidor" — IP 4.229.233.225
├── Docker: postgres:16   (localhost:5432)
├── Docker: vitalis-ml    (localhost:8000)
└── Node API (systemd)    (porta 3333 pública)
```

Mobile Flutter: `http://4.229.233.225:3333` (padrão no app).

**Deploy/atualização na VM:**

```bash
cd ~/vitalis
bash scripts/deploy-vm.sh
```

Serviço systemd: `vitalis-api` → `node api/dist/server.js`

---

## Passo a passo (1 de cada vez)

### Passo 1 — Ligar a VM

Portal Azure → VM **servidor** → **Iniciar**

Aguarde status **Em execucao**.

---

### Passo 2 — Abrir porta da API no firewall

1. VM **servidor** → **Rede** (ou Networking)
2. **Adicionar regra de porta de entrada**
   - Porta: **3333**
   - Protocolo: TCP
   - Nome: `vitalis-api`
   - Prioridade: 300
3. **Nao** abra 5432 (Postgres) para internet — so Docker interno.

---

### Passo 3 — Conectar na VM (SSH)

Portal → VM → **Conectar** → **SSH**

Ou no seu PC (PowerShell):

```bash
ssh azureuser@4.229.233.225
```

(Usuario pode ser `azureuser` ou o que voces criaram na VM.)

---

### Passo 4 — Instalar Docker na VM

Na VM (Linux):

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# sair e entrar de novo no SSH
docker compose version
```

---

### Passo 5 — Subir o projeto na VM

```bash
git clone https://github.com/FatecFranca/SEU-REPO.git vitalis
cd vitalis
```

Crie `.env` na raiz (mesmas vars do local, ajustando):

```env
DATABASE_URL="postgresql://vitalis:vitalis@postgres:5432/vitalis?schema=public"
JWT_SECRET="producao-chave-longa-min-32-chars"
ML_SERVICE_URL="http://ml:8000"
GEMINI_API_KEY="sua-chave"
GEMINI_ENABLED=true
CORS_ORIGINS="*"
PORT=8080
```

Subir stack:

```bash
docker compose -f docker-compose.vm.yml up -d --build
docker compose -f docker-compose.vm.yml exec api npx prisma migrate deploy
docker compose -f docker-compose.vm.yml exec api npx prisma db seed
```

---

### Passo 6 — Testar

No seu PC:

```bash
curl http://4.229.233.225:3333/health
curl http://4.229.233.225:3333/health/ready
```

---

## Credenciais na VM

| Item | Valor (padrao compose) |
|------|------------------------|
| Postgres user | `vitalis` |
| Postgres password | `vitalis` (troque em producao!) |
| Database | `vitalis` |
| DATABASE_URL (dentro Docker) | `postgresql://vitalis:vitalis@postgres:5432/vitalis` |

Nao precisa de API key para Postgres — so user/senha acima.

---

## Local vs VM

| | Local (seu PC) | VM Azure |
|--|---------------|----------|
| DATABASE_URL | `localhost:5432` | `postgres:5432` (Docker) |
| API URL mobile | IP da maquina | `4.229.233.225:3333` |
| Custo | R$ 0 | Credito Azure |

Desenvolvimento continua **local**; VM e para **demo/PI/producao leve**.

---

## Quando desligar

Portal → VM **servidor** → **Parar** (desalocar)

Antes da apresentacao: **Iniciar** + `docker compose up -d`

---

*Vitalis — hospedagem economica PI em VM unica.*
