import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  LedgerEntryType,
  OrderStatus,
  PayoutStatus,
  Prisma,
} from '@prisma/client';
import { round2 } from '../../common/utils/money.util';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class RiderLedgerService {
  constructor(private prisma: PrismaService) {}

  async creditDeliveryEarning(
    tx: Prisma.TransactionClient,
    params: {
      orderId: string;
      riderId: string;
      amount: number;
      note?: string;
    },
  ) {
    const amount = round2(params.amount);
    if (amount <= 0) return;

    const existing = await tx.riderLedgerEntry.findFirst({
      where: {
        orderId: params.orderId,
        type: LedgerEntryType.DELIVERY_EARNED,
      },
    });
    if (existing) return;

    await tx.riderLedgerEntry.create({
      data: {
        riderId: params.riderId,
        orderId: params.orderId,
        type: LedgerEntryType.DELIVERY_EARNED,
        amount,
        note: params.note ?? 'Delivery completed',
      },
    });
  }

  async onOrderDelivered(
    tx: Prisma.TransactionClient,
    order: {
      id: string;
      status: OrderStatus;
      riderFee: number;
      assignment?: { riderId: string; status: string } | null;
    },
  ) {
    if (order.status !== OrderStatus.DELIVERED) return;
    if (!order.assignment || order.assignment.status !== 'ACCEPTED') return;

    await this.creditDeliveryEarning(tx, {
      orderId: order.id,
      riderId: order.assignment.riderId,
      amount: order.riderFee,
    });
  }

  async getRiderBalance(riderId: string) {
    const agg = await this.prisma.riderLedgerEntry.aggregate({
      where: { riderId },
      _sum: { amount: true },
    });
    return round2(agg._sum.amount ?? 0);
  }

  async listLedger(riderId: string, limit = 50) {
    return this.prisma.riderLedgerEntry.findMany({
      where: { riderId },
      orderBy: { createdAt: 'desc' },
      take: limit,
      include: {
        order: { select: { orderNumber: true } },
        payout: { select: { reference: true, status: true } },
      },
    });
  }

  async listPayouts(riderId: string, limit = 20) {
    return this.prisma.riderPayout.findMany({
      where: { riderId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }

  async createPayout(params: {
    riderId: string;
    amount: number;
    createdBy: string;
    reference?: string;
    note?: string;
  }) {
    const amount = round2(params.amount);
    if (amount <= 0) {
      throw new BadRequestException('Payout amount must be positive');
    }

    const rider = await this.prisma.riderProfile.findUnique({
      where: { id: params.riderId },
    });
    if (!rider) throw new NotFoundException('Rider not found');

    const balance = await this.getRiderBalance(params.riderId);
    if (amount > balance) {
      throw new BadRequestException(
        `Insufficient rider balance (${balance} available, ${amount} requested)`,
      );
    }

    const paidAt = new Date();
    return this.prisma.$transaction(async (tx) => {
      const payout = await tx.riderPayout.create({
        data: {
          riderId: params.riderId,
          amount,
          status: PayoutStatus.COMPLETED,
          reference: params.reference,
          note: params.note,
          paidAt,
          createdBy: params.createdBy,
        },
      });

      await tx.riderLedgerEntry.create({
        data: {
          riderId: params.riderId,
          payoutId: payout.id,
          type: LedgerEntryType.PAYOUT,
          amount: -amount,
          note: params.note ?? 'Rider payout',
        },
      });

      return payout;
    });
  }
}
