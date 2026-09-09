import { expect, test } from "@playwright/test";

test("WASABI visual system covers public and authenticated customer screens", async ({ page }, testInfo) => {
  const runtimeErrors: string[] = [];
  page.on("pageerror", (error) => runtimeErrors.push(error.message));

  await page.goto("/");
  await expect(page.getByRole("heading", { name: "HOT. FOLDED. FAST." })).toBeVisible();
  await expect(page.getByRole("heading", { name: "First out of the steamer." })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Find your kind of momo." })).toBeVisible();
  await expect(page.getByRole("heading", { name: "STEAM. SAUCE. REPEAT." })).toBeVisible();
  for (const name of [
    "Where great momo meets good moments.",
    "Find your kind of momo.",
    "From menu to your door",
    "Choose your food",
    "Choose your way",
    "Follow the order",
    "Your next box starts here.",
  ]) {
    await page.getByRole("heading", { name }).scrollIntoViewIfNeeded();
  }
  await page.evaluate(() => window.scrollTo({ top: 0, behavior: "instant" }));
  await page.screenshot({
    path: `../docs/web app design system/mockups/wasabi-home-implemented-${testInfo.project.name}.png`,
    fullPage: true,
  });

  await page.goto("/offers");
  await expect(page.getByRole("heading", { name: "CLIP IT. CLAIM IT." })).toBeVisible();
  await expect(page.getByText("MOBILE10", { exact: true })).toBeVisible();

  await page.goto("/privacy");
  await expect(page.getByRole("heading", { name: "Privacy policy" })).toBeVisible();

  await page.goto("/login?next=/account");
  await expect(page.getByRole("heading", { name: "Welcome back" })).toBeVisible();
  await page.getByRole("tab", { name: "Password" }).click();
  await page.getByLabel("Email or phone").fill("customer@example.com");
  await page.getByLabel("Password").fill("Password123!");
  await page.locator("form").getByRole("button", { name: "Sign in", exact: true }).click();
  await expect(page).toHaveURL(/\/account$/);
  await expect(page.getByRole("heading", { name: "Mobile Customer" })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Profile slip" })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Delivery stops" })).toBeVisible();
  await page.screenshot({
    path: `../docs/web app design system/mockups/wasabi-account-implemented-${testInfo.project.name}.png`,
    fullPage: true,
  });

  await page.goto("/favorites");
  await expect(page.getByRole("heading", { name: "Saved for the next box." })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Chicken Momo" })).toBeVisible();

  await page.goto("/notifications");
  await expect(page.getByRole("heading", { name: "Kitchen signals." })).toBeVisible();
  await expect(page.getByText("Order received", { exact: true })).toBeVisible();

  await page.goto("/support");
  await expect(page.getByRole("heading", { name: "We'll sort the order." })).toBeVisible();

  await page.goto("/orders");
  await expect(page.getByRole("heading", { name: "From kitchen to your door." })).toBeVisible();
  await page.locator('a[href="/orders/order-e2e"]').click();
  await expect(page.getByRole("heading", { name: "We're on it" })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Order slip" })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Counter total" })).toBeVisible();

  await page.goto("/menu");
  await page.getByRole("button", { name: "Customise Chicken Momo" }).first().click();
  await page.getByRole("button", { name: /Add to cart/ }).click();
  await page.goto("/checkout");
  await expect(page.getByRole("heading", { name: "Counter checkout" })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Delivery details" })).toBeVisible();

  const layout = await page.evaluate(() => ({
    overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth,
    offenders: [...document.querySelectorAll("body *")]
      .map((element) => {
        const rect = element.getBoundingClientRect();
        return { tag: element.tagName, className: element.className, left: rect.left, right: rect.right };
      })
      .filter((element) => element.left < -1 || element.right > document.documentElement.clientWidth + 1)
      .slice(0, 10),
  }));
  expect(layout.overflow, JSON.stringify(layout.offenders)).toBeLessThanOrEqual(1);
  expect(runtimeErrors).toEqual([]);
});
