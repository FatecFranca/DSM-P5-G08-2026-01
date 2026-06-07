import express from "express";
import cors from "cors";
import helmet from "helmet";
import swaggerUi from "swagger-ui-express";
import { getCorsOrigins } from "./config/env";
import { swaggerSpec } from "./config/swagger";
import { errorHandler } from "./middleware/error-handler";
import { requestLogger } from "./middleware/request-logger";
import { authRouter } from "./routes/auth.routes";
import { assessmentsRouter } from "./routes/assessments.routes";
import { recommendationsRouter } from "./routes/recommendations.routes";
import { remindersRouter } from "./routes/reminders.routes";
import { gamificationRouter } from "./routes/gamification.routes";
import { foodLogRouter } from "./routes/food-log.routes";
import {
  adminRouter,
  clustersRouter,
  dashboardRouter,
  healthRouter,
} from "./routes/health.routes";

const swaggerUiOptions: swaggerUi.SwaggerUiOptions = {
  customSiteTitle: "Vitalis API - Swagger",
  customCss: ".swagger-ui .topbar .download-url-wrapper { display: none }",
  swaggerOptions: {
    persistAuthorization: true,
    displayRequestDuration: true,
    docExpansion: "list",
    filter: true,
  },
};

export function createApp() {
  const app = express();

  app.set("trust proxy", 1);
  app.use(
    helmet({
      // Swagger UI usa scripts inline + eval; CSP padrão do Helmet deixa /docs em branco
      contentSecurityPolicy: false,
      crossOriginEmbedderPolicy: false,
    }),
  );
  app.use(cors({ origin: getCorsOrigins() }));
  app.use(express.json({ limit: "1mb" }));
  app.use(requestLogger);

  app.use("/docs", swaggerUi.serve);
  app.get("/docs", swaggerUi.setup(swaggerSpec, swaggerUiOptions));
  app.get("/docs/", swaggerUi.setup(swaggerSpec, swaggerUiOptions));
  app.get("/docs.json", (_req, res) => {
    res.json(swaggerSpec);
  });

  app.use("/health", healthRouter);
  app.use("/auth", authRouter);
  app.use("/dashboard", dashboardRouter);
  app.use("/clusters", clustersRouter);
  app.use("/admin", adminRouter);
  app.use("/assessments", assessmentsRouter);
  app.use("/recommendations", recommendationsRouter);
  app.use("/reminders", remindersRouter);
  app.use("/gamification", gamificationRouter);
  app.use("/food-log", foodLogRouter);

  app.use(errorHandler);

  return app;
}
