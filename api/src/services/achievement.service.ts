import { achievementRepository } from "../repositories/achievement.repository";
import { assessmentRepository } from "../repositories/assessment.repository";
import { gamificationRepository } from "../repositories/gamification.repository";
import { reminderCompletionRepository } from "../repositories/reminder-completion.repository";
import { prisma } from "../lib/prisma";
import { GAMIFICATION } from "../domain/constants";

export const achievementService = {
  async checkAndUnlock(userId: string) {
    const unlocked: string[] = [];

    const [assessmentCount, reminderCount, gamification] = await Promise.all([
      assessmentRepository.countForUser(userId),
      reminderCompletionRepository.countForUser(userId),
      gamificationRepository.findByUserId(userId),
    ]);

    const checks: Array<{ code: string; condition: boolean }> = [
      { code: "first_assessment", condition: assessmentCount >= 1 },
      { code: "three_assessments", condition: assessmentCount >= 3 },
      { code: "ten_reminders", condition: reminderCount >= 10 },
      { code: "streak_7", condition: (gamification?.currentStreak ?? 0) >= 7 },
      { code: "level_5", condition: (gamification?.level ?? 0) >= 5 },
    ];

    for (const check of checks) {
      if (!check.condition) continue;
      const achievement = await achievementRepository.findByCode(check.code);
      if (!achievement) continue;

      const existing = await prisma.userAchievement.findUnique({
        where: { userId_achievementId: { userId, achievementId: achievement.id } },
      });
      if (existing) continue;

      await achievementRepository.unlock(userId, achievement.id);
      unlocked.push(achievement.code);

      if (achievement.pointsReward > 0) {
        const current = await gamificationRepository.findByUserId(userId);
        if (current) {
          const newPoints = current.points + achievement.pointsReward;
          await gamificationRepository.update(userId, {
            points: newPoints,
            level: Math.floor(newPoints / GAMIFICATION.POINTS_PER_LEVEL) + 1,
          });
        }
      }
    }

    return unlocked;
  },

  async listForUser(userId: string) {
    const [all, userAchievements] = await Promise.all([
      achievementRepository.findAll(),
      achievementRepository.findUserAchievements(userId),
    ]);

    const unlockedIds = new Set(userAchievements.map((u) => u.achievementId));

    return {
      achievements: all.map((a) => ({
        ...a,
        unlocked: unlockedIds.has(a.id),
        unlockedAt: userAchievements.find((u) => u.achievementId === a.id)?.unlockedAt ?? null,
      })),
      unlockedCount: userAchievements.length,
      totalCount: all.length,
    };
  },
};
