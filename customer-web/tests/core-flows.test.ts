import { describe, expect, it } from "vitest";

import { safeAuthRedirect } from "../lib/auth/redirect";
import { calculateCheckoutTotals } from "../lib/checkout-pricing";
import { progressSteps } from "../lib/order-status";
import { isTrustedPaymentUrl } from "../lib/payments";

describe("customer critical flows", () => {
  it("matches the backend checkout total formula", () => {
    expect(
      calculateCheckoutTotals({
        subtotal: 1000,
        discount: 100,
        taxRatePercent: 5,
        packagingFee: 20,
        deliveryFee: 60,
      })
    ).toEqual({ taxAmount: 50, packagingFee: 20, grandTotal: 1030 });
  });

  it("includes rider pickup before on-the-way delivery", () => {
    expect(progressSteps("DELIVERY").map((step) => step.status)).toEqual([
      "PLACED",
      "ACCEPTED",
      "PREPARING",
      "READY_FOR_PICKUP",
      "PICKED_UP",
      "ON_THE_WAY",
      "DELIVERED",
    ]);
  });

  it("rejects cross-origin and backslash auth redirects", () => {
    expect(safeAuthRedirect("/checkout")).toBe("/checkout");
    expect(safeAuthRedirect("//evil.example/path")).toBe("/");
    expect(safeAuthRedirect("/\\evil.example/path")).toBe("/");
    expect(safeAuthRedirect("https://evil.example")).toBe("/");
  });

  it("allows only HTTPS bKash checkout hosts", () => {
    expect(isTrustedPaymentUrl("https://sandbox.bka.sh/checkout/123")).toBe(true);
    expect(isTrustedPaymentUrl("https://checkout.bkash.com/pay/123")).toBe(true);
    expect(isTrustedPaymentUrl("http://sandbox.bka.sh/checkout/123")).toBe(false);
    expect(isTrustedPaymentUrl("https://bka.sh.evil.example/checkout/123")).toBe(false);
    expect(isTrustedPaymentUrl("javascript:alert(1)")).toBe(false);
  });
});
