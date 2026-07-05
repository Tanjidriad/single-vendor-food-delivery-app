# Production-Readiness Audit Report

**Date:** 2026-07-05
**Scope:** Full system — NestJS backend, customer/kitchen/rider/admin Flutter apps
**Launch parameters:** COD + bKash live at launch · Customer app on Google Play (Android only) · Rider + kitchen sideloaded internally · No production infrastructure provisioned yet

Every finding below was verified directly in code (file:line cited) or by executing the test suites. Findings from automated exploration that did **not** survive verification are listed in §9 so they don't resurface as folklore.

---

## Verdict

**Conditional GO.** The core order/money engine is genuinely production-grade — better than most systems at this stage. Three things stand between you and launch:

1. **One code blocker:** the automated bKash refund call is broken by construction (§2, F-1).
2. **Two release-packaging blockers:** customer bundle ID / signing keystore, and the missing DB migration (§4, F-8/F-9).
3. **One workstream:** production infrastructure does not exist yet (§7).

Everything else is hardening, not blocking.

---

## 1. Test gates (executed 2026-07-05)

| Gate | Expected (TESTING.md) | Actual | Status |
|---|---|---|---|
| Backend `npx jest` | 210/210, 16 suites | **210 passed / 16 suites** | ✅ PASS |
| Backend `npx tsc --noEmit` | exit 0 | **exit 0** | ✅ PASS |
| Customer `flutter test` | 55 passed | **55 passed** | ✅ PASS |
| Rider `flutter test` | 15 passed | **15 passed** | ✅ PASS |
| Kitchen `flutter analyze` | No issues | **12 info-level issues** | ⚠️ SOFT FAIL |
| Admin `flutter analyze` | No issues | **6 info-level issues** | ⚠️ SOFT FAIL |

The analyze issues are deprecations/lints (e.g. `activeColor` in `menu_availability_drawer.dart:124`), not errors — but the documented gate says "No issues found!", so either fix them or update the gate.

---

## 2. Payments & money integrity — the launch-critical domain

### What's solid (verified)

- **Execute is atomic and idempotent** — `updateMany` WHERE-guard means only the first execute settles; concurrent calls return "Already paid" without double-emitting (`backend/src/modules/payments/payments.service.ts:144-173`).
- **Amount tamper check** — captured amount compared to order grand total ±0.01 (`payments.service.ts:127-137`).
- **Online orders are hidden from the kitchen until PAID**; only COD orders appear immediately.
- **Execute has a query fallback** — if execute fails/times out, the backend queries bKash payment status before giving up (`payments.service.ts:114-117`), so a retried execute after an app crash can still settle.
- **Refund *requests* are idempotent** — at most one PENDING/APPROVED request per order (`refunds.service.ts:70-76`); COD is never refunded; reject/cancel/delivery-failure all route through the same guard.
- **Orphan safety net exists** (subagent claimed it was dead code — wrong): the every-minute SLA cron auto-cancels unaccepted orders and files a refund request for online orders with a transactionId (`backend/src/modules/orders/timer-policy.service.ts:41-81`).
- **COD settlement invariants** proven by spec: cash recorded once, rider keeps delivery fee, settlement blocked until DELIVERED, remittance capped, no double-pay via ledger.

### Findings

**F-1 · BLOCKER · Automated bKash refunds are broken by construction**
`bkash.provider.ts:125-153` sends the *same value* as both `paymentID` and `trxID` in the refund call — bKash's refund API requires two distinct values (the checkout paymentID and the transaction ID returned by execute). Worse, the data to fix it is gone: `Payment.transactionId` is the only gateway ID stored (`prisma/schema.prisma:612-625`), and `payments.service.ts:152-158` **overwrites** the initiate-time paymentID with the execute-time trxID. And because `executeRefund` (`refunds.service.ts:120-142`) always attempts the gateway when a transactionId exists and throws on failure, there is **no manual override path for online refunds** — the admin cannot mark a refund executed even after refunding through the bKash portal.
*Fix:* add a `gatewayPaymentId` column to `Payment` (keep both IDs); send `paymentID` + `trxID` correctly in the refund call; allow admin-supplied `manualGatewayRef` to bypass the gateway call. **Verify one real refund in the bKash sandbox before launch.**

