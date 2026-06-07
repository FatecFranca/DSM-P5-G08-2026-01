import { HealthProfile } from "@vitalis/shared";

export type MealType = "breakfast" | "lunch" | "dinner" | "snack";

export interface MealItem {
  name: string;
  quantity: string;
}

export interface MealSuggestion {
  mealType: MealType;
  title: string;
  description: string;
  tip: string;
  items?: MealItem[];
}

export const MEAL_PLANS: Record<HealthProfile, MealSuggestion[]> = {
  Em_Risco: [
    {
      mealType: "breakfast",
      title: "Cafe equilibrado",
      description: "Refeicao leve com fibras e proteina para comecar o dia.",
      tip: "Evite acucar refinado no cafe",
      items: [
        { name: "Aveia", quantity: "4 colheres de sopa" },
        { name: "Iogurte natural", quantity: "1 pote pequeno" },
        { name: "Frutas", quantity: "1 porcao (maca ou banana)" },
      ],
    },
    {
      mealType: "lunch",
      title: "Almoco leve",
      description: "Prato com vegetais, proteina magra e carboidrato integral.",
      tip: "Metade do prato com vegetais",
      items: [
        { name: "Salada de folhas", quantity: "1 prato raso" },
        { name: "Frango grelhado", quantity: "120 g" },
        { name: "Arroz integral", quantity: "3 colheres de sopa" },
      ],
    },
    {
      mealType: "dinner",
      title: "Jantar cedo",
      description: "Refeicao leve para facilitar o sono.",
      tip: "Jantar 3h antes de dormir",
      items: [
        { name: "Sopa de legumes", quantity: "1 concha media" },
        { name: "Proteina magra", quantity: "100 g" },
      ],
    },
    {
      mealType: "snack",
      title: "Lanche saudavel",
      description: "Opcao pratica entre as refeicoes.",
      tip: "Substitua ultraprocessados",
      items: [
        { name: "Frutas", quantity: "1 unidade" },
        { name: "Castanhas", quantity: "1 punhado pequeno" },
      ],
    },
  ],
  Sedentario: [
    {
      mealType: "breakfast",
      title: "Cafe com proteina",
      description: "Combina proteina e fibra para mais saciedade.",
      tip: "Proteina aumenta saciedade",
      items: [
        { name: "Ovos mexidos", quantity: "2 unidades" },
        { name: "Pao integral", quantity: "1 fatia" },
        { name: "Fruta", quantity: "1 porcao" },
      ],
    },
    {
      mealType: "lunch",
      title: "Prato colorido",
      description: "Variedade de vegetais com leguminosa e proteina.",
      tip: "Evite fast food diario",
      items: [
        { name: "Vegetais variados", quantity: "1 prato raso" },
        { name: "Feijao ou lentilha", quantity: "2 colheres de sopa" },
        { name: "Proteina magra", quantity: "120 g" },
      ],
    },
    {
      mealType: "dinner",
      title: "Refeicao moderada",
      description: "Porcao controlada com proteina e carboidrato complexo.",
      tip: "Controle porcoes",
      items: [
        { name: "Peixe ou frango", quantity: "120 g" },
        { name: "Quinoa", quantity: "3 colheres de sopa" },
        { name: "Salada", quantity: "1 prato raso" },
      ],
    },
    {
      mealType: "snack",
      title: "Hidratacao + fibra",
      description: "Lanche simples com agua e fibra.",
      tip: "Beba agua antes de beliscar",
      items: [
        { name: "Agua", quantity: "1 copo (250 ml)" },
        { name: "Fruta ou iogurte", quantity: "1 porcao" },
      ],
    },
  ],
  Moderado: [
    {
      mealType: "breakfast",
      title: "Energia sustentavel",
      description: "Cafe balanceado para manter energia ao longo da manha.",
      tip: "Mantenha horario regular",
      items: [
        { name: "Granola caseira", quantity: "4 colheres de sopa" },
        { name: "Leite ou bebida vegetal", quantity: "200 ml" },
        { name: "Banana", quantity: "1 unidade" },
      ],
    },
    {
      mealType: "lunch",
      title: "Prato equilibrado",
      description: "Metade vegetais, um quarto proteina e um quarto carboidrato.",
      tip: "Varie cores no prato",
      items: [
        { name: "Vegetais", quantity: "50% do prato" },
        { name: "Proteina", quantity: "25% do prato" },
        { name: "Carboidrato complexo", quantity: "25% do prato" },
      ],
    },
    {
      mealType: "dinner",
      title: "Jantar balanceado",
      description: "Refeicao completa sem excessos.",
      tip: "Evite excesso a noite",
      items: [
        { name: "Proteina magra", quantity: "120 g" },
        { name: "Batata-doce ou arroz", quantity: "3 colheres de sopa" },
        { name: "Legumes", quantity: "1 prato raso" },
      ],
    },
    {
      mealType: "snack",
      title: "Pre-treino leve",
      description: "Energia rapida antes de atividade fisica.",
      tip: "Ajuste conforme treino",
      items: [
        { name: "Fruta", quantity: "1 unidade" },
        { name: "Oleaginosas", quantity: "1 punhado pequeno" },
      ],
    },
  ],
  Saudavel_Ativo: [
    {
      mealType: "breakfast",
      title: "Cafe pre-atividade",
      description: "Carboidrato e proteina para performance.",
      tip: "Carboidrato + proteina",
      items: [
        { name: "Ovos", quantity: "2 unidades" },
        { name: "Aveia", quantity: "4 colheres de sopa" },
        { name: "Frutas vermelhas", quantity: "1/2 xicara" },
      ],
    },
    {
      mealType: "lunch",
      title: "Refeicao completa",
      description: "Reposicao de energia e nutrientes no meio do dia.",
      tip: "Reposicao pos-treino se aplicavel",
      items: [
        { name: "Proteina magra", quantity: "150 g" },
        { name: "Carboidrato complexo", quantity: "4 colheres de sopa" },
        { name: "Vegetais", quantity: "1 prato raso" },
      ],
    },
    {
      mealType: "dinner",
      title: "Recuperacao",
      description: "Refeicao para recuperacao muscular e sono.",
      tip: "Mantenha hidratacao",
      items: [
        { name: "Peixe", quantity: "150 g" },
        { name: "Batata-doce", quantity: "1 unidade media" },
        { name: "Brocolis", quantity: "1 xicara" },
      ],
    },
    {
      mealType: "snack",
      title: "Pos-treino",
      description: "Lanche rapido apos exercicio.",
      tip: "Janela de 1-2h pos exercicio",
      items: [
        { name: "Iogurte natural", quantity: "1 pote" },
        { name: "Fruta", quantity: "1 unidade" },
      ],
    },
  ],
};
