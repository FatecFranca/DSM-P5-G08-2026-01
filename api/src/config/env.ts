import path from "path";
import dotenv from "dotenv";
import { z } from "zod";

dotenv.config({ path: path.resolve(__dirname, "../../../.env") });
dotenv.config({ path: path.resolve(process.cwd(), "../.env") });
dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  PORT: z.coerce.number().default(3333),
  DATABASE_URL: z.string().min(1),
  JWT_SECRET: z.string().min(32),
  JWT_ACCESS_EXPIRES_IN: z.string().default("15m"),
  JWT_REFRESH_EXPIRES_IN: z.string().default("7d"),
  JWT_EXPIRES_IN: z.string().optional(),
  ML_SERVICE_URL: z.string().url().optional(),
  ML_SERVICE_TIMEOUT_MS: z.coerce.number().default(5000),
  CORS_ORIGINS: z.string().default("*"),
  ADMIN_API_KEY: z.string().optional(),
});

export const env = envSchema.parse(process.env);

export function getCorsOrigins(): string | string[] {
  if (env.CORS_ORIGINS === "*") return "*";
  return env.CORS_ORIGINS.split(",").map((o) => o.trim());
}
