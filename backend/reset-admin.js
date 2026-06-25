require('./scripts/_safety-guard');
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

async function run() {
  const hash = await bcrypt.hash('Password123!', 12);
  const admin = await prisma.user.findFirst({ where: { role: 'ADMIN' } });
  
  if (admin) {
    await prisma.user.update({
      where: { id: admin.id },
      data: { passwordHash: hash }
    });
    console.log('Password reset to Password123! for ' + admin.email);
  } else {
    console.log('No ADMIN found in DB.');
  }
}

run()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
