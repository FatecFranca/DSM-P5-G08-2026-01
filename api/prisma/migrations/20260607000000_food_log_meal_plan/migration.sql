-- CreateTable
CREATE TABLE "food_log_entries" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "entry_type" TEXT NOT NULL DEFAULT 'food',
    "meal_period" TEXT,
    "logged_on" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "food_log_entries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "meal_plan_caches" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "profile" "HealthProfile" NOT NULL,
    "meals" JSONB NOT NULL,
    "source" TEXT NOT NULL DEFAULT 'gemini',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "meal_plan_caches_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "food_log_entries_user_id_logged_on_idx" ON "food_log_entries"("user_id", "logged_on");

-- CreateIndex
CREATE INDEX "meal_plan_caches_user_id_created_at_idx" ON "meal_plan_caches"("user_id", "created_at");

-- AddForeignKey
ALTER TABLE "food_log_entries" ADD CONSTRAINT "food_log_entries_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "meal_plan_caches" ADD CONSTRAINT "meal_plan_caches_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
