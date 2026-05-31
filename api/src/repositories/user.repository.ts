import { prisma } from "../lib/prisma";

export const userRepository = {
  findByEmail(email: string) {
    return prisma.user.findUnique({ where: { email: email.toLowerCase() } });
  },

  findById(id: string) {
    return prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        createdAt: true,
        gamification: true,
      },
    });
  },

  findByIdWithPassword(id: string) {
    return prisma.user.findUnique({ where: { id } });
  },

  create(data: { name: string; email: string; passwordHash: string; role?: "USER" | "ADMIN" }) {
    return prisma.user.create({
      data: {
        name: data.name,
        email: data.email.toLowerCase(),
        passwordHash: data.passwordHash,
        role: data.role ?? "USER",
        gamification: { create: {} },
      },
      select: { id: true, name: true, email: true, role: true, createdAt: true },
    });
  },

  updateProfile(id: string, data: { name?: string }) {
    return prisma.user.update({
      where: { id },
      select: { id: true, name: true, email: true, role: true, createdAt: true },
      data,
    });
  },

  updatePassword(id: string, passwordHash: string) {
    return prisma.user.update({ where: { id }, data: { passwordHash } });
  },
};
