import { OrderStatus, PaymentMethod } from '@prisma/client';
import { RiderLedgerService } from './rider-ledger.service';

function makeTx() {
  return {
    riderLedgerEntry: {
      findFirst: jest.fn().mockResolvedValue(null),
      create: jest.fn().mockResolvedValue({}),
    },
  };
}

function makeOrder(overrides: Record<string, any> = {}) {
  return {
    id: 'order-1',
    status: OrderStatus.DELIVERED,
    riderFee: 50,
    paymentMethod: PaymentMethod.ONLINE,
    assignment: { riderId: 'rider-1', status: 'ACCEPTED' },
    ...overrides,
  };
}

describe('RiderLedgerService.onOrderDelivered', () => {
  let service: RiderLedgerService;
  let tx: any;

  beforeEach(() => {
    tx = makeTx();
    service = new RiderLedgerService({} as any);
  });

  it('credits the delivery fee for an online-paid order (platform owes the rider)', async () => {
    await service.onOrderDelivered(tx, makeOrder());

    expect(tx.riderLedgerEntry.create).toHaveBeenCalledTimes(1);
    expect(tx.riderLedgerEntry.create.mock.calls[0][0].data).toMatchObject({
      riderId: 'rider-1',
      orderId: 'order-1',
      amount: 50,
    });
  });

  it('does NOT credit the ledger for a COD order (rider already kept the cash)', async () => {
    await service.onOrderDelivered(
      tx,
      makeOrder({ paymentMethod: PaymentMethod.COD }),
    );

    expect(tx.riderLedgerEntry.create).not.toHaveBeenCalled();
  });

  it('skips when the order is not delivered', async () => {
    await service.onOrderDelivered(
      tx,
      makeOrder({ status: OrderStatus.ON_THE_WAY }),
    );

    expect(tx.riderLedgerEntry.create).not.toHaveBeenCalled();
  });

  it('skips when there is no accepted assignment', async () => {
    await service.onOrderDelivered(tx, makeOrder({ assignment: null }));

    expect(tx.riderLedgerEntry.create).not.toHaveBeenCalled();
  });
});
