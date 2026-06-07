import { prisma } from "../lib/prisma";

export const foodLogRepository = {
  findForUserOnDate(userId: string, loggedOn: string) {
    return prisma.foodLogEntry.findMany({
      where: { userId, loggedOn },
      orderBy: { createdAt: "desc" },
    });
  },

  create(data: {
    userId: string;
    description: string;
    entryType: string;
    mealPeriod?: string;
    loggedOn: string;
  }) {
    return prisma.foodLogEntry.create({ data });
  },

  findByIdForUser(id: string, userId: string) {
    return prisma.foodLogEntry.findFirst({ where: { id, userId } });
  },

  delete(id: string) {
    return prisma.foodLogEntry.delete({ where: { id } });
  },
};
