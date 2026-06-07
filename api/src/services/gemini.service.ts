import { GoogleGenerativeAI } from "@google/generative-ai";
import { env, isGeminiActive } from "../config/env";
import { ExplanationFactor } from "./classification.service";

export interface GeminiExplanationInput {
  profile: string;
  profileScore: number;
  confidence?: number;
  modelVersion: string;
  factors: ExplanationFactor[];
  userName?: string;
}

export interface GeminiMealPlanInput {
  profile: string;
  profileScore: number;
  caloriesIntake?: number;
  userName?: string;
}

export interface MealPlanItem {
  mealType: string;
  title: string;
  description: string;
  tip: string;
  items?: Array<{ name: string; quantity: string }>;
}

export const geminiService = {
  isEnabled(): boolean {
    return isGeminiActive();
  },

  async enrichExplanation(input: GeminiExplanationInput): Promise<string | null> {
    if (!this.isEnabled()) return null;

    const factorLines = input.factors
      .slice(0, 6)
      .map((f) => `- ${f.detail} (${f.impact})`)
      .join("\n");

    const prompt = [
      "Voce e assistente de bem-estar do app Vitalis.",
      "REGRAS: Nao faca diagnostico medico. Nao prescreva medicamentos ou tratamentos.",
      "O perfil JA foi definido pelo modelo de Machine Learning — nao altere a classificacao.",
      "",
      `Perfil ML: ${input.profile}`,
      `Score: ${input.profileScore}/100`,
      `Confianca do modelo: ${Math.round((input.confidence ?? 0) * 100)}%`,
      `Versao do modelo: ${input.modelVersion}`,
      input.userName ? `Nome do usuario: ${input.userName}` : "",
      "",
      "Fatores identificados:",
      factorLines || "- Perfil equilibrado",
      "",
      "Escreva 2 a 3 frases motivacionais em portugues do Brasil, tom acolhedor e pratico.",
      "Mencione 1 acao concreta de habito (sono, exercicio, alimentacao ou hidratacao).",
    ]
      .filter(Boolean)
      .join("\n");

    try {
      const client = new GoogleGenerativeAI(env.GEMINI_API_KEY!);
      const model = client.getGenerativeModel({ model: env.GEMINI_MODEL });
      const result = await model.generateContent(prompt);
      const text = result.response.text().trim();
      return text || null;
    } catch (error) {
      console.warn("[gemini] Falha ao gerar explicacao:", error);
      return null;
    }
  },

  async generateMealPlan(input: GeminiMealPlanInput): Promise<MealPlanItem[] | null> {
    if (!this.isEnabled()) return null;

    const prompt = [
      "Voce e nutricionista do app Vitalis (bem-estar, nao clinica).",
      "REGRAS: Nao prescreva medicamentos. Nao diagnostique. Sugestoes gerais em portugues do Brasil.",
      "",
      `Perfil de saude (ML): ${input.profile}`,
      `Score de bem-estar: ${input.profileScore}/100`,
      input.caloriesIntake ? `Calorias informadas pelo usuario: ${input.caloriesIntake} kcal/dia` : "",
      input.userName ? `Nome: ${input.userName}` : "",
      "",
      "Gere um cardapio do dia com 4 refeicoes: breakfast, lunch, dinner, snack.",
      "Para cada refeicao inclua 2 a 4 alimentos com quantidade clara (ex: 120 g, 1 xicara, 2 unidades).",
      "Responda APENAS com JSON valido (array), sem markdown:",
      '[{"mealType":"breakfast","title":"...","description":"resumo curto","tip":"...","items":[{"name":"Ovos mexidos","quantity":"2 unidades"}]}, ...]',
    ]
      .filter(Boolean)
      .join("\n");

    try {
      const client = new GoogleGenerativeAI(env.GEMINI_API_KEY!);
      const model = client.getGenerativeModel({ model: env.GEMINI_MODEL });
      const result = await model.generateContent(prompt);
      const text = result.response.text().trim();
      const jsonText = text.replace(/^```json\s*/i, "").replace(/```\s*$/i, "").trim();
      const parsed = JSON.parse(jsonText) as MealPlanItem[];
      if (!Array.isArray(parsed) || parsed.length === 0) return null;
      return parsed
        .filter((item) => item.mealType && item.title && item.description)
        .slice(0, 4)
        .map((item) => ({
          mealType: String(item.mealType),
          title: String(item.title),
          description: String(item.description),
          tip: String(item.tip ?? ""),
          items: Array.isArray(item.items)
            ? item.items
                .filter((entry) => entry?.name && entry?.quantity)
                .slice(0, 6)
                .map((entry) => ({
                  name: String(entry.name),
                  quantity: String(entry.quantity),
                }))
            : undefined,
        }));
    } catch (error) {
      console.warn("[gemini] Falha ao gerar cardapio:", error);
      return null;
    }
  },
};
