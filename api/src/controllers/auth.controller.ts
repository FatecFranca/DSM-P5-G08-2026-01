import { Request, Response } from "express";
import { AuthenticatedRequest } from "../middleware/auth";
import { authService } from "../services/auth.service";
import {
  changePasswordSchema,
  loginSchema,
  refreshSchema,
  registerSchema,
  updateProfileSchema,
} from "../schemas";

export const authController = {
  async register(req: Request, res: Response) {
    const data = registerSchema.parse(req.body);
    const result = await authService.register(data.name, data.email, data.password);
    return res.status(201).json(result);
  },

  async login(req: Request, res: Response) {
    const data = loginSchema.parse(req.body);
    const result = await authService.login(data.email, data.password);
    return res.json(result);
  },

  async refresh(req: Request, res: Response) {
    const { refreshToken } = refreshSchema.parse(req.body);
    const result = await authService.refresh(refreshToken);
    return res.json(result);
  },

  async logout(req: Request, res: Response) {
    const { refreshToken } = refreshSchema.parse(req.body);
    await authService.logout(refreshToken);
    return res.status(204).send();
  },

  async logoutAll(req: AuthenticatedRequest, res: Response) {
    await authService.logoutAll(req.userId);
    return res.status(204).send();
  },

  async me(req: AuthenticatedRequest, res: Response) {
    const user = await authService.getProfile(req.userId);
    return res.json({ user });
  },

  async updateMe(req: AuthenticatedRequest, res: Response) {
    const { name } = updateProfileSchema.parse(req.body);
    const user = await authService.updateProfile(req.userId, name);
    return res.json({ user });
  },

  async changePassword(req: AuthenticatedRequest, res: Response) {
    const data = changePasswordSchema.parse(req.body);
    await authService.changePassword(req.userId, data.currentPassword, data.newPassword);
    return res.json({ message: "Senha alterada com sucesso" });
  },
};
