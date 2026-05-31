import { Response } from "express";
import { AuthenticatedRequest } from "../middleware/auth";
import { gamificationService } from "../services/assessment.service";
import { achievementService } from "../services/achievement.service";

export const gamificationController = {
  async getProfile(req: AuthenticatedRequest, res: Response) {
    const result = await gamificationService.getProfile(req.userId);
    return res.json(result);
  },

  async leaderboard(_req: AuthenticatedRequest, res: Response) {
    const leaderboard = await gamificationService.getLeaderboard();
    return res.json({ leaderboard });
  },

  async achievements(req: AuthenticatedRequest, res: Response) {
    const result = await achievementService.listForUser(req.userId);
    return res.json(result);
  },
};
