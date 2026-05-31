import { Router } from "express";
import { assessmentController } from "../controllers/assessment.controller";
import { authMiddleware } from "../middleware/auth";
import { asyncHandler } from "../utils/async-handler";

export const assessmentsRouter = Router();

assessmentsRouter.use(authMiddleware);
assessmentsRouter.post("/", asyncHandler(assessmentController.submit));
assessmentsRouter.get("/evolution", asyncHandler(assessmentController.evolution));
assessmentsRouter.get("/compare", asyncHandler(assessmentController.compare));
assessmentsRouter.get("/latest", asyncHandler(assessmentController.latest));
assessmentsRouter.get("/", asyncHandler(assessmentController.list));
assessmentsRouter.get("/:id/explanation", asyncHandler(assessmentController.explanation));
assessmentsRouter.get("/:id", asyncHandler(assessmentController.getById));
