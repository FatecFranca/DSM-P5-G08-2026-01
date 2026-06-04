import { createApp } from "./app";
import { env } from "./config/env";
import { prisma } from "./lib/prisma";

const app = createApp();

async function bootstrap() {
  try {
    await prisma.$connect();
    console.log("✅ Prisma conectado com sucesso");

    const port = Number(env.PORT) || Number(process.env.PORT) || 3000;

    app.listen(port, "0.0.0.0", () => {
      console.log(`🚀 API rodando em http://0.0.0.0:${port}`);
    });
  } catch (error) {
    console.error("❌ Falha ao iniciar a API:", error);
    await prisma.$disconnect().catch(() => {});
    process.exit(1);
  }
}

bootstrap();