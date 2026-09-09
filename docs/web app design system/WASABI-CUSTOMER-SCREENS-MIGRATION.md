# WASABI Customer-Web Full Screen Migration

Date: 2026-08-14

Status: Implemented and validated locally.

## Outcome

The approved WASABI Tokyo street-counter identity now extends beyond `/menu` to the complete customer-web route set. The migration replaces the remaining generic serif, rounded-card, soft-shadow and interchangeable dashboard patterns with one mobile-first visual system while retaining the existing API, authentication, cart, checkout, payment, order tracking, support and account behaviour.

## Shared System

- Added the scoped `wasabi-app-shell` for rice-paper, ink, WASABI red and bamboo-tan surfaces.
- Standardised non-menu display typography on Archivo Black through the existing `font-street` treatment.
- Added a reusable counter-style page kicker and hard-edged bento/receipt surface rules.
- Rebuilt the shared navigation as a black counter rail with a WASABI torii block, active route marker, notifications, basket count and account access.
- Rebuilt the shared footer as a `STEAM. SAUCE. REPEAT.` counter board with real restaurant hours/contact data.
- Rebuilt shared buttons and inputs with hard edges, clearer utility type and consistent focus states.
- Rebuilt the mobile navigation as a black/red tab dock and added global horizontal overflow protection.

## Migrated Screens

| Screen | WASABI treatment |
| --- | --- |
| Home | `HOT. FOLDED. FAST.` red-sun torii hero, flat feature rail, kitchen picks, story board, order route and counter CTA |
| Menu | Existing premium menu implementation retained |
| Offers | Perforated counter tickets with copyable live coupon codes |
| Favorites | Saved-dish order board and flat item rows |
| Notifications | `Kitchen signals` inbox and hard-edged status rows |
| Account | Customer-name masthead, profile slip and delivery-stop board |
| Orders | Kitchen-to-door history board with active and past receipts |
| Order detail | Large live status, receipt-style items, counter total, delivery code and existing realtime/rider actions |
| Checkout | Black counter header, receipt panels, structured section rules and existing sticky mobile order action |
| Login / registration | Existing functional split flow brought under the shared typography, forms and surface language |
| Forgot password | Flat recovery slip with the real reset flow unchanged |
| Payment callback | Counter receipt state for checking, success and failure |
| Support | `We'll sort the order` report board and redesigned problem sheet |
| Privacy / terms | Structured customer-information slips |
| Loading / error / not found | Branded system states instead of generic centered cards |

## Data and Behaviour Guardrails

- Restaurant hours, phone, email and address remain sourced from the restaurant API.
- Offers remain sourced from the public coupons API.
- Auth tokens remain in the existing HttpOnly cookie flow.
- Saved addresses, profile editing, favourites, notifications and complaints retain their existing query and mutation paths.
- Cart pricing, delivery quoting, order placement, bKash initiation/callback and order realtime tracking were not replaced with visual mocks.
- The Mapbox-to-Google provider migration remains outside this visual migration and still waits for production credentials.

## Verification Record

| Check | Result |
| --- | --- |
| ESLint | Passed |
| Vitest | 4/4 passed |
| Next.js production build | Passed |
| TypeScript | Passed |
| Generated routes | 20 |
| Playwright full suite | 12/12 passed |
| Viewports | Pixel 5 mobile and desktop Chromium |
| Cross-screen journey | Home, offers, privacy, login, account, favorites, notifications, support, orders, order detail, menu and checkout |
| Critical flows retained | Security headers, password login/cookie rotation, password reset, online checkout/payment callback and premium menu cart flow |
| Mobile horizontal overflow | No overflow in the tested checkout journey |

## Visual Evidence

- [Home mobile](./mockups/wasabi-home-implemented-mobile-chromium.png)
- [Home desktop](./mockups/wasabi-home-implemented-desktop-chromium.png)
- [Account mobile](./mockups/wasabi-account-implemented-mobile-chromium.png)
- [Account desktop](./mockups/wasabi-account-implemented-desktop-chromium.png)
- [Menu mobile](./mockups/wasabi-menu-implemented-mobile-chromium.png)
- [Menu desktop](./mockups/wasabi-menu-implemented-desktop-chromium.png)

## Main Implementation Areas

- `customer-web/app/globals.css`
- `customer-web/components/landing/*`
- `customer-web/components/mobile-bottom-nav.tsx`
- `customer-web/components/ui/button.tsx`
- `customer-web/components/ui/input.tsx`
- `customer-web/app/page.tsx`
- `customer-web/app/offers/page.tsx`
- `customer-web/app/favorites/page.tsx`
- `customer-web/app/notifications/page.tsx`
- `customer-web/app/account/page.tsx`
- `customer-web/app/orders/page.tsx`
- `customer-web/app/orders/[id]/page.tsx`
- `customer-web/app/checkout/page.tsx`
- `customer-web/app/(auth)/*`
- `customer-web/app/payment/callback/page.tsx`
- `customer-web/app/support/page.tsx`
- `customer-web/components/support/report-problem-sheet.tsx`
- `customer-web/components/orders/leave-review.tsx`
- `customer-web/components/legal-page.tsx`
- `customer-web/app/loading.tsx`
- `customer-web/app/error.tsx`
- `customer-web/app/not-found.tsx`
- `customer-web/e2e/specs/customer-screens.spec.ts`

## Scope Boundary

This document covers the customer website. Flutter customer, kitchen, rider, admin and backend business architecture were not visually redesigned in this change. No production deployment was performed.
