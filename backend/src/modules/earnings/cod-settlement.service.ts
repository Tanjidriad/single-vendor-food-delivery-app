import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  CodSettlementStatus,
  OrderStatus,
  PaymentMethod,
  Prisma,
} from '@prisma/client';
import {
  codDeliveryKeptAmount,
  codFoodRemittanceAmount,
} from '../../common/utils/earnings.util';
import { round2 } from '../../common/utils/money.util';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class CodSettlementService {
  constructor(private prisma: PrismaService) {}

  async recordCodCollection(
    tx: Prisma.TransactionClient,
    order: {
      id: string;
      paymentMethod: PaymentMethod;
      grandTotal: number;
      subtotal: number;
      discountAmount: number;
      taxAmount: number;
      packagingFee: number;
      deliveryFee: number;
      riderFee: number;
      assignment?: { riderId: string; status: string } | null;
    },
    collectedAt: Date,
  ) {
    if (order.paymentMethod !== PaymentMethod.COD) return;
    if (!order.assignment || order.assignment.status !== 'ACCEPTED') return;

    await tx.order.update({
      where: { id: order.id },
      data: { codCollectedAt: collectedAt },
    });

    const existing = await tx.codSettlement.findUnique({
      where: { orderId: order.id },
    });
    if (existing) return;

    await tx.codSettlement.create({
      data: {
        orderId: order.id,
        riderId: order.assignment.riderId,
        codCollectedAmount: round2(order.grandTotal),
        foodAmountRemitted: 0,
        deliveryFeeKept: codDeliveryKeptAmount(order),
        status: CodSettlementStatus.PENDING,
      },
    });
  }

  async listPending(restaurantId?: string) {
    return this.prisma.codSettlement.findMany({
      where: {
        status: CodSettlementStatus.PENDING,
        ...(restaurantId
          ? { order: { restaurantId } }
          : {}),
      },
      orderBy: { createdAt: 'desc' },
      include: {
        order: {
          select: {
            orderNumber: true,
            grandTotal: true,
            deliveredAt: true,
            restaurantId: true,
          },
        },
        rider: { select: { fullName: true } },
      },
    });
  }

  async settle(params: {
    orderId: string;
    settledBy: string;
    foodAmountRemitted?: number;
    note?: string;
  }) {
    const settlement = await this.prisma.codSettlement.findUnique({
      where: { orderId: params.orderId },
      include: {
        order: {
          select: {
            status: true,
            subtotal: true,
            discountAmount: true,
            taxAmount: true,
            packagingFee: true,
            deliveryFee: true,
            grandTotal: true,
          },
        },
      },
    });
    if (!settlement) {
      throw new NotFoundException('COD settlement not found for this order');
    }
    if (settlement.status === CodSettlementStatus.SETTLED) {
      throw new BadRequestException('COD settlement already recorded');
    }
    if (settlement.order.status !== OrderStatus.DELIVERED) {
      throw new BadRequestException('Order must be delivered before settlement');
    }

    const expectedFood = codFoodRemittanceAmount(settlement.order);
    const foodAmountRemitted = round2(
      params.foodAmountRemitted ?? expectedFood,
    );
    if (foodAmountRemitted < 0 || foodAmountRemitted > settlement.codCollectedAmount) {
      throw new BadRequestException('Invalid food remittance amount');
    }

    return this.prisma.codSettlement.update({
      where: { id: settlement.id },
      data: {
        status: CodSettlementStatus.SETTLED,
        foodAmountRemitted,
        settledAt: new Date(),
        settledBy: params.settledBy,
        note: params.note,
      },
    });
  }
}