**F-2 · MEDIUM · Orphan-refund requests fire for never-captured payments**
`enqueueOrphanPayment` (`refunds.service.ts:182-195`) triggers on `transactionId` presence — but that's set at **initiate**, before the customer pays (`payments.service.ts:53-56`). Every abandoned checkout that times out past the acceptance SLA generates a refund request for money that was never captured. With bKash tokenized checkout, funds only move at execute, so this is noise + admin confusion, not money loss — but an admin "executing" one of these will hit a gateway failure.
*Fix:* in `enqueueOrphanPayment`, call `gateway.queryPayment()` first — if the payment actually completed, settle the order instead of refunding; if not, skip the request.

**F-3 · MEDIUM · "Open in browser" breaks payment completion detection**
`bkash_payment_screen.dart:103-111` launches checkout in an external browser, where the app can never observe the callback URL — so execute is never called even if the customer authorizes payment. The SLA cron will cancel the order ~5 min later. No money is captured (execute never ran), but the customer authorized a payment and got a cancelled order.
*Fix:* remove the escape hatch, or on screen re-focus call execute/query for the pending paymentID.

**F-4 · LOW · Failure callbacks also trigger execute**
`_shouldComplete` (`bkash_payment_screen.dart:78-80`) matches the callback prefix only, ignoring the `status=failure|cancel` query param — a failed payment still round-trips execute+query before showing an error. Harmless (backend rejects) but wasteful and produces a misleading "try again" snackbar on a *cancelled* payment.

---

## 3. Order state management & real-time sync

### Verified strong — no findings above LOW

- **State machine:** `VALID_TRANSITIONS` allowlist, terminal states final, transactional update + audit-history row, same-status idempotent no-op (`order-status.service.ts`). The 135-case transition matrix spec passes.
- **Placement idempotency:** `@@unique([customerId, idempotencyKey])` (`schema.prisma:594`) — duplicate submissions return the existing order.
- **Dispatch races:** rider accept is an atomic `updateMany` guarded on `status=NOTIFIED, expiresAt>now` — first writer wins, losers get a clean error (`dispatch.service.ts:404-415`). Expired-offer sweep cron (30s) + on-boot recovery of assignments that expired during downtime.
- **Socket auth & ACL:** JWT verified on handshake, inactive users disconnected (`realtime.gateway.ts:54-111`); `order:join` enforces customer-owns / staff-same-restaurant / rider-assigned via `canAccessOrder` (`realtime.gateway.ts:154-187`); `rider:location` publisher must hold an ACCEPTED assignment. Per-socket rate limiting on both.
- **Kitchen missed-event recovery — better than claimed:** refetch on every socket connect (`kds_provider.dart:385-391`), REST polling every **10s disconnected / 30s connected** (`kds_provider.dart:221-229`), manual reconnect backoff 3/6/15/30s, socket re-init on token refresh, sound alert + optional auto-print on new orders. A kitchen cannot silently miss an order for more than ~10s of restored connectivity.
- **Customer tracking self-heals:** tracking provider polls REST every 20s alongside socket events (`order_tracking_provider.dart:252-255`) and refetches on every event; socket rejoins the order room on reconnect (`socket_service.dart:28-32`) and on app resume.
- **Rider reconnect policy** unit-tested (backoff cadence, suppressed after logout/backgrounding).

**F-5 · MEDIUM · Kitchen status actions fail silently**
`updateOrderStatus` and `rejectOrder` swallow errors — `catch` → `debugPrint` only (`kds_provider.dart:656-683`). If accept/reject fails on flaky Wi-Fi, staff get no feedback; the card simply doesn't move. Confusing during a rush.
*Fix:* rethrow and surface a snackbar/toast in the calling widget (the pattern already exists for print failures).

