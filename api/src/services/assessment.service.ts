import { HealthProfile } from "@vitalis/shared";
import { DEFAULT_REMINDERS, GAMIFICATION } from "../domain/constants";
import { MEAL_PLANS } from "../domain/meal-plan";
import { WEEKLY_ROUTINES } from "../domain/weekly-routine";
import { assessmentRepository } from "../repositories/assessment.repository";
import { classificationRepository } from "../repositories/classification.repository";
import { gamificationRepository } from "../repositories/gamification.repository";
import { recommendationRepository } from "../repositories/recommendation.repository";
import { reminderRepository } from "../repositories/reminder.repository";
import { reminderCompletionRepository } from "../repositories/reminder-completion.repository";
import { mealPlanRepository } from "../repositories/meal-plan.repository";
import { prisma } from "../lib/prisma";
import { Prisma } from "@prisma/client";
import { AppError } from "../utils/app-error";
import { AssessmentInput } from "../schemas";
import { calculateBmi, classificationService, parseExplanation } from "./classification.service";
import { achievementService } from "./achievement.service";
import { geminiService } from "./gemini.service";
import { userRepository } from "../repositories/user.repository";

function computeLevel(points: number): number {
  return Math.floor(points / GAMIFICATION.POINTS_PER_LEVEL) + 1;
}

export const gamificationService = {
  async awardAssessmentPoints(userId: string, isFirstAssessment: boolean) {
    const profile = await gamificationRepository.findByUserId(userId);
    const pointsToAdd = GAMIFICATION.POINTS_ASSESSMENT;

    if (!profile) {
      return gamificationRepository.create({
        userId,
        points: pointsToAdd,
        level: 1,
        currentStreak: 1,
        longestStreak: 1,
        lastActiveAt: new Date(),
        badges: isFirstAssessment ? [GAMIFICATION.BADGE_FIRST_ASSESSMENT] : [],
      });
    }

    const newPoints = profile.points + pointsToAdd;
    const badges = Array.isArray(profile.badges) ? [...(profile.badges as string[])] : [];
    if (isFirstAssessment && !badges.includes(GAMIFICATION.BADGE_FIRST_ASSESSMENT)) {
      badges.push(GAMIFICATION.BADGE_FIRST_ASSESSMENT);
    }

    return gamificationRepository.update(userId, {
      points: newPoints,
      level: computeLevel(newPoints),
      lastActiveAt: new Date(),
      badges,
    });
  },

  async completeReminder(userId: string, reminderId: string) {
    const profile = await gamificationRepository.findByUserId(userId);
    if (!profile) throw new AppError("Perfil de gamificacao nao encontrado", 404);

    const alreadyDone = await reminderCompletionRepository.isCompletedToday(reminderId);
    if (alreadyDone) {
      throw new AppError("Lembrete ja concluido hoje", 409);
    }

    await reminderCompletionRepository.markComplete(reminderId, userId);

    const newPoints = profile.points + GAMIFICATION.POINTS_REMINDER_COMPLETE;
    const today = new Date();
    let currentStreak = profile.currentStreak;

    const startOfDay = (date: Date) =>
      new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();

    if (profile.lastActiveAt) {
      const diffDays = Math.round(
        (startOfDay(today) - startOfDay(profile.lastActiveAt)) / (1000 * 60 * 60 * 24),
      );
      if (diffDays === 0) {
        // Ja ativo hoje: mantem a sequencia (evita inflar com varios lembretes)
        currentStreak = Math.max(currentStreak, 1);
      } else if (diffDays === 1) {
        currentStreak += 1;
      } else {
        currentStreak = 1;
      }
    } else {
      currentStreak = 1;
    }

    const longestStreak = Math.max(profile.longestStreak, currentStreak);
    const badges = Array.isArray(profile.badges) ? [...(profile.badges as string[])] : [];

    if (currentStreak >= 7 && !badges.includes(GAMIFICATION.BADGE_STREAK_7)) {
      badges.push(GAMIFICATION.BADGE_STREAK_7);
    }
    if (currentStreak >= 30 && !badges.includes(GAMIFICATION.BADGE_STREAK_30)) {
      badges.push(GAMIFICATION.BADGE_STREAK_30);
    }

    const updated = await gamificationRepository.update(userId, {
      points: newPoints,
      level: computeLevel(newPoints),
      currentStreak,
      longestStreak,
      lastActiveAt: today,
      badges,
    });

    const newAchievements = await achievementService.checkAndUnlock(userId);

    return {
      gamification: updated,
      pointsEarned: GAMIFICATION.POINTS_REMINDER_COMPLETE,
      newAchievements,
    };
  },

  async getProfile(userId: string) {
    const profile = await gamificationRepository.findByUserId(userId);
    if (!profile) throw new AppError("Perfil de gamificacao nao encontrado", 404);

    const latestClassification = await classificationRepository.findLatestForUser(userId);

    return {
      gamification: profile,
      latestProfile: latestClassification?.profile ?? null,
      pointsToNextLevel: Math.max(profile.level * GAMIFICATION.POINTS_PER_LEVEL - profile.points, 0),
    };
  },

  async getLeaderboard() {
    const top = await gamificationRepository.getLeaderboard(10);
    return top.map((entry, index) => ({
      rank: index + 1,
      name: entry.user.name,
      points: entry.points,
      level: entry.level,
      currentStreak: entry.currentStreak,
    }));
  },
};

