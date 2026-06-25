import { RealtimeModule } from '../../gateways/realtime.module';
import { BullModule } from '@nestjs/bullmq';
import { DISPATCH_QUEUE, NOTIFICATIONS_QUEUE } from '../../common/queues/queue.constants';
import { DeliveryFeeModule } from '../delivery-fee/delivery-fee.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PrintEventsModule } from '../print-events/print-events.module';
import { DispatchModule } from '../dispatch/dispatch.module';
import { Module, forwardRef } from '@nestjs/common';
import { EarningsModule } from '../earnings/earnings.module';
import { PaymentsModule } from '../payments/payments.module';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { OrderStatusService } from './order-status.service';
import { TimerPolicyService } from './timer-policy.service';

@Module({
  imports: [
    DeliveryFeeModule,
    NotificationsModule,
    RealtimeModule,
    PrintEventsModule,
    DispatchModule,
    EarningsModule,
    forwardRef(() => PaymentsModule),
    BullModule.registerQueue(
      { name: DISPATCH_QUEUE },
      { name: NOTIFICATIONS_QUEUE },
    ),
  ],
  controllers: [OrdersController],
  providers: [OrdersService, OrderStatusService, TimerPolicyService],
  exports: [OrdersService, OrderStatusService, TimerPolicyService],
})
export class OrdersModule {}
