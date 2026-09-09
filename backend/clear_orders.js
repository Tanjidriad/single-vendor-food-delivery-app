require('./scripts/_safety-guard');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  // Cascading deletes on Order should handle OrderItem and RiderAssignment
  // but to be safe, we can just delete from Order since onDelete: Cascade is likely configured.
  // Wait, let's just delete everything explicitly in reverse order to avoid foreign key constraints.
  await prisma.orderItemAddon.deleteMany({});
  await prisma.orderItem.deleteMany({});
  await prisma.riderAssignment.deleteMany({});
  await prisma.review.deleteMany({});
  await prisma.order.deleteMany({});
  console.log('All orders and assignments deleted.');
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
