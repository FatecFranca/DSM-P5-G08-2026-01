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
  geminiSummary?: string;
  modelVersion?: string;
}

const VALID_PROFILES: readonly HealthProfile[] = [
  "Em_Risco",
  "Sedentario",
  "Moderado",
  "Saudavel_Ativo",
];

function isValidProfile(value: unknown): value is HealthProfile {
  return typeof value === "string" && VALID_PROFILES.includes(value as HealthProfile);
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

interface MlPredictResponse extends ClassificationResult {
  modelVersion?: string;
}

async function callMlService(input: HealthAssessmentInput, bmi: number): Promise<MlPredictResponse | null> {
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

    if (!response.ok) {
      console.warn(`[ml] Resposta ${response.status} de ${env.ML_SERVICE_URL}/predict`);
      return null;
    }
    return (await response.json()) as MlPredictResponse;
  } catch (error) {
    console.warn("[ml] Servico indisponivel, usando fallback rules-v1:", error);
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
    const cluster = assignCluster({ ...input, bmi });

    // Usa ML somente se retornou um perfil dentro das classes treinadas
    // e com confianca aceitavel; caso contrario, cai no motor de regras.
    const mlConfidence = mlResult?.confidence ?? 0;
    const mlUsable =
      mlResult != null && isValidProfile(mlResult.profile) && mlConfidence >= 0.4;

    if (mlResult && !mlUsable) {
      console.warn(
        `[ml] Resultado descartado (profile="${mlResult.profile}", confidence=${mlConfidence}). Usando rules-v1.`,
      );
    }

    if (mlResult && mlUsable) {
      const profile = mlResult.profile as HealthProfile;
      return {
        profile,
        // Score e cluster derivados de regras deterministicas para garantir
        // consistencia: o cluster do K-Means tem IDs arbitrarios que nao
        // correspondem aos rotulos semanticos (ex.: pessoa saudavel caia em
        // "Grupo Sedentario").
        profileScore: PROFILE_SCORES[profile],
        clusterId: cluster.clusterId,
        clusterLabel: cluster.clusterLabel,
        explanation: fallback.explanation.messages,
        explanationPayload: {
          ...fallback.explanation,
          modelVersion: mlResult.modelVersion ?? "ml-v1.0",
        },
        modelVersion: mlResult.modelVersion ?? "ml-v1.0",
        confidence: mlConfidence > 0 ? mlConfidence : 0.85,
      };
    }

    return {
      profile: fallback.profile,
      profileScore: PROFILE_SCORES[fallback.profile],
      clusterId: cluster.clusterId,
      clusterLabel: cluster.clusterLabel,
      explanation: fallback.explanation.messages,
      explanationPayload: fallback.explanation,
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
