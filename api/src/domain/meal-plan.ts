import { HealthProfile } from "@vitalis/shared";

export type MealType = "breakfast" | "lunch" | "dinner" | "snack";

export interface MealSuggestion {
  mealType: MealType;
  title: string;
  description: string;
  tip: string;
}

export const MEAL_PLANS: Record<HealthProfile, MealSuggestion[]> = {
  Em_Risco: [
    { mealType: "breakfast", title: "Cafe equilibrado", description: "Aveia com frutas e iogurte natural", tip: "Evite acucar refinado no cafe" },
    { mealType: "lunch", title: "Almoco leve", description: "Salada + frango grelhado + arroz integral", tip: "Metade do prato com vegetais" },
    { mealType: "dinner", title: "Jantar cedo", description: "Sopa de legumes + proteina magra", tip: "Jantar 3h antes de dormir" },
    { mealType: "snack", title: "Lanche saudavel", description: "Frutas ou castanhas (porcao pequena)", tip: "Substitua ultraprocessados" },
  ],
  Sedentario: [
    { mealType: "breakfast", title: "Cafe com proteina", description: "Ovos mexidos + pao integral + fruta", tip: "Proteina aumenta saciedade" },
    { mealType: "lunch", title: "Prato colorido", description: "Vegetais variados + leguminosa + proteina", tip: "Evite fast food diario" },
    { mealType: "dinner", title: "Refeicao moderada", description: "Peixe ou frango + quinoa + salada", tip: "Controle porcoes" },
    { mealType: "snack", title: "Hidratacao + fibra", description: "Agua + fruta ou iogurte", tip: "Beba agua antes de beliscar" },
  ],
  Moderado: [
    { mealType: "breakfast", title: "Energia sustentavel", description: "Granola caseira + leite ou vegetal + banana", tip: "Mantenha horario regular" },
    { mealType: "lunch", title: "Prato equilibrado", description: "50% vegetais, 25% proteina, 25% carboidrato", tip: "Varie cores no prato" },
    { mealType: "dinner", title: "Jantar balanceado", description: "Proteina + carboidrato complexo + legumes", tip: "Evite excesso a noite" },
    { mealType: "snack", title: "Pre-treino leve", description: "Fruta + oleaginosas", tip: "Ajuste conforme treino" },
  ],
  Saudavel_Ativo: [
    { mealType: "breakfast", title: "Cafe pre-atividade", description: "Ovos + aveia + frutas vermelhas", tip: "Carboidrato + proteina" },
    { mealType: "lunch", title: "Refeicao completa", description: "Proteina magra + carboidrato + vegetais", tip: "Reposicao pos-treino se aplicavel" },
    { mealType: "dinner", title: "Recuperacao", description: "Peixe + batata-doce + brocolis", tip: "Mantenha hidratacao" },
    { mealType: "snack", title: "Pos-treino", description: "Iogurte + fruta ou shake simples", tip: "Janela de 1-2h pos exercicio" },
  ],
};
