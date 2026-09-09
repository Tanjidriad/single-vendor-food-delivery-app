import { BadRequestException } from '@nestjs/common';
import { CouponsService } from './coupons.service';

function makeCoupon(overrides: Record<string, any> = {}) {
  return {
    id: 'c1',
    code: 'SAVE10',
    restaurantId: 'rest-1',
    isActive: true,
    discountType: 'PERCENT',
    discountValue: 10,
    minOrderAmount: null,
    maxUses: null,
    usedCount: 0,
    startsAt: null,
    endsAt: null,
    ...overrides,
  };
}

describe('CouponsService.validate', () => {
  let prisma: any;
  let service: CouponsService;

  beforeEach(() => {
    prisma = { coupon: { findFirst: jest.fn() } };
    service = new CouponsService(prisma);
  });

  it('rejects an unknown / inactive coupon', async () => {
    prisma.coupon.findFirst.mockResolvedValue(null);
    await expect(
      service.validate('rest-1', 'NOPE', 100),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('computes a percent discount', async () => {
    prisma.coupon.findFirst.mockResolvedValue(
      makeCoupon({ discountType: 'PERCENT', discountValue: 10 }),
    );
    const res = await service.validate('rest-1', 'SAVE10', 200);
    expect(res.valid).toBe(true);
    expect(res.discount).toBe(20);
    expect(res.couponId).toBe('c1');
  });

  it('computes a fixed discount', async () => {
    prisma.coupon.findFirst.mockResolvedValue(
      makeCoupon({ discountType: 'FIXED', discountValue: 50 }),
    );
    const res = await service.validate('rest-1', 'FLAT50', 200);
    expect(res.discount).toBe(50);
  });

  it('rejects a coupon that has not started yet', async () => {
    prisma.coupon.findFirst.mockResolvedValue(
      makeCoupon({ startsAt: new Date(Date.now() + 3_600_000) }),
    );
    await expect(service.validate('rest-1', 'SAVE10', 200)).rejects.toThrow(
      'not yet active',
    );
  });

  it('rejects an expired coupon', async () => {
    prisma.coupon.findFirst.mockResolvedValue(
      makeCoupon({ endsAt: new Date(Date.now() - 3_600_000) }),
    );
    await expect(service.validate('rest-1', 'SAVE10', 200)).rejects.toThrow(
      'expired',
    );
  });

  it('rejects when the usage limit is reached', async () => {
    prisma.coupon.findFirst.mockResolvedValue(
      makeCoupon({ maxUses: 5, usedCount: 5 }),
    );
    await expect(service.validate('rest-1', 'SAVE10', 200)).rejects.toThrow(
      'usage limit',
    );
  });

  it('rejects when the subtotal is below the coupon minimum', async () => {
    prisma.coupon.findFirst.mockResolvedValue(
      makeCoupon({ minOrderAmount: 300 }),
    );
    await expect(service.validate('rest-1', 'SAVE10', 200)).rejects.toThrow(
      'Minimum order',
    );
  });
});
