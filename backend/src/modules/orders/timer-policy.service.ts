import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Cron, CronExpression } from '@nestjs/schedule';
import { acquireCronLock } from '../../common/utils/redis-lock.util';
import {
  FoodDisposition,
  OrderStatus,
  CancelledBy,
  PaymentMethod,
  PaymentStatus,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { RealtimeService } from '../../gateways/realtime.service';
import { OrderStatusService } from './order-status.service';
import { RefundsService } from '../payments/refunds.service';

@Injectable()
export class TimerPolicyService {
  private readonly logger = new Logger(TimerPolicyService.name);

  constructor(
    private prisma: PrismaService,
    private config: ConfigService,
    private orderStatusService: OrderStatusService,
    private realtime: RealtimeService,
    private refundsService: RefundsService,
  ) {}

  @Cron(CronExpression.EVERY_MINUTE)
  async checkSlaBreaches() {
    if (!(await acquireCronLock(this.config, 'check-sla-breaches', 55))) return;
    this.logger.debug('Checking for SLA breaches...');
    const now = new Date();

    await this.checkAcceptanceSla(now);
    await this.checkInTransitSla(now);
    await this.checkReturnedFoodDiscard(now);
    await this.checkDeliveryFailedEscalation(now);
  }

  private async checkAcceptanceSla(now: Date) {
    const placedOrders = await this.prisma.order.findMany({
      where: { status: OrderStatus.PLACED },
      include: { restaurant: { include: { settings: true } }, payment: true },
    });

    for (const order of placedOrders) {
      const slaAcceptSeconds =
        order.slaAcceptSeconds ??
        order.restaurant.settings?.slaAcceptSeconds ??
        300;

      const elapsedSeconds = (now.getTime() - order.createdAt.getTime()) / 1000;

      if (elapsedSeconds > slaAcceptSeconds) {
        this.logger.warn(`Order ${order.id} breached acceptance SLA. Cancelling.`);
        try {
          await this.orderStatusService.transitionOrder(
            { sub: 'SYSTEM', role: 'ADMIN' } as any,
            order.id,
            OrderStatus.CANCELLED,
            {
              note: 'Auto-cancelled: Kitchen failed to accept within SLA',
              cancelledBy: CancelledBy.SYSTEM,
            },
          );
          if (
            order.paymentMethod === PaymentMethod.ONLINE &&
            order.payment?.transactionId
          ) {
            await this.refundsService.enqueueOrphanPayment(
              order.id,
              'Unaccepted online order auto-cancelled',
            );
          }
        } catch (err) {
          this.logger.error(`Failed to auto-cancel order ${order.id}: ${err}`);
        }
      }
    }
  }

  private async checkInTransitSla(now: Date) {
    const inTransit = await this.prisma.order.findMany({
      where: {
        status: OrderStatus.ON_THE_WAY,
        onTheWayAt: { not: null },
      },
      include: { restaurant: { include: { settings: true } } },
    });

    for (const order of inTransit) {
      const slaTransitSeconds =
        order.slaPickupWaitSeconds ??
        order.restaurant.settings?.slaTransitSeconds ??
        1800;

      const onTheWayAt = order.onTheWayAt!;
      const elapsedSeconds = (now.getTime() - onTheWayAt.getTime()) / 1000;

      if (elapsedSeconds > slaTransitSeconds) {
        this.realtime.emitToRoom(
          `restaurant:${order.restaurantId}`,
          'order:transit.sla_breach',
          {
            orderId: order.id,
            orderNumber: order.orderNumber,
            elapsedMinutes: Math.floor(elapsedSeconds / 60),
          },
        );
        this.logger.warn(
          `Order ${order.id} in-transit SLA breach (${Math.floor(elapsedSeconds / 60)} min)`,
        );
      }
    }
  }

  private async checkReturnedFoodDiscard(now: Date) {
    const returned = await this.prisma.order.findMany({
      where: {
        status: OrderStatus.RETURNED_TO_RESTAURANT,
        foodDisposition: FoodDisposition.PENDING,
        deliveryFailedAt: {
          lt: new Date(now.getTime() - 15 * 60 * 1000),
        },
      },
    });

    for (const order of returned) {
      await this.prisma.order.update({
        where: { id: order.id },
        data: { foodDisposition: FoodDisposition.DISCARDED },
      });
    }
  }

  private async checkDeliveryFailedEscalation(now: Date) {
    const failed = await this.prisma.order.findMany({
      where: {
        status: OrderStatus.DELIVERY_FAILED,
        deliveryFailedAt: { not: null },
        paymentStatus: PaymentStatus.PAID,
      },
    });

    for (const order of failed) {
      const failedAt = order.deliveryFailedAt!;
      const elapsedHours =
        (now.getTime() - failedAt.getTime()) / (1000 * 60 * 60);

      if (elapsedHours > 2) {
        try {
          await this.orderStatusService.transitionOrder(
            { sub: 'SYSTEM', role: 'ADMIN' } as any,
            order.id,
            OrderStatus.CANCELLED,
            {
              note: 'Auto-cancelled: delivery exception unresolved after 2h',
              cancelledBy: CancelledBy.SYSTEM,
            },
          );
          await this.refundsService.enqueueDeliveryFailedRefund(order.id);
        } catch (err) {
          this.logger.error(`Failed to escalate order ${order.id}: ${err}`);
        }
      }
    }
  }
}
