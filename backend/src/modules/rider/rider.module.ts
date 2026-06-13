import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module';
import { UploadsModule } from '../uploads/uploads.module';
import { RiderController } from './rider.controller';
import { RiderService } from './rider.service';

@Module({
  imports: [PrismaModule, UploadsModule],
  controllers: [RiderController],
  providers: [RiderService],
})
export class RiderModule {}