export const recommendationService = {
  async assignForProfile(userId: string, profile: HealthProfile) {
    const templates = await recommendationRepository.findActiveTemplatesByProfile(profile);
    await recommendationRepository.replaceUserRecommendations(
      userId,
      templates.map((t) => t.id),
    );
    return templates.length;
  },

  async listForUser(userId: string) {
    return recommendationRepository.findActiveForUser(userId);
  },

  async listGroupedByCategory(userId: string) {
    const recommendations = await recommendationRepository.findActiveForUser(userId);
    return recommendations.reduce<Record<string, typeof recommendations>>((acc, item) => {
      const key = item.template.category;
      if (!acc[key]) acc[key] = [];
      acc[key].push(item);
      return acc;
    }, {});
  },

  async toggle(userId: string, recommendationId: string, isActive: boolean) {
    const result = await recommendationRepository.toggleForUser(userId, recommendationId, isActive);
    if (result.count === 0) throw new AppError("Recomendacao nao encontrada", 404);
  },

  async getMealPlan(userId: string) {
    const latest = await classificationRepository.findLatestForUser(userId);
    if (!latest) throw new AppError("Faca uma avaliacao primeiro", 404);

    const cached = await mealPlanRepository.findLatestForUser(userId);
    if (cached && cached.profile === latest.profile) {
      return {
        profile: latest.profile,
        meals: cached.meals,
        source: cached.source,
        disclaimer:
          "Sugestoes gerais de alimentacao. Nao substitui orientacao de nutricionista ou medico.",
      };
    }

    return {
      profile: latest.profile,
      meals: MEAL_PLANS[latest.profile as HealthProfile],
      source: "static",
      disclaimer:
        "Sugestoes gerais de alimentacao. Nao substitui orientacao de nutricionista ou medico.",
    };
  },

  async generateAndCacheMealPlan(
    userId: string,
    profile: HealthProfile,
    profileScore: number,
    caloriesIntake?: number,
  ) {
    const user = await userRepository.findById(userId);
    let meals = await geminiService.generateMealPlan({
      profile,
      profileScore,
      caloriesIntake,
      userName: user?.name,
    });
    const source = meals ? "gemini" : "static";
    if (!meals) meals = MEAL_PLANS[profile];

    await mealPlanRepository.create({
      userId,
      profile,
      meals: meals as unknown as Prisma.InputJsonValue,
      source,
    });

    return { meals, source };
  },

  async getWeeklyRoutine(userId: string) {
    const latest = await classificationRepository.findLatestForUser(userId);
    if (!latest) throw new AppError("Faca uma avaliacao primeiro", 404);
    return {
      profile: latest.profile,
      week: WEEKLY_ROUTINES[latest.profile],
    };
  },
};

