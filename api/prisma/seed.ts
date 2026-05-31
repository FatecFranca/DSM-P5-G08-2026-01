import { PrismaClient, HealthProfile, RecommendationCategory } from "@prisma/client";

const prisma = new PrismaClient();

const CLUSTER_DEFINITIONS = [
  { id: 0, label: "Grupo Ativo e Regulado", description: "Alta atividade, sono adequado e baixo risco." },
  { id: 1, label: "Grupo Sedentario", description: "Baixa movimentacao e rotina pouco ativa." },
  { id: 2, label: "Grupo Moderado Misto", description: "Habitos intermediarios com margem de melhoria." },
  { id: 3, label: "Grupo de Atencao Clinica", description: "Combinacao de fatores de risco relevantes." },
];

const RECOMMENDATION_TEMPLATES: Array<{
  profile: HealthProfile;
  category: RecommendationCategory;
  title: string;
  description: string;
  priority: number;
}> = [
  { profile: "Em_Risco", category: "ROUTINE", title: "Rotina de recuperacao", description: "Meta de 7h de sono com horarios fixos.", priority: 1 },
  { profile: "Em_Risco", category: "EXERCISE", title: "Caminhada leve diaria", description: "15 minutos, 5 dias por semana.", priority: 2 },
  { profile: "Em_Risco", category: "DIET", title: "Reducao de ultraprocessados", description: "Substitua 1 refeicao rapida por caseira.", priority: 3 },
  { profile: "Em_Risco", category: "HYDRATION", title: "Meta de hidratacao", description: "2 litros de agua por dia.", priority: 4 },
  { profile: "Sedentario", category: "EXERCISE", title: "Movimento a cada 2h", description: "Pausas ativas de 5 minutos.", priority: 1 },
  { profile: "Sedentario", category: "DIET", title: "Cafe da manha com proteina", description: "Ovos, iogurte ou leguminosas.", priority: 2 },
  { profile: "Sedentario", category: "HYDRATION", title: "Agua antes das refeicoes", description: "1 copo 30 min antes de comer.", priority: 3 },
  { profile: "Moderado", category: "ROUTINE", title: "Consistencia semanal", description: "3 dias de exercicio e 7h de sono.", priority: 1 },
  { profile: "Moderado", category: "DIET", title: "Prato equilibrado", description: "Metade vegetais, 1/4 proteina, 1/4 carboidrato.", priority: 2 },
  { profile: "Moderado", category: "SLEEP", title: "Higiene do sono", description: "Evite telas 1h antes de dormir.", priority: 3 },
  { profile: "Saudavel_Ativo", category: "EXERCISE", title: "Periodizacao leve", description: "Alterne forca e cardio.", priority: 1 },
  { profile: "Saudavel_Ativo", category: "DIET", title: "Manutencao nutricional", description: "Alimentos integrais e refeicoes regulares.", priority: 2 },
  { profile: "Saudavel_Ativo", category: "HYDRATION", title: "Hidratacao esportiva", description: "Ajuste agua conforme treino.", priority: 3 },
];

const ACHIEVEMENTS = [
  { code: "first_assessment", title: "Primeiro Passo", description: "Complete sua primeira avaliacao de habitos.", pointsReward: 25 },
  { code: "three_assessments", title: "Em Evolucao", description: "Realize 3 avaliacoes de habitos.", pointsReward: 50 },
  { code: "ten_reminders", title: "Consistente", description: "Conclua 10 lembretes.", pointsReward: 30 },
  { code: "streak_7", title: "Semana Foco", description: "Mantenha streak de 7 dias.", pointsReward: 70 },
  { code: "level_5", title: "Nivel 5", description: "Alcance o nivel 5 de gamificacao.", pointsReward: 100 },
];

async function main() {
  for (const cluster of CLUSTER_DEFINITIONS) {
    await prisma.clusterDefinition.upsert({ where: { id: cluster.id }, update: cluster, create: cluster });
  }

  for (const template of RECOMMENDATION_TEMPLATES) {
    const existing = await prisma.recommendationTemplate.findFirst({
      where: { profile: template.profile, category: template.category, title: template.title },
    });
    if (!existing) await prisma.recommendationTemplate.create({ data: template });
  }

  for (const achievement of ACHIEVEMENTS) {
    await prisma.achievement.upsert({
      where: { code: achievement.code },
      update: achievement,
      create: achievement,
    });
  }

  console.log("Seed concluido.");
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
