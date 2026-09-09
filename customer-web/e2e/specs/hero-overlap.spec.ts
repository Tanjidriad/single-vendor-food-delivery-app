import { test, expect } from "@playwright/test";

/**
 * The mark and the red disc sit behind a headline in the same colour family,
 * so any overlap reads as a smudge rather than as layering. This regressed
 * repeatedly, so both decorations are guarded at real viewport widths.
 */
const WIDTHS = [390, 768, 1024, 1280, 1440, 1536, 1600, 1868];

test("hero mark never overlaps the headline", async ({ page }, testInfo) => {
  // Viewport is driven per-width here; the mobile device profile fixes it.
  test.skip(testInfo.project.name !== "desktop-chromium", "runs once, on desktop");

  const failures: string[] = [];

  for (const width of WIDTHS) {
    await page.setViewportSize({ width, height: 900 });
    await page.goto("/");
    await page.waitForLoadState("networkidle");
    await page.waitForTimeout(900); // let the entrance animations settle

    const box = await page.evaluate(() => {
      const h1 = document.querySelector("h1");
      const section = h1?.closest("section");
      if (!h1 || !section) return null;
      const range = document.createRange();
      range.selectNodeContents(h1);
      const rects = [...range.getClientRects()];
      if (!rects.length) return null;

      const visible = (el: Element | null | undefined) => {
        if (!el) return null;
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0 ? r.toJSON() : null;
      };

      return {
        ink: {
          right: Math.max(...rects.map((r) => r.right)),
          top: Math.min(...rects.map((r) => r.top)),
          bottom: Math.max(...rects.map((r) => r.bottom)),
        },
        // Both decorations matter: the disc is what visibly slices the type.
        mark: visible(section.querySelector("svg")),
        disc: visible(section.querySelector(".rounded-full")),
      };
    });

    if (!box) {
      failures.push(`${width}px: could not locate the headline`);
      continue;
    }

    for (const [name, shape] of [["mark", box.mark], ["disc", box.disc]] as const) {
      if (!shape) continue; // hidden at this width, nothing to clear
      const overlapsX = shape.left < box.ink.right;
      const overlapsY = shape.top < box.ink.bottom && shape.bottom > box.ink.top;
      if (overlapsX && overlapsY) {
        failures.push(
          `${width}px: ${name} x ${Math.round(shape.left)}–${Math.round(shape.right)} y ${Math.round(shape.top)}–${Math.round(shape.bottom)} | headline ink x→${Math.round(box.ink.right)} y ${Math.round(box.ink.top)}–${Math.round(box.ink.bottom)}`
        );
      }
    }
  }

  expect(failures.join("\n")).toBe("");
});