export const reminderService = {
  async assignDefaults(userId: string, profile: HealthProfile) {
    const items = DEFAULT_REMINDERS[profile];
    await reminderRepository.replaceDefaults(userId, items);
    return items.length;
  },

  async listForUser(userId: string) {
    return reminderRepository.findAllForUser(userId);
  },

  async listToday(userId: string) {
    const [reminders, completions] = await Promise.all([
      reminderRepository.findActiveForUser(userId),
      reminderCompletionRepository.findTodayForUser(userId),
    ]);

    const completedIds = new Set(completions.map((c) => c.reminderId));

    return reminders.map((r) => ({
      ...r,
      completedToday: completedIds.has(r.id),
    }));
  },

  async create(
    userId: string,
    data: {
      type: "WATER" | "MEAL" | "SLEEP" | "EXERCISE";
      title: string;
      message?: string;
      timeOfDay: string;
      frequency?: "DAILY" | "WEEKLY";
      isActive?: boolean;
    },
  ) {
    return reminderRepository.create({ userId, ...data });
  },

  async update(userId: string, id: string, data: Record<string, unknown>) {
    const existing = await reminderRepository.findByIdForUser(id, userId);
    if (!existing) throw new AppError("Lembrete nao encontrado", 404);
    return reminderRepository.update(id, data);
  },

  async delete(userId: string, id: string) {
    const existing = await reminderRepository.findByIdForUser(id, userId);
    if (!existing) throw new AppError("Lembrete nao encontrado", 404);
    await reminderRepository.delete(id);
  },
};

