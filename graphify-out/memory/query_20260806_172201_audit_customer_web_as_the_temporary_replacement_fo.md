---
type: "query"
date: "2026-08-06T17:22:01.334980+00:00"
question: "Audit customer-web as the temporary replacement for the Flutter customer app after reading the full Food_delivery workspace."
contributor: "graphify"
source_nodes: ["checkout", "cart", "route_paths.dart"]
---

# Q: Audit customer-web as the temporary replacement for the Flutter customer app after reading the full Food_delivery workspace.

## Answer

Expanded from original query via graph vocab: [customer, web, flutter, order, checkout, cart, auth, payment, delivery, restaurant, address, realtime]. The web app has a strong responsive storefront and aligned API abstractions, but is NO-GO for public transactional launch: silent mock fallbacks mask outages, checkout omits backend tax and packaging totals and allows submit after quote failure, delivery tracking omits PICKED_UP and delivery OTP, auth logout does not send the refresh token, production dependencies have four high vulnerabilities, lint is unconfigured, there are zero web tests, customer-web is untracked, production endpoints are not configured, and acquisition SEO/analytics are incomplete. Current verification: web build passed 11 routes, local runtime smoke returned 200 for four routes, backend build passed and 16 suites/215 tests passed; no real-provider or checkout E2E was completed.

## Source Nodes

- checkout
- cart
- route_paths.dart