import { Router } from "express";
import { gamificationController } from "../controllers/gamification.controller";
import { authMiddleware } from "../middleware/auth";
import { asyncHandler } from "../utils/async-handler";

export const gamificationRouter = Router();

gamificationRouter.use(authMiddleware);
gamificationRouter.get("/achievements", asyncHandler(gamificationController.achievements));
gamificationRouter.get("/leaderboard", asyncHandler(gamificationController.leaderboard));
gamificationRouter.get("/", asyncHandler(gamificationController.getProfile));
