import { expect, type Page } from "@playwright/test";

export class LoginPage {
  constructor(private readonly page: Page) {}

  async goto(next = "/account") {
    await this.page.goto(`/login?next=${encodeURIComponent(next)}`);
  }

  async signInWithPassword() {
    await this.page.getByRole("tab", { name: "Password" }).click();
    await this.page.getByLabel("Email or phone").fill("customer@example.com");
    await this.page.getByLabel("Password", { exact: true }).fill("Password123!");
    const loginResponse = this.page.waitForResponse((response) =>
      response.url().includes("/api/backend/auth/login")
    );
    await this.page.locator("form").getByRole("button", { name: "Sign in", exact: true }).click();
    expect((await loginResponse).ok()).toBe(true);
    await expect(this.page).toHaveURL(/\/account$/);
  }
}
