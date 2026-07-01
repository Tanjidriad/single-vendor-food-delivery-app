import { Test } from '@nestjs/testing';
import { getQueueToken } from '@nestjs/bullmq';
import { ConfigService } from '@nestjs/config';
import { AssignmentStatus, OrderStatus, PaymentMethod, UserRole } from '@prisma/client';
import { DispatchService } from './dispatch.service';
import { PrismaService } from '../../prisma/prisma.service';
import { RealtimeService } from '../../gateways/realtime.service';
import { NotificationsService } from '../notifications/notifications.service';
import { DISPATCH_QUEUE } from '../../common/queues/queue.constants';

/**
 * SIMULATION: "Restaurant receives an order, 6 riders are already onboarded
 * (online + eligible) — how does the delivery assignment get distributed?"
 *
 * This drives the REAL DispatchService (no rewritten logic) through the exact
 * production code path: autoAssign() -> findAvailableRider() -> single NOTIFIED
 * offer -> expiry -> reassignAfterFailure() -> next offer, round after round,
 * with 6 seeded riders at different distances / current loads.
 *
 * Restaurant: 23.8103, 90.4125 (Dhaka)
 *   rider-A: 0.3km, 0 active   -> score 0.3*0.6            = 0.18   (closest, idle)
 *   rider-C: 0.5km, 2 active   -> score 0.5*0.6+(2/3)*0.4  = 0.567  (near but loaded)
 *   rider-B: 1.0km, 0 active   -> score 1.0*0.6            = 0.60
 *   rider-E: 2.0km, 1 active   -> score 2.0*0.6+(1/3)*0.4  = 1.333
 *   rider-D: 5.0km, 0 active   -> score 5.0*0.6            = 3.00
 *   rider-F: 0.1km, 3 active   -> INELIGIBLE (at max concurrent load of 3),
 *                                  never enters the pool regardless of proximity
 */

const RESTAURANT = { name: 'Test Kitchen', latitude: 23.8103, longitude: 90.4125 };

function makeRider(id: string, active: number) {
  return {
    id,
    userId: `user-${id}`,
    fullName: `Rider ${id}`,
    isOnline: true,
    canReceiveOffers: true,
    approvalStatus: 'APPROVED',
    updatedAt: new Date('2025-01-01'),
    _count: { assignments: active },
    user: { id: `user-${id}`, phone: '01700000000', email: `${id}@t.com`, role: UserRole.RIDER, status: 'ACTIVE' },
  };
}

const ALL_RIDERS: Record<string, ReturnType<typeof makeRider>> = {
  'rider-A': makeRider('rider-A', 0),
  'rider-B': makeRider('rider-B', 0),
  'rider-C': makeRider('rider-C', 2),
  'rider-D': makeRider('rider-D', 0),
  'rider-E': makeRider('rider-E', 1),
  'rider-F': makeRider('rider-F', 3), // at max load -> filtered before scoring
};

const LOCATIONS: Record<string, { latitude: number; longitude: number }> = {
  'rider-A': { latitude: 23.8130, longitude: 90.4125 }, // ~0.3km
  'rider-B': { latitude: 23.8193, longitude: 90.4125 }, // ~1.0km
  'rider-C': { latitude: 23.8148, longitude: 90.4125 }, // ~0.5km
  'rider-D': { latitude: 23.8553, longitude: 90.4125 }, // ~5.0km
  'rider-E': { latitude: 23.8283, longitude: 90.4125 }, // ~2.0km
  'rider-F': { latitude: 23.8112, longitude: 90.4125 }, // ~0.1km, irrelevant (ineligible)
};

function makeOrder() {
  return {
    id: 'order-1',
    orderNumber: 'W-9001',
    restaurantId: 'rest-1',
    deliveryLat: 23.79,
    deliveryLng: 90.40,
    deliveryFee: 60,
    grandTotal: 500,
    paymentMethod: PaymentMethod.COD,
    status: OrderStatus.ACCEPTED,
    restaurant: RESTAURANT,
    assignment: null as any,
  };
}

