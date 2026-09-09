import { expect, test } from "@playwright/test";

test("premium menu is responsive, searchable, and keeps cart interaction working", async ({ page }, testInfo) => {
  const runtimeErrors: string[] = [];
  const failedResponses: string[] = [];
  page.on("pageerror", (error) => runtimeErrors.push(error.message));
  page.on("response", (response) => {
    if (response.status() >= 400) {
      failedResponses.push(`${response.status()} ${response.url()}`);
    }
  });

  await page.goto("/menu");

  await expect(page.getByRole("heading", { name: "Momo, made loud." })).toBeVisible();
  await expect(page.getByRole("button", { name: "Search menu" })).toBeVisible();
  await expect(page.getByRole("region", { name: "Popular right now" })).toBeVisible();
  await expect(page.getByText("Kitchen special", { exact: true })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Plan your momo run." })).toBeVisible();
  await expect(page.getByRole("heading", { name: "FOLDED TODAY." })).toBeVisible();

  const overflow = await page.evaluate(
    () => document.documentElement.scrollWidth - document.documentElement.clientWidth
  );
  expect(overflow).toBeLessThanOrEqual(1);

  await page.getByRole("button", { name: "Search menu" }).click();
  await page.getByLabel("Search dishes").fill("Chicken");
  const popular = page.getByRole("region", { name: "Popular right now" });
  await expect(popular.getByRole("heading", { name: "Chicken Momo", exact: true })).toBeVisible();
  await popular.getByRole("button", { name: "Customise Chicken Momo" }).click();
  await expect(page.getByRole("dialog", { name: "Chicken Momo" })).toBeVisible();
  await page.getByRole("button", { name: /Add to cart/ }).click();
  await expect(page.getByRole("link", { name: /View cart/ })).toBeVisible();
  await expect(page.getByText("Chicken Momo added", { exact: true })).toBeHidden({ timeout: 7_000 });
  await page.evaluate(() => window.scrollTo({ top: 0, behavior: "instant" }));
  await expect(page.getByRole("heading", { name: "Momo, made loud." })).toBeInViewport();

  await page.screenshot({
    path: `../docs/web app design system/mockups/wasabi-menu-implemented-${testInfo.project.name}.png`,
    fullPage: true,
  });

  expect(runtimeErrors).toEqual([]);
  expect(
    failedResponses.filter(
      (failure) =>
        !failure.startsWith("401 ") ||
        !failure.includes("/api/backend/users/me")
    )
  ).toEqual([]);
});
