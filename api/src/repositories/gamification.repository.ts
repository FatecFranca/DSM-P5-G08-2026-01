import { Prisma } from "@prisma/client";
import { prisma } from "../lib/prisma";

export const gamificationRepository = {
  findByUserId(userId: string) {
    return prisma.gamificationProfile.findUnique({ where: { userId } });
  },

  create(data: Prisma.GamificationProfileUncheckedCreateInput) {
    return prisma.gamificationProfile.create({ data });
  },

  update(userId: string, data: Prisma.GamificationProfileUpdateInput) {
    return prisma.gamificationProfile.update({ where: { userId }, data });
  },

  getLeaderboard(limit = 10) {
    return prisma.gamificationProfile.findMany({
      take: limit,
      orderBy: { points: "desc" },
      include: { user: { select: { name: true } } },
    });
  },
};
