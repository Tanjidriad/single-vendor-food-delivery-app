import { Module } from '@nestjs/common';
import { DevicesModule } from '../devices/devices.module';
import { FcmService } from './fcm.service';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { SmsService } from './sms.service';

@Module({
  imports: [DevicesModule],
  controllers: [NotificationsController],
  providers: [NotificationsService, FcmService, SmsService],
  exports: [NotificationsService, SmsService, FcmService],
})
export class NotificationsModule {}
