import { Response } from "express";
import { AuthenticatedRequest } from "../middleware/auth";
import { recommendationService } from "../services/assessment.service";
import { toggleRecommendationSchema } from "../schemas";
import { paramId } from "../utils/params";

export const recommendationController = {
  async list(req: AuthenticatedRequest, res: Response) {
    const recommendations = await recommendationService.listForUser(req.userId);
    return res.json({ recommendations });
  },

  async listByCategory(req: AuthenticatedRequest, res: Response) {
    const grouped = await recommendationService.listGroupedByCategory(req.userId);
    return res.json({ grouped });
  },

  async mealPlan(req: AuthenticatedRequest, res: Response) {
    const plan = await recommendationService.getMealPlan(req.userId);
    return res.json(plan);
  },

  async weeklyRoutine(req: AuthenticatedRequest, res: Response) {
    const routine = await recommendationService.getWeeklyRoutine(req.userId);
    return res.json(routine);
  },

  async toggle(req: AuthenticatedRequest, res: Response) {
    const { isActive } = toggleRecommendationSchema.parse(req.body);
    await recommendationService.toggle(req.userId, paramId(req, "id"), isActive);
    return res.json({ message: "Recomendacao atualizada" });
  },
};
