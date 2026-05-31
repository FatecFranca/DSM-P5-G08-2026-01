import { Prisma } from "@prisma/client";
import { prisma } from "../lib/prisma";

export const reminderRepository = {
  findAllForUser(userId: string) {
    return prisma.reminder.findMany({
      where: { userId },
      orderBy: { timeOfDay: "asc" },
    });
  },

  findActiveForUser(userId: string) {
    return prisma.reminder.findMany({
      where: { userId, isActive: true },
      orderBy: { timeOfDay: "asc" },
    });
  },

  findByIdForUser(id: string, userId: string) {
    return prisma.reminder.findFirst({ where: { id, userId } });
  },

  create(data: Prisma.ReminderUncheckedCreateInput) {
    return prisma.reminder.create({ data });
  },

  update(id: string, data: Prisma.ReminderUpdateInput) {
    return prisma.reminder.update({ where: { id }, data });
  },

  delete(id: string) {
    return prisma.reminder.delete({ where: { id } });
  },

  replaceDefaults(
    userId: string,
    items: Array<{
      type: Prisma.ReminderCreateManyInput["type"];
      title: string;
      message: string;
      timeOfDay: string;
    }>,
  ) {
    return prisma.$transaction([
      prisma.reminder.deleteMany({ where: { userId } }),
      prisma.reminder.createMany({
        data: items.map((item) => ({ userId, ...item })),
      }),
    ]);
  },
};
