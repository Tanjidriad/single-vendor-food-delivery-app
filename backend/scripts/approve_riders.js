const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const bcrypt = require('bcryptjs');

async function main() {
  // 1. Approve all pending riders so they can log in
  const updatedRiders = await prisma.riderProfile.updateMany({
    where: { approvalStatus: 'PENDING' },
    data: { approvalStatus: 'APPROVED' }
  });
  console.log('Approved riders:', updatedRiders.count);

  // 2. Just in case they forgot their password, let's reset Tanjid & Smoke Rider to 'Password123!'
  const passwordHash = await bcrypt.hash('Password123!', 12);
  const phonesToReset = ['+8801990908354', '+8801799080252'];
  
  const updatedUsers = await prisma.user.updateMany({
    where: { phone: { in: phonesToReset } },
    data: { passwordHash }
  });
  console.log('Reset passwords for users:', updatedUsers.count);
}

main()
  .then(() => prisma.$disconnect())
  .catch(e => {
    console.error(e);
    prisma.$disconnect();
  });
