FROM node:20-alpine AS base
RUN corepack enable && corepack prepare pnpm@10.11.0 --activate
WORKDIR /app

FROM base AS deps
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml turbo.json .npmrc ./
COPY api/package.json ./api/
COPY api/prisma ./api/prisma/
COPY packages/shared/package.json ./packages/shared/
RUN pnpm install --frozen-lockfile
RUN cd api && npx prisma generate

FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN pnpm --filter @vitalis/shared build
RUN pnpm --filter @vitalis/api build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN corepack enable && corepack prepare pnpm@10.11.0 --activate

COPY --from=builder /app/api/dist ./api/dist
COPY --from=builder /app/api/package.json ./api/
COPY --from=builder /app/api/prisma ./api/prisma
COPY --from=builder /app/packages/shared ./packages/shared
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
COPY --from=builder /app/pnpm-workspace.yaml ./

WORKDIR /app/api
EXPOSE 8080
ENV PORT=8080

CMD ["sh", "-c", "npx prisma migrate deploy && node dist/server.js"]
