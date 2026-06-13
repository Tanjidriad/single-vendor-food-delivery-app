import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import {
  AssignmentStatus,
  CancelledBy,
  DeliveryExceptionReason,
  FoodDisposition,
  OrderStatus,
  OrderType,
  PaymentMethod,
  PaymentStatus,
  UserRole,
} from '@prisma/client';
import { generateOrderNumber } from '../../common/utils/order-number.util';
import { round2 } from '../../common/utils/money.util';
import { PrismaService } from '../../prisma/prisma.service';
import { RealtimeService } from '../../gateways/realtime.service';
import { DeliveryFeeService } from '../delivery-fee/delivery-fee.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PrintEventsService } from '../print-events/print-events.service';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { PlaceOrderDto } from './dto/place-order.dto';
import { generateDeliveryOtp } from '../../common/utils/otp.util';
import { CancelOrderDto } from './dto/cancel-order.dto';
import { DispatchExternalDto } from './dto/dispatch-external.dto';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { VerifyDeliveryDto } from './dto/verify-delivery.dto';
import { DeliveryExceptionDto } from './dto/delivery-exception.dto';
import {
  ResolveExceptionAction,
  ResolveExceptionDto,
} from './dto/resolve-exception.dto';
import { FoodDispositionDto } from './dto/food-disposition.dto';
import { DispatchService } from '../dispatch/dispatch.service';
import { OrderStatusService } from './order-status.service';
import { RefundsService } from '../payments/refunds.service';
import { CodSettlementService } from '../earnings/cod-settlement.service';
import { RiderLedgerService } from '../earnings/rider-ledger.service';

const STAFF_ROLES: UserRole[] = [
  UserRole.OWNER,
  UserRole.MANAGER,
  UserRole.CASHIER,
  UserRole.KITCHEN,
];

const VALID_TRANSITIONS: Partial<Record<OrderStatus, OrderStatus[]>> = {
  PLACED: [OrderStatus.ACCEPTED, OrderStatus.CANCELLED],
  ACCEPTED: [OrderStatus.PREPARING, OrderStatus.CANCELLED, OrderStatus.PICKED_UP],
  PREPARING: [OrderStatus.READY_FOR_PICKUP, OrderStatus.CANCELLED, OrderStatus.PICKED_UP],
  READY_FOR_PICKUP: [OrderStatus.PICKED_UP, OrderStatus.CANCELLED],
  PICKED_UP: [OrderStatus.ON_THE_WAY, OrderStatus.DELIVERY_FAILED, OrderStatus.RETURNED_TO_RESTAURANT],
  ON_THE_WAY: [OrderStatus.DELIVERED, OrderStatus.DELIVERY_FAILED, OrderStatus.RETURNED_TO_RESTAURANT],
  DELIVERY_FAILED: [OrderStatus.CANCELLED, OrderStatus.READY_FOR_PICKUP],
  RETURNED_TO_RESTAURANT: [OrderStatus.CANCELLED, OrderStatus.READY_FOR_PICKUP],
};

@Injectable()
export class OrdersService {
  private readonly logger = new Logger(OrdersService.name);

  constructor(
    private prisma: PrismaService,
    private deliveryFee: DeliveryFeeService,
    private realtime: RealtimeService,
    private notifications: NotificationsService,
    private printEvents: PrintEventsService,
    private dispatchService: DispatchService,
    private orderStatusService: OrderStatusService,
    private refundsService: RefundsService,
    private riderLedger: RiderLedgerService,
    private codSettlement: CodSettlementService,
  ) {}

