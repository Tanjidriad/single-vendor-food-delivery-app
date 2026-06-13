import { OrderStatus, Prisma } from '@prisma/client';
import { round2 } from './money.util';

export type OrderAmountSlice = {
  subtotal: number;
  discountAmount: number;
  taxAmount: number;
  packagingFee: number;
  deliveryFee: number;
  grandTotal: number;
};

/** Restaurant food revenue excluding delivery fee. */
export function orderFoodRevenue(order: OrderAmountSlice): number {
  return round2(
    order.subtotal -
      order.discountAmount +
      order.taxAmount +
      order.packagingFee,
  );
}

/** COD food portion the rider remits to the restaurant. */
export function codFoodRemittanceAmount(order: OrderAmountSlice): number {
  return orderFoodRevenue(order);
}

/** Delivery fee the rider keeps on COD settlement. */
export function codDeliveryKeptAmount(order: {
  riderFee: number;
  deliveryFee: number;
}): number {
  return round2(order.riderFee || order.deliveryFee);
}

/** Delivered, non-test orders included in financial reports. */
export function reportableDeliveredOrderWhere(
  opts: { restaurantId?: string; deliveredSince?: Date } = {},
): Prisma.OrderWhereInput {
  const where: Prisma.OrderWhereInput = {
    status: OrderStatus.DELIVERED,
    isTest: false,
    ignoreInReporting: false,
  };
  if (opts.restaurantId) {
    where.restaurantId = opts.restaurantId;
  }
  if (opts.deliveredSince) {
    where.deliveredAt = { gte: opts.deliveredSince };
  }
  return where;
}
