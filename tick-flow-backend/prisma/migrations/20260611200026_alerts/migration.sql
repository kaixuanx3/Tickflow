-- CreateEnum
CREATE TYPE "AlertRuleType" AS ENUM ('price_above', 'price_below');

-- CreateEnum
CREATE TYPE "AlertKind" AS ENUM ('one_shot', 're_arm');

-- CreateEnum
CREATE TYPE "AlertStatus" AS ENUM ('active', 'cooldown', 'done');

-- CreateTable
CREATE TABLE "Alert" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "symbol" TEXT NOT NULL,
    "ruleType" "AlertRuleType" NOT NULL,
    "threshold" DOUBLE PRECISION NOT NULL,
    "kind" "AlertKind" NOT NULL DEFAULT 'one_shot',
    "status" "AlertStatus" NOT NULL DEFAULT 'active',
    "triggerCount" INTEGER NOT NULL DEFAULT 0,
    "lastTriggeredAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Alert_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Alert_symbol_status_idx" ON "Alert"("symbol", "status");

-- CreateIndex
CREATE INDEX "Alert_userId_idx" ON "Alert"("userId");

-- AddForeignKey
ALTER TABLE "Alert" ADD CONSTRAINT "Alert_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
