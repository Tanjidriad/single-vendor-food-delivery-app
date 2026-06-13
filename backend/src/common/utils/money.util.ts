/**
 * Round a monetary amount to 2 decimal places (whole paisa for BDT).
 *
 * All money in this codebase is stored as `Float`. Floating-point arithmetic
 * (e.g. `0.1 + 0.2 = 0.30000000000000004`) can drift by fractions of a paisa
 * across subtotal/discount/tax/fee math, desyncing `Payment.amount` from
 * `grandTotal`. Apply `round2()` after every money calculation so totals snap
 * back to the nearest paisa and errors cannot accumulate.
 *
 * Note: this is a practical fix for a single-restaurant BDT/COD launch. For a
 * high-volume or multi-currency payments platform, migrate the columns to
 * integer minor units or Prisma `Decimal` instead (see AUDIT.md).
 */
export function round2(amount: number): number {
  return Math.round((amount + Number.EPSILON) * 100) / 100;
}
