import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { DISPATCH_QUEUE } from '../../common/queues/queue.constants';
import { ConfigService } from '@nestjs/config';
import { Cron, CronExpression } from '@nestjs/schedule';
import { acquireCronLock } from '../../common/utils/redis-lock.util';
import {
  AssignmentStatus,
  OrderStatus,
  PaymentMethod,
  Prisma,
  RiderApprovalStatus,
  UserRole,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { RealtimeService } from '../../gateways/realtime.service';
import { NotificationsService } from '../notifications/notifications.service';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { AssignRiderDto } from './dto/assign-rider.dto';

const SAFE_USER_SELECT = {
  id: true,
  phone: true,
  email: true,
  role: true,
  status: true,
} as const;

@Injectable()
export class DispatchService implements OnModuleInit {
  private readonly logger = new Logger(DispatchService.name);

  private static readonly ACTIVE_ORDER_STATUSES: OrderStatus[] = [
    OrderStatus.PLACED,
    OrderStatus.ACCEPTED,
    OrderStatus.PREPARING,
    OrderStatus.READY_FOR_PICKUP,
    OrderStatus.PICKED_UP,
    OrderStatus.ON_THE_WAY,
  ];

  constructor(
    private prisma: PrismaService,
    private config: ConfigService,
    private realtime: RealtimeService,
    private notifications: NotificationsService,
    @InjectQueue(DISPATCH_QUEUE) private dispatchQueue: Queue,
  ) {}

  /** Expired NOTIFIED rows must not block new dispatch or pending recovery. */
  private isAssignmentReplaceable(
    assignment:
      | { status: AssignmentStatus; expiresAt: Date | null }
      | null
      | undefined,
    now = new Date(),
  ): boolean {
    if (!assignment) return true;
    if (
      assignment.status === AssignmentStatus.EXPIRED ||
      assignment.status === AssignmentStatus.REJECTED
    ) {
      return true;
    }
    if (
      assignment.status === AssignmentStatus.NOTIFIED &&
      assignment.expiresAt &&
      assignment.expiresAt <= now
    ) {
      return true;
    }
    return false;
  }

  /** Rider is busy only while they have a live offer or accepted trip. */
  private activeRiderAssignmentWhere(now = new Date()): Prisma.RiderAssignmentWhereInput {
    return {
      OR: [
        {
          status: AssignmentStatus.ACCEPTED,
          order: { status: { in: DispatchService.ACTIVE_ORDER_STATUSES } },
        },
        {
          status: AssignmentStatus.NOTIFIED,
          expiresAt: { gt: now },
          order: { status: { in: DispatchService.ACTIVE_ORDER_STATUSES } },
        },
      ],
    };
  }

  /** On startup, recover any assignments that expired while the server was down */
  async onModuleInit() {
    const stale = await this.prisma.riderAssignment.findMany({
      where: {
        status: AssignmentStatus.NOTIFIED,
        expiresAt: { lt: new Date() },
      },
    });
    if (stale.length > 0) {
      this.logger.warn(
        `Recovering ${stale.length} expired assignment(s) from before restart`,
      );
      for (const assignment of stale) {
        await this.expireIfStillPending(assignment.id);
      }
    }
  }

  @Cron(CronExpression.EVERY_30_SECONDS)
  async sweepExpiredAssignments() {
    if (!(await acquireCronLock(this.config, 'sweep-expired-assignments', 25))) return;
    const expired = await this.prisma.riderAssignment.findMany({
      where: {
        status: AssignmentStatus.NOTIFIED,
        expiresAt: { lt: new Date() },
      },
    });
    for (const assignment of expired) {
      await this.expireIfStillPending(assignment.id);
    }
  }

  async assign(
    staff: JwtPayload,
    orderId: string,
    dto: AssignRiderDto,
  ) {
    const dispatchRoles: UserRole[] = [
      UserRole.OWNER,
      UserRole.MANAGER,
      UserRole.CASHIER,
      UserRole.KITCHEN,
    ];
    if (!dispatchRoles.includes(staff.role)) {
      throw new ForbiddenException();
    }

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { restaurant: true, assignment: true },
    });
    if (!order) throw new NotFoundException('Order not found');
    if (staff.restaurantId !== order.restaurantId) {
      throw new ForbiddenException();
    }
    if (!this.isAssignmentReplaceable(order.assignment)) {
      throw new BadRequestException('Order already has a rider assignment');
    }
    const assignableStatuses: OrderStatus[] = [
      OrderStatus.ACCEPTED,
      OrderStatus.PREPARING,
      OrderStatus.READY_FOR_PICKUP,
    ];
    if (!assignableStatuses.includes(order.status)) {
      throw new BadRequestException(
        'Order must be accepted before rider assignment',
      );
    }

    return this.prisma.$transaction(async (tx) => {
      await tx.$executeRaw`SELECT 1 FROM "Order" WHERE id = ${orderId}::uuid FOR UPDATE`;

      const fresh = await tx.order.findUnique({
        where: { id: orderId },
        include: { restaurant: true, assignment: true },
      });
      if (!fresh) throw new NotFoundException('Order not found');
      if (!this.isAssignmentReplaceable(fresh.assignment)) {
        throw new BadRequestException('Order already has a rider assignment');
      }
      if (fresh.assignment) {
        await tx.riderAssignment.delete({ where: { id: fresh.assignment.id } });
      }
      return this.createAssignmentInTx(
        tx,
        fresh,
        dto.riderProfileId,
        staff.sub,
      );
    });
  }

  private async createAssignmentInTx(
    tx: Prisma.TransactionClient,
    order: {
      id: string;
      orderNumber: string;
      restaurantId: string;
      deliveryLat: number | null;
      deliveryLng: number | null;
      deliveryFee: number;
      grandTotal: number;
      paymentMethod: PaymentMethod;
      restaurant: { name: string; latitude: number; longitude: number };
    },
    riderProfileId: string,
    assignedBy: string,
  ) {
    const rider = await tx.riderProfile.findUnique({
      where: { id: riderProfileId },
      include: { user: { select: SAFE_USER_SELECT } },
    });
    if (!rider?.isOnline) {
      throw new BadRequestException('Rider is not online');
    }
    if (!rider.canReceiveOffers) {
      throw new BadRequestException('Rider is paused pending review');
    }

    const settings = await tx.restaurantSettings.findUnique({
      where: { restaurantId: order.restaurantId },
    });
    const seconds =
      settings?.assignmentTimeoutSec ??
      this.config.get<number>('assignmentTimeoutSeconds') ??
      45;
    const expiresAt = new Date(Date.now() + seconds * 1000);

    const assignment = await tx.riderAssignment.create({
      data: {
        orderId: order.id,
        riderId: rider.id,
        status: AssignmentStatus.NOTIFIED,
        assignedBy,
        expiresAt,
      },
      include: {
        order: true,
        rider: { include: { user: { select: SAFE_USER_SELECT } } },
      },
    });

    // Rider-facing money on the offer: payout is the delivery fee; cash to
    // collect is the order total only for COD (online/wallet is prepaid).
    const estimatedPayout = order.deliveryFee;
    const cashToCollect =
      order.paymentMethod === PaymentMethod.COD ? order.grandTotal : 0;

    this.realtime.emitAssignmentCreated(
      rider.user.id,
      this.buildRiderOfferPayload(
        assignment,
        {
          id: order.id,
          orderNumber: order.orderNumber,
          deliveryLat: order.deliveryLat,
          deliveryLng: order.deliveryLng,
          deliveryFee: order.deliveryFee,
          grandTotal: order.grandTotal,
          paymentMethod: order.paymentMethod,
          restaurant: order.restaurant,
        },
        expiresAt,
      ),
      order.restaurantId,
    );
    this.logger.log(
      `Assignment created: order=${order.id} riderProfile=${rider.id} riderUser=${rider.user.id} assignment=${assignment.id}`,
    );

    await this.notifications.sendToUser(
      rider.user.id,
      'New order offer',
      `৳${estimatedPayout} payout · Order ${order.orderNumber} — respond before it expires`,
      {
        type: 'assignment:created',
        orderId: order.id,
        assignmentId: assignment.id,
        pickupLat: String(order.restaurant.latitude),
        pickupLng: String(order.restaurant.longitude),
        dropLat: order.deliveryLat != null ? String(order.deliveryLat) : undefined,
        dropLng: order.deliveryLng != null ? String(order.deliveryLng) : undefined,
        estimatedPayout: String(estimatedPayout),
        cashToCollect: String(cashToCollect),
        expiresAt: expiresAt.toISOString(),
      },
    );

    this.scheduleExpiry(assignment.id, seconds * 1000);
    return assignment;
  }

  private createAssignment(
    order: Parameters<DispatchService['createAssignmentInTx']>[1],
    riderProfileId: string,
    assignedBy: string,
  ) {
    return this.createAssignmentInTx(
      this.prisma,
      order,
      riderProfileId,
      assignedBy,
    );
  }

  /** Rider-facing offers still awaiting accept/reject (for reconnect recovery). */
  async listPendingForRider(user: JwtPayload) {
    if (user.role !== UserRole.RIDER || !user.riderProfileId) {
      throw new ForbiddenException();
    }
    const now = new Date();
    const assignments = await this.prisma.riderAssignment.findMany({
      where: {
        riderId: user.riderProfileId,
        status: AssignmentStatus.NOTIFIED,
        expiresAt: { gt: now },
        order: {
          status: {
            notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELLED],
          },
        },
      },
      include: {
        order: { include: { restaurant: true } },
      },
      orderBy: { createdAt: 'asc' },
    });
    return assignments.map((a) =>
      this.buildRiderOfferPayload(a, a.order, a.expiresAt!),
    );
  }

  /**
   * Clears pending offers when an order reaches a terminal state so riders
   * are not blocked from new dispatch by stale NOTIFIED rows.
   */
  async releaseAssignmentsForTerminalOrder(
    orderId: string,
    tx?: Prisma.TransactionClient,
  ) {
    const client = tx ?? this.prisma;
    await client.riderAssignment.updateMany({
      where: {
        orderId,
        status: AssignmentStatus.NOTIFIED,
      },
      data: { status: AssignmentStatus.EXPIRED },
    });
  }

  private buildRiderOfferPayload(
    assignment: { id: string },
    order: {
      id: string;
      orderNumber: string;
      deliveryLat: number | null;
      deliveryLng: number | null;
      deliveryFee: number;
      grandTotal: number;
      paymentMethod: PaymentMethod;
      restaurant: { name: string; latitude: number; longitude: number };
    },
    expiresAt: Date,
  ) {
    const cashToCollect =
      order.paymentMethod === PaymentMethod.COD ? order.grandTotal : 0;
    return {
      assignmentId: assignment.id,
      orderId: order.id,
      orderNumber: order.orderNumber,
      pickupName: order.restaurant.name,
      pickupLat: order.restaurant.latitude,
      pickupLng: order.restaurant.longitude,
      dropLat: order.deliveryLat,
      dropLng: order.deliveryLng,
      estimatedPayout: order.deliveryFee,
      cashToCollect,
      paymentMethod: order.paymentMethod,
      expiresAt: expiresAt.toISOString(),
    };
  }

  async accept(user: JwtPayload, assignmentId: string) {
    const assignment = await this.getOwnedAssignment(user, assignmentId);
    this.assertNotExpired(assignment);

    // Defense in depth: only an APPROVED rider can take an order. A PENDING
    // rider can't go online (so shouldn't be assigned), but never trust that
    // alone — block acceptance here too.
    if (assignment.rider.approvalStatus !== RiderApprovalStatus.APPROVED) {
      throw new ForbiddenException('Rider account is not approved');
    }

    // Idempotency: if this rider already accepted the same assignment, treat
    // repeated accepts as success instead of surfacing a hard error to the app.
    if (assignment.status === AssignmentStatus.ACCEPTED) {
      return assignment;
    }

    if (assignment.status !== AssignmentStatus.NOTIFIED) {
      throw new BadRequestException('Assignment is not pending');
    }

    const now = new Date();
    const accepted = await this.prisma.riderAssignment.updateMany({
      where: {
        id: assignmentId,
        riderId: user.riderProfileId!,
        status: AssignmentStatus.NOTIFIED,
        expiresAt: { gt: now },
      },
      data: {
        status: AssignmentStatus.ACCEPTED,
        acceptedAt: now,
      },
    });

    if (accepted.count === 0) {
      const current = await this.prisma.riderAssignment.findUnique({
        where: { id: assignmentId },
        include: { order: true, rider: { include: { user: { select: SAFE_USER_SELECT } } } },
      });
      if (current?.status === AssignmentStatus.ACCEPTED) {
        return current;
      }
      this.assertNotExpired(assignment);
      throw new BadRequestException('Assignment is not pending');
    }

    const updated = await this.prisma.riderAssignment.findUniqueOrThrow({
      where: { id: assignmentId },
      include: { order: true, rider: { include: { user: { select: SAFE_USER_SELECT } } } },
    });

    this.realtime.emitAssignmentAccepted(updated.orderId, {
      assignmentId: updated.id,
      riderId: updated.riderId,
      riderName: updated.rider?.fullName,
      orderId: updated.orderId,
      orderNumber: updated.order?.orderNumber,
    }, updated.order?.restaurantId);

    return updated;
  }

  /// Accepts several of the caller's pending offers in one call ("Accept All").
  ///
  /// Each id runs through the same single-assignment [accept] path (ownership +
  /// expiry-race guard), so the batch can't bypass those checks. Per-item
  /// failures (e.g. one offer expired between fetch and accept) are captured
  /// rather than aborting the whole batch, so a partial success is reported.
  ///
  /// NOTE: this is multi-accept of independent offers, not pickup-grouped batch
  /// dispatch — the schema already lets a rider hold several assignments.
  async acceptBatch(user: JwtPayload, assignmentIds: string[]) {
    const accepted: string[] = [];
    const failed: { assignmentId: string; reason: string }[] = [];

    for (const id of assignmentIds) {
      try {
        await this.accept(user, id);
        accepted.push(id);
      } catch (err) {
        failed.push({
          assignmentId: id,
          reason: err instanceof Error ? err.message : 'Could not accept',
        });
      }
    }

    return { accepted, failed };
  }

  async reject(user: JwtPayload, assignmentId: string) {
    const assignment = await this.getOwnedAssignment(user, assignmentId);

    const updated = await this.prisma.riderAssignment.update({
      where: { id: assignmentId },
      data: {
        status: AssignmentStatus.REJECTED,
        rejectedAt: new Date(),
      },
      include: { order: true },
    });

    this.realtime.emitAssignmentRejected(updated.orderId, {
      assignmentId: updated.id,
      orderId: updated.orderId,
      orderNumber: updated.order?.orderNumber,
    }, updated.order?.restaurantId);

    // Durable rejection record so this rider is kept out of re-offers for this
    // order during the cooldown window (survives the assignment row deletion).
    await this.recordRejection(updated.orderId, assignment.riderId, 'REJECTED');

    this.reassignAfterFailure(assignmentId, updated.orderId, assignment.riderId).catch(
      (err) => this.logger.debug(`Reassign after rejection failed: ${err}`),
    );

    return updated;
  }

  private async getOwnedAssignment(user: JwtPayload, assignmentId: string) {
    if (user.role !== UserRole.RIDER || !user.riderProfileId) {
      throw new ForbiddenException();
    }
    const assignment = await this.prisma.riderAssignment.findUnique({
      where: { id: assignmentId },
      include: { order: { include: { restaurant: true } }, rider: true },
    });
    if (!assignment) throw new NotFoundException('Assignment not found');
    if (assignment.riderId !== user.riderProfileId) {
      throw new ForbiddenException();
    }
    return assignment;
  }

  private assertNotExpired(assignment: { expiresAt: Date | null; status: AssignmentStatus }) {
    if (
      assignment.expiresAt &&
      assignment.expiresAt < new Date() &&
      assignment.status === AssignmentStatus.NOTIFIED
    ) {
      throw new BadRequestException('Assignment expired');
    }
  }

  private scheduleExpiry(assignmentId: string, delayMs: number) {
    this.dispatchQueue
      .add('expire-assignment', { assignmentId }, { delay: delayMs })
      .catch((err) =>
        this.logger.warn(`Failed to enqueue expiry for ${assignmentId}: ${err}`),
      );
  }

  private static readonly RIDER_ONLINE_RETRY_CAP = 3;

  /**
   * When a rider toggles online, offer unassigned kitchen orders that were
   * accepted while no rider was available (fixes "No online riders" at accept).
   */
  async retryDispatchWhenRiderGoesOnline(riderProfileId: string): Promise<void> {
    const rider = await this.prisma.riderProfile.findUnique({
      where: { id: riderProfileId },
    });
    if (!rider?.isOnline) {
      return;
    }

    const assignableStatuses: OrderStatus[] = [
      OrderStatus.ACCEPTED,
      OrderStatus.PREPARING,
      OrderStatus.READY_FOR_PICKUP,
    ];

    const cooldownCutoff = new Date(
      Date.now() - DispatchService.REJECTION_COOLDOWN_MINUTES * 60_000,
    );
    const orders = await this.prisma.order.findMany({
      where: {
        status: { in: assignableStatuses },
        // Don't re-offer an order this rider declined/expired within cooldown,
        // even after the assignment row was deleted on exhaustion.
        riderRejections: {
          none: {
            riderId: riderProfileId,
            createdAt: { gt: cooldownCutoff },
          },
        },
        OR: [
          { assignment: null },
          { assignment: { status: AssignmentStatus.EXPIRED } },
          {
            assignment: {
              status: AssignmentStatus.REJECTED,
              riderId: { not: riderProfileId },
            },
          },
        ],
      },
      include: { restaurant: true, assignment: true },
      orderBy: [{ status: 'desc' }, { createdAt: 'asc' }],
      take: DispatchService.RIDER_ONLINE_RETRY_CAP,
    });

    if (orders.length === 0) {
      return;
    }

    this.logger.log(
      `Rider-online retry: rider ${riderProfileId} — checking ${orders.length} unassigned order(s)`,
    );

    for (const order of orders) {
      if (await this.riderHasMaxAssignments(riderProfileId)) {
        break;
      }

      try {
        await this.offerOrderToRiderOnOnlineRetry(order, riderProfileId);
        this.logger.log(
          `Rider-online retry: offered order ${order.id} to rider ${riderProfileId}`,
        );
      } catch (err) {
        const reason = err instanceof Error ? err.message : String(err);
        this.logger.debug(
          `Rider-online retry: direct offer failed for order ${order.id}: ${reason}`,
        );
        try {
          const staff: JwtPayload = {
            sub: 'system:rider-online-retry',
            role: UserRole.KITCHEN,
            restaurantId: order.restaurantId,
          };
          await this.autoAssign(staff, order.id);
          this.logger.log(
            `Rider-online retry: auto-assigned order ${order.id} after rider ${riderProfileId} went online`,
          );
        } catch (autoErr) {
          const autoReason =
            autoErr instanceof Error ? autoErr.message : String(autoErr);
          this.logger.debug(
            `Rider-online retry: auto-assign failed for order ${order.id}: ${autoReason}`,
          );
        }
      }
    }
  }

  private async riderHasMaxAssignments(riderProfileId: string): Promise<boolean> {
    const count = await this.prisma.riderAssignment.count({
      where: {
        riderId: riderProfileId,
        ...this.activeRiderAssignmentWhere(),
      },
    });
    return count >= 3;
  }

  private static readonly LOCATION_STALENESS_MINUTES = 10;

  /// How long a rider who rejected (or timed out on) an order is kept out of
  /// re-offers for that same order. After the window they become eligible again
  /// so a stuck order can still self-heal (the hybrid policy).
  private static readonly REJECTION_COOLDOWN_MINUTES = 10;

  /// Rider ids that declined/expired [orderId] within the cooldown window and
  /// should therefore be excluded from re-offers of that order right now.
  private async cooledDownRiderIds(
    orderId: string,
    now: Date,
    tx?: Prisma.TransactionClient,
  ): Promise<string[]> {
    const cutoff = new Date(
      now.getTime() - DispatchService.REJECTION_COOLDOWN_MINUTES * 60_000,
    );
    const rows = await (tx ?? this.prisma).riderOrderRejection.findMany({
      where: { orderId, createdAt: { gt: cutoff } },
      select: { riderId: true },
    });
    return [...new Set(rows.map((r) => r.riderId))];
  }

  /// Records that [riderId] declined/expired [orderId]. Best-effort: a failure
  /// to log must never block the reassignment flow.
  private async recordRejection(
    orderId: string,
    riderId: string,
    reason: 'REJECTED' | 'EXPIRED',
  ) {
    try {
      await this.prisma.riderOrderRejection.create({
        data: { orderId, riderId, reason },
      });
    } catch (err) {
      this.logger.debug(`Failed to record rejection: ${err}`);
    }
  }

  private async findAvailableRider(
    now: Date,
    tx?: Prisma.TransactionClient,
    excludeRiderId?: string,
    restaurant?: { latitude: number; longitude: number },
    excludeRiderIds?: string[],
  ) {
    const client = tx ?? this.prisma;
    const excluded = new Set<string>(excludeRiderIds ?? []);
    if (excludeRiderId) excluded.add(excludeRiderId);
    const riders = await client.riderProfile.findMany({
      where: {
        isOnline: true,
        canReceiveOffers: true,
        ...(excluded.size > 0 ? { id: { notIn: [...excluded] } } : {}),
      },
      include: {
        _count: {
          select: {
            assignments: {
              where: this.activeRiderAssignmentWhere(now),
            },
          },
        },
      },
    });

    const eligible = riders.filter((r) => r._count.assignments < 3);
    if (eligible.length === 0) return undefined;
    if (eligible.length === 1) return eligible[0];

    if (!restaurant) {
      eligible.sort((a, b) => a.updatedAt.getTime() - b.updatedAt.getTime());
      return eligible[0];
    }

    const cutoff = new Date(now.getTime() - DispatchService.LOCATION_STALENESS_MINUTES * 60_000);
    const riderIds = eligible.map((r) => r.id);
    const locations = await (tx ?? this.prisma).$queryRaw<
      { riderId: string; latitude: number; longitude: number }[]
    >`
      SELECT DISTINCT ON ("riderId") "riderId", latitude, longitude
      FROM "RiderLocation"
      WHERE "riderId" = ANY(${riderIds}::uuid[])
        AND "recordedAt" > ${cutoff}
      ORDER BY "riderId", "recordedAt" DESC
    `;

    const locationMap = new Map(locations.map((l) => [l.riderId, l]));

    const scored = eligible.map((r) => {
      const loc = locationMap.get(r.id);
      const distanceKm = loc
        ? DispatchService.haversineKm(restaurant.latitude, restaurant.longitude, loc.latitude, loc.longitude)
        : 999;
      const loadFactor = r._count.assignments / 3;
      return { rider: r, score: distanceKm * 0.6 + loadFactor * 0.4 };
    });

    scored.sort((a, b) => a.score - b.score);
    return scored[0].rider;
  }

  private static haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371;
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLon / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }

  private async offerOrderToRiderOnOnlineRetry(
    order: {
      id: string;
      orderNumber: string;
      restaurantId: string;
      deliveryLat: number | null;
      deliveryLng: number | null;
      deliveryFee: number;
      grandTotal: number;
      paymentMethod: PaymentMethod;
      status: OrderStatus;
      restaurant: { name: string; latitude: number; longitude: number };
      assignment: {
        id: string;
        riderId: string;
        status: AssignmentStatus;
        expiresAt: Date | null;
      } | null;
    },
    riderProfileId: string,
  ) {
    const assignableStatuses: OrderStatus[] = [
      OrderStatus.ACCEPTED,
      OrderStatus.PREPARING,
      OrderStatus.READY_FOR_PICKUP,
    ];
    if (!assignableStatuses.includes(order.status)) {
      throw new BadRequestException('Order is not ready for rider assignment');
    }
    if (
      order.assignment?.riderId === riderProfileId &&
      order.assignment?.status === AssignmentStatus.REJECTED
    ) {
      throw new BadRequestException('Rider declined this order');
    }
    // Durable cooldown guard — the assignment row may have been deleted on
    // exhaustion, so also consult the rejection log.
    const cooledDown = await this.cooledDownRiderIds(order.id, new Date());
    if (cooledDown.includes(riderProfileId)) {
      throw new BadRequestException('Rider is in cooldown for this order');
    }
    if (!this.isAssignmentReplaceable(order.assignment)) {
      throw new BadRequestException('Order already has a rider assignment');
    }
    if (order.assignment) {
      await this.prisma.riderAssignment.delete({
        where: { id: order.assignment.id },
      });
    }
    await this.createAssignment(order, riderProfileId, 'system:rider-online-retry');
  }

  async autoAssign(staff: JwtPayload, orderId: string) {
    const dispatchRoles: UserRole[] = [
      UserRole.OWNER,
      UserRole.MANAGER,
      UserRole.CASHIER,
      UserRole.KITCHEN,
    ];
    if (!dispatchRoles.includes(staff.role)) {
      throw new ForbiddenException();
    }

    const activeOrderStatuses = DispatchService.ACTIVE_ORDER_STATUSES;

    return this.prisma.$transaction(async (tx) => {
      await tx.$executeRaw`SELECT 1 FROM "Order" WHERE id = ${orderId}::uuid FOR UPDATE`;

      const order = await tx.order.findUnique({
        where: { id: orderId },
        include: { restaurant: true, assignment: true },
      });
      if (!order || staff.restaurantId !== order.restaurantId) {
        throw new ForbiddenException();
      }
      if (!this.isAssignmentReplaceable(order.assignment)) {
        throw new BadRequestException('Order already has a rider assignment');
      }
      const assignableStatuses: OrderStatus[] = [
        OrderStatus.ACCEPTED,
        OrderStatus.PREPARING,
        OrderStatus.READY_FOR_PICKUP,
      ];
      if (!assignableStatuses.includes(order.status)) {
        throw new BadRequestException(
          'Order must be accepted before rider assignment',
        );
      }
      if (order.assignment) {
        await tx.riderAssignment.delete({ where: { id: order.assignment.id } });
      }

      const now = new Date();
      const cooledDown = await this.cooledDownRiderIds(orderId, now, tx);
      const rider = await this.findAvailableRider(
        now,
        tx,
        undefined,
        order.restaurant,
        cooledDown,
      );
      if (!rider) {
        throw new BadRequestException('No online riders available');
      }

      return this.createAssignmentInTx(tx, order, rider.id, staff.sub);
    });
  }

  async listAvailableRiders(restaurantId: string) {
    return this.prisma.riderProfile.findMany({
      where: { isOnline: true, canReceiveOffers: true },
      select: {
        id: true,
        fullName: true,
        vehicleType: true,
        ratingAvg: true,
        ratingCount: true,
        isOnline: true,
        user: { select: { id: true, phone: true } },
      },
      orderBy: { updatedAt: 'asc' },
    });
  }

  async expireIfStillPending(assignmentId: string) {
    const now = new Date();
    const expired = await this.prisma.riderAssignment.updateMany({
      where: {
        id: assignmentId,
        status: AssignmentStatus.NOTIFIED,
        expiresAt: { lt: now },
      },
      data: { status: AssignmentStatus.EXPIRED },
    });
    if (expired.count === 0) {
      return;
    }

    const assignment = await this.prisma.riderAssignment.findUnique({
      where: { id: assignmentId },
      include: { order: true, rider: true },
    });
    if (!assignment) {
      return;
    }

    this.realtime.emitAssignmentExpired(
      assignment.orderId,
      {
        assignmentId,
        orderId: assignment.orderId,
        orderNumber: assignment.order?.orderNumber,
      },
      assignment.order?.restaurantId,
      assignment.rider?.userId,
    );

    // A timeout is also a (softer) decline — apply the same cooldown so the
    // order doesn't immediately bounce back to a rider who didn't respond.
    await this.recordRejection(assignment.orderId, assignment.riderId, 'EXPIRED');

    await this.reassignAfterFailure(assignmentId, assignment.orderId, assignment.riderId);
  }

  private async reassignAfterFailure(
    oldAssignmentId: string,
    orderId: string,
    excludeRiderId: string,
  ) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { restaurant: true, assignment: true },
    });
    if (
      !order ||
      order.status === OrderStatus.CANCELLED ||
      order.status === OrderStatus.DELIVERED
    ) {
      return;
    }

    if (order.assignment?.id === oldAssignmentId) {
      await this.prisma.riderAssignment.delete({ where: { id: oldAssignmentId } });
    }

    const now = new Date();
    const cooledDown = await this.cooledDownRiderIds(orderId, now);
    const nextRider = await this.findAvailableRider(
      now,
      undefined,
      excludeRiderId,
      order.restaurant,
      cooledDown,
    );
    if (nextRider) {
      try {
        await this.createAssignment(order, nextRider.id, 'system:auto-reassign');
      } catch (err) {
        this.logger.debug(`Reassignment failed for order ${orderId}: ${err}`);
      }
    } else {
      this.logger.warn(`All riders exhausted for order ${orderId}`);
      this.realtime.emitToRoom(
        `restaurant:${order.restaurantId}`,
        'order:dispatch.exhausted',
        { orderId, orderNumber: order.orderNumber },
      );
    }
  }

  async forceUnassign(staff: JwtPayload, orderId: string, reason?: string) {
    const dispatchRoles: UserRole[] = [
      UserRole.OWNER,
      UserRole.MANAGER,
      UserRole.CASHIER,
      UserRole.ADMIN,
    ];
    if (!dispatchRoles.includes(staff.role)) {
      throw new ForbiddenException();
    }

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { assignment: true },
    });
    if (!order) throw new NotFoundException('Order not found');
    if (staff.role !== UserRole.ADMIN && staff.restaurantId !== order.restaurantId) {
      throw new ForbiddenException();
    }
    if (!order.assignment) {
      throw new BadRequestException('No rider assignment on this order');
    }

    await this.prisma.riderAssignment.update({
      where: { id: order.assignment.id },
      data: { status: AssignmentStatus.CANCELLED },
    });

    this.realtime.emitAssignmentExpired(orderId, {
      assignmentId: order.assignment.id,
      orderId,
      orderNumber: order.orderNumber,
      reason: reason ?? 'force_unassign',
    }, order.restaurantId);

    return { orderId, released: true };
  }
}
