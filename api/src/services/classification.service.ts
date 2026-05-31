import {
  ClassificationResult,
  HealthAssessmentInput,
  HealthProfile,
} from "@vitalis/shared";
import { env } from "../config/env";
import { CLUSTER_LABELS, PROFILE_SCORES } from "../domain/constants";

export interface ExplanationFactor {
  factor: string;
  impact: "positive" | "negative" | "neutral";
  weight: number;
  detail: string;
}

export interface ExplanationPayload {
  messages: string[];
  factors: ExplanationFactor[];
}

interface RuleInput {
  bmi: number;
  dailySteps: number;
  hoursOfSleep: number;
  exerciseHoursPerWeek: number;
  smoker: string;
  diabetic: string;
  heartDisease: string;
  alcoholPerWeek: number;
}

function classifyByRules(row: RuleInput): {
  profile: HealthProfile;
  explanation: ExplanationPayload;
} {
  let scoreRisco = 0;
  let scoreSaude = 0;
  const messages: string[] = [];
  const factors: ExplanationFactor[] = [];

  const addFactor = (factor: ExplanationFactor) => {
    factors.push(factor);
    if (factor.impact === "negative") messages.push(factor.detail);
  };

  if (row.dailySteps < 5000) {
    scoreRisco += 3;
    addFactor({ factor: "atividade_fisica", impact: "negative", weight: 0.25, detail: "Baixa atividade fisica (menos de 5.000 passos/dia)" });
  } else if (row.dailySteps < 8000) {
    scoreRisco += 1;
    addFactor({ factor: "atividade_fisica", impact: "neutral", weight: 0.1, detail: "Atividade fisica abaixo do ideal (5.000-8.000 passos)" });
  } else if (row.dailySteps >= 10000) {
    scoreSaude += 3;
    addFactor({ factor: "atividade_fisica", impact: "positive", weight: 0.2, detail: "Alta atividade fisica (10.000+ passos/dia)" });
  } else {
    scoreSaude += 2;
    addFactor({ factor: "atividade_fisica", impact: "positive", weight: 0.15, detail: "Boa atividade fisica (8.000+ passos/dia)" });
  }

  if (row.exerciseHoursPerWeek < 1.5) {
    scoreRisco += 3;
    addFactor({ factor: "exercicio", impact: "negative", weight: 0.2, detail: "Pouco exercicio semanal (menos de 1,5h)" });
  } else if (row.exerciseHoursPerWeek < 3) {
    scoreRisco += 1;
    addFactor({ factor: "exercicio", impact: "neutral", weight: 0.1, detail: "Exercicio semanal moderado (1,5-3h)" });
  } else if (row.exerciseHoursPerWeek >= 5) {
    scoreSaude += 3;
    addFactor({ factor: "exercicio", impact: "positive", weight: 0.2, detail: "Excelente volume de exercicio (5h+/semana)" });
  } else {
    scoreSaude += 2;
    addFactor({ factor: "exercicio", impact: "positive", weight: 0.15, detail: "Bom volume de exercicio (3h+/semana)" });
  }

  if (row.hoursOfSleep < 5 || row.hoursOfSleep > 9.5) {
    scoreRisco += 2;
    addFactor({ factor: "sono", impact: "negative", weight: 0.2, detail: "Sono fora da faixa recomendada (6-9h)" });
  } else if (row.hoursOfSleep < 6) {
    scoreRisco += 1;
    addFactor({ factor: "sono", impact: "neutral", weight: 0.1, detail: "Sono levemente abaixo do ideal" });
  } else if (row.hoursOfSleep >= 6.5 && row.hoursOfSleep <= 8.5) {
    scoreSaude += 2;
    addFactor({ factor: "sono", impact: "positive", weight: 0.15, detail: "Sono adequado (6,5-8,5h)" });
  }

  if (row.bmi >= 30) {
    scoreRisco += 3;
    addFactor({ factor: "imc", impact: "negative", weight: 0.2, detail: "IMC indica obesidade" });
  } else if (row.bmi >= 25) {
    scoreRisco += 1;
    addFactor({ factor: "imc", impact: "negative", weight: 0.1, detail: "IMC acima do ideal" });
  } else if (row.bmi >= 18.5 && row.bmi < 25) {
    scoreSaude += 2;
    addFactor({ factor: "imc", impact: "positive", weight: 0.15, detail: "IMC na faixa saudavel" });
  } else if (row.bmi < 18.5) {
    scoreRisco += 1;
    addFactor({ factor: "imc", impact: "negative", weight: 0.1, detail: "IMC abaixo do ideal" });
  }

  if (row.smoker === "Yes") {
    scoreRisco += 2;
    addFactor({ factor: "tabagismo", impact: "negative", weight: 0.15, detail: "Habitos de tabagismo" });
  } else {
    scoreSaude += 1;
    addFactor({ factor: "tabagismo", impact: "positive", weight: 0.05, detail: "Nao fumante" });
  }

  if (row.diabetic === "Yes") {
    scoreRisco += 2;
    addFactor({ factor: "diabetes", impact: "negative", weight: 0.15, detail: "Historico de diabetes" });
  } else {
    scoreSaude += 1;
  }

  if (row.heartDisease === "Yes") {
    scoreRisco += 3;
    addFactor({ factor: "cardiovascular", impact: "negative", weight: 0.2, detail: "Historico de doenca cardiaca" });
  }

  if (row.alcoholPerWeek >= 7) {
    scoreRisco += 2;
    addFactor({ factor: "alcool", impact: "negative", weight: 0.1, detail: "Consumo elevado de alcool" });
  } else if (row.alcoholPerWeek >= 5) {
    scoreRisco += 1;
    addFactor({ factor: "alcool", impact: "neutral", weight: 0.05, detail: "Consumo moderado de alcool" });
  } else if (row.alcoholPerWeek <= 2) {
    scoreSaude += 1;
    addFactor({ factor: "alcool", impact: "positive", weight: 0.05, detail: "Consumo baixo de alcool" });
  }

  let profile: HealthProfile;
  if (scoreRisco >= 8) profile = "Em_Risco";
  else if (scoreRisco >= 4 && scoreSaude < 5) profile = "Sedentario";
  else if (scoreSaude >= 8 && scoreRisco <= 2) profile = "Saudavel_Ativo";
  else profile = "Moderado";

  if (messages.length === 0) {
    messages.push("Perfil equilibrado com habitos dentro da media");
  }

  return { profile, explanation: { messages, factors } };
}

