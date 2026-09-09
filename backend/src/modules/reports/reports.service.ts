import { Injectable } from '@nestjs/common';
import { OrderStatus, PaymentMethod, RefundRequestStatus } from '@prisma/client';
import {
  codDeliveryKeptAmount,
  codFoodRemittanceAmount,
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

  /// Rider-facing quality metrics for the performance insights screen.
  ///
  /// Period-scoped by assignment `createdAt` (offers) and order `deliveredAt`
  /// (completions). Rating is lifetime (from the rider profile). Every rate is
  /// an integer percentage; rates degrade to 100 when there is no denominator
  /// so a brand-new rider doesn't see a punitive 0%.
  async riderQualityMetrics(riderProfileId: string, period: Period = 'week') {
    const { start } = this.range(period);

    const offered = await this.prisma.riderAssignment.count({
      where: { riderId: riderProfileId, createdAt: { gte: start } },
    });
    const accepted = await this.prisma.riderAssignment.count({
      where: {
        riderId: riderProfileId,
        status: 'ACCEPTED',
        createdAt: { gte: start },
      },
    });
    const cancelledCount = await this.prisma.riderAssignment.count({
      where: {
        riderId: riderProfileId,
        status: 'CANCELLED',
        createdAt: { gte: start },
      },
    });
    const acceptanceRate =
      offered > 0 ? Math.round((accepted / offered) * 100) : 100;

    // Completion + on-time from delivered orders in the period.
    const deliveredOrders = await this.prisma.order.findMany({
      where: {
        status: OrderStatus.DELIVERED,
        deliveredAt: { gte: start },
        isTest: false,
        ignoreInReporting: false,
        assignment: { riderId: riderProfileId, status: 'ACCEPTED' as const },
      },
      select: {
        pickedUpAt: true,
        deliveredAt: true,
        restaurant: {
          select: { settings: { select: { slaTransitSeconds: true } } },
        },
      },
    });
    const deliveries = deliveredOrders.length;
    const completionRate =
      accepted > 0
        ? Math.min(100, Math.round((deliveries / accepted) * 100))
        : 100;

    let timedDeliveries = 0;
    let onTimeDeliveries = 0;
    for (const o of deliveredOrders) {
      if (o.pickedUpAt && o.deliveredAt) {
        timedDeliveries += 1;
        const transitSeconds =
          (o.deliveredAt.getTime() - o.pickedUpAt.getTime()) / 1000;
        const slaTransitSeconds =
          o.restaurant?.settings?.slaTransitSeconds ?? 1800;
        if (transitSeconds <= slaTransitSeconds) onTimeDeliveries += 1;
      }
    }
    const onTimeRate =
      timedDeliveries > 0
        ? Math.round((onTimeDeliveries / timedDeliveries) * 100)
        : 100;

    const profile = await this.prisma.riderProfile.findUnique({
      where: { id: riderProfileId },
      select: { ratingAvg: true, ratingCount: true },
    });

    return {
      period,
      offered,
      accepted,
      deliveries,
      cancelledCount,
      acceptanceRate,
      completionRate,
      onTimeRate,
      ratingAvg: round2(profile?.ratingAvg ?? 5),
      ratingCount: profile?.ratingCount ?? 0,
    };
  }

  /// Cash-on-delivery reconciliation for a rider.
  ///
  /// The rider collects the full grandTotal from the customer, but keeps only
  /// their riderFee. The food revenue portion (subtotal − discount + tax +
  /// packaging) must be handed back to the restaurant. This view shows both
  /// figures so the rider knows exactly how to split the cash at end of shift.
  async riderCashSummary(riderProfileId: string, period: Period = 'day') {
    const { start } = this.range(period);

    // Include COD orders for this rider via settlement rows (recorded at OTP
    // delivery), codCollectedAt, or assignment — do not require assignment
    // status ACCEPTED because that row can be replaced during dispatch retries.
    const orders = await this.prisma.order.findMany({
      where: {
        status: OrderStatus.DELIVERED,
        deliveredAt: { gte: start },
        isTest: false,
        ignoreInReporting: false,
        paymentMethod: PaymentMethod.COD,
        OR: [
          { codSettlement: { is: { riderId: riderProfileId } } },
          {
            codCollectedAt: { not: null },
            assignment: { is: { riderId: riderProfileId } },
          },
          { assignment: { is: { riderId: riderProfileId } } },
        ],
      },
      select: {
        orderNumber: true,
        grandTotal: true,
        riderFee: true,
        deliveryFee: true,
        subtotal: true,
        discountAmount: true,
        taxAmount: true,
        packagingFee: true,
        deliveredAt: true,
        codSettlement: {
          select: {
            codCollectedAmount: true,
            deliveryFeeKept: true,
          },
        },
      },
      orderBy: { deliveredAt: 'desc' },
    });

    let cashCollected = 0;
    let foodToRemit = 0;
    let deliveryFeeKept = 0;

    for (const order of orders) {
      const collected =
        order.codSettlement?.codCollectedAmount ?? order.grandTotal;
      const kept =
        order.codSettlement?.deliveryFeeKept ??
        codDeliveryKeptAmount(order);
      const remit = codFoodRemittanceAmount(order);

      cashCollected += collected;
      foodToRemit += remit;
      deliveryFeeKept += kept;
    }

    const entries = orders.slice(0, 20).map((o) => {
      const collected = o.codSettlement?.codCollectedAmount ?? o.grandTotal;
      const kept =
        o.codSettlement?.deliveryFeeKept ?? codDeliveryKeptAmount(o);
      return {
        orderNumber: o.orderNumber,
        collected: round2(collected),
        toRemit: round2(codFoodRemittanceAmount(o)),
        kept: round2(kept),
        time: o.deliveredAt
          ? o.deliveredAt.toLocaleTimeString('en-US', {
              hour: 'numeric',
              minute: '2-digit',
              hour12: true,
            })
          : '--',
      };
    });

    return {
      period,
      cashCollected: round2(cashCollected),
      ordersCount: orders.length,
      foodToRemit: round2(foodToRemit),
      deliveryFeeKept: round2(deliveryFeeKept),
      cashToDeposit: round2(foodToRemit),
      entries,
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
