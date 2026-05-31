import { Router } from "express";
import { recommendationController } from "../controllers/recommendation.controller";
import { authMiddleware } from "../middleware/auth";
import { asyncHandler } from "../utils/async-handler";

export const recommendationsRouter = Router();

recommendationsRouter.use(authMiddleware);
recommendationsRouter.get("/meal-plan", asyncHandler(recommendationController.mealPlan));
recommendationsRouter.get("/weekly-routine", asyncHandler(recommendationController.weeklyRoutine));
recommendationsRouter.get("/by-category", asyncHandler(recommendationController.listByCategory));
recommendationsRouter.get("/", asyncHandler(recommendationController.list));
recommendationsRouter.patch("/:id/toggle", asyncHandler(recommendationController.toggle));
