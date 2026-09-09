---
type: "query"
date: "2026-08-06T20:46:13.389505+00:00"
question: "accha tahole tumi full web app ta complete korar jonno ekta plan create kore then kaj shuru kore daooo\nkheyal rekho 90% user kintu mobile the visit korbe so mobile friendly howa kintu mandatory\n\nsuper responsive smooth vabe kaj koro"
contributor: "graphify"
source_nodes: ["docs/web app design system/premium-food-delivery-design-system-prompt.md", "apps/customer_app/lib/core/utils/responsive/app_responsive.dart", "customer-web/app/checkout/page.tsx"]
---

# Q: accha tahole tumi full web app ta complete korar jonno ekta plan create kore then kaj shuru kore daooo
kheyal rekho 90% user kintu mobile the visit korbe so mobile friendly howa kintu mandatory

super responsive smooth vabe kaj koro

## Answer

Expanded from original query via vocab: [customer, web, mobile, checkout, delivery, order, auth, payment, coupon, restaurant, realtime, responsive]. Implemented the first production P0 batch: removed silent storefront mock fallbacks; aligned checkout estimate with backend tax, packaging, minimum-order and delivery quote rules; invalidated coupons when the cart changes; added a thumb-reachable mobile checkout bar; restored PICKED_UP tracking, internal-rider delivery OTP, external-courier confirmation gating and realtime room leave/filtering; corrected logout refresh-token revocation and same-origin auth redirects; added CSP and security headers, environment documentation, ESLint and Vitest coverage; upgraded dependencies until npm audit reported zero vulnerabilities. Verified 390px mobile viewport with no horizontal overflow or console errors. Web lint, 3 tests and production build passed; backend build and 215 tests passed. Real provider-backed menu-to-order OTP E2E remains pending a live backend and production configuration.

## Source Nodes

- docs/web app design system/premium-food-delivery-design-system-prompt.md
- apps/customer_app/lib/core/utils/responsive/app_responsive.dart
- customer-web/app/checkout/page.tsx