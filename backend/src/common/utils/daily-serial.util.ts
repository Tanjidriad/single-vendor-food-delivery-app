import { Prisma } from '@prisma/client';

/**
 * Calendar-day key in Bangladesh local time (UTC+6), e.g. "2026-06-23".
 * Used to bucket the per-restaurant daily order counter so it resets at local
 * midnight rather than UTC midnight (which would roll over at 6am Dhaka time).
 */
export function dhakaDayKey(now = new Date()): string {
  const dhaka = new Date(now.getTime() + 6 * 60 * 60 * 1000);
  return dhaka.toISOString().slice(0, 10);
}

/**
 * Atomically allocates the next sequential serial for a restaurant on the
 * current local day. Must run inside the order-creation transaction so two
 * concurrent orders can never receive the same serial.
 */
export async function nextDailySerial(
  tx: Prisma.TransactionClient,
  restaurantId: string,
  now = new Date(),
): Promise<number> {
  const day = dhakaDayKey(now);
  const counter = await tx.dailyOrderCounter.upsert({
    where: { restaurantId_day: { restaurantId, day } },
    create: { restaurantId, day, count: 1 },
    update: { count: { increment: 1 } },
  });
  return counter.count;
}
