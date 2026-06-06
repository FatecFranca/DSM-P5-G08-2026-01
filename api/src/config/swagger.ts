import swaggerJsdoc from "swagger-jsdoc";
import { env } from "./env";

const options: swaggerJsdoc.Options = {
  definition: {
    openapi: "3.0.0",
    info: {
      title: "Vitalis API",
      version: "1.0.0",
      description:
        "API REST do Vitalis — analise de habitos e bem-estar com Machine Learning. Nao realiza diagnostico medico.",
    },
    servers: [{ url: `http://localhost:${env.PORT}`, description: "Local" }],
    components: {
      securitySchemes: {
        bearerAuth: { type: "http", scheme: "bearer", bearerFormat: "JWT" },
        adminKey: { type: "apiKey", in: "header", name: "X-Admin-Key" },
      },
    },
  },
  apis: ["./src/routes/*.ts", "./src/docs/*.yaml"],
};

export const swaggerSpec = swaggerJsdoc(options);