**F-6 · LOW · Dispatch offer race window** — a rider flipping online between the candidate query and assignment creation could receive an offer while taking another; accept-side atomicity still prevents double-assignment. Acceptable at single-restaurant scale.

---

## 4. Release packaging & store compliance (Android launch)

**F-7 · BLOCKER (for Play submission) · Bundle ID + signing**
`applicationId = "com.demokitchen.fooddelivery.customer_app"` (`apps/customer_app/android/app/build.gradle.kts:44`) and release builds **fall back to debug signing** when `keystore.properties` is absent (`build.gradle.kts:56-59`). You cannot upload either to Play. Set the real application ID, generate and back up an upload keystore, and update `google-services.json` for the new package name.

**F-8 · BLOCKER (for fresh prod DB) · Missing migration**
`Message` + `RiderOrderRejection` exist in the schema but have no migration file (applied via `db push` — TESTING.md §5.2). The Dockerfile runs migrations at startup; a fresh production database will be missing these tables. Generate the migration against a disposable shadow DB before first deploy.

**F-9 · MEDIUM (Play Console requirement) · No hosted privacy policy**
The privacy policy is a hardcoded in-app text sheet (`register_screen.dart:199-205`). Google Play requires a **hosted URL** in the Console listing (and the app collects location + payment data, so the Data Safety form must match). Host the policy at a public URL and link it in-app.

Checked and fine: no `.env` committed (only `.env.example`); `google-services.json` in-repo is client config, not secret; tokens stored in `FlutterSecureStorage` (`token_storage.dart`); admin app reads API URL from build-time define.

---

## 5. Security

Systematically checked all 30 controllers: every module carries `JwtAuthGuard + RolesGuard` with `@Roles` scoping except intentionally public surfaces (health, public menu, app-config, coupon validate, delivery-fee quote). The `dev/client-config` endpoint returns 404 in production (`dev.controller.ts:22-24`). Spec-proven: refresh-token rotation with replay rejection, single-use expiry-guarded OTP, RBAC deny paths.

Also verified: boot-time env validation is production-strict — rejects wildcard CORS, weak JWT secrets (<32 chars), missing Redis/Sentry/OTP channels (`env.validation.spec.ts` passing); Helmet enabled; CORS allowlist shared between HTTP and Socket.IO; rate limiting 200 req/60s Redis-backed.

**F-10 · LOW · Admin app has no crash reporting** (customer + kitchen: Crashlytics wired to `FlutterError.onError` and `PlatformDispatcher.onError` in `app_bootstrap.dart`; rider: Sentry). Internal tool — acceptable, add Crashlytics when convenient.

---

## 6. Performance & data layer

- **Indexes:** comprehensive on every hot path — `Order @@index([restaurantId, status, createdAt])`, `([customerId, status])`, assignments `([riderId, status])`, refresh tokens `([userId, tokenHash])`, etc. (`schema.prisma`). No missing-index red flags for launch scale.
- **Caching:** none for the public menu; at single-restaurant scale the indexed queries are fine. Redis is present for throttling/BullMQ/cron locks, so adding menu caching later is cheap.
- **Load testing:** not performed — and cannot be until an environment exists (§7). Run a k6/artillery pass against staging covering: menu browse, order placement burst, KDS polling (the 10s KDS poll × tablets is your steady background load), and socket connections.
- **Kitchen polling note:** `GET /orders?limit=100` every 10-30s per kitchen device is the single heaviest recurring query — it's indexed, but keep an eye on it once real traffic exists.

---

## 7. Infrastructure & observability — the from-scratch workstream

Nothing is provisioned. The good news: the backend is genuinely container-ready (multi-stage Dockerfile, non-root user, healthcheck, migrations on start, `/health/live` + `/health/ready` fail-closed, Pino JSON logs, Sentry, BullMQ, Redis-locked crons). Minimum viable production for a soft launch:

