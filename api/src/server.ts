import { createApp } from "./app";
import { env } from "./config/env";
import { prisma } from "./lib/prisma";

const app = createApp();

async function bootstrap() {
  try {
    await prisma.$connect();
    console.log("✅ Prisma connected successfully");

    const port = env.PORT || Number(process.env.PORT) || 3000;

    app.listen(port, () => {
      console.log(`🚀 API rodando em http://0.0.0.0:${port}`);
    });
  } catch (error) {
    console.error("❌ Falha ao iniciar API:", error);
    await prisma.$disconnect();
    process.exit(1);
  }
}

bootstrap();