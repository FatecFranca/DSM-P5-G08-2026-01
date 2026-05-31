import { Request, Response, NextFunction } from "express";
import { env } from "../config/env";
import { verifyAccessToken } from "../lib/jwt";
import { AppError } from "../utils/app-error";
import { AuthenticatedRequest } from "./auth";

export function adminMiddleware(req: Request, _res: Response, next: NextFunction) {
  const apiKey = req.headers["x-admin-key"];
  if (env.ADMIN_API_KEY && apiKey === env.ADMIN_API_KEY) {
    return next();
  }

  const header = req.headers.authorization;
  if (header?.startsWith("Bearer ")) {
    try {
      const payload = verifyAccessToken(header.slice(7));
      if (payload.role === "ADMIN") {
        (req as AuthenticatedRequest).userId = payload.sub;
        (req as AuthenticatedRequest).userEmail = payload.email;
        (req as AuthenticatedRequest).userRole = payload.role;
        return next();
      }
    } catch {
      // fallthrough
    }
  }

  next(new AppError("Acesso restrito a administradores", 403));
}