  async placeOrder(customerId: string, dto: PlaceOrderDto) {
    const idempotencyKey = dto.idempotencyKey?.trim();
    if (idempotencyKey) {
      const existing = await this.prisma.orderPlacementIdempotency.findUnique({
        where: {
          customerId_idempotencyKey: {
            customerId,
            idempotencyKey,
          },
        },
        include: {
          order: {
            include: {
              items: { include: { addons: true } },
              payment: true,
            },
          },
        },
      });
      if (existing) {
        return existing.order;
      }
    }

    const restaurant = await this.prisma.restaurant.findUnique({
      where: { id: dto.restaurantId },
      include: { settings: true },
    });
    if (!restaurant?.isActive) {
      throw new BadRequestException('Restaurant unavailable');
    }

    const menuItems = await this.prisma.menuItem.findMany({
      where: {
        id: { in: dto.items.map((i) => i.menuItemId) },
        restaurantId: dto.restaurantId,
        isAvailable: true,
      },
    });
    if (menuItems.length !== dto.items.length) {
      throw new BadRequestException('One or more items unavailable');
    }

    const menuMap = new Map(menuItems.map((m) => [m.id, m]));

    // Resolve add-on prices SERVER-SIDE. The client only sends `addonId`; price
    // and name come from the DB. Only add-ons actually linked to the requested
    // menu item (via MenuItemAddon) and currently active are accepted — this
    // prevents a client from sending a paid add-on with price 0 to underpay.
    const requestedAddonIds = Array.from(
      new Set(dto.items.flatMap((i) => i.addons?.map((a) => a.addonId) ?? [])),
    );
    const addonLinks = requestedAddonIds.length
      ? await this.prisma.menuItemAddon.findMany({
          where: {
            menuItemId: { in: dto.items.map((i) => i.menuItemId) },
            addonId: { in: requestedAddonIds },
            addon: { isActive: true },
          },
          include: { addon: true },
        })
      : [];
    const addonMap = new Map(
      addonLinks.map((l) => [`${l.menuItemId}:${l.addonId}`, l.addon]),
    );

    let subtotal = 0;
    const orderItemsData: {
      menuItemId: string;
      name: string;
      unitPrice: number;
      quantity: number;
      notes?: string;
      lineTotal: number;
      addons: { addonId: string; name: string; price: number }[];
    }[] = [];

    for (const item of dto.items) {
      const menu = menuMap.get(item.menuItemId)!;
      const resolvedAddons = (item.addons ?? []).map((a) => {
        const addon = addonMap.get(`${item.menuItemId}:${a.addonId}`);
        if (!addon) {
          throw new BadRequestException(
            `Invalid or unavailable add-on for item "${menu.name}"`,
          );
        }
        return { addonId: addon.id, name: addon.name, price: addon.price };
      });
      const addonTotal = resolvedAddons.reduce((sum, a) => sum + a.price, 0);
      const lineTotal = round2((menu.price + addonTotal) * item.quantity);
      subtotal = round2(subtotal + lineTotal);
      orderItemsData.push({
        menuItemId: menu.id,
        name: menu.name,
        unitPrice: menu.price,
        quantity: item.quantity,
        notes: item.notes,
        lineTotal,
        addons: resolvedAddons,
      });
    }

    const settings = restaurant.settings;
    if (settings && subtotal < settings.minOrderAmount) {
      throw new BadRequestException(
        `Minimum order amount is ${settings.minOrderAmount}`,
      );
    }

    let discountAmount = 0;
    let couponId: string | undefined;
    let couponMaxUses: number | null = null;
    if (dto.couponCode) {
      const now = new Date();
      const coupon = await this.prisma.coupon.findFirst({
        where: {
          restaurantId: dto.restaurantId,
          code: dto.couponCode,
          isActive: true,
          AND: [
            { OR: [{ endsAt: null }, { endsAt: { gt: now } }] },
            { OR: [{ startsAt: null }, { startsAt: { lte: now } }] },
          ],
        },
      });
      if (!coupon) throw new BadRequestException('Invalid coupon');
      if (coupon.maxUses && coupon.usedCount >= coupon.maxUses) {
        throw new BadRequestException('Coupon usage limit reached');
      }
      if (coupon.minOrderAmount && subtotal < coupon.minOrderAmount) {
        throw new BadRequestException(
          `Minimum order ${coupon.minOrderAmount} required for this coupon`,
        );
      }
      if (coupon.discountType === 'PERCENT') {
        const percent = Math.min(Math.max(coupon.discountValue, 0), 100);
        discountAmount = round2((subtotal * percent) / 100);
      } else {
        discountAmount = round2(Math.max(coupon.discountValue, 0));
      }
      // Never let a discount exceed the subtotal (would make grandTotal negative).
      discountAmount = Math.min(discountAmount, subtotal);
      couponId = coupon.id;
      couponMaxUses = coupon.maxUses ?? null;
    }

    let deliveryFee = 0;
    let riderFee = 0;
    let routeDistanceKm: number | undefined;
    let routeEtaMinutes: number | undefined;

    if (dto.orderType === OrderType.DELIVERY) {
      if (dto.deliveryLat == null || dto.deliveryLng == null) {
        throw new BadRequestException('Delivery coordinates required');
      }
      const quote = await this.deliveryFee.quote({
        restaurantId: dto.restaurantId,
        deliveryLat: dto.deliveryLat,
        deliveryLng: dto.deliveryLng,
        subtotal,
      });
      deliveryFee = quote.deliveryFee;
      riderFee = quote.riderFee;
      routeDistanceKm = quote.distanceKm;
      routeEtaMinutes = quote.etaMinutes;
    }

    const taxAmount = settings
      ? round2((subtotal * settings.taxRatePercent) / 100)
      : 0;
    const packagingFee = round2(settings?.packagingFee ?? 0);
    const grandTotal = round2(
      subtotal - discountAmount + taxAmount + packagingFee + deliveryFee,
    );

    const customer = await this.prisma.user.findUnique({
      where: { id: customerId },
      include: { customerProfile: true },
    });

    const order = await this.prisma.$transaction(async (tx) => {
      const created = await tx.order.create({
        data: {
          orderNumber: generateOrderNumber(),
          restaurantId: dto.restaurantId,
          customerId,
          couponId,
          orderType: dto.orderType,
          paymentMethod: dto.paymentMethod,
          customerName:
            dto.customerName ?? customer?.customerProfile?.fullName ?? 'Customer',
          customerPhone: dto.customerPhone ?? customer?.phone ?? '',
          deliveryAddress: dto.deliveryAddress,
          deliveryLat: dto.deliveryLat,
          deliveryLng: dto.deliveryLng,
          deliveryNote: dto.deliveryNote,
          subtotal,
          discountAmount,
          taxAmount,
          packagingFee,
          deliveryFee,
          riderFee,
          grandTotal,
          routeDistanceKm,
          routeEtaMinutes,
          items: {
            create: orderItemsData.map((item) => ({
              menuItemId: item.menuItemId,
              name: item.name,
              unitPrice: item.unitPrice,
              quantity: item.quantity,
              notes: item.notes,
              lineTotal: item.lineTotal,
              addons: {
                create: item.addons.map((a) => ({
                  addonId: a.addonId,
                  name: a.name,
                  price: a.price,
                })),
              },
            })),
          },
          statusHistory: {
            create: { status: OrderStatus.PLACED, changedBy: customerId },
          },
          payment: {
            create: {
              method: dto.paymentMethod,
              status: PaymentStatus.PENDING,
              amount: grandTotal,
            },
          },
          ...(idempotencyKey
            ? {
                placementIdempotency: {
                  create: {
                    customerId,
                    idempotencyKey,
                  },
                },
              }
            : {}),
        },
        include: { items: { include: { addons: true } }, payment: true },
      });

      if (couponId) {
        // Atomic, conditional increment: only succeeds while usedCount is still
        // below maxUses. Two concurrent orders can't both pass a stale check and
        // push usedCount past the limit — the loser gets count === 0 here.
        const result = await tx.coupon.updateMany({
          where: {
            id: couponId,
            ...(couponMaxUses !== null
              ? { usedCount: { lt: couponMaxUses } }
              : {}),
          },
          data: { usedCount: { increment: 1 } },
        });
        if (result.count === 0) {
          throw new BadRequestException('Coupon usage limit reached');
        }
      }

      return created;
    });

    // ONLINE orders enter kitchen only after payment is confirmed (executeOnline).
    if (order.paymentMethod !== PaymentMethod.ONLINE) {
      this.emitKitchenNewOrder(order);
    }

    return order;
  }

