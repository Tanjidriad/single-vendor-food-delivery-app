const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function run() {
  const r = await prisma.restaurant.findFirst();
  if (r) {
    await prisma.user.updateMany({
      where: { role: 'ADMIN' },
      data: { restaurantId: r.id }
    });
    console.log('Assigned restaurant to ADMINs');
  } else {
    console.log('No restaurant found');
  }
}

run().finally(() => prisma.$disconnect());
