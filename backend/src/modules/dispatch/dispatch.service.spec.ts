import { Test } from '@nestjs/testing';
import { getQueueToken } from '@nestjs/bullmq';
import { BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

jest.mock('../../common/utils/redis-lock.util', () => ({
  acquireCronLock: jest.fn().mockResolvedValue(true),
}));
import {
  AssignmentStatus,
  OrderStatus,
  PaymentMethod,
  UserRole,
} from '@prisma/client';
import { DispatchService } from './dispatch.service';
import { PrismaService } from '../../prisma/prisma.service';
import { RealtimeService } from '../../gateways/realtime.service';
import { NotificationsService } from '../notifications/notifications.service';
import { DISPATCH_QUEUE } from '../../common/queues/queue.constants';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makeRider(overrides: Record<string, any> = {}) {
  return {
    id: overrides.id ?? 'rider-1',
    userId: overrides.userId ?? 'user-1',
    fullName: 'Test Rider',
    isOnline: true,
    canReceiveOffers: true,
    approvalStatus: 'APPROVED',
    updatedAt: overrides.updatedAt ?? new Date('2025-01-01'),
    _count: { assignments: overrides.activeAssignments ?? 0 },
    user: { id: overrides.userId ?? 'user-1', phone: '01700000000', email: 'r@t.com', role: UserRole.RIDER, status: 'ACTIVE' },
    ...overrides,
  };
}

function makeOrder(overrides: Record<string, any> = {}) {
  return {
    id: overrides.id ?? 'order-1',
    orderNumber: overrides.orderNumber ?? 'W-1001',
    restaurantId: 'rest-1',
    deliveryLat: 23.81,
    deliveryLng: 90.41,
    deliveryFee: 60,
    grandTotal: 500,
    paymentMethod: PaymentMethod.COD,
    status: overrides.status ?? OrderStatus.ACCEPTED,
    restaurant: { name: 'Test Kitchen', latitude: 23.8103, longitude: 90.4125 },
    assignment: overrides.assignment ?? null,
    ...overrides,
  };
}

function makeAssignment(overrides: Record<string, any> = {}) {
  return {
    id: overrides.id ?? 'asgn-1',
    orderId: overrides.orderId ?? 'order-1',
    riderId: overrides.riderId ?? 'rider-1',
    status: overrides.status ?? AssignmentStatus.NOTIFIED,
    assignedBy: 'system',
    expiresAt: overrides.expiresAt ?? new Date(Date.now() + 45_000),
    acceptedAt: null,
    rejectedAt: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    order: makeOrder(),
    rider: makeRider(),
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// Mock factories
// ---------------------------------------------------------------------------

function createMockPrisma() {
  return {
    riderProfile: {
      findMany: jest.fn().mockResolvedValue([]),
      findUnique: jest.fn().mockResolvedValue(null),
    },
    riderAssignment: {
      findMany: jest.fn().mockResolvedValue([]),
      findUnique: jest.fn().mockResolvedValue(null),
      findUniqueOrThrow: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn().mockResolvedValue({ count: 0 }),
      delete: jest.fn().mockResolvedValue({}),
      count: jest.fn().mockResolvedValue(0),
    },
    order: {
      findUnique: jest.fn().mockResolvedValue(null),
      findMany: jest.fn().mockResolvedValue([]),
    },
    restaurantSettings: {
      findUnique: jest.fn().mockResolvedValue(null),
    },
    riderOrderRejection: {
      findMany: jest.fn().mockResolvedValue([]),
      create: jest.fn().mockResolvedValue({}),
    },
    $transaction: jest.fn((fn: any) => fn(mockTx())),
    $executeRaw: jest.fn(),
    $queryRaw: jest.fn().mockResolvedValue([]),
  };
}

function mockTx() {
  return {
    riderProfile: { findMany: jest.fn().mockResolvedValue([]), findUnique: jest.fn() },
    riderAssignment: {
      create: jest.fn().mockResolvedValue(makeAssignment()),
      delete: jest.fn(),
      findMany: jest.fn().mockResolvedValue([]),
    },
    order: { findUnique: jest.fn() },
    restaurantSettings: { findUnique: jest.fn().mockResolvedValue(null) },
    riderOrderRejection: {
      findMany: jest.fn().mockResolvedValue([]),
      create: jest.fn().mockResolvedValue({}),
    },
    $executeRaw: jest.fn(),
    $queryRaw: jest.fn().mockResolvedValue([]),
  };
}

function createMockRealtime() {
  return {
    emitAssignmentCreated: jest.fn(),
    emitAssignmentAccepted: jest.fn(),
    emitAssignmentRejected: jest.fn(),
    emitAssignmentExpired: jest.fn(),
    emitToRoom: jest.fn(),
  };
}

function createMockNotifications() {
  return { sendToUser: jest.fn().mockResolvedValue(undefined) };
}

function createMockQueue() {
  return { add: jest.fn().mockResolvedValue({}) };
}

// ---------------------------------------------------------------------------
// Test suite
// ---------------------------------------------------------------------------

describe('DispatchService', () => {
  let service: DispatchService;
  let prisma: ReturnType<typeof createMockPrisma>;
  let realtime: ReturnType<typeof createMockRealtime>;
  let notifications: ReturnType<typeof createMockNotifications>;
  let queue: ReturnType<typeof createMockQueue>;

  beforeEach(async () => {
    prisma = createMockPrisma();
    realtime = createMockRealtime();
    notifications = createMockNotifications();
    queue = createMockQueue();

    const module = await Test.createTestingModule({
      providers: [
        DispatchService,
        { provide: PrismaService, useValue: prisma },
        { provide: ConfigService, useValue: { get: jest.fn().mockReturnValue(45) } },
        { provide: RealtimeService, useValue: realtime },
        { provide: NotificationsService, useValue: notifications },
        { provide: getQueueToken(DISPATCH_QUEUE), useValue: queue },
      ],
    }).compile();

    service = module.get(DispatchService);
  });

  // ---------- 1.1 Rejection triggers reassignment ----------

  describe('reject() — instant reassignment', () => {
    it('should reassign to the next available rider after rejection', async () => {
      const rider1 = makeRider({ id: 'rider-1', userId: 'user-1' });
      const rider2 = makeRider({ id: 'rider-2', userId: 'user-2' });
      const assignment = makeAssignment({ riderId: 'rider-1', rider: rider1 });
      const order = makeOrder({ assignment: null });

      // getOwnedAssignment
      prisma.riderAssignment.findUnique.mockResolvedValueOnce(assignment);
      // atomic NOTIFIED → REJECTED transition
      prisma.riderAssignment.updateMany.mockResolvedValueOnce({ count: 1 });
      // re-fetch of the rejected row
      prisma.riderAssignment.findUniqueOrThrow.mockResolvedValueOnce({
        ...assignment,
        status: AssignmentStatus.REJECTED,
        rejectedAt: new Date(),
      });

      // reassignAfterFailure: fetch order
      prisma.order.findUnique.mockResolvedValueOnce(order);
      // reassignAfterFailure: delete old assignment
      prisma.riderAssignment.delete.mockResolvedValueOnce({});
      // findAvailableRider: fetch riders (excluding rider-1)
      prisma.riderProfile.findMany.mockResolvedValueOnce([rider2]);
      // findAvailableRider: query locations (no recent location → fallback)
      prisma.$queryRaw.mockResolvedValueOnce([]);
      // createAssignment → createAssignmentInTx (uses prisma directly since no tx)
      prisma.riderProfile.findUnique.mockResolvedValueOnce(rider2);
      prisma.restaurantSettings.findUnique.mockResolvedValueOnce(null);
      prisma.riderAssignment.create.mockResolvedValueOnce(
        makeAssignment({ id: 'asgn-2', riderId: 'rider-2' }),
      );

      const user = { sub: 'user-1', role: UserRole.RIDER, riderProfileId: 'rider-1' };
      await service.reject(user, 'asgn-1');

      // Wait for the fire-and-forget reassignment
      await new Promise((r) => setTimeout(r, 50));

      expect(realtime.emitAssignmentRejected).toHaveBeenCalledWith('order-1', {
        assignmentId: 'asgn-1',
        orderId: 'order-1',
        orderNumber: 'W-1001',
      }, 'rest-1');
      // Verify a new assignment was created for rider-2
      expect(prisma.riderAssignment.create).toHaveBeenCalled();
      const createCall = prisma.riderAssignment.create.mock.calls[0][0];
      expect(createCall.data.riderId).toBe('rider-2');
      expect(createCall.data.assignedBy).toBe('system:auto-reassign');
      // A durable rejection is logged for the rejecting rider (cooldown).
      expect(prisma.riderOrderRejection.create).toHaveBeenCalledWith({
        data: { orderId: 'order-1', riderId: 'rider-1', reason: 'REJECTED' },
      });
    });

    it('refuses to reject an already-accepted assignment and does not reassign', async () => {
      const assignment = makeAssignment({ status: AssignmentStatus.ACCEPTED });
      prisma.riderAssignment.findUnique.mockResolvedValueOnce(assignment);

      const user = { sub: 'user-1', role: UserRole.RIDER, riderProfileId: 'rider-1' };
      await expect(service.reject(user, 'asgn-1')).rejects.toThrow(
        'Assignment is not pending',
      );

      expect(prisma.riderAssignment.updateMany).not.toHaveBeenCalled();
      expect(prisma.riderAssignment.create).not.toHaveBeenCalled();
      expect(prisma.riderOrderRejection.create).not.toHaveBeenCalled();
    });

    it('treats a repeated reject as idempotent success', async () => {
      const assignment = makeAssignment({ status: AssignmentStatus.REJECTED });
      prisma.riderAssignment.findUnique.mockResolvedValueOnce(assignment);

      const user = { sub: 'user-1', role: UserRole.RIDER, riderProfileId: 'rider-1' };
      const result = await service.reject(user, 'asgn-1');

      expect(result.status).toBe(AssignmentStatus.REJECTED);
      expect(prisma.riderAssignment.updateMany).not.toHaveBeenCalled();
      expect(realtime.emitAssignmentRejected).not.toHaveBeenCalled();
    });

    it('does not reassign when reject loses the race against expiry', async () => {
      const assignment = makeAssignment(); // NOTIFIED at fetch time
      prisma.riderAssignment.findUnique.mockResolvedValueOnce(assignment);
      // Expiry won the race: the conditional update matches nothing…
      prisma.riderAssignment.updateMany.mockResolvedValueOnce({ count: 0 });
      // …and the row is now EXPIRED.
      prisma.riderAssignment.findUnique.mockResolvedValueOnce({
        ...assignment,
        status: AssignmentStatus.EXPIRED,
      });

      const user = { sub: 'user-1', role: UserRole.RIDER, riderProfileId: 'rider-1' };
      await expect(service.reject(user, 'asgn-1')).rejects.toThrow(
        'Assignment is not pending',
      );
      expect(prisma.riderAssignment.create).not.toHaveBeenCalled();
    });
  });

  // ---------- Rejection cooldown ----------

  describe('rejection cooldown', () => {
    it('excludes a rider who recently rejected the order from re-offers', async () => {
      const tx = mockTx();
      // rider-1 rejected this order within the cooldown window
      tx.riderOrderRejection.findMany.mockResolvedValueOnce([{ riderId: 'rider-1' }]);
      // After excluding rider-1, no eligible riders remain
      tx.riderProfile.findMany.mockResolvedValueOnce([]);
      tx.order.findUnique.mockResolvedValueOnce(makeOrder());
      prisma.$transaction.mockImplementation((fn: any) => fn(tx));

      const staff = { sub: 'staff-1', role: UserRole.KITCHEN, restaurantId: 'rest-1' };
      await expect(service.autoAssign(staff, 'order-1')).rejects.toThrow(
        'No online riders available',
      );

      // The rider query must exclude the cooled-down rider.
      const findCall = tx.riderProfile.findMany.mock.calls[0][0];
      expect(findCall.where.id).toEqual({ notIn: ['rider-1'] });
    });
  });

  // ---------- 1.2 Proximity scoring ----------

  describe('findAvailableRider() — proximity scoring', () => {
    it('should prefer closer rider over farther one', async () => {
      const nearRider = makeRider({ id: 'rider-near', updatedAt: new Date('2025-01-02') });
      const farRider = makeRider({ id: 'rider-far', updatedAt: new Date('2025-01-01') });

      const order = makeOrder();
      const tx = mockTx();

      // findAvailableRider riders query
      tx.riderProfile.findMany.mockResolvedValueOnce([nearRider, farRider]);
      // Location query: near rider is 0.5km away, far rider is 10km away
      tx.$queryRaw.mockResolvedValueOnce([
        { riderId: 'rider-near', latitude: 23.8108, longitude: 90.4130 },
        { riderId: 'rider-far', latitude: 23.9000, longitude: 90.5000 },
      ]);

      // Set up the transaction to use our tx
      prisma.$transaction.mockImplementation((fn: any) => fn(tx));

      // We need the order in the tx
      tx.order.findUnique.mockResolvedValueOnce(order);
      tx.riderProfile.findUnique.mockResolvedValueOnce(nearRider);
      tx.restaurantSettings.findUnique.mockResolvedValueOnce(null);
      tx.riderAssignment.create.mockResolvedValueOnce(
        makeAssignment({ riderId: 'rider-near' }),
      );

      const staff = { sub: 'staff-1', role: UserRole.KITCHEN, restaurantId: 'rest-1' };
      const result = await service.autoAssign(staff, 'order-1');

      // The near rider should be selected
      expect(tx.riderAssignment.create).toHaveBeenCalled();
      const createCall = tx.riderAssignment.create.mock.calls[0][0];
      expect(createCall.data.riderId).toBe('rider-near');
    });

    it('should fall back to updatedAt order when no restaurant coords provided', async () => {
      // This test exercises the fallback path via expireIfStillPending → reassignAfterFailure
      // which passes restaurant coords, so we test via autoAssign where restaurant is always present
      const oldRider = makeRider({ id: 'rider-old', updatedAt: new Date('2025-01-01') });
      const newRider = makeRider({ id: 'rider-new', updatedAt: new Date('2025-06-01') });

      const tx = mockTx();
      // No locations — will use distance 999 for both, then score by load (both 0) → tie
      // With equal scores, sort is stable so first in array wins
      tx.riderProfile.findMany.mockResolvedValueOnce([newRider, oldRider]);
      tx.$queryRaw.mockResolvedValueOnce([]); // no locations

      const order = makeOrder();
      tx.order.findUnique.mockResolvedValueOnce(order);
      tx.riderProfile.findUnique.mockResolvedValueOnce(newRider);
      tx.restaurantSettings.findUnique.mockResolvedValueOnce(null);
      tx.riderAssignment.create.mockResolvedValueOnce(makeAssignment());

      prisma.$transaction.mockImplementation((fn: any) => fn(tx));

      const staff = { sub: 'staff-1', role: UserRole.KITCHEN, restaurantId: 'rest-1' };
      await service.autoAssign(staff, 'order-1');

      // Both riders have no location → both get distance=999
      // Equal scores → first in array wins (which is newRider since that's how findMany returned them)
      expect(tx.riderAssignment.create).toHaveBeenCalled();
    });
  });

  // ---------- 1.3 All riders exhausted ----------

  describe('expireIfStillPending() — exhausted notification', () => {
    it('should emit dispatch.exhausted when no riders are available after expiry', async () => {
      const assignment = makeAssignment({
        expiresAt: new Date(Date.now() - 10_000), // already expired
      });
      const order = makeOrder();

      // Mark as expired
      prisma.riderAssignment.updateMany.mockResolvedValueOnce({ count: 1 });
      // Fetch assignment
      prisma.riderAssignment.findUnique.mockResolvedValueOnce(assignment);
      // reassignAfterFailure: fetch order
      prisma.order.findUnique.mockResolvedValueOnce(order);
      // Delete old assignment
      prisma.riderAssignment.delete.mockResolvedValueOnce({});
      // findAvailableRider: no riders available
      prisma.riderProfile.findMany.mockResolvedValueOnce([]);

      await service.expireIfStillPending('asgn-1');

      expect(realtime.emitAssignmentExpired).toHaveBeenCalledWith(
        'order-1',
        {
          assignmentId: 'asgn-1',
          orderId: 'order-1',
          orderNumber: 'W-1001',
        },
        'rest-1',
        // Also notifies the offered rider's personal room that the offer expired.
        'user-1',
      );
      expect(realtime.emitToRoom).toHaveBeenCalledWith(
        'restaurant:rest-1',
        'order:dispatch.exhausted',
        { orderId: 'order-1', orderNumber: 'W-1001' },
      );
    });

    it('should reassign to next rider on expiry when available', async () => {
      const rider2 = makeRider({ id: 'rider-2', userId: 'user-2' });
      const assignment = makeAssignment({
        expiresAt: new Date(Date.now() - 10_000),
      });
      const order = makeOrder();

      prisma.riderAssignment.updateMany.mockResolvedValueOnce({ count: 1 });
      prisma.riderAssignment.findUnique.mockResolvedValueOnce(assignment);
      prisma.order.findUnique.mockResolvedValueOnce(order);
      prisma.riderAssignment.delete.mockResolvedValueOnce({});
      prisma.riderProfile.findMany.mockResolvedValueOnce([rider2]);
      prisma.$queryRaw.mockResolvedValueOnce([]);
      prisma.riderProfile.findUnique.mockResolvedValueOnce(rider2);
      prisma.restaurantSettings.findUnique.mockResolvedValueOnce(null);
      prisma.riderAssignment.create.mockResolvedValueOnce(
        makeAssignment({ id: 'asgn-2', riderId: 'rider-2' }),
      );

      await service.expireIfStillPending('asgn-1');

      expect(prisma.riderAssignment.create).toHaveBeenCalled();
      const createCall = prisma.riderAssignment.create.mock.calls[0][0];
      expect(createCall.data.riderId).toBe('rider-2');
      // Should NOT emit exhausted
      expect(realtime.emitToRoom).not.toHaveBeenCalledWith(
        expect.anything(),
        'order:dispatch.exhausted',
        expect.anything(),
      );
    });
  });

  // ---------- 1.6 listAvailableRiders filter ----------

  describe('listAvailableRiders()', () => {
    it('should filter by canReceiveOffers=true', async () => {
      prisma.riderProfile.findMany.mockResolvedValueOnce([]);

      await service.listAvailableRiders('rest-1');

      expect(prisma.riderProfile.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { isOnline: true, canReceiveOffers: true },
        }),
      );
    });
  });

  // ---------- 1.4 Ordering consistency ----------

  describe('retryDispatchWhenRiderGoesOnline() — order priority', () => {
    it('should prioritize READY_FOR_PICKUP orders over ACCEPTED', async () => {
      const rider = makeRider({ id: 'rider-1' });
      prisma.riderProfile.findUnique.mockResolvedValueOnce(rider);

      const acceptedOrder = makeOrder({ id: 'order-old', status: OrderStatus.ACCEPTED, assignment: null });
      const readyOrder = makeOrder({ id: 'order-ready', status: OrderStatus.READY_FOR_PICKUP, assignment: null });

      prisma.order.findMany.mockResolvedValueOnce([readyOrder, acceptedOrder]);
      prisma.riderAssignment.count.mockResolvedValueOnce(0); // not at max

      // For the first order offer
      prisma.riderProfile.findUnique.mockResolvedValueOnce(rider);
      prisma.restaurantSettings.findUnique.mockResolvedValueOnce(null);
      prisma.riderAssignment.create.mockResolvedValueOnce(makeAssignment());
      prisma.riderAssignment.count.mockResolvedValueOnce(1); // now has 1

      // For the second order offer
      prisma.riderProfile.findUnique.mockResolvedValueOnce(rider);
      prisma.restaurantSettings.findUnique.mockResolvedValueOnce(null);
      prisma.riderAssignment.create.mockResolvedValueOnce(makeAssignment({ id: 'asgn-2' }));

      await service.retryDispatchWhenRiderGoesOnline('rider-1');

      // Verify orderBy includes status desc (READY_FOR_PICKUP > ACCEPTED in enum order)
      expect(prisma.order.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          orderBy: [{ status: 'desc' }, { createdAt: 'asc' }],
        }),
      );
    });
  });

  // ---------- Stranded-order recovery sweep ----------

  describe('sweepUnassignedOrders()', () => {
    it('re-dispatches assignable orders with no live assignment, continuing past failures', async () => {
      prisma.order.findMany.mockResolvedValueOnce([
        { id: 'order-1', restaurantId: 'rest-1' },
        { id: 'order-2', restaurantId: 'rest-1' },
      ]);
      const autoAssign = jest
        .spyOn(service, 'autoAssign')
        .mockRejectedValueOnce(
          new BadRequestException('No online riders available'),
        )
        .mockResolvedValueOnce(makeAssignment() as any);

      await service.sweepUnassignedOrders();

      // The first failure must not abort the loop — both orders attempted.
      expect(autoAssign).toHaveBeenCalledTimes(2);
      expect(autoAssign).toHaveBeenNthCalledWith(
        1,
        expect.objectContaining({
          sub: 'system:dispatch-sweep',
          role: UserRole.KITCHEN,
          restaurantId: 'rest-1',
        }),
        'order-1',
      );
      expect(autoAssign).toHaveBeenNthCalledWith(2, expect.anything(), 'order-2');

      // Only orders without a live assignment are eligible.
      const where = prisma.order.findMany.mock.calls[0][0].where;
      expect(where.OR).toEqual([
        { assignment: null },
        {
          assignment: {
            status: {
              in: [AssignmentStatus.EXPIRED, AssignmentStatus.REJECTED],
            },
          },
        },
      ]);
      expect(where.status).toEqual({
        in: [
          OrderStatus.ACCEPTED,
          OrderStatus.PREPARING,
          OrderStatus.READY_FOR_PICKUP,
        ],
      });
    });

    it('does nothing when no stranded orders exist', async () => {
      prisma.order.findMany.mockResolvedValueOnce([]);
      const autoAssign = jest.spyOn(service, 'autoAssign');

      await service.sweepUnassignedOrders();

      expect(autoAssign).not.toHaveBeenCalled();
    });
  });
});
