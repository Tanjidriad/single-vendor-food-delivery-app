import { Module } from '@nestjs/common';
import { EarningsModule } from '../earnings/earnings.module';
import { ReportsController } from './reports.controller';
import { ReportsService } from './reports.service';

@Module({
  imports: [EarningsModule],
  controllers: [ReportsController],
  providers: [ReportsService],
})
export class ReportsModule {}
