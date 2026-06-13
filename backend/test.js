const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
prisma.restaurant.findUnique({ where: { slug: 'demo-kitchen' }, include: { settings: true, operatingHours: true, deliveryFeeConfig: true } })
  .then(console.log)
  .catch(console.error)
  .finally(() => prisma.$disconnect());
