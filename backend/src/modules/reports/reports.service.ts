import { Injectable } from '@nestjs/common';
import { OrderStatus, RefundRequestStatus } from '@prisma/client';
import {
  orderFoodRevenue,
  reportableDeliveredOrderWhere,
} from '../../common/utils/earnings.util';
import { round2 } from '../../common/utils/money.util';
import { PrismaService } from '../../prisma/prisma.service';
import { RiderLedgerService } from '../earnings/rider-ledger.service';

type Period = 'day' | 'week' | 'month' | 'all';

@Injectable()
export class ReportsService {
  constructor(
    private prisma: PrismaService,
    private riderLedger: RiderLedgerService,
  ) {}

  private range(period: Period) {
    const end = new Date();
    const start = new Date();
    if (period === 'all') {
      start.setFullYear(2000, 0, 1);
    } else if (period === 'day') {
      start.setHours(0, 0, 0, 0);
    } else if (period === 'week') {
      start.setDate(start.getDate() - 7);
    } else if (period === 'month') {
      start.setMonth(start.getMonth() - 1);
    }
    return { start, end };
  }

  private async executedRefundsTotal(
    restaurantId: string,
    since: Date,
  ): Promise<number> {
    const refunds = await this.prisma.refundRequest.aggregate({
      where: {
        status: RefundRequestStatus.EXECUTED,
        executedAt: { gte: since },
        order: { restaurantId },
      },
      _sum: { amount: true },
    });
    return round2(refunds._sum.amount ?? 0);
  }

  private async aggregateDeliveredOrders(
    restaurantId: string,
    since: Date,
  ) {
    const orders = await this.prisma.order.findMany({
      where: reportableDeliveredOrderWhere({
        restaurantId,
        deliveredSince: since,
      }),
      select: {
        subtotal: true,
        discountAmount: true,
        taxAmount: true,
        packagingFee: true,
        deliveryFee: true,
        grandTotal: true,
      },
    });

    let foodRevenue = 0;
    let deliveryRevenue = 0;
    let totalGmv = 0;
    for (const order of orders) {
      foodRevenue += orderFoodRevenue(order);
      deliveryRevenue += order.deliveryFee;
      totalGmv += order.grandTotal;
    }

    return {
      orderCount: orders.length,
      foodRevenue: round2(foodRevenue),
      deliveryRevenue: round2(deliveryRevenue),
      totalGmv: round2(totalGmv),
    };
  }

  async salesSummary(restaurantId: string, period: Period = 'day') {
    const { start } = this.range(period);
    const totals = await this.aggregateDeliveredOrders(restaurantId, start);
    const refundsTotal = await this.executedRefundsTotal(restaurantId, start);
    const netFoodRevenue = round2(totals.foodRevenue - refundsTotal);

    return {
      period,
      orderCount: totals.orderCount,
      foodRevenue: totals.foodRevenue,
      deliveryRevenue: totals.deliveryRevenue,
      totalGmv: totals.totalGmv,
      refundsTotal,
      netFoodRevenue,
      totalRevenue: netFoodRevenue,
      averageOrderValue: totals.orderCount
        ? round2(netFoodRevenue / totals.orderCount)
        : 0,
    };
  }

  async earnings(restaurantId: string, period: Period = 'day') {
    const { start } = this.range(period);
    const totals = await this.aggregateDeliveredOrders(restaurantId, start);
    const refundsTotal = await this.executedRefundsTotal(restaurantId, start);

    return {
      period,
      deliveredOrders: totals.orderCount,
      foodRevenue: totals.foodRevenue,
      deliveryRevenue: totals.deliveryRevenue,
      totalGmv: totals.totalGmv,
      refundsTotal,
      netFoodRevenue: round2(totals.foodRevenue - refundsTotal),
      totalPaid: round2(totals.totalGmv - refundsTotal),
      paidOrders: totals.orderCount,
    };
  }

  async riderPerformance(restaurantId: string) {
    const assignments = await this.prisma.riderAssignment.findMany({
      where: {
        order: { restaurantId, status: OrderStatus.DELIVERED },
        status: 'ACCEPTED',
      },
      include: {
        rider: { select: { id: true, fullName: true, ratingAvg: true, ratingCount: true } },
      },
    });
    const map = new Map<string, { rider: object; deliveries: number }>();
    for (const a of assignments) {
      const key = a.riderId;
      const cur = map.get(key) ?? { rider: a.rider, deliveries: 0 };
      cur.deliveries += 1;
      map.set(key, cur);
    }
    return Array.from(map.values()).sort((a, b) => b.deliveries - a.deliveries);
  }

