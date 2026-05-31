import { Prisma } from "@prisma/client";
import { prisma } from "../lib/prisma";

export const classificationRepository = {
  create(data: Prisma.HealthClassificationUncheckedCreateInput) {
    return prisma.healthClassification.create({ data });
  },

  findLatestForUser(userId: string) {
    return prisma.healthClassification.findFirst({
      where: { userId },
      orderBy: { createdAt: "desc" },
    });
  },
};
