export const QUESTIONNAIRE_SECTIONS = [
  {
    id: "profile",
    title: "Dados pessoais",
    fields: [
      { key: "age", label: "Idade", type: "number", min: 18, max: 120 },
      { key: "gender", label: "Sexo", type: "select", options: ["Male", "Female"] },
      { key: "heightCm", label: "Altura (cm)", type: "number", min: 100, max: 250 },
      { key: "weightKg", label: "Peso (kg)", type: "number", min: 30, max: 300 },
    ],
  },
  {
    id: "activity",
    title: "Atividade fisica",
    fields: [
      { key: "dailySteps", label: "Passos diarios (media)", type: "number", min: 0, max: 50000 },
      { key: "exerciseHoursPerWeek", label: "Horas de exercicio por semana", type: "number", min: 0, max: 30 },
    ],
  },
  {
    id: "nutrition",
    title: "Alimentacao e hidratacao",
    fields: [
      { key: "caloriesIntake", label: "Calorias consumidas por dia", type: "number", min: 800, max: 6000 },
      { key: "alcoholPerWeek", label: "Doses de alcool por semana", type: "number", min: 0, max: 30 },
    ],
  },
  {
    id: "sleep",
    title: "Sono",
    fields: [
      { key: "hoursOfSleep", label: "Horas de sono por noite", type: "number", min: 3, max: 14 },
    ],
  },
  {
    id: "clinical",
    title: "Historico de saude (nao e diagnostico)",
    fields: [
      { key: "smoker", label: "Fumante", type: "boolean", options: ["Yes", "No"] },
      { key: "diabetic", label: "Diabetes", type: "boolean", options: ["Yes", "No"] },
      { key: "heartDisease", label: "Doenca cardiaca", type: "boolean", options: ["Yes", "No"] },
      { key: "heartRate", label: "Frequencia cardiaca em repouso", type: "number", optional: true },
      { key: "bloodPressureSystolic", label: "Pressao sistolica", type: "number", optional: true },
      { key: "bloodPressureDiastolic", label: "Pressao diastolica", type: "number", optional: true },
    ],
  },
] as const;

export const HEALTH_PROFILES = [
  { key: "Saudavel_Ativo", label: "Saudavel Ativo" },
  { key: "Moderado", label: "Moderado" },
  { key: "Sedentario", label: "Sedentario" },
  { key: "Em_Risco", label: "Em Risco" },
] as const;
