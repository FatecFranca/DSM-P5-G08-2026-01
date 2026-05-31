import { Request, Response } from "express";
import { AuthenticatedRequest } from "../middleware/auth";
import { dashboardService, healthService } from "../services/dashboard.service";
import { clusterService } from "../services/cluster.service";
import { paginationSchema } from "../schemas";

export const healthController = {
  status(_req: Request, res: Response) {
    return res.json(healthService.getStatus());
  },

  async ready(_req: Request, res: Response) {
    const result = await healthService.getReady();
    const statusCode = result.status === "ready" ? 200 : 503;
    return res.status(statusCode).json(result);
  },

  questionnaire(_req: Request, res: Response) {
    return res.json(healthService.getQuestionnaire());
  },

  async clusters(_req: Request, res: Response) {
    const clusters = await healthService.getClusters();
    return res.json({ clusters });
  },
};

export const dashboardController = {
  async userDashboard(req: AuthenticatedRequest, res: Response) {
    const dashboard = await dashboardService.getUserDashboard(req.userId);
    return res.json({ dashboard });
  },
};

export const adminController = {
  async systemStats(_req: Request, res: Response) {
    const stats = await dashboardService.getSystemStats();
    return res.json({ stats });
  },

  async listUsers(req: Request, res: Response) {
    const { page, limit } = paginationSchema.parse(req.query);
    const result = await dashboardService.listUsers(page, limit);
    return res.json(result);
  },

  async listClusters(_req: Request, res: Response) {
    const clusters = await clusterService.listAll();
    return res.json({ clusters });
  },
};

export const clusterController = {
  async myCluster(req: AuthenticatedRequest, res: Response) {
    const cluster = await clusterService.getMyCluster(req.userId);
    return res.json({ cluster });
  },

  async myClusterStats(req: AuthenticatedRequest, res: Response) {
    const stats = await clusterService.getMyClusterStats(req.userId);
    return res.json({ stats });
  },
};
