import { foodLogRepository } from "../repositories/food-log.repository";
import { AppError } from "../utils/app-error";

function todayIsoDate(): string {
  return new Date().toISOString().slice(0, 10);
}

export const foodLogService = {
  listToday(userId: string, date?: string) {
    return foodLogRepository.findForUserOnDate(userId, date ?? todayIsoDate());
  },

  create(
    userId: string,
    data: {
      description: string;
      entryType?: string;
      mealPeriod?: string;
      loggedOn?: string;
    },
  ) {
    const description = data.description.trim();
    if (description.length < 2) {
      throw new AppError("Descreva o que comeu ou bebeu", 400);
    }
    return foodLogRepository.create({
      userId,
      description,
      entryType: data.entryType ?? "food",
      mealPeriod: data.mealPeriod,
      loggedOn: data.loggedOn ?? todayIsoDate(),
    });
  },

  async remove(userId: string, id: string) {
    const existing = await foodLogRepository.findByIdForUser(id, userId);
    if (!existing) throw new AppError("Registro nao encontrado", 404);
    await foodLogRepository.delete(id);
  },
};
