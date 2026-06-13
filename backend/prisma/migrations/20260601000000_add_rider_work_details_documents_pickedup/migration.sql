-- CreateEnum
CREATE TYPE "RiderDocumentType" AS ENUM ('NID', 'DRIVING_LICENSE', 'VEHICLE_REGISTRATION', 'INSURANCE', 'OTHER');

-- CreateEnum
CREATE TYPE "RiderDocumentStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- AlterTable
ALTER TABLE "Order" ADD COLUMN     "pickedUpAt" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "RiderProfile" ADD COLUMN     "vehicleModel" TEXT,
ADD COLUMN     "vehicleRegistration" TEXT,
ADD COLUMN     "zone" TEXT;

-- CreateTable
CREATE TABLE "RiderDocument" (
    "id" TEXT NOT NULL,
    "riderId" TEXT NOT NULL,
    "type" "RiderDocumentType" NOT NULL,
    "url" TEXT NOT NULL,
    "publicId" TEXT NOT NULL,
    "status" "RiderDocumentStatus" NOT NULL DEFAULT 'PENDING',
    "uploadedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RiderDocument_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "RiderDocument_riderId_type_idx" ON "RiderDocument"("riderId", "type");

-- AddForeignKey
ALTER TABLE "RiderDocument" ADD CONSTRAINT "RiderDocument_riderId_fkey" FOREIGN KEY ("riderId") REFERENCES "RiderProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
