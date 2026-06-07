import { Response } from "express";
import { AuthenticatedRequest } from "../middleware/auth";
import { foodLogSchema } from "../schemas";
import { foodLogService } from "../services/food-log.service";
import { paramId } from "../utils/params";

export const foodLogController = {
  async today(req: AuthenticatedRequest, res: Response) {
    const date = typeof req.query.date === "string" ? req.query.date : undefined;
    const entries = await foodLogService.listToday(req.userId, date);
    return res.json({ entries, date: date ?? new Date().toISOString().slice(0, 10) });
  },

  async create(req: AuthenticatedRequest, res: Response) {
    const data = foodLogSchema.parse(req.body);
    const entry = await foodLogService.create(req.userId, data);
    return res.status(201).json({ entry });
  },

  async remove(req: AuthenticatedRequest, res: Response) {
    await foodLogService.remove(req.userId, paramId(req, "id"));
    return res.status(204).send();
  },
};
