import express from "express";
import cors from "cors";
import helmet from "helmet";
import { getCorsOrigins } from "./config/env";
import { errorHandler } from "./middleware/error-handler";
import { requestLogger } from "./middleware/request-logger";
import { authRouter } from "./routes/auth.routes";
import { assessmentsRouter } from "./routes/assessments.routes";
import { recommendationsRouter } from "./routes/recommendations.routes";
import { remindersRouter } from "./routes/reminders.routes";
import { gamificationRouter } from "./routes/gamification.routes";
import {
  adminRouter,
  clustersRouter,
  dashboardRouter,
  healthRouter,
} from "./routes/health.routes";

export function createApp() {
  const app = express();

  app.set("trust proxy", 1);
  app.use(helmet());
  app.use(cors({ origin: getCorsOrigins() }));
  app.use(express.json({ limit: "1mb" }));
  app.use(requestLogger);

  app.use("/health", healthRouter);
  app.use("/auth", authRouter);
  app.use("/dashboard", dashboardRouter);
  app.use("/clusters", clustersRouter);
  app.use("/admin", adminRouter);
  app.use("/assessments", assessmentsRouter);
  app.use("/recommendations", recommendationsRouter);
  app.use("/reminders", remindersRouter);
  app.use("/gamification", gamificationRouter);

  app.use(errorHandler);

  return app;
}
