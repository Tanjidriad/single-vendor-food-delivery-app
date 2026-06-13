const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function run() {
  const result = await prisma.user.deleteMany({
    where: { email: 'tanjidriad3@gmail.com' }
  });
  console.log('Deleted users:', result.count);
}

run()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
