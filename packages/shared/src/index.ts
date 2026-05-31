export type HealthProfile =
  | "Em_Risco"
  | "Sedentario"
  | "Moderado"
  | "Saudavel_Ativo";

export type Gender = "Male" | "Female";
export type YesNo = "Yes" | "No";

export type RecommendationCategory =
  | "DIET"
  | "ROUTINE"
  | "EXERCISE"
  | "HYDRATION"
  | "SLEEP";

export type ReminderType = "WATER" | "MEAL" | "SLEEP" | "EXERCISE";

export interface HealthAssessmentInput {
  age: number;
  gender: Gender;
  heightCm: number;
  weightKg: number;
  dailySteps: number;
  caloriesIntake: number;
  hoursOfSleep: number;
  heartRate?: number;
  bloodPressureSystolic?: number;
  bloodPressureDiastolic?: number;
  exerciseHoursPerWeek: number;
  smoker: YesNo;
  alcoholPerWeek: number;
  diabetic: YesNo;
  heartDisease: YesNo;
}

export interface ClassificationResult {
  profile: HealthProfile;
  profileScore: number;
  clusterId: number;
  clusterLabel: string;
  explanation: string[];
  confidence?: number;
}

export const HEALTH_PROFILE_LABELS: Record<HealthProfile, string> = {
  Em_Risco: "Em Risco",
  Sedentario: "Sedentario",
  Moderado: "Moderado",
  Saudavel_Ativo: "Saudavel Ativo",
};

export const ML_FEATURE_COLUMNS = [
  "Age",
  "BMI",
  "Daily_Steps",
  "Hours_of_Sleep",
  "Exercise_Hours_per_Week",
  "Heart_Rate",
  "Calories_Intake",
  "Alcohol_Consumption_per_Week",
  "Gender_enc",
  "Smoker_enc",
  "Diabetic_enc",
  "Heart_Disease_enc",
] as const;
