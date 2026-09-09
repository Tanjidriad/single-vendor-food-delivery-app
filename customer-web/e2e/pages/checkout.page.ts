import { expect, type Page } from "@playwright/test";

export class CheckoutPage {
  constructor(private readonly page: Page) {}

  async seedCart() {
    await this.page.evaluate(() => {
      localStorage.setItem(
        "customer-cart",
        JSON.stringify({
          state: {
            lines: [
              {
                itemId: "momo-e2e",
                name: "Chicken Momo",
                price: 120,
                quantity: 2,
                addons: [],
              },
            ],
          },
          version: 0,
        })
      );
    });
  }

  async goto() {
    await this.page.goto("/checkout");
    await expect(this.page.getByRole("heading", { name: "Checkout" })).toBeVisible();
    await expect(this.page.getByText("House 1, Test Road", { exact: false })).toBeVisible();
  }

  async chooseBkashAndPlace() {
    await this.page.getByRole("button", { name: /Pay with bKash/ }).click();
    await this.page.getByRole("button", { name: /Place order|Continue & place order/ }).click();
  }
}
