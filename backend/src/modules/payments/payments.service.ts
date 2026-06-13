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

    const callbackUrl = this.config.get<string>('bkash.callbackUrl');
    if (!callbackUrl?.trim()) {
      throw new ServiceUnavailableException(
        'BKASH_CALLBACK_URL is not configured',
      );
    }

    const created = await this.gateway.createPayment({
      amount: order.grandTotal,
      merchantInvoiceNumber: order.id,
      payerReference: order.customerPhone || order.customerId,
      callbackUrl: callbackUrl.trim(),
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
      callbackUrl: callbackUrl.trim(),
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

    const trxId = result.transactionId ?? paymentId;
    const now = new Date();

    const updatedOrder = await this.prisma.$transaction(async (tx) => {
      await tx.payment.update({
        where: { orderId },
        data: {
          status: PaymentStatus.PAID,
          transactionId: trxId,
          paidAt: now,
        },
      });
      return tx.order.update({
        where: { id: orderId },
        data: { paymentStatus: PaymentStatus.PAID },
      });
    });

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
