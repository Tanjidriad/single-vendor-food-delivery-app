import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { NOTIFICATIONS_QUEUE } from '../../common/queues/queue.constants';
import { DevicesModule } from '../devices/devices.module';
import { FcmService } from './fcm.service';
import { NotificationsController } from './notifications.controller';
import { NotificationsProcessor } from './notifications.processor';
import { NotificationsService } from './notifications.service';
import { SmsService } from './sms.service';

@Module({
  imports: [DevicesModule, BullModule.registerQueue({ name: NOTIFICATIONS_QUEUE })],
  controllers: [NotificationsController],
  providers: [NotificationsService, NotificationsProcessor, FcmService, SmsService],
  exports: [NotificationsService, SmsService, FcmService],
})
export class NotificationsModule {}
