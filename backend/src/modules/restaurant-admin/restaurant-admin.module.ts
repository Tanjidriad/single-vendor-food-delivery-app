import { Module } from '@nestjs/common';
import { RestaurantAdminController } from './restaurant-admin.controller';
import { RestaurantAdminService } from './restaurant-admin.service';

@Module({
  controllers: [RestaurantAdminController],
  providers: [RestaurantAdminService],
})
export class RestaurantAdminModule {}
