import { HealthProfile, ReminderType } from "@vitalis/shared";

export const GAMIFICATION = {
  POINTS_ASSESSMENT: 50,
  POINTS_REMINDER_COMPLETE: 10,
  POINTS_PER_LEVEL: 100,
  BADGE_FIRST_ASSESSMENT: "first_assessment",
  BADGE_STREAK_7: "streak_7",
  BADGE_STREAK_30: "streak_30",
} as const;

export const PROFILE_SCORES: Record<HealthProfile, number> = {
  Em_Risco: 25,
  Sedentario: 45,
  Moderado: 65,
  Saudavel_Ativo: 90,
};

export const CLUSTER_LABELS: Record<number, string> = {
  0: "Grupo Ativo e Regulado",
  1: "Grupo Sedentario",
  2: "Grupo Moderado Misto",
  3: "Grupo de Atencao Clinica",
};

export const DEFAULT_REMINDERS: Record<
  HealthProfile,
  Array<{ type: ReminderType; title: string; message: string; timeOfDay: string }>
> = {
  Em_Risco: [
    { type: "WATER", title: "Hidratacao", message: "Beba um copo de agua agora", timeOfDay: "09:00" },
    { type: "SLEEP", title: "Rotina de sono", message: "Prepare-se para dormir em 30 minutos", timeOfDay: "22:00" },
    { type: "EXERCISE", title: "Caminhada leve", message: "Faca uma caminhada de 15 minutos", timeOfDay: "18:00" },
  ],
  Sedentario: [
    { type: "WATER", title: "Agua", message: "Meta: 2 litros por dia. Beba agora.", timeOfDay: "10:00" },
    { type: "EXERCISE", title: "Movimento", message: "Levante e caminhe 5 minutos", timeOfDay: "15:00" },
    { type: "MEAL", title: "Refeicao equilibrada", message: "Inclua proteina e vegetais no almoco", timeOfDay: "12:00" },
  ],
  Moderado: [
    { type: "WATER", title: "Hidratacao", message: "Mantenha a ingestao de agua regular", timeOfDay: "11:00" },
    { type: "EXERCISE", title: "Atividade fisica", message: "Reserve 30 minutos para exercicio", timeOfDay: "07:00" },
  ],
  Saudavel_Ativo: [
    { type: "WATER", title: "Hidratacao pos-treino", message: "Reponha liquidos apos atividade", timeOfDay: "08:00" },
    { type: "MEAL", title: "Refeicao pos-treino", message: "Consuma proteina e carboidrato de qualidade", timeOfDay: "19:00" },
  ],
};

export const MEDICAL_DISCLAIMER =
  "Este sistema nao realiza diagnostico medico. Apenas classifica perfil de habitos e estilo de vida.";
