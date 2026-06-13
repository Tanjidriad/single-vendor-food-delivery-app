import { NestFactory } from '@nestjs/core';
import { AppModule } from './src/app.module';
import { ReportsService } from './src/modules/reports/reports.service';
import { PrismaService } from './src/prisma/prisma.service';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const reportsService = app.get(ReportsService);
  const prisma = app.get(PrismaService);
  
  const rider = await prisma.riderProfile.findFirst();
  if (rider) {
    const earnings = await reportsService.riderEarnings(rider.id, 'day');
    console.log('EARNINGS RESPONSE:');
    console.log(JSON.stringify(earnings, null, 2));
  } else {
    console.log('No rider found');
  }
  await app.close();
}
bootstrap();