  async riderEarnings(riderProfileId: string, period: Period = 'day') {
    const { start } = this.range(period);
    const deliveredWhere = {
      status: OrderStatus.DELIVERED,
      deliveredAt: { gte: start },
      isTest: false,
      ignoreInReporting: false,
      assignment: { riderId: riderProfileId, status: 'ACCEPTED' as const },
    };

    const deliveries = await this.prisma.order.count({ where: deliveredWhere });

    const fees = await this.prisma.order.aggregate({
      where: deliveredWhere,
      _sum: { riderFee: true },
    });
    const deliveryFeesTotal = round2(fees._sum.riderFee ?? 0);

    const totalAssignments = await this.prisma.riderAssignment.count({
      where: { riderId: riderProfileId },
    });
    const acceptedAssignments = await this.prisma.riderAssignment.count({
      where: { riderId: riderProfileId, status: 'ACCEPTED' },
    });
    const acceptanceRate =
      totalAssignments > 0
        ? Math.round((acceptedAssignments / totalAssignments) * 100)
        : 100;

    const deliveredOrders = await this.prisma.order.findMany({
      where: deliveredWhere,
      select: { pickedUpAt: true, deliveredAt: true, acceptedAt: true },
      orderBy: { deliveredAt: 'desc' },
    });
    let totalMinutesOnline = 0;
    for (const o of deliveredOrders) {
      const from = o.pickedUpAt ?? o.acceptedAt ?? o.deliveredAt;
      const to = o.deliveredAt;
      if (from && to) {
        totalMinutesOnline += (to.getTime() - from.getTime()) / 60000;
      }
    }
    const hours = Math.floor(totalMinutesOnline / 60);
    const mins = Math.round(totalMinutesOnline % 60);
    const onlineHours = hours > 0 ? `${hours}h ${mins}m` : `${mins}m`;

    const recentOrders = await this.prisma.order.findMany({
      where: deliveredWhere,
      select: {
        riderFee: true,
        deliveredAt: true,
        orderNumber: true,
        restaurant: { select: { name: true } },
      },
      orderBy: { deliveredAt: 'desc' },
      take: 20,
    });
    const history = recentOrders.map((o) => ({
      amount: o.riderFee,
      type: 'Delivery',
      time: o.deliveredAt
        ? o.deliveredAt.toLocaleTimeString('en-US', {
            hour: 'numeric',
            minute: '2-digit',
            hour12: true,
          })
        : '--',
      orderNumber: o.orderNumber,
      restaurant: o.restaurant?.name ?? '--',
    }));

    const pendingBalance = await this.riderLedger.getRiderBalance(riderProfileId);
    const payouts = await this.riderLedger.listPayouts(riderProfileId, 10);

    return {
      period,
      deliveries,
      deliveryFeesTotal,
      totalEarnings: deliveryFeesTotal,
      totalTrips: deliveries,
      acceptanceRate,
      onlineHours,
      history,
      pendingBalance,
      payoutReady: pendingBalance > 0,
      recentPayouts: payouts,
    };
  }

  async getPopularItems(restaurantId: string, limit: number = 4) {
    const popularItems = await this.prisma.orderItem.groupBy({
      by: ['menuItemId'],
      where: {
        order: reportableDeliveredOrderWhere({ restaurantId }),
      },
      _sum: {
        quantity: true,
      },
      orderBy: {
        _sum: { quantity: 'desc' },
      },
      take: limit,
    });

    const itemIds = popularItems.map((p) => p.menuItemId);
    const menuItems = await this.prisma.menuItem.findMany({
      where: { id: { in: itemIds } },
      select: {
        id: true,
        name: true,
        price: true,
        imageUrl: true,
        description: true,
        category: { select: { name: true } },
      },
    });

    // Map back to preserve order and inject totalSales
    return popularItems.map((p) => {
      const item = menuItems.find((m) => m.id === p.menuItemId);
      return {
        ...item,
        totalSales: p._sum.quantity ?? 0,
      };
    }).filter((i) => i.id); // Filter out any missing items
  }
}
