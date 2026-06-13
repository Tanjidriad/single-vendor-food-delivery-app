import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class CouponsService {
  constructor(private prisma: PrismaService) {}

  /** Returns active, non-expired coupons visible to customers */
  async listPublic(restaurantId: string) {
    const now = new Date();
    return this.prisma.coupon.findMany({
      where: {
        restaurantId,
        isActive: true,
        AND: [
          { OR: [{ endsAt: null }, { endsAt: { gt: now } }] },
          { OR: [{ startsAt: null }, { startsAt: { lte: now } }] },
        ],
      },
      select: {
        id: true,
        code: true,
        description: true,
        discountType: true,
        discountValue: true,
        minOrderAmount: true,
        endsAt: true,
      },
      orderBy: { discountValue: 'desc' },
    });
  }

  async validate(restaurantId: string, code: string, subtotal: number) {
    const coupon = await this.prisma.coupon.findFirst({
      where: { restaurantId, code, isActive: true },
    });
    if (!coupon) throw new BadRequestException('Invalid coupon');
    const now = new Date();
    if (coupon.startsAt && coupon.startsAt > now) {
      throw new BadRequestException('Coupon not yet active');
    }
    if (coupon.endsAt && coupon.endsAt < now) {
      throw new BadRequestException('Coupon expired');
    }
    if (coupon.maxUses && coupon.usedCount >= coupon.maxUses) {
      throw new BadRequestException('Coupon usage limit reached');
    }
    if (coupon.minOrderAmount && subtotal < coupon.minOrderAmount) {
      throw new BadRequestException(
        `Minimum order ${coupon.minOrderAmount} required`,
      );
    }
    let discount = 0;
    if (coupon.discountType === 'PERCENT') {
      discount = (subtotal * coupon.discountValue) / 100;
    } else {
      discount = coupon.discountValue;
    }
    return { valid: true, couponId: coupon.id, code: coupon.code, discount };
  }
}
