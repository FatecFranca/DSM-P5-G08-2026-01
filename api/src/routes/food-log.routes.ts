import { Router } from "express";
import { foodLogController } from "../controllers/food-log.controller";
import { authMiddleware } from "../middleware/auth";
import { asyncHandler } from "../utils/async-handler";

export const foodLogRouter = Router();

foodLogRouter.use(authMiddleware);

foodLogRouter.get("/today", asyncHandler(foodLogController.today));
foodLogRouter.post("/", asyncHandler(foodLogController.create));
foodLogRouter.delete("/:id", asyncHandler(foodLogController.remove));
