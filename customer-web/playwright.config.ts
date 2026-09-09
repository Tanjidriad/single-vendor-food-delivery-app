import { defineConfig, devices } from "@playwright/test";

const externalBaseUrl = process.env.PLAYWRIGHT_BASE_URL;

export default defineConfig({
  testDir: "./e2e/specs",
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 2,
  reporter: [["list"], ["html", { open: "never" }]],
  use: {
    baseURL: externalBaseUrl ?? "http://localhost:3101",
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },
  projects: [
    {
      name: "mobile-chromium",
      use: { ...devices["Pixel 5"] },
    },
    {
      name: "desktop-chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
  webServer: externalBaseUrl ? undefined : [
    {
      command: "node e2e/mock-backend.mjs",
      url: "http://127.0.0.1:4010/health",
      timeout: 30_000,
      reuseExistingServer: !process.env.CI,
    },
    {
      command: "npx next dev -p 3101",
      url: "http://127.0.0.1:3101/api/health",
      timeout: 120_000,
      reuseExistingServer: !process.env.CI,
      env: {
        BACKEND_API_URL: "http://127.0.0.1:4010/api/v1",
        NEXT_PUBLIC_SITE_URL: "http://localhost:3101",
        NEXT_PUBLIC_RESTAURANT_SLUG: "wasabi",
      },
    },
  ],
});
