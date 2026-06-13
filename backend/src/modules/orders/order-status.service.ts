import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
} from '@nestjs/common';
import { AssignmentStatus, OrderStatus, CancelledBy } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';

// Tighter rules as per senior PRD, but relaxed for Rider edge cases
const VALID_TRANSITIONS: Partial<Record<OrderStatus, OrderStatus[]>> = {
  PLACED: [OrderStatus.ACCEPTED, OrderStatus.REJECTED, OrderStatus.CANCELLED],
  ACCEPTED: [OrderStatus.PREPARING, OrderStatus.READY_FOR_PICKUP, OrderStatus.PICKED_UP, OrderStatus.CANCELLED],
  PREPARING: [OrderStatus.READY_FOR_PICKUP, OrderStatus.PICKED_UP, OrderStatus.CANCELLED],
  READY_FOR_PICKUP: [OrderStatus.PICKED_UP, OrderStatus.CANCELLED],
  PICKED_UP: [OrderStatus.ON_THE_WAY, OrderStatus.DELIVERY_FAILED, OrderStatus.RETURNED_TO_RESTAURANT],
  ON_THE_WAY: [OrderStatus.DELIVERED, OrderStatus.DELIVERY_FAILED, OrderStatus.RETURNED_TO_RESTAURANT],
  DELIVERY_FAILED: [OrderStatus.CANCELLED, OrderStatus.READY_FOR_PICKUP],
  RETURNED_TO_RESTAURANT: [OrderStatus.CANCELLED, OrderStatus.READY_FOR_PICKUP],
};

@Injectable()
export class OrderStatusService {
  private readonly logger = new Logger(OrderStatusService.name);

  constructor(private prisma: PrismaService) {}

  async transitionOrder(
    user: JwtPayload,
    orderId: string,
    targetStatus: OrderStatus,
    meta?: {
      note?: string;
      prepMinutes?: number;
      cancelledBy?: CancelledBy;
      isTest?: boolean;
    },
  ) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { assignment: true },
    });
    if (!order) throw new BadRequestException('Order not found');

    // Idempotency check: if already at target, return immediately
    if (order.status === targetStatus) {
      return order;
    }

    // Guard rules based on status
    const allowed = VALID_TRANSITIONS[order.status] ?? [];
    if (!allowed.includes(targetStatus)) {
      throw new BadRequestException(
        `Cannot transition from ${order.status} to ${targetStatus}`,
      );
    }

    const timestamps: Record<string, Date> = {};
    if (targetStatus === OrderStatus.ACCEPTED) timestamps.acceptedAt = new Date();
    if (targetStatus === OrderStatus.PREPARING) timestamps.prepStartedAt = new Date();
    if (targetStatus === OrderStatus.READY_FOR_PICKUP) timestamps.readyAt = new Date();
    if (targetStatus === OrderStatus.PICKED_UP) timestamps.pickedUpAt = new Date();
    if (targetStatus === OrderStatus.DELIVERED) timestamps.deliveredAt = new Date();
    if (targetStatus === OrderStatus.ON_THE_WAY) timestamps['onTheWayAt'] = new Date();
    if (targetStatus === OrderStatus.DELIVERY_FAILED || targetStatus === OrderStatus.RETURNED_TO_RESTAURANT) {
      timestamps['deliveryFailedAt'] = new Date();
    }
    if (targetStatus === OrderStatus.CANCELLED) timestamps.cancelledAt = new Date();
    if (targetStatus === OrderStatus.REJECTED) timestamps.rejectedAt = new Date();

    const updated = await this.prisma.$transaction(async (tx) => {
      const o = await tx.order.update({
        where: { id: orderId },
        data: {
          status: targetStatus,
          prepMinutes: meta?.prepMinutes ?? order.prepMinutes,
          cancelledReason:
            targetStatus === OrderStatus.CANCELLED || targetStatus === OrderStatus.REJECTED
              ? meta?.note
              : undefined,
          cancelledBy: targetStatus === OrderStatus.CANCELLED ? meta?.cancelledBy : undefined,
          ...timestamps,
        },
        include: { items: { include: { addons: true } } },
      });

      await tx.orderStatusHistory.create({
        data: {
          orderId,
          status: targetStatus,
          previousStatus: order.status,
          note: meta?.note,
          changedBy: user.sub,
        },
      });

      return o;
    });

    return updated;
  }
}
