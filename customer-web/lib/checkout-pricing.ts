interface CheckoutPricingInput {
  subtotal: number;
  discount: number;
  taxRatePercent: number;
  packagingFee: number;
  deliveryFee: number;
}

export function roundCurrency(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

/** Mirrors the backend order total formula for the pre-submit estimate. */
export function calculateCheckoutTotals(input: CheckoutPricingInput) {
  const taxAmount = roundCurrency(
    (input.subtotal * input.taxRatePercent) / 100
  );
  const packagingFee = roundCurrency(input.packagingFee);
  const grandTotal = roundCurrency(
    Math.max(
      0,
      input.subtotal -
        input.discount +
        taxAmount +
        packagingFee +
        input.deliveryFee
    )
  );

  return { taxAmount, packagingFee, grandTotal };
}
