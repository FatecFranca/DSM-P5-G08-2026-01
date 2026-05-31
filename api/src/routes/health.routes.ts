import { Router } from "express";
import {
  adminController,
  clusterController,
  dashboardController,
  healthController,
} from "../controllers/dashboard.controller";
import { authMiddleware } from "../middleware/auth";
import { adminMiddleware } from "../middleware/admin";
import { asyncHandler } from "../utils/async-handler";

export const healthRouter = Router();

healthRouter.get("/", healthController.status);
healthRouter.get("/ready", asyncHandler(healthController.ready));
healthRouter.get("/questionnaire", healthController.questionnaire);
healthRouter.get("/clusters", asyncHandler(healthController.clusters));

export const dashboardRouter = Router();
dashboardRouter.use(authMiddleware);
dashboardRouter.get("/", asyncHandler(dashboardController.userDashboard));

export const clustersRouter = Router();
clustersRouter.use(authMiddleware);
clustersRouter.get("/me", asyncHandler(clusterController.myCluster));
clustersRouter.get("/me/stats", asyncHandler(clusterController.myClusterStats));

export const adminRouter = Router();
adminRouter.use(adminMiddleware);
adminRouter.get("/stats", asyncHandler(adminController.systemStats));
adminRouter.get("/users", asyncHandler(adminController.listUsers));
adminRouter.get("/clusters", asyncHandler(adminController.listClusters));
