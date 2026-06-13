import { Injectable } from '@nestjs/common';
import { OrderStatus, UserRole } from '@prisma/client';
import {
  orderFoodRevenue,
  reportableDeliveredOrderWhere,
} from '../../common/utils/earnings.util';
import { round2 } from '../../common/utils/money.util';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AdminService {
  constructor(private prisma: PrismaService) {}

  // ─── Dashboard KPI Stats ──────────────────────────────────────────
  async getDashboardStats(restaurantId: string) {
    const [deliveredOrders, activeOrders, onlineRiders, totalCustomers, ordersToday] =
      await Promise.all([
        this.prisma.order.findMany({
          where: reportableDeliveredOrderWhere({ restaurantId }),
          select: {
            subtotal: true,
            discountAmount: true,
            taxAmount: true,
            packagingFee: true,
            deliveryFee: true,
            grandTotal: true,
          },
        }),

        // Active orders count
        this.prisma.order.count({
          where: {
            restaurantId,
            status: {
              in: [
                OrderStatus.PLACED,
                OrderStatus.ACCEPTED,
                OrderStatus.PREPARING,
                OrderStatus.READY_FOR_PICKUP,
                OrderStatus.PICKED_UP,
                OrderStatus.ON_THE_WAY,
              ],
            },
          },
        }),

        // Online riders count
        this.prisma.riderProfile.count({
          where: { isOnline: true },
        }),

        // Total registered customers
        this.prisma.user.count({
          where: { role: UserRole.CUSTOMER },
        }),

        // Orders placed today
        this.prisma.order.count({
          where: {
            restaurantId,
            placedAt: { gte: this.startOfDay() },
          },
        }),
      ]);

    let foodRevenue = 0;
    let deliveryRevenue = 0;
    let totalGmv = 0;
    for (const order of deliveredOrders) {
      foodRevenue += orderFoodRevenue(order);
      deliveryRevenue += order.deliveryFee;
      totalGmv += order.grandTotal;
    }

    return {
      totalRevenue: round2(foodRevenue),
      foodRevenue: round2(foodRevenue),
      deliveryRevenue: round2(deliveryRevenue),
      totalGmv: round2(totalGmv),
      deliveredOrders: deliveredOrders.length,
      activeOrders,
      onlineRiders,
      totalCustomers,
      ordersToday,
    };
  }

  // ─── Daily Revenue Chart ──────────────────────────────────────────
  async getDailyRevenue(restaurantId: string, days: number = 7) {
    const since = new Date();
    since.setDate(since.getDate() - days);
    since.setHours(0, 0, 0, 0);

    const orders = await this.prisma.order.findMany({
      where: {
        ...reportableDeliveredOrderWhere({ restaurantId }),
        deliveredAt: { gte: since },
      },
      select: {
        subtotal: true,
        discountAmount: true,
        taxAmount: true,
        packagingFee: true,
        deliveryFee: true,
        grandTotal: true,
        deliveredAt: true,
      },
    });

    const revenueByDate = new Map<string, number>();
    const deliveryByDate = new Map<string, number>();
    for (let i = 0; i < days; i++) {
      const d = new Date();
      d.setDate(d.getDate() - (days - 1 - i));
      const key = d.toISOString().split('T')[0];
      revenueByDate.set(key, 0);
      deliveryByDate.set(key, 0);
    }
    for (const order of orders) {
      if (!order.deliveredAt) continue;
      const dateKey = order.deliveredAt.toISOString().split('T')[0];
      revenueByDate.set(
        dateKey,
        (revenueByDate.get(dateKey) ?? 0) + orderFoodRevenue(order),
      );
      deliveryByDate.set(
        dateKey,
        (deliveryByDate.get(dateKey) ?? 0) + order.deliveryFee,
      );
    }

    return Array.from(revenueByDate.entries()).map(([date, revenue]) => ({
      date,
      revenue: round2(revenue),
      foodRevenue: round2(revenue),
      deliveryRevenue: round2(deliveryByDate.get(date) ?? 0),
    }));
  }

  // ─── Admin User List ──────────────────────────────────────────────
  async listUsers(filters: {
    role?: UserRole;
    search?: string;
    page?: number;
    limit?: number;
  }) {
    const page = filters.page ?? 1;
    const limit = filters.limit ?? 20;
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = {};
    if (filters.role) where.role = filters.role;
    if (filters.search) {
      where.OR = [
        { email: { contains: filters.search, mode: 'insensitive' } },
        { phone: { contains: filters.search } },
        { customerProfile: { fullName: { contains: filters.search, mode: 'insensitive' } } },
        { staffProfile: { fullName: { contains: filters.search, mode: 'insensitive' } } },
        { riderProfile: { fullName: { contains: filters.search, mode: 'insensitive' } } },
      ];
    }

    const [data, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          email: true,
          phone: true,
          role: true,
          status: true,
          createdAt: true,
          lastLoginAt: true,
          customerProfile: { select: { fullName: true, avatarUrl: true } },
          staffProfile: { select: { fullName: true, jobTitle: true } },
          riderProfile: { select: { fullName: true, isOnline: true, ratingAvg: true } },
          _count: { select: { orders: true } },
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      data: data.map((u) => ({
        id: u.id,
        email: u.email,
        phone: u.phone,
        role: u.role,
        status: u.status,
        createdAt: u.createdAt,
        lastLoginAt: u.lastLoginAt,
        name:
          u.customerProfile?.fullName ??
          u.staffProfile?.fullName ??
          u.riderProfile?.fullName ??
          u.email ??
          u.phone ??
          'Unknown',
        avatarUrl: u.customerProfile?.avatarUrl ?? null,
        totalOrders: u._count.orders,
        isOnline: u.riderProfile?.isOnline ?? null,
        ratingAvg: u.riderProfile?.ratingAvg ?? null,
      })),
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  // ─── Rider List ───────────────────────────────────────────────────
  async listRiders() {
    const riders = await this.prisma.riderProfile.findMany({
      include: {
        user: { select: { id: true, phone: true, email: true, status: true } },
        documents: { select: { id: true, type: true, url: true, status: true, uploadedAt: true } },
        _count: { select: { assignments: true } },
      },
      orderBy: { fullName: 'asc' },
    });

    return riders.map((r) => ({
      id: r.id,
      userId: r.userId,
      fullName: r.fullName,
      phone: r.user.phone,
      email: r.user.email,
      isOnline: r.isOnline,
      canReceiveOffers: r.canReceiveOffers,
      exceptionCount30d: r.exceptionCount30d,
      lastExceptionAt: r.lastExceptionAt,
      ratingAvg: r.ratingAvg,
      ratingCount: r.ratingCount,
      vehicleType: r.vehicleType,
      totalDeliveries: r._count.assignments,
      status: r.user.status,
      approvalStatus: r.approvalStatus,
      documents: r.documents,
    }));
  }

  async listPendingRiders() {
    const riders = await this.prisma.riderProfile.findMany({
      where: { approvalStatus: 'PENDING' },
      include: {
        user: { select: { id: true, phone: true, email: true } },
        documents: { select: { id: true, type: true, url: true, status: true, uploadedAt: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return riders.map((r) => ({
      id: r.id,
      fullName: r.fullName,
      phone: r.user.phone,
      vehicleType: r.vehicleType,
      createdAt: r.createdAt,
      documents: r.documents,
    }));
  }

  async updateRiderApprovalStatus(id: string, status: 'APPROVED' | 'REJECTED' | 'SUSPENDED') {
    const rider = await this.prisma.riderProfile.findUnique({
      where: { id },
    });
    if (!rider) throw new Error('Rider not found');

    return this.prisma.riderProfile.update({
      where: { id },
      data: { approvalStatus: status },
      select: { id: true, fullName: true, approvalStatus: true },
    });
  }

  // ─── Orders with Filters ──────────────────────────────────────────
  async listOrders(
    restaurantId: string,
    filters: {
      status?: OrderStatus;
      from?: string;
      to?: string;
      search?: string;
      page?: number;
      limit?: number;
    },
  ) {
    const page = filters.page ?? 1;
    const limit = filters.limit ?? 50;
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = { restaurantId };
    if (filters.status) where.status = filters.status;
    if (filters.from || filters.to) {
      where.placedAt = {};
      if (filters.from) (where.placedAt as Record<string, unknown>).gte = new Date(filters.from);
      if (filters.to) (where.placedAt as Record<string, unknown>).lte = new Date(filters.to);
    }
    if (filters.search) {
      where.OR = [
        { orderNumber: { contains: filters.search, mode: 'insensitive' } },
        { customerName: { contains: filters.search, mode: 'insensitive' } },
        { customerPhone: { contains: filters.search } },
      ];
    }

    const [data, total] = await Promise.all([
      this.prisma.order.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          items: { select: { name: true, quantity: true } },
          payment: true,
          assignment: {
            select: {
              status: true,
              rider: { select: { fullName: true } },
            },
          },
        },
      }),
      this.prisma.order.count({ where }),
    ]);

    return {
      data: data.map((o) => ({
        id: o.id,
        orderNumber: o.orderNumber,
        customerName: o.customerName,
        customerPhone: o.customerPhone,
        status: o.status,
        orderType: o.orderType,
        paymentMethod: o.paymentMethod,
        paymentStatus: o.paymentStatus,
        grandTotal: o.grandTotal,
        placedAt: o.placedAt,
        deliveredAt: o.deliveredAt,
        itemsSummary: o.items.map((i) => `${i.quantity}x ${i.name}`).join(', '),
        riderName: o.assignment?.rider?.fullName ?? null,
        deliveryService: o.deliveryService,
        trackingId: o.trackingId,
      })),
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  // ─── Audit Logs ───────────────────────────────────────────────────
  async listAuditLogs(page: number = 1, limit: number = 20) {
    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      this.prisma.auditLog.findMany({
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          user: {
            select: {
              email: true,
              customerProfile: { select: { fullName: true } },
              staffProfile: { select: { fullName: true } },
            },
          },
        },
      }),
      this.prisma.auditLog.count(),
    ]);

    return {
      data: data.map((log) => ({
        id: log.id,
        action: log.action,
        entityType: log.entityType,
        entityId: log.entityId,
        metadata: log.metadata,
        userName:
          log.user?.staffProfile?.fullName ??
          log.user?.customerProfile?.fullName ??
          log.user?.email ??
          'System',
        createdAt: log.createdAt,
      })),
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  // ─── Super Admin (Platform-wide) ──────────────────────────────────
  async getGlobalDashboardStats() {
    const [deliveredOrders, activeOrders, onlineRiders, totalCustomers, totalRestaurants, riderLiabilityAgg] =
      await Promise.all([
        this.prisma.order.findMany({
          where: reportableDeliveredOrderWhere(),
          select: {
            subtotal: true,
            discountAmount: true,
            taxAmount: true,
            packagingFee: true,
            deliveryFee: true,
            grandTotal: true,
          },
        }),
        this.prisma.order.count({
          where: {
            status: {
              in: [
                OrderStatus.PLACED,
                OrderStatus.ACCEPTED,
                OrderStatus.PREPARING,
                OrderStatus.READY_FOR_PICKUP,
                OrderStatus.PICKED_UP,
                OrderStatus.ON_THE_WAY,
              ],
            },
          },
        }),
        this.prisma.riderProfile.count({ where: { isOnline: true } }),
        this.prisma.user.count({ where: { role: UserRole.CUSTOMER } }),
        this.prisma.restaurant.count(),
        this.prisma.riderLedgerEntry.aggregate({ _sum: { amount: true } }),
      ]);

    let foodRevenue = 0;
    let deliveryRevenue = 0;
    let totalGmv = 0;
    for (const order of deliveredOrders) {
      foodRevenue += orderFoodRevenue(order);
      deliveryRevenue += order.deliveryFee;
      totalGmv += order.grandTotal;
    }

    return {
      totalRevenue: round2(foodRevenue),
      foodRevenue: round2(foodRevenue),
      deliveryRevenue: round2(deliveryRevenue),
      totalGmv: round2(totalGmv),
      totalRiderLiability: round2(riderLiabilityAgg._sum.amount ?? 0),
      deliveredOrders: deliveredOrders.length,
      activeOrders,
      onlineRiders,
      totalCustomers,
      totalRestaurants,
    };
  }

  async getGlobalDailyRevenue(days: number = 7) {
    const since = new Date();
    since.setDate(since.getDate() - days);
    since.setHours(0, 0, 0, 0);

    const orders = await this.prisma.order.findMany({
      where: {
        ...reportableDeliveredOrderWhere(),
        deliveredAt: { gte: since },
      },
      select: {
        subtotal: true,
        discountAmount: true,
        taxAmount: true,
        packagingFee: true,
        deliveryFee: true,
        grandTotal: true,
        deliveredAt: true,
      },
    });

    const revenueByDate = new Map<string, number>();
    for (let i = 0; i < days; i++) {
      const d = new Date();
      d.setDate(d.getDate() - (days - 1 - i));
      revenueByDate.set(d.toISOString().split('T')[0], 0);
    }
    for (const order of orders) {
      if (!order.deliveredAt) continue;
      const dateKey = order.deliveredAt.toISOString().split('T')[0];
      revenueByDate.set(
        dateKey,
        (revenueByDate.get(dateKey) ?? 0) + orderFoodRevenue(order),
      );
    }

    return Array.from(revenueByDate.entries()).map(([date, revenue]) => ({
      date,
      revenue: round2(revenue),
      foodRevenue: round2(revenue),
    }));
  }

  async listGlobalOrders(filters: {
    status?: OrderStatus;
    restaurantId?: string;
    search?: string;
    page?: number;
    limit?: number;
  }) {
    const page = filters.page ?? 1;
    const limit = filters.limit ?? 50;
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = {};
    if (filters.status) where.status = filters.status;
    if (filters.restaurantId) where.restaurantId = filters.restaurantId;
    if (filters.search) {
      where.OR = [
        { orderNumber: { contains: filters.search, mode: 'insensitive' } },
        { customerName: { contains: filters.search, mode: 'insensitive' } },
      ];
    }

    const [data, total] = await Promise.all([
      this.prisma.order.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          restaurant: { select: { name: true } },
          payment: true,
          items: true,
          assignment: {
            select: { rider: { select: { fullName: true } } },
          },
        },
      }),
      this.prisma.order.count({ where }),
    ]);

    return {
      data: data.map((o) => ({
        id: o.id,
        orderNumber: o.orderNumber,
        restaurantName: o.restaurant.name,
        customerName: o.customerName,
        status: o.status,
        orderType: o.orderType,
        grandTotal: o.grandTotal,
        placedAt: o.placedAt,
        items: o.items,
        riderName: o.assignment?.rider?.fullName ?? null,
      })),
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  async listGlobalRestaurants(filters: { search?: string; page?: number; limit?: number }) {
    const page = filters.page ?? 1;
    const limit = filters.limit ?? 20;
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = {};
    if (filters.search) {
      where.name = { contains: filters.search, mode: 'insensitive' };
    }

    const [data, total] = await Promise.all([
      this.prisma.restaurant.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          _count: { select: { orders: true, staffProfiles: true } },
        },
      }),
      this.prisma.restaurant.count({ where }),
    ]);

    return {
      data: data.map((r) => ({
        id: r.id,
        name: r.name,
        slug: r.slug,
        city: r.city,
        isActive: r.isActive,
        createdAt: r.createdAt,
        totalOrders: r._count.orders,
        staffCount: r._count.staffProfiles,
      })),
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  // ─── Helpers ──────────────────────────────────────────────────────
  private startOfDay(): Date {
    const d = new Date();
    d.setHours(0, 0, 0, 0);
    return d;
  }
}