function assignCluster(input: HealthAssessmentInput & { bmi: number }) {
  const activityScore = input.dailySteps / 20000 + input.exerciseHoursPerWeek / 10;
  const sleepScore = input.hoursOfSleep / 10;
  const riskScore =
    (input.smoker === "Yes" ? 1 : 0) +
    (input.diabetic === "Yes" ? 1 : 0) +
    (input.heartDisease === "Yes" ? 1 : 0);

  if (activityScore >= 0.6 && sleepScore >= 0.6 && riskScore === 0) {
    return { clusterId: 0, clusterLabel: CLUSTER_LABELS[0] };
  }
  if (riskScore >= 2 || input.bmi >= 30) {
    return { clusterId: 3, clusterLabel: CLUSTER_LABELS[3] };
  }
  if (activityScore < 0.35) {
    return { clusterId: 1, clusterLabel: CLUSTER_LABELS[1] };
  }
  return { clusterId: 2, clusterLabel: CLUSTER_LABELS[2] };
}

export function calculateBmi(heightCm: number, weightKg: number): number {
  const heightM = heightCm / 100;
  return Number((weightKg / (heightM * heightM)).toFixed(2));
}

async function callMlService(input: HealthAssessmentInput, bmi: number): Promise<ClassificationResult | null> {
  if (!env.ML_SERVICE_URL) return null;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), env.ML_SERVICE_TIMEOUT_MS);

  try {
    const response = await fetch(`${env.ML_SERVICE_URL}/predict`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ ...input, bmi }),
      signal: controller.signal,
    });

    if (!response.ok) return null;
    return (await response.json()) as ClassificationResult;
  } catch {
    return null;
  } finally {
    clearTimeout(timeout);
  }
}

export const classificationService = {
  async checkMlHealth(): Promise<{ available: boolean; url?: string }> {
    if (!env.ML_SERVICE_URL) return { available: false };
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 3000);
      const res = await fetch(`${env.ML_SERVICE_URL}/health`, { signal: controller.signal });
      clearTimeout(timeout);
      return { available: res.ok, url: env.ML_SERVICE_URL };
    } catch {
      return { available: false, url: env.ML_SERVICE_URL };
    }
  },

  async classify(input: HealthAssessmentInput): Promise<
    ClassificationResult & { modelVersion: string; explanationPayload: ExplanationPayload }
  > {
    const bmi = calculateBmi(input.heightCm, input.weightKg);
    const mlResult = await callMlService(input, bmi);

    if (mlResult) {
      const fallback = classifyByRules({
        bmi,
        dailySteps: input.dailySteps,
        hoursOfSleep: input.hoursOfSleep,
        exerciseHoursPerWeek: input.exerciseHoursPerWeek,
        smoker: input.smoker,
        diabetic: input.diabetic,
        heartDisease: input.heartDisease,
        alcoholPerWeek: input.alcoholPerWeek,
      });

      return {
        ...mlResult,
        explanation: mlResult.explanation ?? fallback.explanation.messages,
        modelVersion: "ml-service",
        explanationPayload: fallback.explanation,
        confidence: mlResult.confidence ?? 0.85,
      };
    }

    const { profile, explanation } = classifyByRules({
      bmi,
      dailySteps: input.dailySteps,
      hoursOfSleep: input.hoursOfSleep,
      exerciseHoursPerWeek: input.exerciseHoursPerWeek,
      smoker: input.smoker,
      diabetic: input.diabetic,
      heartDisease: input.heartDisease,
      alcoholPerWeek: input.alcoholPerWeek,
    });

    const cluster = assignCluster({ ...input, bmi });

    return {
      profile,
      profileScore: PROFILE_SCORES[profile],
      clusterId: cluster.clusterId,
      clusterLabel: cluster.clusterLabel,
      explanation: explanation.messages,
      explanationPayload: explanation,
      modelVersion: "rules-v1",
      confidence: 0.75,
    };
  },
};

export function parseExplanation(raw: unknown): ExplanationPayload {
  if (raw && typeof raw === "object" && "factors" in raw && "messages" in raw) {
    return raw as ExplanationPayload;
  }
  if (Array.isArray(raw)) {
    return { messages: raw as string[], factors: [] };
  }
  return { messages: ["Sem detalhes disponiveis"], factors: [] };
}
