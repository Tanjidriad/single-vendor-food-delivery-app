const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const email = 'admin@platform.com';
  
  // Check if it already exists
  let admin = await prisma.user.findUnique({ where: { email } });
  
  if (!admin) {
    admin = await prisma.user.create({
      data: {
        email,
        role: 'ADMIN',
        status: 'ACTIVE',
        passwordHash: '$2b$10$Ep2/YvT3sS4Yk2t6x/7/L.a18Z3bL8I50s6B1k4z7T0r9K5M4Uq',
      }
    });
    console.log('Admin user created:', admin.email);
  } else {
    // Ensure role is ADMIN
    await prisma.user.update({
      where: { email },
      data: { role: 'ADMIN' }
    });
    console.log('Admin user updated:', admin.email);
  }
}

main()
  .catch(e => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
