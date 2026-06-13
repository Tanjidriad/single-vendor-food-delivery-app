-- CreateEnum
CREATE TYPE "LedgerEntryType" AS ENUM ('DELIVERY_EARNED', 'PAYOUT', 'ADJUSTMENT');

-- CreateEnum
CREATE TYPE "PayoutStatus" AS ENUM ('PENDING', 'COMPLETED', 'FAILED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "CodSettlementStatus" AS ENUM ('PENDING', 'SETTLED');

-- AlterTable
ALTER TABLE "Order" ADD COLUMN "codCollectedAt" TIMESTAMP(3);

-- CreateTable
CREATE TABLE "RiderLedgerEntry" (
    "id" TEXT NOT NULL,
    "riderId" TEXT NOT NULL,
    "orderId" TEXT,
    "payoutId" TEXT,
    "type" "LedgerEntryType" NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RiderLedgerEntry_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RiderPayout" (
    "id" TEXT NOT NULL,
    "riderId" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "status" "PayoutStatus" NOT NULL DEFAULT 'PENDING',
    "reference" TEXT,
    "note" TEXT,
    "paidAt" TIMESTAMP(3),
    "createdBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "RiderPayout_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CodSettlement" (
    "id" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "riderId" TEXT NOT NULL,
    "codCollectedAmount" DOUBLE PRECISION NOT NULL,
    "foodAmountRemitted" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "deliveryFeeKept" DOUBLE PRECISION NOT NULL,
    "status" "CodSettlementStatus" NOT NULL DEFAULT 'PENDING',
    "settledAt" TIMESTAMP(3),
    "settledBy" TEXT,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CodSettlement_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "RiderLedgerEntry_orderId_type_key" ON "RiderLedgerEntry"("orderId", "type");

-- CreateIndex
CREATE INDEX "RiderLedgerEntry_riderId_createdAt_idx" ON "RiderLedgerEntry"("riderId", "createdAt");

-- CreateIndex
CREATE INDEX "RiderPayout_riderId_createdAt_idx" ON "RiderPayout"("riderId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "CodSettlement_orderId_key" ON "CodSettlement"("orderId");

-- CreateIndex
CREATE INDEX "CodSettlement_riderId_status_idx" ON "CodSettlement"("riderId", "status");

-- AddForeignKey
ALTER TABLE "RiderLedgerEntry" ADD CONSTRAINT "RiderLedgerEntry_riderId_fkey" FOREIGN KEY ("riderId") REFERENCES "RiderProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RiderLedgerEntry" ADD CONSTRAINT "RiderLedgerEntry_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RiderLedgerEntry" ADD CONSTRAINT "RiderLedgerEntry_payoutId_fkey" FOREIGN KEY ("payoutId") REFERENCES "RiderPayout"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RiderPayout" ADD CONSTRAINT "RiderPayout_riderId_fkey" FOREIGN KEY ("riderId") REFERENCES "RiderProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CodSettlement" ADD CONSTRAINT "CodSettlement_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CodSettlement" ADD CONSTRAINT "CodSettlement_riderId_fkey" FOREIGN KEY ("riderId") REFERENCES "RiderProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
