import {
  BadRequestException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { NOTIFICATIONS_QUEUE } from '../../common/queues/queue.constants';
import {
  OrderStatus,
  PaymentMethod,
  PaymentStatus,
  RefundRequestStatus,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PAYMENT_GATEWAY } from './gateways/payment-gateway.interface';
import type { PaymentGatewayProvider } from './gateways/payment-gateway.interface';
import { CreateRefundRequestDto, UpdateRefundRequestDto } from './dto/refund-request.dto';

@Injectable()
export class RefundsService {
  private readonly logger = new Logger(RefundsService.name);

  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
    @Inject(PAYMENT_GATEWAY) private gateway: PaymentGatewayProvider,
    @InjectQueue(NOTIFICATIONS_QUEUE) private notificationsQueue: Queue,
  ) {}

  async listPending(restaurantId?: string) {
    return this.prisma.refundRequest.findMany({
      where: {
        status: { in: [RefundRequestStatus.PENDING, RefundRequestStatus.APPROVED] },
        ...(restaurantId
          ? { order: { restaurantId } }
          : {}),
      },
      include: {
        order: {
          select: {
            id: true,
            orderNumber: true,
            grandTotal: true,
            paymentMethod: true,
            paymentStatus: true,
            customerId: true,
            restaurantId: true,
          },
        },
        payment: true,
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async create(dto: CreateRefundRequestDto) {
    const order = await this.prisma.order.findUnique({
      where: { id: dto.orderId },
      include: { payment: true },
    });
    if (!order) throw new NotFoundException('Order not found');
    if (dto.amount > order.grandTotal) {
      throw new BadRequestException('Refund amount exceeds order total');
    }

    const existing = await this.prisma.refundRequest.findFirst({
      where: {
        orderId: dto.orderId,
        status: { in: [RefundRequestStatus.PENDING, RefundRequestStatus.APPROVED] },
      },
    });
    if (existing) return existing;

    return this.prisma.refundRequest.create({
      data: {
        orderId: dto.orderId,
        paymentId: order.payment?.id,
        amount: dto.amount,
        reason: dto.reason,
      },
      include: { order: true, payment: true },
    });
  }

  async update(id: string, dto: UpdateRefundRequestDto) {
    const refund = await this.prisma.refundRequest.findUnique({
      where: { id },
      include: { order: true, payment: true },
    });
    if (!refund) throw new NotFoundException('Refund request not found');

    if (dto.status === RefundRequestStatus.EXECUTED) {
      return this.executeRefund(refund.id, dto.adminNote, dto.gatewayRef);
    }

    return this.prisma.refundRequest.update({
      where: { id },
      data: {
        status: dto.status,
        adminNote: dto.adminNote,
        gatewayRef: dto.gatewayRef,
      },
      include: { order: true, payment: true },
    });
  }

  async executeRefund(id: string, adminNote?: string, manualGatewayRef?: string) {
    const refund = await this.prisma.refundRequest.findUnique({
      where: { id },
      include: { order: true, payment: true },
    });
    if (!refund) throw new NotFoundException('Refund request not found');

    let gatewayRef = manualGatewayRef;

    if (
      refund.payment?.method === PaymentMethod.ONLINE &&
      refund.payment.transactionId &&
      this.gateway.refundPayment
    ) {
      const result = await this.gateway.refundPayment(
        refund.payment.transactionId,
        refund.amount,
      );
      if (!result.success) {
        await this.prisma.refundRequest.update({
          where: { id },
          data: {
            status: RefundRequestStatus.FAILED,
            adminNote: result.errorMessage ?? adminNote,
          },
        });
        throw new BadRequestException(
          result.errorMessage ?? 'Automated refund failed',
        );
      }
      gatewayRef = result.refundTrxId ?? gatewayRef;
    }

    const now = new Date();
    const updated = await this.prisma.$transaction(async (tx) => {
      const r = await tx.refundRequest.update({
        where: { id },
        data: {
          status: RefundRequestStatus.EXECUTED,
          executedAt: now,
          adminNote,
          gatewayRef,
        },
        include: { order: true, payment: true },
      });

      if (r.paymentId) {
        await tx.payment.update({
          where: { id: r.paymentId },
          data: { status: PaymentStatus.REFUNDED },
        });
      }
      await tx.order.update({
        where: { id: r.orderId },
        data: { paymentStatus: PaymentStatus.REFUNDED },
      });

      return r;
    });

    this.notificationsQueue.add('send', {
      userId: updated.order.customerId,
      title: 'Refund processed',
      body: `Your refund of ৳${updated.amount} for order ${updated.order.orderNumber} has been processed.`,
      data: { type: 'order:refund.executed', orderId: updated.orderId },
    }).catch((err) => this.logger.warn(`Failed to enqueue refund notification: ${err}`));

    return updated;
  }

  /** Reconciliation: charged at gateway but order still unpaid. */
  async enqueueOrphanPayment(orderId: string, reason: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { payment: true },
    });
    if (!order?.payment?.transactionId) return null;
    if (order.paymentStatus === PaymentStatus.PAID) return null;

    return this.create({
      orderId,
      amount: order.grandTotal,
      reason,
    });
  }

  /**
   * Create a refund request for a prepaid (ONLINE + PAID) order. It is a no-op
   * for COD or not-yet-paid orders, so it is safe to call on ANY terminal path
   * (reject, cancel, delivery failure). Idempotent via {@link create}, so
   * calling it more than once for the same order never creates a second refund.
   */
  async enqueuePrepaidRefund(orderId: string, reason: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
    });
    if (!order) return null;
    if (order.paymentMethod !== PaymentMethod.ONLINE) return null;
    if (order.paymentStatus !== PaymentStatus.PAID) return null;

    return this.create({
      orderId,
      amount: order.grandTotal,
      reason,
    });
  }

  async enqueueDeliveryFailedRefund(orderId: string) {
    return this.enqueuePrepaidRefund(
      orderId,
      'Delivery failed — prepaid order refund',
    );
  }
}