export const assessmentService = {
  async submit(userId: string, input: AssessmentInput) {
    const bmi = calculateBmi(input.heightCm, input.weightKg);
    const previousCount = await assessmentRepository.countForUser(userId);
    const isFirstAssessment = previousCount === 0;

    const classification = await classificationService.classify(input);

    if (geminiService.isEnabled()) {
      const user = await userRepository.findById(userId);
      const geminiText = await geminiService.enrichExplanation({
        profile: classification.profile,
        profileScore: classification.profileScore,
        confidence: classification.confidence,
        modelVersion: classification.modelVersion,
        factors: classification.explanationPayload.factors,
        userName: user?.name,
      });
      if (geminiText) {
        classification.explanationPayload.geminiSummary = geminiText;
        classification.explanationPayload.messages = [geminiText, ...classification.explanationPayload.messages];
      }
    }

    const result = await prisma.$transaction(async (tx) => {
      const assessment = await tx.healthAssessment.create({
        data: {
          userId,
          age: input.age,
          gender: input.gender,
          heightCm: input.heightCm,
          weightKg: input.weightKg,
          bmi,
          dailySteps: input.dailySteps,
          caloriesIntake: input.caloriesIntake,
          hoursOfSleep: input.hoursOfSleep,
          heartRate: input.heartRate,
          bloodPressureSystolic: input.bloodPressureSystolic,
          bloodPressureDiastolic: input.bloodPressureDiastolic,
          exerciseHoursPerWeek: input.exerciseHoursPerWeek,
          smoker: input.smoker,
          alcoholPerWeek: input.alcoholPerWeek,
          diabetic: input.diabetic,
          heartDisease: input.heartDisease,
        },
      });

      const healthClassification = await tx.healthClassification.create({
        data: {
          userId,
          assessmentId: assessment.id,
          profile: classification.profile,
          profileScore: classification.profileScore,
          clusterId: classification.clusterId,
          clusterLabel: classification.clusterLabel,
          explanation: classification.explanationPayload as unknown as Prisma.InputJsonValue,
          confidence: classification.confidence,
          modelVersion: classification.modelVersion,
        },
      });

      return { assessment, classification: healthClassification };
    });

    await recommendationService.assignForProfile(userId, classification.profile);
    await reminderService.assignDefaults(userId, classification.profile);
    await recommendationService
      .generateAndCacheMealPlan(
        userId,
        classification.profile,
        classification.profileScore,
        input.caloriesIntake,
      )
      .catch((error) => console.warn("[meal-plan] Falha ao gerar cardapio:", error));
    await gamificationService.awardAssessmentPoints(userId, isFirstAssessment);
    const newAchievements = await achievementService.checkAndUnlock(userId);

    const [recommendations, reminders, gamification] = await Promise.all([
      recommendationService.listForUser(userId),
      reminderRepository.findActiveForUser(userId),
      gamificationRepository.findByUserId(userId),
    ]);

    return {
      ...result,
      plan: {
        recommendationsCount: recommendations.length,
        remindersCount: reminders.length,
        profile: classification.profile,
        profileScore: classification.profileScore,
        clusterLabel: classification.clusterLabel,
      },
      explanation: classification.explanationPayload,
      gamification,
      newAchievements,
    };
  },

  async listForUser(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [assessments, total] = await Promise.all([
      assessmentRepository.findAllForUser(userId, skip, limit),
      assessmentRepository.countForUser(userId),
    ]);
    return { assessments, pagination: { page, limit, total, pages: Math.ceil(total / limit) } };
  },

  async getEvolution(userId: string) {
    const points = await assessmentRepository.findEvolutionForUser(userId);
    return {
      evolution: points.map((p) => ({
        id: p.id,
        date: p.createdAt,
        profile: p.classification?.profile ?? null,
        profileScore: p.classification?.profileScore ?? null,
        clusterLabel: p.classification?.clusterLabel ?? null,
        bmi: p.bmi,
        dailySteps: p.dailySteps,
        hoursOfSleep: p.hoursOfSleep,
      })),
    };
  },

  async compare(userId: string, fromId: string, toId: string) {
    const [from, to] = await Promise.all([
      assessmentRepository.findByIdForUser(fromId, userId),
      assessmentRepository.findByIdForUser(toId, userId),
    ]);

    if (!from || !to) throw new AppError("Avaliacao nao encontrada", 404);

    return {
      from: { id: from.id, date: from.createdAt, classification: from.classification, metrics: from },
      to: { id: to.id, date: to.createdAt, classification: to.classification, metrics: to },
      diff: {
        bmi: Number((to.bmi - from.bmi).toFixed(2)),
        dailySteps: to.dailySteps - from.dailySteps,
        hoursOfSleep: Number((to.hoursOfSleep - from.hoursOfSleep).toFixed(2)),
        profileScore:
          (to.classification?.profileScore ?? 0) - (from.classification?.profileScore ?? 0),
      },
    };
  },

  async getExplanation(userId: string, id: string) {
    const assessment = await assessmentRepository.findByIdForUser(id, userId);
    if (!assessment?.classification) throw new AppError("Avaliacao nao encontrada", 404);

    const explanation = parseExplanation(assessment.classification.explanation);

    return {
      assessmentId: id,
      profile: assessment.classification.profile,
      profileScore: assessment.classification.profileScore,
      modelVersion: assessment.classification.modelVersion,
      confidence: assessment.classification.confidence,
      explanation,
    };
  },

  async getLatest(userId: string) {
    const assessment = await assessmentRepository.findLatestForUser(userId);
    if (!assessment) throw new AppError("Nenhuma avaliacao encontrada", 404);
    return assessment;
  },

  async getById(userId: string, id: string) {
    const assessment = await assessmentRepository.findByIdForUser(id, userId);
    if (!assessment) throw new AppError("Avaliacao nao encontrada", 404);
    return assessment;
  },
};
