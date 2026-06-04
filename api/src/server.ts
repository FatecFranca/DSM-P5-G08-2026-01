import { createApp } from "./app";
import { env } from "./config/env";
import { prisma } from "./lib/prisma";

const app = createApp();

async function bootstrap() {
  await prisma.$connect();
  app.listen(env.PORT, () => {
    console.log(`API rodando em http://localhost:${env.PORT}`);
  });
}

bootstrap().catch(async (error) => {
  console.error("Falha ao iniciar API:", error);
  await prisma.$disconnect();
  process.exit(1);
});
