import { expect, test } from "@playwright/test";

import { CheckoutPage } from "../pages/checkout.page";
import { LoginPage } from "../pages/login.page";

test("public shell is responsive and sends launch security headers", async ({ page }) => {
  const response = await page.goto("/");
  expect(response?.headers()["content-security-policy"]).toContain("default-src 'self'");
  expect(response?.headers()["x-content-type-options"]).toBe("nosniff");
  expect(response?.headers()["x-frame-options"]).toBe("DENY");
  await expect(page.getByRole("link", { name: /menu/i }).first()).toBeVisible();
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  expect(overflow).toBeLessThanOrEqual(1);
  await expect(page.getByRole("link", { name: "Offers", exact: true }).first()).toBeVisible();
  const offersResponse = page.waitForResponse((candidate) =>
    candidate.url().includes("/api/backend/coupons/public")
  );
  await page.goto("/offers");
  expect((await offersResponse).ok()).toBe(true);
  await expect(page.getByText("MOBILE10", { exact: true })).toBeVisible();
});

test("password login stores tokens only in HttpOnly cookies and rotates an expired access token", async ({ page, context }) => {
  const login = new LoginPage(page);
  await login.goto();
  await login.signInWithPassword();

  let cookies = await context.cookies();
  expect(cookies.find((cookie) => cookie.name === "wasabi_access")?.httpOnly).toBe(true);
  expect(cookies.find((cookie) => cookie.name === "wasabi_refresh")?.httpOnly).toBe(true);
  const persisted = await page.evaluate(() => localStorage.getItem("customer-auth"));
  expect(persisted).not.toContain("access-e2e");
  expect(persisted).not.toContain("refresh-e2e");

  await context.addCookies([
    { name: "wasabi_access", value: "expired", url: "http://localhost:3101", httpOnly: true, sameSite: "Lax" },
  ]);
  const refreshedProfile = page.waitForResponse(
    (response) =>
      response.url().includes("/api/backend/users/me") && response.ok()
  );
  await page.reload();
  await refreshedProfile;
  await expect(page.getByText("Mobile Customer", { exact: false }).first()).toBeVisible();
  await expect
    .poll(async () => {
      cookies = await context.cookies();
      return cookies.find((cookie) => cookie.name === "wasabi_access")?.value;
    })
    .toBe("access-rotated");
  expect(cookies.find((cookie) => cookie.name === "wasabi_refresh")?.value).toBe("refresh-rotated");
});

test("customer can reset a forgotten password", async ({ page }) => {
  await page.goto("/forgot-password");
  await page.getByLabel("Email or phone").fill("01700000000");
  await page.getByRole("button", { name: "Send reset code" }).click();
  await page.getByLabel("Reset code").fill("123456");
  await page.getByLabel("New password", { exact: true }).fill("NewPassword123!");
  await page.getByLabel("Confirm password").fill("NewPassword123!");
  await page.getByRole("button", { name: "Update password" }).click();
  await expect(page.getByRole("heading", { name: "Password updated" })).toBeVisible();
});

test("online checkout opens trusted bKash and callback confirms payment", async ({ page }) => {
  const login = new LoginPage(page);
  await login.goto();
  await login.signInWithPassword();

  const checkout = new CheckoutPage(page);
  await checkout.seedCart();
  await checkout.goto();
  await page.route("https://sandbox.bka.sh/**", (route) =>
    route.fulfill({ status: 200, contentType: "text/html", body: "<h1>bKash secure checkout</h1>" })
  );
  await checkout.chooseBkashAndPlace();
  await expect(page).toHaveURL("https://sandbox.bka.sh/checkout/payment-e2e");
  await expect(page.getByRole("heading", { name: "bKash secure checkout" })).toBeVisible();

  const confirmation = page.waitForResponse((response) =>
    response.url().includes("/api/backend/payments/orders/order-e2e/online/execute")
  );
  await page.goto("/payment/callback?orderId=order-e2e&paymentID=payment-e2e&status=success");
  expect((await confirmation).ok()).toBe(true);
  await expect(page.getByRole("heading", { name: "Payment confirmed" })).toBeVisible();
  await expect(page.getByRole("link", { name: "View order" })).toHaveAttribute("href", "/orders/order-e2e");
});
