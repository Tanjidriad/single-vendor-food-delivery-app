import { CodSettlementStatus, OrderStatus, PaymentMethod } from '@prisma/client';
import { CodSettlementService } from './cod-settlement.service';

/**
 * MONEY-PATH PROOF (Flow #1): COD cash reconciliation. When a rider collects
 * cash at the door we must record exactly what was collected, what fee the rider
 * keeps, and what food revenue is owed to the restaurant — once, idempotently —
 * and settlement must be blocked until the order is actually delivered and can
 * never be double-recorded. This is the ledger a COD-first launch runs on.
 */
function makeCollectOrder(overrides: Record<string, any> = {}) {
  return {
    id: 'order-1',
    paymentMethod: PaymentMethod.COD,
    grandTotal: 440,
    subtotal: 400,
    discountAmount: 50,
    taxAmount: 20,
    packagingFee: 10,
    deliveryFee: 60,
    riderFee: 50,
    assignment: { riderId: 'rider-1', status: 'ACCEPTED' },
    ...overrides,
  };
}

function makeCollectTx(existing: any = null) {
  return {
    order: { update: jest.fn().mockResolvedValue({}) },
    codSettlement: {
      findUnique: jest.fn().mockResolvedValue(existing),
      create: jest.fn().mockResolvedValue({}),
    },
  };
}

describe('CodSettlementService.recordCodCollection', () => {
  it('records the collection once with correct amounts (collected=grandTotal, rider keeps riderFee)', async () => {
    const service = new CodSettlementService({} as any);
    const tx = makeCollectTx();
    const collectedAt = new Date('2026-07-01T10:00:00Z');

    await service.recordCodCollection(tx as any, makeCollectOrder(), collectedAt);

    expect(tx.order.update).toHaveBeenCalledWith({
      where: { id: 'order-1' },
      data: { codCollectedAt: collectedAt },
    });
    expect(tx.codSettlement.create).toHaveBeenCalledTimes(1);
    expect(tx.codSettlement.create.mock.calls[0][0].data).toMatchObject({
      orderId: 'order-1',
      riderId: 'rider-1',
      codCollectedAmount: 440, // full cash taken from the customer
      foodAmountRemitted: 0, // not yet remitted to the restaurant
      deliveryFeeKept: 50, // rider keeps riderFee
      status: CodSettlementStatus.PENDING,
    });
  });

  it('is a NO-OP for a non-COD (online) order', async () => {
    const service = new CodSettlementService({} as any);
    const tx = makeCollectTx();

    await service.recordCodCollection(
      tx as any,
      makeCollectOrder({ paymentMethod: PaymentMethod.ONLINE }),
      new Date(),
    );

    expect(tx.order.update).not.toHaveBeenCalled();
    expect(tx.codSettlement.create).not.toHaveBeenCalled();
  });

  it('is a NO-OP when there is no ACCEPTED rider assignment', async () => {
    const service = new CodSettlementService({} as any);
    const tx = makeCollectTx();

    await service.recordCodCollection(
      tx as any,
      makeCollectOrder({ assignment: null }),
      new Date(),
    );

    expect(tx.codSettlement.create).not.toHaveBeenCalled();
  });

  it('is idempotent — an existing settlement is never recreated (no double count)', async () => {
    const service = new CodSettlementService({} as any);
    const tx = makeCollectTx({ id: 'settle-1' }); // already exists

    await service.recordCodCollection(tx as any, makeCollectOrder(), new Date());

    expect(tx.codSettlement.create).not.toHaveBeenCalled();
  });
});

describe('CodSettlementService.settle', () => {
  function makeService(settlement: any) {
    const prisma = {
      codSettlement: {
        findUnique: jest.fn().mockResolvedValue(settlement),
        update: jest.fn(async ({ data }: any) => ({ id: 'settle-1', ...data })),
      },
    };
    return { service: new CodSettlementService(prisma as any), prisma };
  }

  const deliveredSettlement = {
    id: 'settle-1',
    status: CodSettlementStatus.PENDING,
    order: {
      status: OrderStatus.DELIVERED,
      subtotal: 400,
      discountAmount: 50,
      taxAmount: 20,
      packagingFee: 10,
      deliveryFee: 60,
      grandTotal: 440,
    },
  };

  it('settles a delivered order and defaults food remittance to the food revenue (380)', async () => {
    const { service, prisma } = makeService(deliveredSettlement);

    await service.settle({ orderId: 'order-1', settledBy: 'admin-1' });

    expect(prisma.codSettlement.update).toHaveBeenCalledTimes(1);
    expect(prisma.codSettlement.update.mock.calls[0][0].data).toMatchObject({
      status: CodSettlementStatus.SETTLED,
      foodAmountRemitted: 380, // subtotal - discount + tax + packaging
      settledBy: 'admin-1',
    });
  });

  it('rejects settlement before the order is delivered', async () => {
    const { service } = makeService({
      ...deliveredSettlement,
      order: { ...deliveredSettlement.order, status: OrderStatus.ON_THE_WAY },
    });

    await expect(
      service.settle({ orderId: 'order-1', settledBy: 'admin-1' }),
    ).rejects.toThrow('Order must be delivered before settlement');
  });

  it('rejects a double settlement', async () => {
    const { service } = makeService({
      ...deliveredSettlement,
      status: CodSettlementStatus.SETTLED,
    });

    await expect(
      service.settle({ orderId: 'order-1', settledBy: 'admin-1' }),
    ).rejects.toThrow('already recorded');
  });

  it('caps the food remittance at the expected food revenue (cannot over-credit the restaurant)', async () => {
    const { service } = makeService(deliveredSettlement);

    await expect(
      service.settle({ orderId: 'order-1', settledBy: 'admin-1', foodAmountRemitted: 440 }),
    ).rejects.toThrow('Food remittance must be between 0 and 380');
  });
});
