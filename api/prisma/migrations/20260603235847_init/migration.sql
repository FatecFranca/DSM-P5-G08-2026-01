-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('USER', 'ADMIN');

-- CreateEnum
CREATE TYPE "Gender" AS ENUM ('Male', 'Female');

-- CreateEnum
CREATE TYPE "YesNo" AS ENUM ('Yes', 'No');

-- CreateEnum
CREATE TYPE "HealthProfile" AS ENUM ('Em_Risco', 'Sedentario', 'Moderado', 'Saudavel_Ativo');

-- CreateEnum
CREATE TYPE "RecommendationCategory" AS ENUM ('DIET', 'ROUTINE', 'EXERCISE', 'HYDRATION', 'SLEEP');

-- CreateEnum
CREATE TYPE "ReminderType" AS ENUM ('WATER', 'MEAL', 'SLEEP', 'EXERCISE');

-- CreateEnum
CREATE TYPE "ReminderFrequency" AS ENUM ('DAILY', 'WEEKLY');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "role" "UserRole" NOT NULL DEFAULT 'USER',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "token_hash" TEXT NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "health_assessments" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "age" INTEGER NOT NULL,
    "gender" "Gender" NOT NULL,
    "height_cm" DOUBLE PRECISION NOT NULL,
    "weight_kg" DOUBLE PRECISION NOT NULL,
    "bmi" DOUBLE PRECISION NOT NULL,
    "daily_steps" INTEGER NOT NULL,
    "calories_intake" INTEGER NOT NULL,
    "hours_of_sleep" DOUBLE PRECISION NOT NULL,
    "heart_rate" INTEGER,
    "blood_pressure_systolic" INTEGER,
    "blood_pressure_diastolic" INTEGER,
    "exercise_hours_per_week" DOUBLE PRECISION NOT NULL,
    "smoker" "YesNo" NOT NULL,
    "alcohol_per_week" INTEGER NOT NULL,
    "diabetic" "YesNo" NOT NULL,
    "heart_disease" "YesNo" NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "health_assessments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "health_classifications" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "assessment_id" TEXT NOT NULL,
    "profile" "HealthProfile" NOT NULL,
    "profile_score" INTEGER NOT NULL,
    "cluster_id" INTEGER NOT NULL,
    "cluster_label" TEXT NOT NULL,
    "explanation" JSONB NOT NULL,
    "model_version" TEXT NOT NULL DEFAULT 'rules-v1',
    "confidence" DOUBLE PRECISION,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "health_classifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "recommendation_templates" (
    "id" TEXT NOT NULL,
    "profile" "HealthProfile" NOT NULL,
    "category" "RecommendationCategory" NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "priority" INTEGER NOT NULL DEFAULT 1,
    "is_active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "recommendation_templates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_recommendations" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "template_id" TEXT NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "assigned_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_recommendations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reminders" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "type" "ReminderType" NOT NULL,
    "title" TEXT NOT NULL,
    "message" TEXT,
    "time_of_day" TEXT NOT NULL,
    "frequency" "ReminderFrequency" NOT NULL DEFAULT 'DAILY',
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "reminders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reminder_completions" (
    "id" TEXT NOT NULL,
    "reminder_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "completed_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completed_on" TEXT NOT NULL,

    CONSTRAINT "reminder_completions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "gamification_profiles" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "points" INTEGER NOT NULL DEFAULT 0,
    "level" INTEGER NOT NULL DEFAULT 1,
    "current_streak" INTEGER NOT NULL DEFAULT 0,
    "longest_streak" INTEGER NOT NULL DEFAULT 0,
    "badges" JSONB NOT NULL DEFAULT '[]',
    "last_active_at" TIMESTAMP(3),
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "gamification_profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "achievements" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "points_reward" INTEGER NOT NULL DEFAULT 0,
    "icon" TEXT,

    CONSTRAINT "achievements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_achievements" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "achievement_id" TEXT NOT NULL,
    "unlocked_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_achievements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cluster_definitions" (
    "id" INTEGER NOT NULL,
    "label" TEXT NOT NULL,
    "description" TEXT NOT NULL,

    CONSTRAINT "cluster_definitions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_hash_key" ON "refresh_tokens"("token_hash");

-- CreateIndex
CREATE INDEX "refresh_tokens_user_id_idx" ON "refresh_tokens"("user_id");

-- CreateIndex
CREATE INDEX "health_assessments_user_id_created_at_idx" ON "health_assessments"("user_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "health_classifications_assessment_id_key" ON "health_classifications"("assessment_id");

-- CreateIndex
CREATE INDEX "health_classifications_user_id_created_at_idx" ON "health_classifications"("user_id", "created_at");

-- CreateIndex
CREATE INDEX "health_classifications_cluster_id_idx" ON "health_classifications"("cluster_id");

-- CreateIndex
CREATE INDEX "recommendation_templates_profile_category_idx" ON "recommendation_templates"("profile", "category");

-- CreateIndex
CREATE UNIQUE INDEX "user_recommendations_user_id_template_id_key" ON "user_recommendations"("user_id", "template_id");

-- CreateIndex
CREATE INDEX "reminders_user_id_is_active_idx" ON "reminders"("user_id", "is_active");

-- CreateIndex
CREATE INDEX "reminder_completions_user_id_completed_on_idx" ON "reminder_completions"("user_id", "completed_on");

-- CreateIndex
CREATE UNIQUE INDEX "reminder_completions_reminder_id_completed_on_key" ON "reminder_completions"("reminder_id", "completed_on");

-- CreateIndex
CREATE UNIQUE INDEX "gamification_profiles_user_id_key" ON "gamification_profiles"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "achievements_code_key" ON "achievements"("code");

-- CreateIndex
CREATE UNIQUE INDEX "user_achievements_user_id_achievement_id_key" ON "user_achievements"("user_id", "achievement_id");

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "health_assessments" ADD CONSTRAINT "health_assessments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "health_classifications" ADD CONSTRAINT "health_classifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "health_classifications" ADD CONSTRAINT "health_classifications_assessment_id_fkey" FOREIGN KEY ("assessment_id") REFERENCES "health_assessments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_recommendations" ADD CONSTRAINT "user_recommendations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_recommendations" ADD CONSTRAINT "user_recommendations_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "recommendation_templates"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reminders" ADD CONSTRAINT "reminders_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reminder_completions" ADD CONSTRAINT "reminder_completions_reminder_id_fkey" FOREIGN KEY ("reminder_id") REFERENCES "reminders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reminder_completions" ADD CONSTRAINT "reminder_completions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gamification_profiles" ADD CONSTRAINT "gamification_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_achievements" ADD CONSTRAINT "user_achievements_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_achievements" ADD CONSTRAINT "user_achievements_achievement_id_fkey" FOREIGN KEY ("achievement_id") REFERENCES "achievements"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
