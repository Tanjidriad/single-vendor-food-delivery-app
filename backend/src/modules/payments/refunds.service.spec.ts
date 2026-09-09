import { Test } from '@nestjs/testing';
import { getQueueToken } from '@nestjs/bullmq';
import { PaymentMethod, PaymentStatus, RefundRequestStatus } from '@prisma/client';
import { RefundsService } from './refunds.service';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PAYMENT_GATEWAY } from './gateways/payment-gateway.interface';
import { NOTIFICATIONS_QUEUE } from '../../common/queues/queue.constants';

/**
 * MONEY-PATH PROOF (Flow #1): a prepaid order that is rejected or cancelled must
 * ALWAYS produce exactly one refund request; a COD order must never produce one;
 * and calling the helper twice must not double-refund.
 *
 * This locks in the launch-critical guarantee that no prepaid customer is ever
 * charged and then silently not refunded when the restaurant rejects or the
 * order is cancelled before delivery.
 */
function makeOrder(overrides: Record<string, any> = {}) {
  return {
    id: 'order-1',
    orderNumber: 'W-9001',
    grandTotal: 500,
    paymentMethod: PaymentMethod.ONLINE,
    paymentStatus: PaymentStatus.PAID,
    customerId: 'cust-1',
    payment: { id: 'pay-1', method: PaymentMethod.ONLINE, transactionId: 'trx-1' },
    ...overrides,
  };
}

describe('RefundsService.enqueuePrepaidRefund (money-path guard)', () => {
  let service: RefundsService;
  let prisma: any;

  function build(order: any, existingRefund: any = null) {
    prisma = {
      order: { findUnique: jest.fn().mockResolvedValue(order) },
      refundRequest: {
        findFirst: jest.fn().mockResolvedValue(existingRefund),
        create: jest.fn(async ({ data }: any) => ({ id: 'refund-1', ...data })),
      },
    };
    return Test.createTestingModule({
      providers: [
        RefundsService,
        { provide: PrismaService, useValue: prisma },
        { provide: NotificationsService, useValue: { sendToUser: jest.fn() } },
        { provide: PAYMENT_GATEWAY, useValue: { id: 'bkash' } },
        { provide: getQueueToken(NOTIFICATIONS_QUEUE), useValue: { add: jest.fn().mockResolvedValue({}) } },
      ],
    })
      .compile()
      .then((m) => (service = m.get(RefundsService)));
  }

  it('creates exactly one refund request for a prepaid (ONLINE + PAID) order', async () => {
    await build(makeOrder());

    const result = await service.enqueuePrepaidRefund('order-1', 'Order rejected by restaurant — prepaid refund');

    expect(prisma.refundRequest.create).toHaveBeenCalledTimes(1);
    const data = prisma.refundRequest.create.mock.calls[0][0].data;
    expect(data.orderId).toBe('order-1');
    expect(data.amount).toBe(500); // full grand total
    expect(data.paymentId).toBe('pay-1');
    expect(data.reason).toBe('Order rejected by restaurant — prepaid refund');
    expect(result).not.toBeNull();
  });

  it('is a NO-OP for a COD order (nothing to refund pre-delivery)', async () => {
    await build(makeOrder({ paymentMethod: PaymentMethod.COD, paymentStatus: PaymentStatus.PENDING, payment: null }));

    const result = await service.enqueuePrepaidRefund('order-1', 'Order cancelled — prepaid refund');

    expect(result).toBeNull();
    expect(prisma.refundRequest.create).not.toHaveBeenCalled();
  });

  it('is a NO-OP for an online order that has NOT been paid yet', async () => {
    await build(makeOrder({ paymentStatus: PaymentStatus.PENDING }));

    const result = await service.enqueuePrepaidRefund('order-1', 'reason');

    expect(result).toBeNull();
    expect(prisma.refundRequest.create).not.toHaveBeenCalled();
  });

  it('is idempotent — a second call does not create a second refund', async () => {
    // A pending refund already exists for this order.
    await build(makeOrder(), { id: 'refund-existing', status: RefundRequestStatus.PENDING });

    const result = await service.enqueuePrepaidRefund('order-1', 'reason');

    expect(result).toEqual(expect.objectContaining({ id: 'refund-existing' }));
    expect(prisma.refundRequest.create).not.toHaveBeenCalled();
  });

  it('enqueueDeliveryFailedRefund delegates to the same guard with its own reason', async () => {
    await build(makeOrder());

    await service.enqueueDeliveryFailedRefund('order-1');

    expect(prisma.refundRequest.create).toHaveBeenCalledTimes(1);
    expect(prisma.refundRequest.create.mock.calls[0][0].data.reason).toContain('Delivery failed');
  });
});
