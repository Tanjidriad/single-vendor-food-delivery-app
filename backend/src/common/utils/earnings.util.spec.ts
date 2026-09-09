import { OrderStatus } from '@prisma/client';
import {
  codDeliveryKeptAmount,
  codFoodRemittanceAmount,
  orderFoodRevenue,
  reportableDeliveredOrderWhere,
} from './earnings.util';

const slice = {
  subtotal: 200,
  discountAmount: 20,
  taxAmount: 10,
  packagingFee: 5,
  deliveryFee: 60,
  grandTotal: 255,
};

describe('orderFoodRevenue', () => {
  it('is subtotal minus discount plus tax and packaging (no delivery fee)', () => {
    expect(orderFoodRevenue(slice)).toBe(195);
  });

  it('rounds floating-point drift', () => {
    expect(
      orderFoodRevenue({
        subtotal: 0.1,
        discountAmount: 0,
        taxAmount: 0.2,
        packagingFee: 0,
        deliveryFee: 0,
        grandTotal: 0.3,
      }),
    ).toBe(0.3);
  });
});

describe('codFoodRemittanceAmount', () => {
  it('equals the food revenue the rider remits to the restaurant', () => {
    expect(codFoodRemittanceAmount(slice)).toBe(195);
  });
});

describe('codDeliveryKeptAmount', () => {
  it('prefers riderFee when set', () => {
    expect(codDeliveryKeptAmount({ riderFee: 40, deliveryFee: 60 })).toBe(40);
  });

  it('falls back to deliveryFee when riderFee is 0', () => {
    expect(codDeliveryKeptAmount({ riderFee: 0, deliveryFee: 60 })).toBe(60);
  });
});

describe('reportableDeliveredOrderWhere', () => {
  it('only counts delivered, non-test, reportable orders', () => {
    expect(reportableDeliveredOrderWhere()).toEqual({
      status: OrderStatus.DELIVERED,
      isTest: false,
      ignoreInReporting: false,
    });
  });

  it('scopes by restaurant and delivery date when provided', () => {
    const since = new Date('2026-01-01');
    const where = reportableDeliveredOrderWhere({
      restaurantId: 'rest-1',
      deliveredSince: since,
    });
    expect(where.restaurantId).toBe('rest-1');
    expect(where.deliveredAt).toEqual({ gte: since });
  });
});
