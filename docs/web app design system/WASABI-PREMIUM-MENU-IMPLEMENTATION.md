# WASABI Premium Customer Menu Implementation

Date: 2026-08-14

Status: Implemented and validated locally.

## Outcome

The approved mobile-first WASABI concept now powers the real customer-web `/menu` route. The implementation removes the generic rounded-card appearance and introduces a distinct Tokyo street-counter visual language while preserving production data and ordering behaviour.

## Customer Experience

- Mobile-first branded header with saved delivery location, account access, and live cart count.
- Restaurant hero with WASABI signature artwork, live open state, preparation estimate, and delivery/pickup state.
- Live promotion ticket sourced from backend banners.
- Sticky ticket-style category navigation with smooth active-state motion.
- Featured and category sections backed by live menu data.
- Search, favourites, add-ons, product customisation, quantity controls, and cart updates remain functional.
- Modal product sheet and persistent cart dock are designed for thumb-reach mobile use.
- Two-column desktop menu layout, with no horizontal overflow on the verified mobile viewport.
- Reduced-motion preferences are respected through the menu motion provider.

## Data and Integration Changes

- Menu API mapping now retains `isFeatured` so the customer website can render the real featured set.
- Restaurant settings expose `defaultPrepMinutes` to the menu UI.
- Seed image URLs that failed live requests were replaced and the WASABI seed was rerun.
- Playwright can target an already-running local environment through `PLAYWRIGHT_BASE_URL`.

## Validation Record

| Check | Result |
| --- | --- |
| ESLint | Passed |
| Unit tests | 4/4 passed |
| Next.js production build | Passed |
| Generated routes | 20 |
| Live Playwright, Pixel 5 | Passed |
| Live Playwright, desktop Chromium | Passed |
| WASABI API menu | 4 categories, 10 items |
| Unexpected page errors / HTTP failures | None in the tested flow |

The live smoke path covered page load, responsive overflow, search, item customisation, add-to-cart, cart-dock visibility, and external menu images. An initially discovered mobile z-index collision and three invalid seed photo URLs were corrected before the final passing run.

## 2026-08-14 Counter Board and Footer Refinement

The first implementation still used a conventional three-column information row and a standard dark navigation footer. Both were replaced after visual review:

- `Good to know / Hours & contact` became a live kitchen notice-board with a prominent open/closed signal, grouped weekly service board, direct contact actions, and delivery/pickup hand-off strip.
- The footer became a branded takeaway-wrapper composition with an oversized `FOLDED TODAY. GONE TONIGHT.` statement, red-sun torii signature, correct Japanese `芥末` label, menu return action, and compact utility navigation.
- The footer is now present on mobile as well as desktop, with safe bottom spacing for the fixed mobile navigation.
- The information remains sourced from the restaurant API; no fictional phone, email, address, or opening time is introduced when data is absent.

## Visual Evidence

- [Approved concept](./mockups/wasabi-mobile-menu-concept-v1.png)
- [Implemented mobile capture](./mockups/wasabi-menu-implemented-mobile-chromium.png)
- [Implemented desktop capture](./mockups/wasabi-menu-implemented-desktop-chromium.png)

## Scope Boundary

This document records the original `/menu` implementation. The visual system was subsequently extended to the remaining customer-web routes; see [WASABI Customer-Web Full Screen Migration](./WASABI-CUSTOMER-SCREENS-MIGRATION.md) for the current full-site scope and validation record.
