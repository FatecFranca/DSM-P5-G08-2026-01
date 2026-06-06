import swaggerJsdoc from "swagger-jsdoc";
import { env } from "./env";

const productionServer =
  process.env.API_PUBLIC_URL ?? "http://4.229.233.225:3333";

const options: swaggerJsdoc.Options = {
  definition: {
    openapi: "3.0.3",
    info: {
      title: "Vitalis API",
      version: "1.0.0",
      description: [
        "API REST do **Vitalis** — análise de hábitos e bem-estar com Machine Learning.",
        "",
        "Fluxo: questionário → classificação ML → cluster → recomendações, lembretes e gamificação.",
        "",
        "> **Disclaimer:** não realiza diagnóstico médico. Apenas classificação de perfil comportamental.",
        "",
        "Documentação interativa: `/docs`",
      ].join("\n"),
      contact: {
        name: "FATEC Franca — DSM PI G08",
      },
    },
    servers: [
      { url: productionServer, description: "VM Azure (produção PI)" },
      { url: `http://localhost:${env.PORT}`, description: "Local" },
    ],
    tags: [
      { name: "Health", description: "Status, readiness e metadados públicos" },
      { name: "Auth", description: "Cadastro, login e sessão JWT" },
      { name: "Dashboard", description: "Visão agregada do usuário" },
      { name: "Assessments", description: "Questionário e classificação ML" },
      { name: "Clusters", description: "Grupo comportamental do usuário" },
      { name: "Recommendations", description: "Planos e recomendações" },
      { name: "Reminders", description: "Lembretes diários" },
      { name: "Gamification", description: "Pontos, nível, conquistas e ranking" },
      { name: "Admin", description: "Métricas do sistema (admin)" },
    ],
    components: {
      securitySchemes: {
        bearerAuth: { type: "http", scheme: "bearer", bearerFormat: "JWT" },
        adminKey: { type: "apiKey", in: "header", name: "X-Admin-Key" },
      },
    },
  },
  apis: ["./src/docs/openapi.yaml"],
};

export const swaggerSpec = swaggerJsdoc(options);
