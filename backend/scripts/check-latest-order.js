const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const order = await prisma.order.findFirst({
    orderBy: { createdAt: 'desc' },
    include: { assignment: true },
  });
  console.log(JSON.stringify(order, null, 2));
}
main().finally(() => prisma.$disconnect());
