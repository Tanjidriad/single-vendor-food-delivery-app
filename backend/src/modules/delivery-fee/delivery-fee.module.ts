import { Module } from '@nestjs/common';
import { DeliveryFeeController } from './delivery-fee.controller';
import { DeliveryFeeService } from './delivery-fee.service';
import { MapsService } from './maps.service';

@Module({
  controllers: [DeliveryFeeController],
  providers: [DeliveryFeeService, MapsService],
  exports: [DeliveryFeeService, MapsService],
})
export class DeliveryFeeModule {}
