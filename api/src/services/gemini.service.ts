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
};
