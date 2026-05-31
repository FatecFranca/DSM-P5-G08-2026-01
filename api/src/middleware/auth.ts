import { Request, Response, NextFunction } from "express";
import { verifyAccessToken } from "../lib/jwt";
import { AppError } from "../utils/app-error";

export interface AuthenticatedRequest extends Request {
  userId: string;
  userEmail: string;
  userRole: string;
}

export function authMiddleware(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;

  if (!header?.startsWith("Bearer ")) {
    return next(new AppError("Token nao informado", 401));
  }

  const token = header.slice(7);

  try {
    const payload = verifyAccessToken(token);
    (req as AuthenticatedRequest).userId = payload.sub;
    (req as AuthenticatedRequest).userEmail = payload.email;
    (req as AuthenticatedRequest).userRole = payload.role ?? "USER";
    next();
  } catch {
    next(new AppError("Token invalido ou expirado", 401));
  }
}
