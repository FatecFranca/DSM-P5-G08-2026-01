import { Response } from "express";
import { AuthenticatedRequest } from "../middleware/auth";
import { assessmentService } from "../services/assessment.service";
import { assessmentSchema, compareSchema, paginationSchema } from "../schemas";
import { paramId } from "../utils/params";

export const assessmentController = {
  async submit(req: AuthenticatedRequest, res: Response) {
    const data = assessmentSchema.parse(req.body);
    const result = await assessmentService.submit(req.userId, data);
    return res.status(201).json(result);
  },

  async list(req: AuthenticatedRequest, res: Response) {
    const { page, limit } = paginationSchema.parse(req.query);
    const result = await assessmentService.listForUser(req.userId, page, limit);
    return res.json(result);
  },

  async evolution(req: AuthenticatedRequest, res: Response) {
    const result = await assessmentService.getEvolution(req.userId);
    return res.json(result);
  },

  async compare(req: AuthenticatedRequest, res: Response) {
    const { from, to } = compareSchema.parse(req.query);
    const result = await assessmentService.compare(req.userId, from, to);
    return res.json(result);
  },

  async latest(req: AuthenticatedRequest, res: Response) {
    const assessment = await assessmentService.getLatest(req.userId);
    return res.json({ assessment });
  },

  async explanation(req: AuthenticatedRequest, res: Response) {
    const result = await assessmentService.getExplanation(req.userId, paramId(req, "id"));
    return res.json(result);
  },

  async getById(req: AuthenticatedRequest, res: Response) {
    const assessment = await assessmentService.getById(req.userId, paramId(req, "id"));
    return res.json({ assessment });
  },
};
