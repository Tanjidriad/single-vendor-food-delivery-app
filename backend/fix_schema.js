const fs = require('fs');

const file = 'C:/Users/riads/Desktop/Food_delivery/backend/prisma/schema.prisma';
let content = fs.readFileSync(file, 'utf8');

const correctOrderModel = `model Order {
  id                String        @id @default(uuid())
  orderNumber       String        @unique
  restaurantId      String
  branchId          String?
  customerId        String
  couponId          String?
  status            OrderStatus   @default(PLACED)
  orderType         OrderType     @default(DELIVERY)
  paymentMethod     PaymentMethod @default(COD)
  paymentStatus     PaymentStatus @default(PENDING)
  customerName      String
  customerPhone     String
  deliveryAddress   String?
  deliveryLat       Float?
  deliveryLng       Float?
  deliveryNote      String?
  subtotal          Float
  discountAmount    Float         @default(0)
  taxAmount         Float         @default(0)
  packagingFee      Float         @default(0)
  deliveryFee       Float         @default(0)
  riderFee          Float         @default(0)
  grandTotal        Float
  routeDistanceKm   Float?
  routeEtaMinutes   Int?
  prepMinutes       Int?
  cancelledReason   String?
  placedAt          DateTime      @default(now())
  acceptedAt        DateTime?
  readyAt           DateTime?
  pickedUpAt        DateTime?     // Set when the rider marks PICKED_UP (departure time)
  deliveredAt       DateTime?
  cancelledAt       DateTime?
  prepStartedAt     DateTime?
  rejectedAt        DateTime?
  riderAssignedAt   DateTime?
  deliveryOtp       String?
  dropoffPhotoUrl   String?
  pickupExperience  String?
  deliveryService   String?       // e.g. "Pathao Parcel", "RedX", "Steadfast"
  trackingId        String?       // Courier consignment / tracking number
  trackingUrl       String?       // Direct tracking page URL
  isTest            Boolean       @default(false)
  ignoreInReporting Boolean       @default(false)
  cancelledBy       CancelledBy?
  externalStatus    String?
  normalizedStatus  String?
  slaAcceptSeconds  Int?
  slaPrepSeconds    Int?
  slaPickupWaitSeconds Int?
  createdAt         DateTime      @default(now())
  updatedAt         DateTime      @updatedAt

  restaurant   Restaurant          @relation(fields: [restaurantId], references: [id])
  complaints   Complaint[]
  branch       Branch?             @relation(fields: [branchId], references: [id])
  customer     User                @relation("CustomerOrders", fields: [customerId], references: [id])
  coupon       Coupon?             @relation(fields: [couponId], references: [id])
  items        OrderItem[]
  statusHistory OrderStatusHistory[]
  payment      Payment?
  assignment   RiderAssignment?
  review       Review?
  placementIdempotency OrderPlacementIdempotency?

  @@index([restaurantId, status, createdAt])
  @@index([customerId, createdAt])
  @@index([customerId, status])
}`;

// The file currently has a mangled model Order block. We'll find it with regex and replace it.
const regex = /model Order\s+\{([\s\S]*?)\}\r?\n/g;
content = content.replace(regex, correctOrderModel + '\n');

fs.writeFileSync(file, content);
console.log('Fixed schema.prisma');
