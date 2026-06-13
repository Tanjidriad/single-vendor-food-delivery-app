import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const EMAIL = 'customer@example.com';
const line1 = 'House 12, Road 5, Dhaka';
const latitude = 23.815;
const longitude = 90.42;

try {
  const customer = await prisma.user.findUnique({ where: { email: EMAIL } });
  if (!customer) {
    console.error(`User not found: ${EMAIL}`);
    process.exit(1);
  }

  let addr = await prisma.address.findFirst({
    where: { userId: customer.id, line1 },
  });

  if (addr) {
    addr = await prisma.address.update({
      where: { id: addr.id },
      data: {
        label: 'HOME',
        city: 'Dhaka',
        country: 'BD',
        latitude,
        longitude,
        isDefault: true,
      },
    });
    console.log('Updated existing address:', addr.id);
  } else {
    await prisma.address.updateMany({
      where: { userId: customer.id },
      data: { isDefault: false },
    });
    addr = await prisma.address.create({
      data: {
        userId: customer.id,
        label: 'HOME',
        line1,
        city: 'Dhaka',
        country: 'BD',
        latitude,
        longitude,
        isDefault: true,
      },
    });
    console.log('Created address:', addr.id);
  }

  const all = await prisma.address.findMany({
    where: { userId: customer.id },
    orderBy: { isDefault: 'desc' },
  });
  console.log(JSON.stringify(all, null, 2));
} finally {
  await prisma.$disconnect();
}
