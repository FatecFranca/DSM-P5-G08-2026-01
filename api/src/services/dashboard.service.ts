import { MEDICAL_DISCLAIMER } from "../domain/constants";
import { HEALTH_PROFILES, QUESTIONNAIRE_SECTIONS } from "../domain/questionnaire";
import { prisma } from "../lib/prisma";
import { clusterRepository } from "../repositories/cluster.repository";
import { classificationService, parseExplanation } from "./classification.service";

export const healthService = {
  getStatus() {
    return { status: "ok", service: "vitalis-api", version: "0.2.0" };
  },

  async getReady() {
    try {
      await prisma.$queryRaw`SELECT 1`;
      const ml = await classificationService.checkMlHealth();
      return { status: "ready", database: "connected", ml };
    } catch {
      return { status: "not_ready", database: "disconnected" };
    }
  },

  getQuestionnaire() {
    return {
      disclaimer: MEDICAL_DISCLAIMER,
      sections: QUESTIONNAIRE_SECTIONS,
      profiles: HEALTH_PROFILES,
    };
  },

  getClusters() {
    return clusterRepository.findAll();
  },
};

export const dashboardService = {
  async getUserDashboard(userId: string) {
    const { assessmentRepository } = await import("../repositories/assessment.repository");
    const { gamificationRepository } = await import("../repositories/gamification.repository");
    const { recommendationRepository } = await import("../repositories/recommendation.repository");
    const { reminderService } = await import("./assessment.service");

    const [latestAssessment, gamification, recommendations, remindersToday, assessmentCount] =
      await Promise.all([
        assessmentRepository.findLatestForUser(userId),
        gamificationRepository.findByUserId(userId),
        recommendationRepository.findActiveForUser(userId),
        reminderService.listToday(userId),
        assessmentRepository.countForUser(userId),
      ]);

    return {
      hasAssessment: assessmentCount > 0,
      assessmentCount,
      latestAssessment,
      gamification,
      recommendations,
      remindersToday,
      summary: latestAssessment?.classification
        ? {
            profile: latestAssessment.classification.profile,
            profileScore: latestAssessment.classification.profileScore,
            clusterLabel: latestAssessment.classification.clusterLabel,
            explanation: parseExplanation(latestAssessment.classification.explanation).messages,
          }
        : null,
    };
  },

  async getSystemStats() {
    const [users, assessments, classifications, activeReminders] = await Promise.all([
      prisma.user.count(),
      prisma.healthAssessment.count(),
      prisma.healthClassification.groupBy({
        by: ["profile"],
        _count: { profile: true },
      }),
      prisma.reminder.count({ where: { isActive: true } }),
    ]);

    return {
      users,
      assessments,
      profileDistribution: classifications.map((c) => ({
        profile: c.profile,
        count: c._count.profile,
      })),
      activeReminders,
    };
  },

  async listUsers(page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [users, total] = await Promise.all([
      prisma.user.findMany({
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        select: {
          id: true,
          name: true,
          email: true,
          role: true,
          createdAt: true,
          _count: { select: { assessments: true } },
        },
      }),
      prisma.user.count(),
    ]);
    return { users, pagination: { page, limit, total } };
  },
};
