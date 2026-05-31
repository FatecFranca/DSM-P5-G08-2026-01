import { HealthProfile } from "@vitalis/shared";
import { prisma } from "../lib/prisma";

export const recommendationRepository = {
  findActiveTemplatesByProfile(profile: HealthProfile) {
    return prisma.recommendationTemplate.findMany({
      where: { profile, isActive: true },
      orderBy: { priority: "asc" },
    });
  },

  replaceUserRecommendations(userId: string, templateIds: string[]) {
    return prisma.$transaction([
      prisma.userRecommendation.deleteMany({ where: { userId } }),
      ...(templateIds.length > 0
        ? [
            prisma.userRecommendation.createMany({
              data: templateIds.map((templateId) => ({ userId, templateId })),
            }),
          ]
        : []),
    ]);
  },

  findActiveForUser(userId: string) {
    return prisma.userRecommendation.findMany({
      where: { userId, isActive: true },
      include: { template: true },
      orderBy: { template: { priority: "asc" } },
    });
  },

  toggleForUser(userId: string, recommendationId: string, isActive: boolean) {
    return prisma.userRecommendation.updateMany({
      where: { id: recommendationId, userId },
      data: { isActive },
    });
  },
};
