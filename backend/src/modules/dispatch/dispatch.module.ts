import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { ScheduleModule } from '@nestjs/schedule';
import { DISPATCH_QUEUE } from '../../common/queues/queue.constants';
import { RealtimeModule } from '../../gateways/realtime.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { DispatchController } from './dispatch.controller';
import { DispatchProcessor } from './dispatch.processor';
import { DispatchService } from './dispatch.service';
import { PathaoService } from './pathao.service';

@Module({
  imports: [
    ScheduleModule.forRoot(),
    BullModule.registerQueue({ name: DISPATCH_QUEUE }),
    RealtimeModule,
    NotificationsModule,
  ],
  controllers: [DispatchController],
  providers: [DispatchService, DispatchProcessor, PathaoService],
  exports: [DispatchService, PathaoService],
})
export class DispatchModule {}
