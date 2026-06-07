import bcrypt from "bcryptjs";
import { signAccessToken } from "../lib/jwt";
import { userRepository } from "../repositories/user.repository";
import { refreshTokenRepository } from "../repositories/refresh-token.repository";
import { AppError } from "../utils/app-error";

async function issueTokens(user: { id: string; email: string; role?: string }) {
  const accessToken = signAccessToken({
    sub: user.id,
    email: user.email,
    role: user.role ?? "USER",
  });
  const refresh = await refreshTokenRepository.create(user.id);
  return {
    accessToken,
    refreshToken: refresh.token,
    refreshExpiresAt: refresh.expiresAt,
  };
}

export const authService = {
  async register(name: string, email: string, password: string) {
    const existing = await userRepository.findByEmail(email);
    if (existing) throw new AppError("E-mail ja cadastrado", 409);

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await userRepository.create({ name, email, passwordHash });
    const tokens = await issueTokens(user);

    return { user, ...tokens, token: tokens.accessToken };
  },

  async login(email: string, password: string) {
    const user = await userRepository.findByEmail(email);
    if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
      throw new AppError("Credenciais invalidas", 401);
    }

    const tokens = await issueTokens({ id: user.id, email: user.email, role: user.role });
    return {
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
      ...tokens,
      token: tokens.accessToken,
    };
  },

  async refresh(refreshToken: string) {
    const record = await refreshTokenRepository.findValid(refreshToken);
    if (!record) throw new AppError("Refresh token invalido ou expirado", 401);

    await refreshTokenRepository.revoke(refreshToken);
    const tokens = await issueTokens({
      id: record.user.id,
      email: record.user.email,
      role: record.user.role,
    });

    return {
      user: { id: record.user.id, name: record.user.name, email: record.user.email, role: record.user.role },
      ...tokens,
      token: tokens.accessToken,
    };
  },

  async logout(refreshToken: string) {
    await refreshTokenRepository.revoke(refreshToken);
  },

  async logoutAll(userId: string) {
    await refreshTokenRepository.revokeAllForUser(userId);
  },

  async getProfile(userId: string) {
    const user = await userRepository.findById(userId);
    if (!user) throw new AppError("Usuario nao encontrado", 404);
    return user;
  },

  async updateProfile(userId: string, name: string) {
    return userRepository.updateProfile(userId, { name });
  },

  async changePassword(userId: string, currentPassword: string, newPassword: string) {
    const user = await userRepository.findByIdWithPassword(userId);
    if (!user || !(await bcrypt.compare(currentPassword, user.passwordHash))) {
      throw new AppError("Senha atual incorreta", 401);
    }

    const passwordHash = await bcrypt.hash(newPassword, 10);
    await userRepository.updatePassword(userId, passwordHash);
    await refreshTokenRepository.revokeAllForUser(userId);
  },
};
