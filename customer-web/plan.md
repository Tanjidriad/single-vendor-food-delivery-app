# Customer web launch-completion plan

The customer web is the temporary primary customer product, with mobile traffic expected to dominate. Work is ordered by launch risk rather than page count.

## 1. Customer-critical correctness — completed

- Live restaurant, menu, featured dishes, categories, coupons and delivery quotes; no silent mock-store fallback.
- Server-aligned tax, packaging, discount, minimum-order and delivery-fee totals.
- Delivery/pickup checkout, saved/manual location, COD and online payment selection.
- Order history, cancellation, reorder, complaints, reviews, notifications, favorites and live tracking.
- Rider pickup status, internal-rider delivery code and external-delivery confirmation rules.

## 2. Account and browser security — completed

- Same-origin backend-for-frontend proxy.
- Rotating access/refresh sessions in `HttpOnly`, `SameSite=Lax` cookies.
- No JWT persistence in browser JavaScript storage; legacy persisted tokens are migrated away.
- Mutation origin validation, fixed backend destination, safe post-login redirects and logout revocation.
- Phone/email OTP, password login, registration and forgotten-password reset.
- CSP, clickjacking, MIME-sniffing, referrer, permissions and production HSTS headers.

## 3. Online payment — completed in code

- Create online order, initiate bKash, allow only trusted HTTPS bKash checkout hosts.
- Callback contains the order id, executes payment idempotently and displays success/failure/cancel states.
- Pending or failed payment can be retried from the order page.
- Kitchen visibility remains gated by backend `PAID` status.

## 4. Mobile launch shell — completed

- Responsive layouts and sticky mobile checkout action.
- Loading, route error, global error and not-found states.
- Metadata, Open Graph, robots, sitemap, installable manifest and brand icon.
- Privacy policy, terms and footer links.
- Optional Do-Not-Track-aware analytics.
- Standalone Docker build, health endpoint and customer-web CI.

## 5. Verification — automated coverage completed

- Lint, unit tests, production build and dependency audit.
- Backend build and tests including callback integrity.
- Playwright mobile and desktop critical paths through the real web BFF with deterministic backend/gateway mocks.

## 6. External launch operations — requires production access

- Set the final HTTPS site/API/socket origins and restaurant identity.
- Configure backend CORS and `BKASH_CALLBACK_URL` for the final domain.
- Verify one real OTP delivery and one bKash sandbox transaction, including kitchen release after `PAID`.
- Deploy the web container, run production smoke tests, verify monitoring and then switch acquisition traffic.