describe('SIMULATION: 6-rider dispatch waterfall for a single order', () => {
  let service: DispatchService;
  let prisma: any;
  let realtime: any;
  const rejectedSoFar: string[] = []; // riderOrderRejection rows accumulate for real
  const offersInOrder: string[] = [];

  beforeEach(async () => {
    rejectedSoFar.length = 0;
    offersInOrder.length = 0;

    prisma = {
      riderProfile: {
        findMany: jest.fn(async ({ where }: any) => {
          const excluded: string[] = where?.id?.notIn ?? [];
          return Object.values(ALL_RIDERS).filter(
            (r) => !excluded.includes(r.id) && r._count.assignments < 3,
          );
        }),
        findUnique: jest.fn(async ({ where }: any) => ALL_RIDERS[where.id]),
      },
      riderAssignment: {
        create: jest.fn(async ({ data }: any) => {
          offersInOrder.push(data.riderId);
          return {
            id: `asgn-${offersInOrder.length}`,
            orderId: data.orderId,
            riderId: data.riderId,
            status: AssignmentStatus.NOTIFIED,
            expiresAt: data.expiresAt,
            order: makeOrder(),
            rider: ALL_RIDERS[data.riderId],
          };
        }),
        delete: jest.fn().mockResolvedValue({}),
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        findUnique: jest.fn(),
      },
      order: {
        findUnique: jest.fn(async () => makeOrder()),
      },
      restaurantSettings: { findUnique: jest.fn().mockResolvedValue(null) },
      riderOrderRejection: {
        findMany: jest.fn(async () => rejectedSoFar.map((riderId) => ({ riderId }))),
        create: jest.fn(async ({ data }: any) => {
          rejectedSoFar.push(data.riderId);
          return {};
        }),
      },
      $transaction: jest.fn((fn: any) => fn(prisma)),
      $executeRaw: jest.fn(),
      $queryRaw: jest.fn(async ({ } = {}) => {
        // Real query filters by riderIds param; we just return all known locations
        return Object.entries(LOCATIONS).map(([riderId, loc]) => ({ riderId, ...loc }));
      }),
    };

    realtime = {
      emitAssignmentCreated: jest.fn(),
      emitAssignmentAccepted: jest.fn(),
      emitAssignmentRejected: jest.fn(),
      emitAssignmentExpired: jest.fn(),
      emitToRoom: jest.fn(),
    };

    const module = await Test.createTestingModule({
      providers: [
        DispatchService,
        { provide: PrismaService, useValue: prisma },
        { provide: ConfigService, useValue: { get: jest.fn().mockReturnValue(45) } },
        { provide: RealtimeService, useValue: realtime },
        { provide: NotificationsService, useValue: { sendToUser: jest.fn() } },
        { provide: getQueueToken(DISPATCH_QUEUE), useValue: { add: jest.fn().mockResolvedValue({}) } },
      ],
    }).compile();

    service = module.get(DispatchService);
  });

  it('offers the order to exactly ONE rider at a time, in closest+least-loaded order, never broadcasting to all six', async () => {
    const staff = { sub: 'staff-1', role: UserRole.KITCHEN, restaurantId: 'rest-1' };

    // --- Round 1: initial auto-assign ---
    await service.autoAssign(staff, 'order-1');
    expect(offersInOrder).toEqual(['rider-A']); // closest + idle wins; only 1 offer created

    // --- Rounds 2-5: simulate each offer timing out (no swipe) ---
    for (let round = 0; round < 4; round++) {
      const lastAssignmentId = `asgn-${offersInOrder.length}`;
      prisma.riderAssignment.findUnique.mockResolvedValueOnce({
        id: lastAssignmentId,
        orderId: 'order-1',
        riderId: offersInOrder[offersInOrder.length - 1],
        status: AssignmentStatus.EXPIRED,
        order: makeOrder(),
        rider: ALL_RIDERS[offersInOrder[offersInOrder.length - 1]],
      });
      await service.expireIfStillPending(lastAssignmentId);
    }

    // --- Round 6: last remaining eligible rider also expires -> exhaustion ---
    const lastAssignmentId = `asgn-${offersInOrder.length}`;
    prisma.riderAssignment.findUnique.mockResolvedValueOnce({
      id: lastAssignmentId,
      orderId: 'order-1',
      riderId: offersInOrder[offersInOrder.length - 1],
      status: AssignmentStatus.EXPIRED,
      order: makeOrder(),
      rider: ALL_RIDERS[offersInOrder[offersInOrder.length - 1]],
    });
    await service.expireIfStillPending(lastAssignmentId);

    // eslint-disable-next-line no-console
    console.log('\n=== 6-RIDER DISPATCH WATERFALL RESULT ===');
    console.log('Offer order:', offersInOrder.join(' -> '));
    console.log('rider-F (0.1km but at max load=3) was never offered:', !offersInOrder.includes('rider-F'));
    console.log('Total distinct riders offered:', new Set(offersInOrder).size, 'out of 6 onboarded');
    console.log('Exhausted event fired:', realtime.emitToRoom.mock.calls.some(
      (c: any) => c[1] === 'order:dispatch.exhausted',
    ));

    // Exactly the 5 eligible riders (everyone except the maxed-out rider-F),
    // offered ONE AT A TIME, closest+least-loaded first, never in parallel.
    expect(offersInOrder).toEqual(['rider-A', 'rider-C', 'rider-B', 'rider-E', 'rider-D']);
    expect(offersInOrder).not.toContain('rider-F');
    expect(new Set(offersInOrder).size).toBe(5); // 1 offer per rider, no duplicates, no broadcast

    // After the 5th eligible rider also times out, the restaurant is alerted
    // that dispatch is exhausted (no 7th auto-retry rider exists).
    expect(realtime.emitToRoom).toHaveBeenCalledWith(
      'restaurant:rest-1',
      'order:dispatch.exhausted',
      { orderId: 'order-1', orderNumber: 'W-9001' },
    );
  });
});
