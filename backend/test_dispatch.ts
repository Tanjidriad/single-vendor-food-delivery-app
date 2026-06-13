import { NestFactory } from '@nestjs/core';
import { AppModule } from './src/app.module';
import { PrismaService } from './src/prisma/prisma.service';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const prisma = app.get(PrismaService);
  
  const assignments = await prisma.riderAssignment.findMany({
    orderBy: { createdAt: 'desc' },
    take: 3
  });
  console.log('Recent Assignments:', JSON.stringify(assignments, null, 2));

  const riders = await prisma.riderProfile.findMany({
    select: { id: true, fullName: true, isOnline: true }
  });
  console.log('Riders:', JSON.stringify(riders, null, 2));

  await app.close();
}
bootstrap();
