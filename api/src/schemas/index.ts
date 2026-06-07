import { z } from "zod";

export const registerSchema = z.object({
  name: z.string().min(2).max(120),
  email: z.string().email(),
  password: z.string().min(6).max(72),
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export const refreshSchema = z.object({
  refreshToken: z.string().min(1),
});

export const updateProfileSchema = z.object({
  name: z.string().min(2).max(120),
});

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1),
  newPassword: z.string().min(6).max(72),
});

export const assessmentSchema = z.object({
  age: z.number().int().min(18).max(120),
  gender: z.enum(["Male", "Female"]),
  heightCm: z.number().min(100).max(250),
  weightKg: z.number().min(30).max(300),
  dailySteps: z.number().int().min(0).max(50000),
  caloriesIntake: z.number().int().min(800).max(6000),
  hoursOfSleep: z.number().min(3).max(14),
  heartRate: z.number().int().min(40).max(200).optional(),
  bloodPressureSystolic: z.number().int().min(70).max(200).optional(),
  bloodPressureDiastolic: z.number().int().min(40).max(130).optional(),
  exerciseHoursPerWeek: z.number().min(0).max(30),
  smoker: z.enum(["Yes", "No"]),
  alcoholPerWeek: z.number().int().min(0).max(30),
  diabetic: z.enum(["Yes", "No"]),
  heartDisease: z.enum(["Yes", "No"]),
});

export type AssessmentInput = z.infer<typeof assessmentSchema>;

export const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const compareSchema = z.object({
  from: z.string().uuid(),
  to: z.string().uuid(),
});

export const reminderSchema = z.object({
  type: z.enum(["WATER", "MEAL", "SLEEP", "EXERCISE"]),
  title: z.string().min(2).max(100),
  message: z.string().max(255).optional(),
  timeOfDay: z.string().regex(/^\d{2}:\d{2}$/),
  frequency: z.enum(["DAILY", "WEEKLY"]).default("DAILY"),
  isActive: z.boolean().default(true),
});

export const reminderUpdateSchema = reminderSchema.partial();

export const toggleRecommendationSchema = z.object({
  isActive: z.boolean(),
});

export const foodLogSchema = z.object({
  description: z.string().min(2).max(500),
  entryType: z.enum(["food", "drink"]).default("food"),
  mealPeriod: z.enum(["breakfast", "lunch", "dinner", "snack"]).optional(),
  loggedOn: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .optional(),
});
