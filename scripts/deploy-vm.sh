#!/bin/bash
# Deploy/atualiza Vitalis na VM Azure
# Uso (na VM): bash scripts/deploy-vm.sh

set -euo pipefail

ROOT="${HOME}/vitalis"
cd "$ROOT"

echo "==> Git pull"
git pull origin main || git pull

echo "==> Docker: Postgres + ML"
sudo docker compose -f docker-compose.vm.yml up -d --build postgres ml

echo "==> Node dependencies"
pnpm install --frozen-lockfile
pnpm --filter @vitalis/shared build

echo "==> Prisma"
export $(grep -v '^#' .env | xargs)
cd api
npx prisma generate
npx prisma migrate deploy
cd ..

echo "==> Build API"
pnpm --filter @vitalis/api build

echo "==> Restart API (systemd)"
sudo systemctl restart vitalis-api
sleep 3
sudo systemctl is-active vitalis-api

echo "==> Health"
curl -sf "http://localhost:${PORT:-3333}/health/ready"
echo ""
echo "Deploy concluido."
