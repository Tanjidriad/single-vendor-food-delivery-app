import { NestFactory } from '@nestjs/core';
import { AppModule } from './src/app.module';
import { PrismaService } from './src/prisma/prisma.service';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const prisma = app.get(PrismaService);
  const kitchen = await prisma.user.findFirst({ where: { role: 'KITCHEN' } });
  console.log('Kitchen User:', kitchen);
  await app.close();
}
bootstrap();
