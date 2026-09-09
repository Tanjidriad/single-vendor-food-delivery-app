import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { NOTIFICATIONS_QUEUE } from '../../common/queues/queue.constants';
import { RealtimeModule } from '../../gateways/realtime.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { BkashProvider } from './gateways/bkash.provider';
import { PAYMENT_GATEWAY } from './gateways/payment-gateway.interface';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';
import { RefundsController } from './refunds.controller';
import { RefundsService } from './refunds.service';

@Module({
  imports: [NotificationsModule, RealtimeModule, BullModule.registerQueue({ name: NOTIFICATIONS_QUEUE })],
  controllers: [PaymentsController, RefundsController],
  providers: [
    PaymentsService,
    RefundsService,
    BkashProvider,
    { provide: PAYMENT_GATEWAY, useExisting: BkashProvider },
  ],
  exports: [PaymentsService, RefundsService],
})
export class PaymentsModule {}
