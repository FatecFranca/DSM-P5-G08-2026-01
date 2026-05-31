import { HealthProfile } from "@vitalis/shared";

export interface DayRoutine {
  day: string;
  focus: string;
  activities: string[];
}

export const WEEKLY_ROUTINES: Record<HealthProfile, DayRoutine[]> = {
  Em_Risco: [
    { day: "Segunda", focus: "Movimento leve", activities: ["Caminhada 15 min", "2L agua", "Dormir antes das 23h"] },
    { day: "Terca", focus: "Alimentacao", activities: ["Cafe com frutas", "Evitar refrigerante", "Alongamento 10 min"] },
    { day: "Quarta", focus: "Recuperacao", activities: ["Caminhada 15 min", "Reduzir telas a noite", "Refeicao caseira"] },
    { day: "Quinta", focus: "Habitos", activities: ["Pausa a cada 2h", "2L agua", "Sono 7h"] },
    { day: "Sexta", focus: "Consistencia", activities: ["Caminhada 20 min", "Almoco equilibrado", "Evitar excesso de alcool"] },
    { day: "Sabado", focus: "Descanso ativo", activities: ["Caminhada leve", "Refeicoes regulares", "Relaxamento"] },
    { day: "Domingo", focus: "Planejamento", activities: ["Preparar refeicoes da semana", "Descanso", "Meta de sono"] },
  ],
  Sedentario: [
    { day: "Segunda", focus: "Ativacao", activities: ["5 min caminhada a cada 2h", "Agua ao acordar", "Cafe com proteina"] },
    { day: "Terca", focus: "Exercicio", activities: ["20 min caminhada", "Subir escadas", "Fruta no lanche"] },
    { day: "Quarta", focus: "Movimento", activities: ["Pausas ativas", "2L agua", "Jantar leve"] },
    { day: "Quinta", focus: "Exercicio", activities: ["20 min caminhada", "Alongamento", "Evitar fast food"] },
    { day: "Sexta", focus: "Rotina", activities: ["Pausas ativas", "Refeicao balanceada", "Sono regular"] },
    { day: "Sabado", focus: "Atividade", activities: ["30 min caminhada", "Atividade ao ar livre", "Hidratacao"] },
    { day: "Domingo", focus: "Descanso", activities: ["Caminhada leve", "Planejar semana", "7h sono"] },
  ],
  Moderado: [
    { day: "Segunda", focus: "Treino", activities: ["30 min exercicio", "2L agua", "Refeicoes regulares"] },
    { day: "Terca", focus: "Recuperacao", activities: ["Alongamento 15 min", "Vegetais no almoco", "Sono 7h"] },
    { day: "Quarta", focus: "Treino", activities: ["30 min exercicio", "Hidratacao", "Evitar telas a noite"] },
    { day: "Quinta", focus: "Ativo", activities: ["Caminhada 30 min", "Prato equilibrado", "Agua constante"] },
    { day: "Sexta", focus: "Treino", activities: ["30 min exercicio", "Refeicao pos-treino", "Descanso"] },
    { day: "Sabado", focus: "Lazer ativo", activities: ["Esporte ou caminhada", "Alimentacao consciente", "Relaxamento"] },
    { day: "Domingo", focus: "Regeneracao", activities: ["Atividade leve", "Preparo semanal", "Sono de qualidade"] },
  ],
  Saudavel_Ativo: [
    { day: "Segunda", focus: "Forca", activities: ["Treino forca 45 min", "Proteina pos-treino", "2.5L agua"] },
    { day: "Terca", focus: "Cardio", activities: ["Cardio 30 min", "Refeicoes integrais", "Recuperacao"] },
    { day: "Quarta", focus: "Forca", activities: ["Treino forca 45 min", "Hidratacao esportiva", "Sono 8h"] },
    { day: "Quinta", focus: "Cardio leve", activities: ["Caminhada ou bike 30 min", "Alimentacao balanceada", "Mobilidade"] },
    { day: "Sexta", focus: "Forca", activities: ["Treino forca 45 min", "Refeicao pos-treino", "Descanso"] },
    { day: "Sabado", focus: "Esporte", activities: ["Atividade preferida 60 min", "Refeicoes regulares", "Recuperacao"] },
    { day: "Domingo", focus: "Regeneracao", activities: ["Yoga ou caminhada", "Preparo nutricional", "Descanso completo"] },
  ],
};
