import { HealthProfile, Prisma } from "@prisma/client";
import { prisma } from "../lib/prisma";

export const mealPlanRepository = {
  findLatestForUser(userId: string) {
    return prisma.mealPlanCache.findFirst({
      where: { userId },
      orderBy: { createdAt: "desc" },
    });
  },

  create(data: {
    userId: string;
    profile: HealthProfile;
    meals: Prisma.InputJsonValue;
    source: string;
  }) {
    return prisma.mealPlanCache.create({ data });
  },
};
