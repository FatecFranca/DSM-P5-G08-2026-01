import { prisma } from "../lib/prisma";

export const assessmentRepository = {
  create(data: Parameters<typeof prisma.healthAssessment.create>[0]["data"]) {
    return prisma.healthAssessment.create({ data });
  },

  findByIdForUser(id: string, userId: string) {
    return prisma.healthAssessment.findFirst({
      where: { id, userId },
      include: { classification: true },
    });
  },

  findLatestForUser(userId: string) {
    return prisma.healthAssessment.findFirst({
      where: { userId },
      orderBy: { createdAt: "desc" },
      include: { classification: true },
    });
  },

  findAllForUser(userId: string, skip = 0, take = 20) {
    return prisma.healthAssessment.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
      skip,
      take,
      include: { classification: true },
    });
  },

  countForUser(userId: string) {
    return prisma.healthAssessment.count({ where: { userId } });
  },

  findEvolutionForUser(userId: string) {
    return prisma.healthAssessment.findMany({
      where: { userId },
      orderBy: { createdAt: "asc" },
      select: {
        id: true,
        createdAt: true,
        bmi: true,
        dailySteps: true,
        hoursOfSleep: true,
        classification: {
          select: {
            profile: true,
            profileScore: true,
            clusterLabel: true,
          },
        },
      },
    });
  },
};
