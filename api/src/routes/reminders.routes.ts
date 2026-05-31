import { Router } from "express";
import { reminderController } from "../controllers/reminder.controller";
import { authMiddleware } from "../middleware/auth";
import { asyncHandler } from "../utils/async-handler";

export const remindersRouter = Router();

remindersRouter.use(authMiddleware);
remindersRouter.get("/today", asyncHandler(reminderController.today));
remindersRouter.get("/", asyncHandler(reminderController.list));
remindersRouter.post("/", asyncHandler(reminderController.create));
remindersRouter.patch("/:id", asyncHandler(reminderController.update));
remindersRouter.delete("/:id", asyncHandler(reminderController.remove));
remindersRouter.post("/:id/complete", asyncHandler(reminderController.complete));