1. **One VPS** (4GB+): Docker Compose with backend + Postgres 16 + Redis 7 + Caddy/nginx for TLS. Pin image tags for one-command rollback (`docker compose up -d backend@previous-tag`).
2. **Backups:** nightly `pg_dump` to off-server storage (object storage or even another box) + restore drill once before launch. This is the single most important infra item — everything else is recoverable.
3. **Uptime alerting:** external ping on `/health/ready` (UptimeRobot/Better Stack free tier) + Sentry alert rules (backend DSN required by env validation anyway).
4. **Staging:** same compose file on a second box or a second compose project on the same box with separate DB — enough to mirror production for the §8 manual tests.
5. **Secrets:** production `.env` lives only on the server; document every var from `.env.example`.

**F-11 · LOW · Dockerfile healthcheck uses `/health/live` only** — fine for Compose; switch readiness wiring if you ever move to K8s. **F-12 · LOW · Request-ID middleware exists but isn't propagated into BullMQ jobs**, so queue work can't be traced back to the originating request.

---

## 8. Cannot be verified without environment/credentials

These are **launch-gating manual tests**, currently blocked (exact steps in TESTING.md §5):

| Test | Needs | Priority |
|---|---|---|
| bKash initiate → checkout → execute → PAID, and **one refund** (F-1 fix) | bKash sandbox creds | 🔴 before launch |
| Push delivery to all 3 apps (foreground/background/terminated) | FCM service account | 🔴 before launch |
| SMS OTP to a real number | rtcom.xyz creds | 🔴 before launch |
| Order → money e2e incl. COD settlement row | seeded staging DB | 🔴 before launch |
| Health fail-closed (stop Postgres → `/health/ready` 503) | staging | 🟡 |
| Device reconnect during live order (kill network 30s) | staging + device | 🟡 |

---

## 9. Exploration claims that did NOT survive verification

For the record — these were reported by automated exploration and are **wrong**; don't act on them:

- ~~"No missed-event recovery on socket reconnect"~~ — kitchen refetches on connect + polls at 10/30s; customer tracking polls every 20s.
- ~~"No ACL on `order:join`"~~ — `canAccessOrder` enforces owner/staff/assigned-rider (`realtime.gateway.ts:154-187`).
- ~~"`enqueueOrphanPayment` is dead code"~~ — called by the SLA cron (`timer-policy.service.ts:71`).
- ~~"Customer app has no crash reporting"~~ — Crashlytics is wired (`customer_app/lib/main.dart:28`, `app_bootstrap.dart`).

---

## 10. Go/no-go checklist (ordered)

**Code blockers (do first):**
- [ ] F-1: Fix bKash refund (store both gateway IDs, correct refund payload, manual override path) — then prove one sandbox refund
- [ ] F-8: Generate formal migration for `Message` + `RiderOrderRejection` on a shadow DB
- [ ] F-7: Real application ID + release keystore for customer app (regenerate `google-services.json`)

**Infrastructure (parallel workstream):**
- [ ] Provision VPS: Compose stack, TLS, domain
- [ ] Production `.env` (env validation will enforce completeness), bKash **production** credentials + `BKASH_CALLBACK_URL`
- [ ] Nightly Postgres backups + one restore drill
- [ ] Uptime monitor on `/health/ready` + Sentry alert rules
- [ ] Staging stack, then run all §8 manual tests

**Store submission:**
- [ ] F-9: Host privacy policy at public URL; complete Play Data Safety form (location, payment info)
- [ ] Internal testing track first; staged rollout

**Pre-launch hardening (should-do, not blocking):**
- [ ] F-2: Query gateway before filing orphan refunds (settle if actually paid)
- [ ] F-3: Remove/repair "Open in browser" bKash fallback
- [ ] F-5: Surface kitchen accept/reject failures to staff
- [ ] Clean the 18 `flutter analyze` infos or update the documented gate

**Post-launch:**
- [ ] F-4, F-10, F-11, F-12 · menu caching · load test against staging · request-ID→job tracing
