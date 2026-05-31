import { prisma } from "../lib/prisma";

export const achievementRepository = {
  findAll() {
    return prisma.achievement.findMany({ orderBy: { code: "asc" } });
  },

  findByCode(code: string) {
    return prisma.achievement.findUnique({ where: { code } });
  },

  findUserAchievements(userId: string) {
    return prisma.userAchievement.findMany({
      where: { userId },
      include: { achievement: true },
      orderBy: { unlockedAt: "desc" },
    });
  },

  async unlock(userId: string, achievementId: string) {
    const existing = await prisma.userAchievement.findUnique({
      where: { userId_achievementId: { userId, achievementId } },
    });
    if (existing) return existing;

    return prisma.userAchievement.create({
      data: { userId, achievementId },
      include: { achievement: true },
    });
  },
};
