import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module';
import { UploadsModule } from '../uploads/uploads.module';
import { RiderController } from './rider.controller';
import { RiderLocationCleanupService } from './rider-location-cleanup.service';
import { RiderService } from './rider.service';

@Module({
  imports: [PrismaModule, UploadsModule],
  controllers: [RiderController],
  providers: [RiderService, RiderLocationCleanupService],
})
export class RiderModule {}
