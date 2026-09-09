import { BadRequestException } from '@nestjs/common';
import { OrderStatus } from '@prisma/client';
import { OrderStatusService } from './order-status.service';

/**
 * ORDER-LIFECYCLE PROOF (Flow #2): the order state machine is the backbone every
 * other system trusts. This exhaustively drives EVERY from→to status pair through
 * the real service and asserts that exactly the intended transitions are allowed,
 * all others are rejected, same-status is an idempotent no-op, and every accepted
 * transition writes an audit-trail history row. If anyone edits VALID_TRANSITIONS,
 * this test tells them precisely what changed.
 */

// The intended contract (source of truth the service must match).
const EXPECTED_ALLOWED: Record<OrderStatus, OrderStatus[]> = {
  [OrderStatus.PLACED]: [OrderStatus.ACCEPTED, OrderStatus.REJECTED, OrderStatus.CANCELLED],
  [OrderStatus.ACCEPTED]: [OrderStatus.PREPARING, OrderStatus.READY_FOR_PICKUP, OrderStatus.PICKED_UP, OrderStatus.CANCELLED],
  [OrderStatus.PREPARING]: [OrderStatus.READY_FOR_PICKUP, OrderStatus.PICKED_UP, OrderStatus.CANCELLED],
  [OrderStatus.READY_FOR_PICKUP]: [OrderStatus.PICKED_UP, OrderStatus.CANCELLED],
  [OrderStatus.PICKED_UP]: [OrderStatus.ON_THE_WAY, OrderStatus.DELIVERY_FAILED, OrderStatus.RETURNED_TO_RESTAURANT],
  [OrderStatus.ON_THE_WAY]: [OrderStatus.DELIVERED, OrderStatus.DELIVERY_FAILED, OrderStatus.RETURNED_TO_RESTAURANT],
  [OrderStatus.DELIVERY_FAILED]: [OrderStatus.CANCELLED, OrderStatus.READY_FOR_PICKUP],
  [OrderStatus.RETURNED_TO_RESTAURANT]: [OrderStatus.CANCELLED, OrderStatus.READY_FOR_PICKUP],
  // Terminal states — no outgoing transitions.
  [OrderStatus.DELIVERED]: [],
  [OrderStatus.CANCELLED]: [],
  [OrderStatus.REJECTED]: [],
  [OrderStatus.IGNORED_TEST]: [],
};

const ALL_STATUSES = Object.values(OrderStatus);
const user = { sub: 'user-1', role: 'OWNER' } as any;

function makePrisma(currentStatus: OrderStatus) {
  const tx = {
    order: {
      update: jest.fn(async ({ data }: any) => ({ id: 'order-1', status: currentStatus, ...data })),
    },
    orderStatusHistory: { create: jest.fn().mockResolvedValue({}) },
  };
  const prisma: any = {
    _tx: tx,
    order: {
      findUnique: jest.fn().mockResolvedValue({ id: 'order-1', status: currentStatus, assignment: null }),
    },
    $transaction: jest.fn(async (fn: any) => fn(tx)),
  };
  return prisma;
}

describe('OrderStatusService.transitionOrder — full transition matrix', () => {
  // Build every cross-status pair (from !== to).
  const crossPairs: [OrderStatus, OrderStatus][] = [];
  for (const from of ALL_STATUSES) {
    for (const to of ALL_STATUSES) {
      if (from !== to) crossPairs.push([from, to]);
    }
  }

  it.each(crossPairs)('%s → %s behaves per the contract', async (from, to) => {
    const prisma = makePrisma(from);
    const service = new OrderStatusService(prisma);
    const shouldAllow = EXPECTED_ALLOWED[from].includes(to);

    if (shouldAllow) {
      const result = await service.transitionOrder(user, 'order-1', to);
      expect(result.status).toBe(to);
      // Accepted transitions must write an audit-trail row with the previous status.
      expect(prisma._tx.orderStatusHistory.create).toHaveBeenCalledTimes(1);
      expect(prisma._tx.orderStatusHistory.create.mock.calls[0][0].data).toMatchObject({
        orderId: 'order-1',
        status: to,
        previousStatus: from,
        changedBy: 'user-1',
      });
    } else {
      await expect(service.transitionOrder(user, 'order-1', to)).rejects.toThrow(
        /Cannot transition from/,
      );
      expect(prisma._tx.order.update).not.toHaveBeenCalled();
    }
  });

  it('same-status transition is an idempotent no-op (no write, no history)', async () => {
    const prisma = makePrisma(OrderStatus.PREPARING);
    const service = new OrderStatusService(prisma);

    const result = await service.transitionOrder(user, 'order-1', OrderStatus.PREPARING);

    expect(result.status).toBe(OrderStatus.PREPARING);
    expect(prisma.$transaction).not.toHaveBeenCalled();
    expect(prisma._tx.orderStatusHistory.create).not.toHaveBeenCalled();
  });

  it('throws when the order does not exist', async () => {
    const prisma = makePrisma(OrderStatus.PLACED);
    prisma.order.findUnique.mockResolvedValueOnce(null);
    const service = new OrderStatusService(prisma);

    await expect(
      service.transitionOrder(user, 'missing', OrderStatus.ACCEPTED),
    ).rejects.toThrow(BadRequestException);
  });

  it('terminal states (DELIVERED/CANCELLED/REJECTED) reject every onward transition', async () => {
    for (const terminal of [OrderStatus.DELIVERED, OrderStatus.CANCELLED, OrderStatus.REJECTED]) {
      for (const to of ALL_STATUSES) {
        if (to === terminal) continue;
        const prisma = makePrisma(terminal);
        const service = new OrderStatusService(prisma);
        await expect(
          service.transitionOrder(user, 'order-1', to),
        ).rejects.toThrow(/Cannot transition from/);
      }
    }
  });
});
