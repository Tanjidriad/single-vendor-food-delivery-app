import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PaymentMethod, PaymentStatus } from '@prisma/client';
import { RealtimeService } from '../../gateways/realtime.service';
import { PrismaService } from '../../prisma/prisma.service';
import { PAYMENT_GATEWAY } from './gateways/payment-gateway.interface';
import type { PaymentGatewayProvider } from './gateways/payment-gateway.interface';

@Injectable()
export class PaymentsService {
  constructor(
    private prisma: PrismaService,
    private config: ConfigService,
    private realtime: RealtimeService,
    @Inject(PAYMENT_GATEWAY) private gateway: PaymentGatewayProvider,
  ) {}

  async initiateOnline(orderId: string, customerId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { payment: true },
    });
    if (!order || order.customerId !== customerId) {
      throw new NotFoundException('Order not found');
    }
    if (order.paymentMethod !== PaymentMethod.ONLINE) {
      throw new BadRequestException('Order is not online payment');
    }
    if (order.paymentStatus === PaymentStatus.PAID) {
      throw new BadRequestException('Order is already paid');
    }

    const callbackUrlBase = this.config.get<string>('bkash.callbackUrl');
    if (!callbackUrlBase?.trim()) {
      throw new ServiceUnavailableException(
        'BKASH_CALLBACK_URL is not configured',
      );
    }
    let callbackUrl: string;
    try {
      const parsed = new URL(callbackUrlBase.trim());
      if (!['http:', 'https:'].includes(parsed.protocol)) throw new Error();
      if (
        this.config.get<string>('nodeEnv') === 'production' &&
        parsed.protocol !== 'https:'
      ) {
        throw new Error();
      }
      parsed.searchParams.set('orderId', order.id);
      callbackUrl = parsed.toString();
    } catch {
      throw new ServiceUnavailableException(
        'BKASH_CALLBACK_URL must be a valid HTTPS web URL',
      );
    }

    const created = await this.gateway.createPayment({
      amount: order.grandTotal,
      merchantInvoiceNumber: order.id,
      payerReference: order.customerPhone || order.customerId,
      callbackUrl,
    });

    await this.prisma.payment.update({
      where: { orderId },
      data: { transactionId: created.paymentId },
    });

    return {
      orderId,
      gateway: this.gateway.id,
      amount: order.grandTotal,
      currency: 'BDT',
      status: PaymentStatus.PENDING,
      paymentId: created.paymentId,
      checkoutUrl: created.checkoutUrl,
      callbackUrl,
      sandboxHint:
        this.config.get<boolean>('bkash.sandbox') !== false
          ? {
              wallets: ['01770618575', '01929918378'],
              pin: '12121',
              otp: '123456',
              failWalletInsufficient: '01823074817',
              failWalletDebitBlock: '01823074818',
            }
          : undefined,
    };
  }

  async executeOnline(
    orderId: string,
    customerId: string,
    paymentId: string,
  ) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { payment: true },
    });
    if (!order || order.customerId !== customerId) {
      throw new NotFoundException('Order not found');
    }
    if (order.paymentMethod !== PaymentMethod.ONLINE) {
      throw new BadRequestException('Order is not online payment');
    }
    if (!order.payment) {
      throw new BadRequestException('Payment record missing');
    }
    if (order.paymentStatus === PaymentStatus.PAID) {
      return {
        orderId,
        status: PaymentStatus.PAID,
        transactionId: order.payment.transactionId,
        message: 'Already paid',
      };
    }

    if (
      order.payment.transactionId &&
      order.payment.transactionId !== paymentId
    ) {
      throw new BadRequestException('Payment ID does not match this order');
    }

    let result = await this.gateway.executePayment(paymentId);
    if (!result.success) {
      result = await this.gateway.queryPayment(paymentId);
    }

    if (!result.success) {
      throw new BadRequestException(
        `Payment not completed (${result.transactionStatus ?? 'unknown'})`,
      );
    }

    // Defense in depth: confirm the gateway captured the exact order total so a
    // tampered or inconsistent flow can't settle an order for the wrong amount.
    if (result.amount != null) {
      const captured = Number(result.amount);
      if (
        !Number.isFinite(captured) ||
        Math.abs(captured - order.grandTotal) > 0.01
      ) {
        throw new BadRequestException(
          'Captured payment amount does not match the order total',
        );
      }
    }

    const trxId = result.transactionId ?? paymentId;
    const now = new Date();

    // Settle atomically: only the first execute flips the status (the WHERE
    // guard), so concurrent executes can't double-settle or double-emit.
    const updatedOrder = await this.prisma.$transaction(async (tx) => {
      const settled = await tx.order.updateMany({
        where: { id: orderId, paymentStatus: { not: PaymentStatus.PAID } },
        data: { paymentStatus: PaymentStatus.PAID },
      });
      if (settled.count === 0) {
        return null;
      }
      await tx.payment.update({
        where: { orderId },
        data: {
          status: PaymentStatus.PAID,
          transactionId: trxId,
          paidAt: now,
        },
      });
      return tx.order.findUnique({ where: { id: orderId } });
    });

    // A concurrent request already settled this order — return idempotently
    // without re-emitting the restaurant notification.
    if (!updatedOrder) {
      return {
        orderId,
        gateway: this.gateway.id,
        status: PaymentStatus.PAID,
        transactionId: trxId,
        message: 'Already paid',
      };
    }

    this.realtime.emitRestaurantNewOrder(updatedOrder.restaurantId, {
      orderId: updatedOrder.id,
      orderNumber: updatedOrder.orderNumber,
      status: updatedOrder.status,
      grandTotal: updatedOrder.grandTotal,
      paymentStatus: PaymentStatus.PAID,
    });

    return {
      orderId,
      gateway: this.gateway.id,
      status: PaymentStatus.PAID,
      transactionId: trxId,
      paidAt: now,
    };
  }

  async walletPay(orderId: string, customerId: string) {
    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order || order.customerId !== customerId) {
      throw new NotFoundException('Order not found');
    }
    return {
      orderId,
      status: PaymentStatus.PENDING,
      message: 'Wallet module ready for integration',
    };
  }
}
