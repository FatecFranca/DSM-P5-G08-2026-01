import { prisma } from "../lib/prisma";

export const reminderCompletionRepository = {
  todayDateString(): string {
    return new Date().toISOString().slice(0, 10);
  },

  async findTodayForUser(userId: string) {
    const today = this.todayDateString();
    return prisma.reminderCompletion.findMany({
      where: { userId, completedOn: today },
    });
  },

  async markComplete(reminderId: string, userId: string) {
    const completedOn = this.todayDateString();
    return prisma.reminderCompletion.upsert({
      where: { reminderId_completedOn: { reminderId, completedOn } },
      create: { reminderId, userId, completedOn },
      update: { completedAt: new Date() },
    });
  },

  async isCompletedToday(reminderId: string): Promise<boolean> {
    const today = this.todayDateString();
    const record = await prisma.reminderCompletion.findUnique({
      where: { reminderId_completedOn: { reminderId, completedOn: today } },
    });
    return !!record;
  },

  countForUser(userId: string) {
    return prisma.reminderCompletion.count({ where: { userId } });
  },
};
