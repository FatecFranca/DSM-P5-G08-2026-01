import { Router } from "express";
import { authController } from "../controllers/auth.controller";
import { authMiddleware } from "../middleware/auth";
import { rateLimit } from "../middleware/rate-limit";
import { asyncHandler } from "../utils/async-handler";

const authLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 30, keyPrefix: "auth" });

export const authRouter = Router();

authRouter.post("/register", authLimiter, asyncHandler(authController.register));
authRouter.post("/login", authLimiter, asyncHandler(authController.login));
authRouter.post("/refresh", asyncHandler(authController.refresh));
authRouter.post("/logout", asyncHandler(authController.logout));

authRouter.get("/me", authMiddleware, asyncHandler(authController.me));
authRouter.patch("/me", authMiddleware, asyncHandler(authController.updateMe));
authRouter.patch("/password", authMiddleware, asyncHandler(authController.changePassword));
authRouter.post("/logout-all", authMiddleware, asyncHandler(authController.logoutAll));
