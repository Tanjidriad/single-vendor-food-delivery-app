import { BadRequestException } from '@nestjs/common';
import { PaymentMethod, PaymentStatus } from '@prisma/client';
import { PaymentsService } from './payments.service';

function makeOrder(overrides: Record<string, any> = {}) {
  return {
    id: 'order-1',
    customerId: 'cust-1',
    customerPhone: '01700000000',
    orderNumber: 'W-1001',
    restaurantId: 'rest-1',
    status: 'CONFIRMED',
    grandTotal: 500,
    paymentMethod: PaymentMethod.ONLINE,
    paymentStatus: PaymentStatus.PENDING,
    payment: { transactionId: 'pay-123', status: PaymentStatus.PENDING },
    ...overrides,
  };
}

describe('PaymentsService.executeOnline', () => {
  let prisma: any;
  let tx: any;
  let realtime: any;
  let gateway: any;
  let config: any;
  let service: PaymentsService;

  beforeEach(() => {
    tx = {
      order: {
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        findUnique: jest
          .fn()
          .mockResolvedValue(makeOrder({ paymentStatus: PaymentStatus.PAID })),
      },
      payment: { update: jest.fn().mockResolvedValue({}) },
    };
    prisma = {
      order: { findUnique: jest.fn() },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    realtime = { emitRestaurantNewOrder: jest.fn() };
    gateway = {
      id: 'bkash',
      executePayment: jest.fn(),
      queryPayment: jest.fn(),
    };
    config = { get: jest.fn() };
    service = new PaymentsService(prisma, config, realtime, gateway);
  });

  it('settles and notifies the restaurant once on success', async () => {
    prisma.order.findUnique.mockResolvedValue(makeOrder());
    gateway.executePayment.mockResolvedValue({
      success: true,
      transactionId: 'TRX1',
      amount: '500',
    });

    const res = await service.executeOnline('order-1', 'cust-1', 'pay-123');

    expect(res.status).toBe(PaymentStatus.PAID);
    expect(res.transactionId).toBe('TRX1');
    expect(realtime.emitRestaurantNewOrder).toHaveBeenCalledTimes(1);
  });

  it('rejects when the captured amount does not match the order total', async () => {
    prisma.order.findUnique.mockResolvedValue(makeOrder());
    gateway.executePayment.mockResolvedValue({
      success: true,
      transactionId: 'TRX1',
      amount: '450',
    });

    await expect(
      service.executeOnline('order-1', 'cust-1', 'pay-123'),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(realtime.emitRestaurantNewOrder).not.toHaveBeenCalled();
  });

  it('is idempotent when the order is already paid (no gateway call)', async () => {
    prisma.order.findUnique.mockResolvedValue(
      makeOrder({ paymentStatus: PaymentStatus.PAID }),
    );

    const res = await service.executeOnline('order-1', 'cust-1', 'pay-123');

    expect(res.message).toBe('Already paid');
    expect(gateway.executePayment).not.toHaveBeenCalled();
  });

  it('does not double-settle or double-emit under a concurrent execute', async () => {
    prisma.order.findUnique.mockResolvedValue(makeOrder());
    gateway.executePayment.mockResolvedValue({
      success: true,
      transactionId: 'TRX1',
      amount: '500',
    });
    // Another request flipped the status first: the guarded update matches 0 rows.
    tx.order.updateMany.mockResolvedValue({ count: 0 });

    const res = await service.executeOnline('order-1', 'cust-1', 'pay-123');

    expect(res.message).toBe('Already paid');
    expect(realtime.emitRestaurantNewOrder).not.toHaveBeenCalled();
  });

  it('rejects a paymentId that does not match the order', async () => {
    prisma.order.findUnique.mockResolvedValue(
      makeOrder({ payment: { transactionId: 'a-different-id' } }),
    );

    await expect(
      service.executeOnline('order-1', 'cust-1', 'pay-123'),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects when the gateway and the status query both report failure', async () => {
    prisma.order.findUnique.mockResolvedValue(makeOrder());
    gateway.executePayment.mockResolvedValue({
      success: false,
      transactionStatus: 'Failed',
    });
    gateway.queryPayment.mockResolvedValue({ success: false });

    await expect(
      service.executeOnline('order-1', 'cust-1', 'pay-123'),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});
