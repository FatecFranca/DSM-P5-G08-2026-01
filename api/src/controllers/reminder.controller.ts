import { Response } from "express";
import { AuthenticatedRequest } from "../middleware/auth";
import { gamificationService, reminderService } from "../services/assessment.service";
import { reminderSchema, reminderUpdateSchema } from "../schemas";
import { paramId } from "../utils/params";

export const reminderController = {
  async list(req: AuthenticatedRequest, res: Response) {
    const reminders = await reminderService.listForUser(req.userId);
    return res.json({ reminders });
  },

  async today(req: AuthenticatedRequest, res: Response) {
    const reminders = await reminderService.listToday(req.userId);
    return res.json({ reminders });
  },

  async create(req: AuthenticatedRequest, res: Response) {
    const data = reminderSchema.parse(req.body);
    const reminder = await reminderService.create(req.userId, data);
    return res.status(201).json({ reminder });
  },

  async update(req: AuthenticatedRequest, res: Response) {
    const data = reminderUpdateSchema.parse(req.body);
    const reminder = await reminderService.update(req.userId, paramId(req, "id"), data);
    return res.json({ reminder });
  },

  async remove(req: AuthenticatedRequest, res: Response) {
    await reminderService.delete(req.userId, paramId(req, "id"));
    return res.status(204).send();
  },

  async complete(req: AuthenticatedRequest, res: Response) {
    const reminderId = paramId(req, "id");
    const existing = await reminderService.listForUser(req.userId);
    if (!existing.find((r) => r.id === reminderId)) {
      const { AppError } = await import("../utils/app-error");
      throw new AppError("Lembrete nao encontrado", 404);
    }
    const result = await gamificationService.completeReminder(req.userId, reminderId);
    return res.json({ message: "Lembrete concluido", ...result });
  },
};
