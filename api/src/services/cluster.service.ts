import { prisma } from "../lib/prisma";
import { clusterRepository } from "../repositories/cluster.repository";
import { classificationRepository } from "../repositories/classification.repository";
import { AppError } from "../utils/app-error";

export const clusterService = {
  async getMyCluster(userId: string) {
    const latest = await classificationRepository.findLatestForUser(userId);
    if (!latest) throw new AppError("Nenhuma classificacao encontrada. Faca uma avaliacao primeiro.", 404);

    const definition = await prisma.clusterDefinition.findUnique({
      where: { id: latest.clusterId },
    });

    return {
      clusterId: latest.clusterId,
      clusterLabel: latest.clusterLabel,
      description: definition?.description ?? null,
      profile: latest.profile,
      profileScore: latest.profileScore,
      classifiedAt: latest.createdAt,
    };
  },

  async getMyClusterStats(userId: string) {
    const latest = await classificationRepository.findLatestForUser(userId);
    if (!latest) throw new AppError("Nenhuma classificacao encontrada", 404);

    const clusterId = latest.clusterId;

    const peers = await prisma.healthClassification.findMany({
      where: { clusterId },
      include: {
        assessment: {
          select: {
            dailySteps: true,
            hoursOfSleep: true,
            exerciseHoursPerWeek: true,
            bmi: true,
          },
        },
      },
    });

    const count = peers.length;
    if (count === 0) {
      return { clusterId, peerCount: 0, averages: null, userComparison: null };
    }

    const avg = (values: number[]) =>
      Number((values.reduce((a, b) => a + b, 0) / values.length).toFixed(2));

    const userAssessment = await prisma.healthAssessment.findUnique({
      where: { id: latest.assessmentId },
    });

    const averages = {
      dailySteps: avg(peers.map((p) => p.assessment.dailySteps)),
      hoursOfSleep: avg(peers.map((p) => p.assessment.hoursOfSleep)),
      exerciseHoursPerWeek: avg(peers.map((p) => p.assessment.exerciseHoursPerWeek)),
      bmi: avg(peers.map((p) => p.assessment.bmi)),
      profileScore: avg(peers.map((p) => p.profileScore)),
    };

    const userComparison = userAssessment
      ? {
          dailySteps: { yours: userAssessment.dailySteps, clusterAvg: averages.dailySteps },
          hoursOfSleep: { yours: userAssessment.hoursOfSleep, clusterAvg: averages.hoursOfSleep },
          exerciseHoursPerWeek: {
            yours: userAssessment.exerciseHoursPerWeek,
            clusterAvg: averages.exerciseHoursPerWeek,
          },
          bmi: { yours: userAssessment.bmi, clusterAvg: averages.bmi },
        }
      : null;

    return {
      clusterId,
      clusterLabel: latest.clusterLabel,
      peerCount: count,
      averages,
      userComparison,
      disclaimer: "Dados agregados e anonimos do seu grupo de cluster.",
    };
  },

  listAll() {
    return clusterRepository.findAll();
  },
};
