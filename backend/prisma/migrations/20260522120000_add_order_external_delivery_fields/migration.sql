-- External courier tracking fields on Order (Pathao, RedX, etc.)
ALTER TABLE "Order" ADD COLUMN IF NOT EXISTS "deliveryService" TEXT;
ALTER TABLE "Order" ADD COLUMN IF NOT EXISTS "trackingId" TEXT;
ALTER TABLE "Order" ADD COLUMN IF NOT EXISTS "trackingUrl" TEXT;
