import crypto from "crypto";
import { prisma } from "../lib/prisma";
import { getRefreshTokenExpiry } from "../lib/jwt";

export const refreshTokenRepository = {
  hashToken(token: string): string {
    return crypto.createHash("sha256").update(token).digest("hex");
  },

  generateToken(): string {
    return crypto.randomBytes(40).toString("hex");
  },

  async create(userId: string) {
    const token = this.generateToken();
    const tokenHash = this.hashToken(token);
    const expiresAt = getRefreshTokenExpiry();

    await prisma.refreshToken.create({
      data: { userId, tokenHash, expiresAt },
    });

    return { token, expiresAt };
  },

  async findValid(token: string) {
    const tokenHash = this.hashToken(token);
    const record = await prisma.refreshToken.findUnique({
      where: { tokenHash },
      include: { user: true },
    });

    if (!record || record.expiresAt < new Date()) {
      return null;
    }

    return record;
  },

  async revoke(token: string) {
    const tokenHash = this.hashToken(token);
    await prisma.refreshToken.deleteMany({ where: { tokenHash } });
  },

  async revokeAllForUser(userId: string) {
    await prisma.refreshToken.deleteMany({ where: { userId } });
  },
};