  emitKitchenNewOrder(order: {
    id: string;
    orderNumber: string;
    status: OrderStatus;
    grandTotal: number;
    restaurantId: string;
    paymentMethod?: PaymentMethod;
    paymentStatus?: PaymentStatus;
  }) {
    this.realtime.emitRestaurantNewOrder(order.restaurantId, {
      orderId: order.id,
      orderNumber: order.orderNumber,
      status: order.status,
      grandTotal: order.grandTotal,
      paymentMethod: order.paymentMethod,
      paymentStatus: order.paymentStatus,
    });
  }

  async findOne(user: JwtPayload, orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        items: {
          include: {
            addons: true,
            // Surface the catalog image so rider screens can show thumbnails
            // (OrderItem has no image of its own).
            menuItem: { select: { imageUrl: true } },
          },
        },
        statusHistory: { orderBy: { createdAt: 'asc' } },
        restaurant: {
          select: {
            id: true,
            name: true,
            latitude: true,
            longitude: true,
            addressLine: true,
          },
        },
        assignment: {
          include: {
            rider: {
              include: {
                user: true,
                locations: {
                  orderBy: { recordedAt: 'desc' },
                  take: 1,
                },
              },
            },
          },
        },
        payment: true,
      },
    });
    if (!order) throw new NotFoundException('Order not found');
    this.assertCanViewOrder(user, order);
    return order;
  }

  async listForUser(user: JwtPayload, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    if (user.role === UserRole.CUSTOMER) {
      return this.prisma.order.findMany({
        where: { customerId: user.sub },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: { items: true },
      });
    }
    if (STAFF_ROLES.includes(user.role) && user.restaurantId) {
      const settings = await this.prisma.restaurantSettings.findUnique({
        where: { restaurantId: user.restaurantId },
        select: { showTestOrdersInKitchen: true },
      });

      const whereClause: Record<string, unknown> = { restaurantId: user.restaurantId };
      if (!settings?.showTestOrdersInKitchen) {
        whereClause.status = { not: OrderStatus.IGNORED_TEST };
      }
      // Gate unpaid ONLINE orders from kitchen until payment confirms.
      whereClause.NOT = {
        AND: [
          { paymentMethod: PaymentMethod.ONLINE },
          { paymentStatus: PaymentStatus.PENDING },
        ],
      };

      return this.prisma.order.findMany({
        where: whereClause,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: { items: true, assignment: true, payment: true },
      });
    }
    if (user.role === UserRole.RIDER && user.riderProfileId) {
      return this.prisma.order.findMany({
        where: { assignment: { riderId: user.riderProfileId } },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: {
          items: { include: { menuItem: { select: { imageUrl: true } } } },
        },
      });
    }
    throw new ForbiddenException('Role not permitted to list orders');
  }

  async updateStatus(
    user: JwtPayload,
    orderId: string,
    dto: UpdateOrderStatusDto,
  ) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { assignment: true },
    });
    if (!order) throw new NotFoundException('Order not found');

    if (user.role === UserRole.RIDER) {
      return this.updateRiderStatus(user, order, dto);
    }

    if (!STAFF_ROLES.includes(user.role)) {
      throw new ForbiddenException();
    }
    if (user.restaurantId !== order.restaurantId) {
      throw new ForbiddenException();
    }

    if (
      order.paymentMethod === PaymentMethod.ONLINE &&
      order.paymentStatus !== PaymentStatus.PAID &&
      dto.status !== OrderStatus.CANCELLED &&
      dto.status !== OrderStatus.REJECTED
    ) {
      throw new BadRequestException(
        'Cannot progress unpaid online order — wait for payment confirmation',
      );
    }

    const updated = await this.orderStatusService.transitionOrder(
      user,
      orderId,
      dto.status,
      { note: dto.note, prepMinutes: dto.prepMinutes }
    );

    if (
      dto.status === OrderStatus.ACCEPTED ||
      dto.status === OrderStatus.PREPARING
    ) {
      await this.printEvents.logAndEmit({
        orderId,
        restaurantId: order.restaurantId,
        printType: 'KITCHEN_TICKET',
        status: 'REQUESTED',
      });
    }

    if (dto.status === OrderStatus.READY_FOR_PICKUP) {
      if (!order.assignment || order.assignment.status === AssignmentStatus.EXPIRED || order.assignment.status === AssignmentStatus.REJECTED) {
        void this.dispatchService
          .autoAssign(user, orderId)
          .then((assignment) => {
            this.logger.log(
              `Auto-assigned rider ${assignment.riderId} for ready order ${orderId}`,
            );
          })
          .catch((err: unknown) => {
            const message = err instanceof Error ? err.message : String(err);
            this.logger.warn(`Failed to auto-assign order ${orderId} at ready: ${message}`);
            this.realtime.emitToRoom(`restaurant:${order.restaurantId}`, 'order:dispatch.failed', {
              orderId,
              phase: 'READY_FOR_PICKUP',
              reason: message,
            });
          });
      }
    }

    if (dto.status === OrderStatus.DELIVERED) {
      await this.printEvents.logAndEmit({
        orderId,
        restaurantId: order.restaurantId,
        printType: 'CUSTOMER_RECEIPT',
        status: 'REQUESTED',
      });
    }

    this.broadcastStatus(updated);
    return updated;
  }

  private async updateRiderStatus(
    user: JwtPayload,
    order: {
      id: string;
      status: OrderStatus;
      customerId: string;
      assignment: { riderId: string } | null;
    },
    dto: UpdateOrderStatusDto,
  ) {
    if (!order.assignment || order.assignment.riderId !== user.riderProfileId) {
      throw new ForbiddenException();
    }
    // Riders can only advance pickup/transit. DELIVERED is NOT settable here:
    // it must go through verifyDeliveryOtp() so cash-on-delivery is only ever
    // marked PAID after the customer's OTP is confirmed at the door.
    const riderAllowed: OrderStatus[] = [
      OrderStatus.PICKED_UP,
      OrderStatus.ON_THE_WAY,
    ];
    if (!riderAllowed.includes(dto.status)) {
      throw new BadRequestException('Rider cannot set this status');
    }
    // Enforce the state machine so a rider can't skip steps (e.g. jump straight
    // to ON_THE_WAY without PICKED_UP).
    const allowed: OrderStatus[] = [OrderStatus.PICKED_UP, OrderStatus.ON_THE_WAY, OrderStatus.READY_FOR_PICKUP];
    if (!allowed.includes(dto.status)) {
      throw new BadRequestException(
        `Cannot transition from ${order.status} to ${dto.status}`,
      );
    }

    const deliveryOtp =
      dto.status === OrderStatus.ON_THE_WAY ? generateDeliveryOtp() : undefined;

    // Use orderStatusService for the core update
    const updated = await this.orderStatusService.transitionOrder(
      user,
      order.id,
      dto.status,
      { note: dto.note }
    );
    
    if (deliveryOtp) {
       await this.prisma.order.update({
         where: { id: order.id },
         data: { deliveryOtp, onTheWayAt: new Date() },
       });
       updated['deliveryOtp'] = deliveryOtp;
       updated['onTheWayAt'] = new Date();
    }

    this.broadcastStatus(updated);

    if (dto.status === OrderStatus.ON_THE_WAY && deliveryOtp) {
      void this.notifications.sendToUser(
        order.customerId,
        'Delivery OTP',
        `Your delivery code is ${deliveryOtp}`,
        { type: 'order:delivery.otp', orderId: order.id },
      );
    }

    return updated;
  }

  private broadcastStatus(order: {
    id: string;
    status: OrderStatus;
    orderNumber: string;
    restaurantId: string;
    customerId: string;
    paymentMethod?: PaymentMethod;
    paymentStatus?: PaymentStatus;
  }) {
    const payload = {
      orderId: order.id,
      orderNumber: order.orderNumber,
      status: order.status,
    };
    this.realtime.emitOrderStatus(order.id, payload);
    this.realtime.emitToRoom(
      `restaurant:${order.restaurantId}`,
      'order:status.changed',
      payload,
    );
    const customerMessage = this.customerStatusMessage(order);
    void this.notifications.sendToUser(
      order.customerId,
      customerMessage.title,
      customerMessage.body,
      { type: 'order:status.changed', orderId: order.id, status: order.status },
    );
  }

  private customerStatusMessage(order: {
    status: OrderStatus;
    orderNumber: string;
    paymentMethod?: PaymentMethod;
    paymentStatus?: PaymentStatus;
  }) {
    if (order.status === OrderStatus.DELIVERY_FAILED) {
      const prepaid =
        order.paymentMethod === PaymentMethod.ONLINE &&
        order.paymentStatus === PaymentStatus.PAID;
      return {
        title: 'Delivery issue',
        body: prepaid
          ? `We couldn't complete delivery for order ${order.orderNumber}. Your refund is being processed.`
          : `We couldn't complete delivery for order ${order.orderNumber}. We're resolving this now.`,
      };
    }
    return {
      title: 'Order update',
      body: `Your order ${order.orderNumber} is now ${order.status}`,
    };
  }

  private assertCanViewOrder(
    user: JwtPayload,
    order: {
      customerId: string;
      restaurantId: string;
      assignment?: { riderId: string } | null;
    },
  ) {
    if (user.role === UserRole.CUSTOMER && order.customerId === user.sub) {
      return;
    }
    if (STAFF_ROLES.includes(user.role) && user.restaurantId === order.restaurantId) {
      return;
    }
    if (
      user.role === UserRole.RIDER &&
      user.riderProfileId &&
      order.assignment?.riderId === user.riderProfileId
    ) {
      return;
    }
    throw new ForbiddenException();
  }

  async acceptOrder(user: JwtPayload, orderId: string, prepMinutes?: number) {
    const order = await this.updateStatus(user, orderId, {
      status: OrderStatus.ACCEPTED,
      prepMinutes,
    });

    // Auto-assign rider after order is accepted.
    void this.dispatchService
      .autoAssign(user, orderId)
      .then((assignment) => {
        this.logger.log(
          `Auto-assigned rider ${assignment.riderId} for accepted order ${orderId}`,
        );
      })
      .catch((err: unknown) => {
        const message = err instanceof Error ? err.message : String(err);
        this.logger.warn(`Failed to auto-assign order ${orderId}: ${message}`);
        this.realtime.emitToRoom(`restaurant:${order.restaurantId}`, 'order:dispatch.failed', {
          orderId,
          phase: 'ORDER_ACCEPTED',
          reason: message,
        });
      });

    return order;
  }

  async rejectOrder(user: JwtPayload, orderId: string, note?: string) {
    const updated = await this.orderStatusService.transitionOrder(user, orderId, OrderStatus.REJECTED, {
      note: note ?? 'Order rejected by restaurant',
    });
    this.broadcastStatus(updated as any);
    return updated;
  }

  async cancelOrder(user: JwtPayload, orderId: string, dto: CancelOrderDto) {
    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) throw new NotFoundException('Order not found');

    if (user.role === UserRole.CUSTOMER) {
      if (order.customerId !== user.sub) throw new ForbiddenException();
      if (
        order.status !== OrderStatus.PLACED &&
        order.status !== OrderStatus.ACCEPTED
      ) {
        throw new BadRequestException(
          'Order can only be cancelled before preparation starts',
        );
      }
    } else if (STAFF_ROLES.includes(user.role)) {
      if (user.restaurantId !== order.restaurantId) {
        throw new ForbiddenException();
      }
    } else {
      throw new ForbiddenException();
    }

    const cancelledBy = user.role === UserRole.CUSTOMER ? 'CUSTOMER' : 'KITCHEN';

    const updated = await this.orderStatusService.transitionOrder(user, orderId, OrderStatus.CANCELLED, {
      note: dto.reason ?? 'Cancelled',
      cancelledBy: cancelledBy as any
    });

    await this.dispatchService.releaseAssignmentsForTerminalOrder(orderId, this.prisma);

    this.broadcastStatus(updated as any);
    return updated;
  }

  async getKitchenHistory(user: JwtPayload, date?: string, includeTest = false) {
    if (!STAFF_ROLES.includes(user.role)) {
      throw new ForbiddenException();
    }
    
    let startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);
    
    if (date) {
      const parsed = new Date(date);
      if (!isNaN(parsed.getTime())) {
        startOfDay = parsed;
      }
    }
    
    const endOfDay = new Date(startOfDay);
    endOfDay.setDate(endOfDay.getDate() + 1);

    const orders = await this.prisma.order.findMany({
      where: {
        restaurantId: user.restaurantId as string,
        status: { in: [OrderStatus.DELIVERED, OrderStatus.REJECTED, OrderStatus.CANCELLED, OrderStatus.IGNORED_TEST] },
        ...(includeTest ? {} : { isTest: false, ignoreInReporting: false }),
        OR: [
          { deliveredAt: { gte: startOfDay, lt: endOfDay } },
          { rejectedAt: { gte: startOfDay, lt: endOfDay } },
          { cancelledAt: { gte: startOfDay, lt: endOfDay } },
        ]
      },
      orderBy: { createdAt: 'desc' },
      include: { items: true },
    });

    return orders;
  }

  async reorder(user: JwtPayload, orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { items: { include: { addons: true } } },
    });
    if (!order) throw new NotFoundException('Order not found');
    if (order.customerId !== user.sub) throw new ForbiddenException();

    const dto: PlaceOrderDto = {
      restaurantId: order.restaurantId,
      orderType: order.orderType,
      paymentMethod: order.paymentMethod,
      deliveryAddress: order.deliveryAddress ?? undefined,
      deliveryLat: order.deliveryLat ?? undefined,
      deliveryLng: order.deliveryLng ?? undefined,
      deliveryNote: order.deliveryNote ?? undefined,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      items: order.items.map((item) => ({
        menuItemId: item.menuItemId,
        quantity: item.quantity,
        notes: item.notes ?? undefined,
        // Only re-add add-ons we can resolve by id; price/name come from the DB.
        addons: item.addons
          .filter((a) => a.addonId)
          .map((a) => ({ addonId: a.addonId as string })),
      })),
    };

    return this.placeOrder(user.sub, dto);
  }

  /**
   * Dispatch an order via a third-party courier (e.g. Pathao Parcel, RedX).
   * - Cancels any active local rider assignment.
   * - Sets the order status directly to ON_THE_WAY.
   * - Saves courier name, tracking ID, and optional tracking URL.
   */
  async dispatchExternal(
    user: JwtPayload,
    orderId: string,
    dto: DispatchExternalDto,
  ) {
    if (!STAFF_ROLES.includes(user.role)) {
      throw new ForbiddenException();
    }

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { assignment: true },
    });
    if (!order) throw new NotFoundException('Order not found');
    if (user.restaurantId !== order.restaurantId) {
      throw new ForbiddenException();
    }

    const dispatchableStatuses: OrderStatus[] = [
      OrderStatus.ACCEPTED,
      OrderStatus.PREPARING,
      OrderStatus.READY_FOR_PICKUP,
    ];
    if (!dispatchableStatuses.includes(order.status)) {
      throw new BadRequestException(
        'Order must be accepted/preparing/ready before external dispatch',
      );
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      // Cancel any pending local rider assignment
      if (
        order.assignment &&
        (order.assignment.status === AssignmentStatus.CREATED ||
         order.assignment.status === AssignmentStatus.NOTIFIED)
      ) {
        await tx.riderAssignment.update({
          where: { id: order.assignment.id },
          data: { status: AssignmentStatus.CANCELLED },
        });
      }

      const o = await tx.order.update({
        where: { id: orderId },
        data: {
          status: OrderStatus.ON_THE_WAY,
          deliveryService: dto.deliveryService,
          trackingId: dto.trackingId,
          trackingUrl: dto.trackingUrl,
        },
        include: { items: { include: { addons: true } } },
      });

      await tx.orderStatusHistory.create({
        data: {
          orderId,
          status: OrderStatus.ON_THE_WAY,
          note: `Dispatched via ${dto.deliveryService} — Tracking: ${dto.trackingId}`,
          changedBy: user.sub,
        },
      });

      return o;
    });

    this.broadcastStatus(updated);

    // Notify customer about external delivery
    void this.notifications.sendToUser(
      order.customerId,
      'Order shipped!',
      `Your order ${order.orderNumber} is on the way via ${dto.deliveryService}. Track: ${dto.trackingId}`,
      {
        type: 'order:dispatched.external',
        orderId: order.id,
        deliveryService: dto.deliveryService,
        trackingId: dto.trackingId,
        trackingUrl: dto.trackingUrl ?? '',
      },
    );

    return updated;
  }

  /**
   * Allow a customer to confirm receipt of an externally-delivered order.
   * This bypasses rider OTP verification since third-party couriers
   * don't use our rider app.
   */
  async confirmDeliveryByCustomer(user: JwtPayload, orderId: string) {
    if (user.role !== UserRole.CUSTOMER) {
      throw new ForbiddenException();
    }

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
    });
    if (!order) throw new NotFoundException('Order not found');
    if (order.customerId !== user.sub) {
      throw new ForbiddenException();
    }
    if (order.status !== OrderStatus.ON_THE_WAY) {
      throw new BadRequestException('Order must be on the way to confirm delivery');
    }
    if (!order.deliveryService) {
      throw new BadRequestException(
        'Only orders dispatched via third-party courier can be confirmed by customer',
      );
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const o = await tx.order.update({
        where: { id: orderId },
        data: {
          status: OrderStatus.DELIVERED,
          deliveredAt: new Date(),
        },
        include: { items: { include: { addons: true } } },
      });

      await tx.orderStatusHistory.create({
        data: {
          orderId,
          status: OrderStatus.DELIVERED,
          note: 'Delivery confirmed by customer (external courier)',
          changedBy: user.sub,
        },
      });

      // COD is collected on delivery, so mark it PAID now. Online payments stay
      // PENDING until settled by the gateway (bKash) — never auto-mark them here.
      if (order.paymentMethod === PaymentMethod.COD) {
        const paidAt = new Date();
        await tx.payment.updateMany({
          where: { orderId },
          data: { status: PaymentStatus.PAID, paidAt },
        });
        await tx.order.update({
          where: { id: orderId },
          data: { paymentStatus: PaymentStatus.PAID },
        });
      }

      return o;
    });

    this.broadcastStatus(updated);

    // Print receipt
    await this.printEvents.logAndEmit({
      orderId,
      restaurantId: order.restaurantId,
      printType: 'CUSTOMER_RECEIPT',
      status: 'REQUESTED',
    });

    return updated;
  }

  async verifyDeliveryOtp(
    user: JwtPayload,
    orderId: string,
    dto: VerifyDeliveryDto,
  ) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { assignment: true },
    });
    if (!order) throw new NotFoundException('Order not found');
    if (
      user.role !== UserRole.RIDER ||
      !order.assignment ||
      order.assignment.riderId !== user.riderProfileId
    ) {
      throw new ForbiddenException();
    }
    if (order.status !== OrderStatus.ON_THE_WAY) {
      throw new BadRequestException('Order must be on the way to verify delivery');
    }
    if (!order.deliveryOtp || order.deliveryOtp !== dto.otp) {
      throw new BadRequestException('Invalid delivery OTP');
    }

    // This is the ONLY path a rider-delivered order reaches DELIVERED, and the
    // only place COD is marked PAID — i.e. the OTP at the door is what confirms
    // both delivery and cash collection. Online payments stay PENDING (bKash).
    const updated = await this.prisma.$transaction(async (tx) => {
      const o = await tx.order.update({
        where: { id: orderId },
        data: {
          status: OrderStatus.DELIVERED,
          deliveredAt: new Date(),
          deliveryOtp: null,
          dropoffPhotoUrl: dto.dropoffPhotoUrl,
          pickupExperience: dto.pickupExperience,
        },
        include: { items: { include: { addons: true } } },
      });
      await tx.orderStatusHistory.create({
        data: {
          orderId,
          status: OrderStatus.DELIVERED,
          note: 'Delivery confirmed via OTP',
          changedBy: user.sub,
        },
      });
      if (order.paymentMethod === PaymentMethod.COD) {
        const paidAt = new Date();
        await tx.payment.updateMany({
          where: { orderId },
          data: { status: PaymentStatus.PAID, paidAt },
        });
        await tx.order.update({
          where: { id: orderId },
          data: { paymentStatus: PaymentStatus.PAID },
        });
      }
      await this.dispatchService.releaseAssignmentsForTerminalOrder(
        orderId,
        tx,
      );

      const deliveredOrder = await tx.order.findUnique({
        where: { id: orderId },
        include: { assignment: true },
      });
      if (deliveredOrder) {
        const collectedAt = new Date();
        await this.riderLedger.onOrderDelivered(tx, deliveredOrder);
        await this.codSettlement.recordCodCollection(
          tx,
          deliveredOrder,
          collectedAt,
        );
      }

      return o;
    });

    this.broadcastStatus(updated);

    await this.printEvents.logAndEmit({
      orderId,
      restaurantId: order.restaurantId,
      printType: 'CUSTOMER_RECEIPT',
      status: 'REQUESTED',
    });

    return updated;
  }

  async reportDeliveryException(
    user: JwtPayload,
    orderId: string,
    dto: DeliveryExceptionDto,
  ) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { assignment: true },
    });
    if (!order) throw new NotFoundException('Order not found');
    if (
      user.role !== UserRole.RIDER ||
      !order.assignment ||
      order.assignment.riderId !== user.riderProfileId
    ) {
      throw new ForbiddenException();
    }
    const allowed: OrderStatus[] = [
      OrderStatus.PICKED_UP,
      OrderStatus.ON_THE_WAY,
    ];
    if (!allowed.includes(order.status)) {
      throw new BadRequestException(
        'Delivery exceptions only allowed during active delivery',
      );
    }

    const targetStatus = dto.foodReturned
      ? OrderStatus.RETURNED_TO_RESTAURANT
      : OrderStatus.DELIVERY_FAILED;

    const compensation = this.riderCompensationForException(
      dto.reason,
      order.deliveryFee,
    );

    const updated = await this.prisma.$transaction(async (tx) => {
      await tx.deliveryException.create({
        data: {
          orderId,
          riderId: user.riderProfileId!,
          reason: dto.reason,
          note: dto.note,
          photoUrl: dto.photoUrl,
          latitude: dto.latitude,
          longitude: dto.longitude,
          foodReturned: dto.foodReturned ?? false,
          riderCompensationAmount: compensation,
        },
      });

      if (order.assignment) {
        await tx.riderAssignment.update({
          where: { id: order.assignment.id },
          data: { status: AssignmentStatus.CANCELLED },
        });
      }

      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      const rider = await tx.riderProfile.update({
        where: { id: user.riderProfileId! },
        data: {
          exceptionCount30d: { increment: 1 },
          lastExceptionAt: new Date(),
          canReceiveOffers:
            (await tx.deliveryException.count({
              where: {
                riderId: user.riderProfileId!,
                createdAt: { gte: thirtyDaysAgo },
              },
            })) < 5,
        },
      });

      const o = await tx.order.update({
        where: { id: orderId },
        data: {
          status: targetStatus,
          deliveryFailedAt: new Date(),
          deliveryOtp: null,
          foodDisposition: dto.foodReturned ? FoodDisposition.PENDING : null,
        },
        include: { items: { include: { addons: true } }, payment: true },
      });

      await tx.orderStatusHistory.create({
        data: {
          orderId,
          status: targetStatus,
          previousStatus: order.status,
          note: `Delivery exception: ${dto.reason}`,
          changedBy: user.sub,
        },
      });

      return { order: o, rider };
    });

    this.broadcastStatus(updated.order);
    this.realtime.emitToRoom(
      `restaurant:${order.restaurantId}`,
      'order:delivery.exception',
      {
        orderId,
        reason: dto.reason,
        status: targetStatus,
      },
    );

    return updated.order;
  }

  private riderCompensationForException(
    reason: DeliveryExceptionReason,
    deliveryFee: number,
  ): number | null {
    if (reason === DeliveryExceptionReason.ACCIDENT_EMERGENCY) {
      return Math.round(deliveryFee * 0.5 * 100) / 100;
    }
    return null;
  }

  async setFoodDisposition(
    user: JwtPayload,
    orderId: string,
    dto: FoodDispositionDto,
  ) {
    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) throw new NotFoundException('Order not found');
    if (!STAFF_ROLES.includes(user.role) || user.restaurantId !== order.restaurantId) {
      throw new ForbiddenException();
    }
    if (order.status !== OrderStatus.RETURNED_TO_RESTAURANT) {
      throw new BadRequestException('Order is not in returned state');
    }

    const updated = await this.prisma.order.update({
      where: { id: orderId },
      data: { foodDisposition: dto.disposition },
      include: { items: { include: { addons: true } } },
    });
    this.broadcastStatus(updated);
    return updated;
  }

  async resolveDeliveryException(
    user: JwtPayload,
    orderId: string,
    dto: ResolveExceptionDto,
  ) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { items: { include: { addons: true } }, payment: true },
    });
    if (!order) throw new NotFoundException('Order not found');
    if (!STAFF_ROLES.includes(user.role) && user.role !== UserRole.ADMIN) {
      throw new ForbiddenException();
    }
    if (
      user.role !== UserRole.ADMIN &&
      user.restaurantId !== order.restaurantId
    ) {
      throw new ForbiddenException();
    }
    if (
      order.status !== OrderStatus.DELIVERY_FAILED &&
      order.status !== OrderStatus.RETURNED_TO_RESTAURANT
    ) {
      throw new BadRequestException('Order is not awaiting exception resolution');
    }

    switch (dto.action) {
      case ResolveExceptionAction.REASSIGN: {
        const updated = await this.orderStatusService.transitionOrder(
          user,
          orderId,
          OrderStatus.READY_FOR_PICKUP,
          { note: dto.note ?? 'Re-dispatch after delivery exception' },
        );
        void this.dispatchService.autoAssign(user, orderId).catch(() => undefined);
        this.broadcastStatus(updated);
        return updated;
      }
      case ResolveExceptionAction.CANCEL_REFUND: {
        const updated = await this.orderStatusService.transitionOrder(
          user,
          orderId,
          OrderStatus.CANCELLED,
          { note: dto.note ?? 'Cancelled after delivery exception', cancelledBy: CancelledBy.SYSTEM },
        );
        await this.refundsService.enqueueDeliveryFailedRefund(orderId);
        this.broadcastStatus(updated);
        return updated;
      }
      case ResolveExceptionAction.CLONE_REORDER: {
        const clone = await this.cloneOrderForRedelivery(user, order);
        return clone;
      }
      case ResolveExceptionAction.RESOLVED_NO_REFUND:
      default: {
        const updated = await this.orderStatusService.transitionOrder(
          user,
          orderId,
          OrderStatus.CANCELLED,
          { note: dto.note ?? 'Exception resolved without refund' },
        );
        this.broadcastStatus(updated);
        return updated;
      }
    }
  }

  private async cloneOrderForRedelivery(
    user: JwtPayload,
    source: {
      id: string;
      restaurantId: string;
      branchId: string | null;
      customerId: string;
      couponId: string | null;
      orderType: OrderType;
      paymentMethod: PaymentMethod;
      customerName: string;
      customerPhone: string;
      deliveryAddress: string | null;
      deliveryLat: number | null;
      deliveryLng: number | null;
      deliveryNote: string | null;
      subtotal: number;
      discountAmount: number;
      taxAmount: number;
      packagingFee: number;
      deliveryFee: number;
      riderFee: number;
      grandTotal: number;
      items: Array<{
        menuItemId: string;
        name: string;
        unitPrice: number;
        quantity: number;
        notes: string | null;
        lineTotal: number;
        addons: Array<{ addonId: string | null; name: string; price: number }>;
      }>;
    },
  ) {
    const orderNumber = generateOrderNumber();
    const clone = await this.prisma.$transaction(async (tx) => {
      const created = await tx.order.create({
        data: {
          orderNumber,
          restaurantId: source.restaurantId,
          branchId: source.branchId,
          customerId: source.customerId,
          couponId: null,
          parentOrderId: source.id,
          orderType: source.orderType,
          paymentMethod: source.paymentMethod,
          paymentStatus:
            source.paymentMethod === PaymentMethod.ONLINE
              ? PaymentStatus.PAID
              : PaymentStatus.PENDING,
          customerName: source.customerName,
          customerPhone: source.customerPhone,
          deliveryAddress: source.deliveryAddress,
          deliveryLat: source.deliveryLat,
          deliveryLng: source.deliveryLng,
          deliveryNote: source.deliveryNote,
          subtotal: source.subtotal,
          discountAmount: source.discountAmount,
          taxAmount: source.taxAmount,
          packagingFee: source.packagingFee,
          deliveryFee: source.deliveryFee,
          riderFee: source.riderFee,
          grandTotal: source.grandTotal,
          items: {
            create: source.items.map((item) => ({
              menuItemId: item.menuItemId,
              name: item.name,
              unitPrice: item.unitPrice,
              quantity: item.quantity,
              notes: item.notes,
              lineTotal: item.lineTotal,
              addons: {
                create: item.addons.map((a) => ({
                  addonId: a.addonId,
                  name: a.name,
                  price: a.price,
                })),
              },
            })),
          },
          statusHistory: {
            create: {
              status: OrderStatus.PLACED,
              note: `Cloned from ${source.id} after delivery exception`,
              changedBy: user.sub,
            },
          },
          payment: {
            create: {
              method: source.paymentMethod,
              status:
                source.paymentMethod === PaymentMethod.ONLINE
                  ? PaymentStatus.PAID
                  : PaymentStatus.PENDING,
              amount: source.grandTotal,
            },
          },
        },
        include: { items: { include: { addons: true } }, payment: true },
      });
      await tx.order.update({
        where: { id: source.id },
        data: {
          status: OrderStatus.CANCELLED,
          cancelledAt: new Date(),
          cancelledReason: 'Replaced by redelivery clone',
        },
      });
      return created;
    });

    this.emitKitchenNewOrder(clone);
    this.broadcastStatus(clone);
    return clone;
  }

  async listOpsQueues(user: JwtPayload) {
    const restaurantId =
      user.role === UserRole.ADMIN ? undefined : user.restaurantId;
    if (!restaurantId && user.role !== UserRole.ADMIN) {
      throw new ForbiddenException();
    }

    const baseWhere = restaurantId ? { restaurantId } : {};

    const [stuckDeliveries, failedDeliveries, returnedOrders] =
      await Promise.all([
        this.prisma.order.findMany({
          where: {
            ...baseWhere,
            status: OrderStatus.ON_THE_WAY,
            onTheWayAt: { not: null },
          },
          include: { assignment: true, payment: true },
          orderBy: { onTheWayAt: 'asc' },
          take: 50,
        }),
        this.prisma.order.findMany({
          where: {
            ...baseWhere,
            status: OrderStatus.DELIVERY_FAILED,
          },
          include: { payment: true, deliveryExceptions: { take: 1, orderBy: { createdAt: 'desc' } } },
          orderBy: { deliveryFailedAt: 'asc' },
          take: 50,
        }),
        this.prisma.order.findMany({
          where: {
            ...baseWhere,
            status: OrderStatus.RETURNED_TO_RESTAURANT,
          },
          include: { payment: true },
          orderBy: { deliveryFailedAt: 'asc' },
          take: 50,
        }),
      ]);

    return { stuckDeliveries, failedDeliveries, returnedOrders };
  }
}
