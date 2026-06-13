# Production Readiness Audit — Food Delivery Backend

**Stack:** NestJS 11 · Prisma 6 · PostgreSQL · socket.io · Flutter client
**Audited:** 2026-05-31
**Launch context:** Cash-on-delivery (COD) first. bKash online payment deferred until the API is available.

**Status legend:** ✅ Fixed this pass · ⏸ Deferred (bKash) · 📋 Backlog (post-launch hardening)

---

## 🔴 CRITICAL

- [x] ✅ **C1 — Rider can forge delivery & auto-mark COD as PAID** — [orders.service.ts:382-447](src/modules/orders/orders.service.ts#L382-L447)
  `updateRiderStatus` validated the *target* status but never the *current* one, so a rider could jump straight to `DELIVERED`, skipping `ON_THE_WAY` + the delivery-OTP step, and the order's COD payment was auto-set to `PAID`.
  **Risk (COD #1 money leak):** an order closed as "paid" with no cash actually collected.
  **Fix:** riders can only set `PICKED_UP`/`ON_THE_WAY` and must follow the state machine; `DELIVERED` happens only through OTP verification, which marks COD `PAID` only on success.

- [x] ✅ **C2 — Add-on prices trusted from the client** — [orders.service.ts:93-95](src/modules/orders/orders.service.ts#L93-L95), [place-order.dto.ts:16-30](src/modules/orders/dto/place-order.dto.ts#L16-L30)
  Item base price read from DB (good), but add-on prices came from the request body and `addonId` was never validated.
  **Risk:** client sends a paid add-on with `price: 0` (passes `@Min(0)`) and underpays.
  **Fix:** `addonId` required; add-on name/price resolved server-side from the `Addon` table; unknown add-ons rejected.

- [x] ✅ **C3 — WebSocket order rooms have no authorization (IDOR)** — [realtime.gateway.ts:79-86](src/gateways/realtime.gateway.ts#L79-L86), [realtime.gateway.ts:88-113](src/gateways/realtime.gateway.ts#L88-L113)
  Any authenticated client could `order:join` for *any* orderId and stream another customer's order status + the rider's live GPS. Rider location writes were also unverified.
  **Risk:** cross-customer data + live location leak; spoofed location writes.
  **Fix:** `order:join` checks the caller owns the order / is the assigned rider / is restaurant staff; `rider:location` requires an active assignment.

- [x] ✅ **C4 — Money stored & summed as `Float`** — [schema.prisma:422-427](prisma/schema.prisma#L422-L427) and related
  Floating-point currency math drifts by fractions of a paisa and desyncs `Payment.amount` from `grandTotal`.
  **Fix (owner-approved):** `round2()` helper applied at every money step ([money.util.ts](src/common/utils/money.util.ts)). Columns stay `Float`, API responses unchanged. Decimal/integer migration left as 📋 backlog.

- [x] ✅ **C5 — Online-payment confirm marks any order PAID without paying** — [payments.service.ts:34-43](src/modules/payments/payments.service.ts#L34-L43), [payments.controller.ts:30-34](src/modules/payments/payments.controller.ts#L30-L34)
  `confirmOnline()` set `PAID` from a client-supplied `transactionId`, no gateway verification, no ownership check.
  **Fix now:** endpoint disabled (returns 501) until bKash. **⏸ At bKash:** see C5-bKash below.

- [x] ✅ **C6 — No env/secret validation; `NODE_ENV` defaults to development; CORS wildcard + credentials** — [configuration.ts:2](src/config/configuration.ts#L2), [main.ts:26-30](src/main.ts#L26-L30), [auth.service.ts:304-320](src/modules/auth/auth.service.ts#L304-L320)
  Missing secrets booted silently; if `NODE_ENV` was unset in prod, OTP codes were returned in API responses + logged; `CORS_ORIGINS=*` with `credentials:true` allowed any site authenticated cross-origin calls.
  **Fix:** boot-time env validation (fails on missing/short secrets); OTP leak gated to explicit `development`; Swagger gated to non-prod; CORS refuses `*`+credentials outside dev.
  **⚠️ Action for you:** rotate the Cloudinary / Mapbox / Google Maps keys that were committed in `.env`.

---

## 🟠 HIGH

- [x] ✅ **H1 — Coupon usage-limit race + negative totals** — [orders.service.ts:117-145](src/modules/orders/orders.service.ts#L117-L145), [orders.service.ts:233-238](src/modules/orders/orders.service.ts#L233-L238)
  Usage limit read outside the transaction and incremented unconditionally → concurrent orders blow past `maxUses`. FIXED coupon > subtotal or PERCENT > 100 → negative `grandTotal`.
  **Fix:** atomic conditional increment inside the transaction; discount clamped (`percent ≤ 100`, `discount ≤ subtotal`).

- [x] ✅ **H2 — OTP not cryptographically secure + no brute-force throttle** — [auth.service.ts:272](src/modules/auth/auth.service.ts#L272), [otp.util.ts:2](src/common/utils/otp.util.ts#L2), [auth.controller.ts:48-65](src/modules/auth/auth.controller.ts#L48-L65)
  Login & delivery OTPs used `Math.random()` (predictable); `/auth/otp/verify` and `/auth/refresh` had no per-route throttle.
  **Fix:** `crypto.randomInt()` for both OTPs; tight `@Throttle` on verify & refresh.

- [ ] 📋 **H3 — Cross-tenant admin access / privilege escalation** — [admin.controller.ts:67-132](src/modules/admin/admin.controller.ts#L67-L132)
  `listUsers`, `userDetail`, rider approval, and audit-logs aren't scoped to the caller's `restaurantId`; a MANAGER can read all tenants' PII and suspend any account incl. OWNER/ADMIN.
  **Fix (backlog):** scope every admin query to `requireRestaurantId(user)`; forbid status changes on equal/higher roles. *Lower urgency for a single-restaurant deployment, but fix before multi-tenant.*

- [ ] 📋 **H4 — Dispatch accept-vs-expire race can double-assign** — [dispatch.service.ts:183-206](src/modules/dispatch/dispatch.service.ts#L183-L206)
  Read-then-update on assignment status with no row lock; a rider accepting at expiry can collide with the sweeper.
  **Fix (backlog):** atomic conditional update on assignment status inside a transaction.

---

## 🟡 MEDIUM

- [ ] 📋 **M1 — Delivery OTP stored in plaintext in notifications/logs** — [orders.service.ts:438-443](src/modules/orders/orders.service.ts#L438-L443), readable via `GET /notifications`. Redact before persisting.
- [ ] 📋 **M2 — Fire-and-forget `void notifications.sendToUser(...)` with no `.catch`** — unhandled rejection can crash the process. Wrap in `.catch(err => logger.error(...))`.
- [ ] 📋 **M3 — Public review listing leaks full customer profile PII** — [reviews.service.ts:29-35](src/modules/reviews/reviews.service.ts#L29-L35). Select display-name only.
- [ ] 📋 **M4 — No structured logging / request IDs / error tracking** — default console Logger. Add `nestjs-pino` + Sentry.
- [ ] 📋 **M5 — No `helmet`, no `compression`, no body-size/timeout limits, no DB pool config.**
- [ ] 📋 **M6 — Dev startup code (LAN scan, asset write) runs unconditionally** — [main.ts:45-63](src/main.ts#L45-L63). Gate behind non-prod.
- [ ] 📋 **M7 — Coupon `usedCount` never refunded on cancel** — cancelled orders permanently consume a coupon use.
- [x] ✅ **M8 — Production build entry-point mismatch** — `tsconfig.build.json` didn't exclude `prisma/`, so the seed scripts were compiled alongside `src/`, nesting the entry at `dist/src/main.js` while `start:prod` runs `node dist/main`. Production start would crash. **Fix:** excluded `prisma`/`scripts` from the build; entry now emits to `dist/main.js`.

---

## ⏸ DEFERRED — implement when bKash API is available

- [ ] ⏸ **C5-bKash — Real online payment** — replace the disabled `confirmOnline` stub ([payments.service.ts](src/modules/payments/payments.service.ts)):
  - Verify payment **server-side** via bKash's query/execute API (never trust a client `transactionId`).
  - Check the caller owns the order before confirming.
  - Idempotency on the transaction ID (a callback may fire twice).
  - Sync both `Payment.status` and `Order.paymentStatus`.
  - Add webhook/callback signature verification.

---

## 📋 BACKLOG — production-ops hardening (not blocking COD launch)

- [ ] **Money → integer paisa or Prisma `Decimal`** (supersedes the `round2` stopgap if scale/precision demands it).
- [ ] **Dockerfile** (multi-stage; `prisma migrate deploy` then `node dist/main`).
- [ ] **CI pipeline** (.github/workflows) running lint + build + tests.
- [ ] **Baseline Prisma migration** — only one migration exists; the base schema was likely `db push`'d, so `migrate deploy` can't rebuild the DB. Generate a baseline.
- [ ] **Test suite** — zero app `*.spec.ts` today. Add unit tests for order totals, coupon logic, and the rider/OTP state machine first.
- [ ] **Per-user coupon limit** — needs a `CouponRedemption` table (userId, couponId, orderId). Schema change.
- [ ] **Readiness/liveness probes** split from the single `/health` check.
- [ ] **Remove committed dev scripts** — `test_geocode.js`, `test_mapbox.js`, `scripts/*.mjs` debug helpers.
- [ ] **Account enumeration / login timing** — register & sendOtp reveal account existence; login skips bcrypt when no user. Use generic messages + a dummy compare.

---

## ✅ Already solid (no action needed)

- Clean modular NestJS structure; DTO validation with `whitelist + forbidNonWhitelisted`; global guards.
- bcrypt cost 12; refresh tokens SHA-256-hashed in DB, rotated on refresh, revoked on logout; JWT re-checks user status each request.
- Order subtotal & item base price computed server-side from the DB.
- Graceful shutdown enabled; exception filter does **not** leak stack traces to clients; health check verifies DB connectivity.
- Socket handshake JWT auth with disconnect-on-missing-token.
- Review ownership + DELIVERED + rating-bounds validation; upload/media endpoints guarded with tenant ownership on delete.
