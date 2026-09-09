# Testing Guide — Food Delivery Platform

> **Audience:** engineering reviewer / QA (may be executed by an AI agent such as Antigravity).
> **Purpose:** verify the platform's launch-critical logic before go-live. Every critical
> flow below has automated tests; this guide shows how to run them, what they assert, what
> the expected result is, and which items still require live credentials or a database.
>
> **How to read pass/fail:** each step lists an exact command, the working directory, and
> the **Expected result**. A step passes only if the actual output matches. If any step
> fails, stop and report the failing command + its full output.

---

## 0. What this platform is

A single-restaurant food-delivery system: a **NestJS + Prisma + PostgreSQL** backend, four
**Flutter** apps (customer, rider, kitchen, admin), and a Next.js merchant dashboard.
Real-time is Socket.IO; dispatch runs on BullMQ. This guide covers the backend + the three
mobile apps that carry launch-critical logic.

---

## 1. Environment prerequisites

| Tool | Version | Check command |
|------|---------|---------------|
| Node.js | 22.x | `node --version` |
| npm | 10.x+ | `npm --version` |
| Flutter | 3.41.x (stable) | `flutter --version` |
| PostgreSQL | 16 | only needed for the **integration/e2e** and **migration** steps (§4) |
| Redis | 7 | only needed for full runtime/throttle checks (§5) |

The **unit test suites in §3 need NO database, Redis, or credentials** — they run fully
offline with mocked dependencies. That is intentional: the risky business logic is proven
without any live infrastructure.

Repository root referenced below as `<repo>` = the `Food_delivery` directory.

---

## 2. One-time setup

```bash
# Backend
cd <repo>/backend
npm install

# Flutter apps (run once each)
cd <repo>/apps/customer_app && flutter pub get
cd <repo>/apps/rider_app    && flutter pub get
cd <repo>/apps/kitchen_app  && flutter pub get
cd <repo>/apps/admin_app    && flutter pub get
```

**Expected result:** each command completes without error (`npm install` ends with a
package count; `flutter pub get` ends with `Got dependencies!` or `Changed N dependencies!`).

---

## 3. Automated tests (no credentials required) — RUN THESE FIRST

### 3.1 Backend unit + service tests

```bash
cd <repo>/backend
npx jest
```

**Expected result:**
```
Test Suites: 16 passed, 16 total
Tests:       210 passed, 210 total
```

### 3.2 Backend type safety

```bash
cd <repo>/backend
npx tsc --noEmit
```

**Expected result:** command exits with code `0` and prints nothing (no type errors).

### 3.3 Flutter app tests

```bash
cd <repo>/apps/customer_app && flutter test     # Expected: All tests passed! (55 tests)
cd <repo>/apps/rider_app    && flutter test     # Expected: All tests passed! (15 tests)
cd <repo>/apps/kitchen_app  && flutter analyze   # Expected: No issues found!  (analyze-only)
cd <repo>/apps/admin_app    && flutter analyze   # Expected: No issues found!
```

> Kitchen and admin apps currently have no unit tests; `flutter analyze` is the gate for
> them (static analysis must be clean).

---

## 4. Critical-flow coverage map (what the automated tests prove)

Each launch-critical flow maps to specific test files. A reviewer can open any spec to see
the exact assertions. All of these run inside §3 above.

| # | Critical flow | Test file(s) | Key guarantees asserted |
|---|---------------|--------------|--------------------------|
| 1 | **Money — refunds** | `backend/src/modules/payments/refunds.service.spec.ts` | Prepaid order rejected/cancelled → **exactly one** refund request; COD → **no** refund; not-yet-paid → no refund; **idempotent** (no double-refund) |
| 1 | **Money — COD settlement** | `backend/src/modules/earnings/cod-settlement.service.spec.ts` | Cash recorded once (collected = grand total, rider keeps delivery fee); no double-count; settlement blocked until DELIVERED; food remittance capped (can't over-credit restaurant) |
| 1 | **Money — rider ledger** | `backend/src/modules/earnings/rider-ledger.service.spec.ts` | Online order credits the rider; COD does **not** (rider already kept cash) → no double-pay |
| 2 | **Order lifecycle** | `backend/src/modules/orders/order-status.service.spec.ts` | **Every** from→to transition (135 cases): valid ones succeed + write an audit row; invalid ones rejected; same-status is an idempotent no-op; terminal states are final |
| 3 | **Dispatch** | `backend/src/modules/dispatch/dispatch.service.spec.ts`, `six-rider-scenario.manual-test.spec.ts` | One offer at a time (never broadcast); proximity + load scoring; rejection cooldown; at-capacity riders excluded; exhaustion alert fires |
| 4 | **Access control (RBAC)** | `backend/src/common/guards/roles.guard.spec.ts` | Customer token **blocked** from admin route; rider blocked from staff route; unauthenticated rejected; open routes stay open |
| 4 | **Auth — token & OTP** | `backend/src/modules/auth/auth.service.spec.ts` | Refresh token **rotated** (old one revoked → no replay); bad signature / revoked / inactive user rejected; OTP is **single-use** and expiry-guarded |
| 5 | **Real-time reconnection** | `apps/rider_app/test/core/websockets/socket_reconnect_test.dart` | Backoff cadence 3s → 6s → 15s (never runs away, never speeds up); reconnect suppressed after logout / while backgrounded |
| 6 | **App config safety** | `apps/customer_app` + `apps/admin_app` analyze | admin_app now reads API URL from build-time define (no hardcoded localhost in release); customer critical-screen tests green (checkout, cart, orders) |

---

## 5. Manual / smoke tests (require a running stack and/or credentials)

These cannot be covered by offline unit tests. Do them in a staging environment before
go-live. Each needs the backend running (`cd backend && npm run start:dev`) plus a
PostgreSQL and Redis instance.

### 5.1 Health checks (needs backend + DB running)
1. `GET /health/live` → **200** (process up).
2. `GET /health/ready` → **200** when DB + Redis reachable.
3. Stop PostgreSQL, then `GET /health/ready` → **503** (must fail closed). Restart DB.

### 5.2 Database migration integrity (needs a Postgres)
```bash
cd <repo>/backend
npx prisma migrate status
```
**Expected:** "Database schema is up to date."
> ⚠️ **Known gap:** the `Message` and `RiderOrderRejection` tables exist in the schema but
> have no migration file yet (applied via `db push`). A formal migration must be generated
> against a dev/shadow DB before deploying to a fresh production database. See §7.

### 5.3 Order → money end-to-end (needs DB; ideally seeded)
1. Place an order with a coupon → verify grand total = subtotal − discount + tax + packaging + delivery fee.
2. Move it through ACCEPTED → PREPARING → READY_FOR_PICKUP → PICKED_UP → ON_THE_WAY → DELIVERED.
3. For a COD order, confirm a `CodSettlement` row is created and the rider ledger reflects the fee correctly.

### 5.4 Auto-refund on rejection (the bug fixed in this cycle)
1. Create an **online-paid** order (payment status PAID).
2. Reject it (restaurant) **or** cancel it. → A refund **request** must be auto-created for the full amount.
3. Repeat the reject/cancel. → Still only **one** refund request (idempotent).
4. Do the same with a **COD** order. → **No** refund request is created.

### 5.5 bKash payment (needs bKash sandbox/prod credentials)
Configure `BKASH_*` env + a reachable `BKASH_CALLBACK_URL`, then run one payment through
`initiate → checkout → execute`; confirm the order flips to PAID.

### 5.6 SMS OTP (needs rtcom.xyz credentials)
Set `RTCOM_ACODE` / `RTCOM_API_KEY` / `RTCOM_SENDER_ID`; request an OTP to a real number and confirm receipt.

### 5.7 Push notifications (needs Firebase service account)
Configure `FCM_*`; trigger a notification and confirm delivery to customer, rider, and kitchen apps.

### 5.8 Real-time reconnection (needs backend + a device/emulator)
With an order in progress, kill network for ~30s then restore → the app reconnects and the
tracking/assignment stream resumes without a manual refresh.

---

## 6. Test result sign-off sheet

| Area | Method | Status | Notes |
|------|--------|--------|-------|
| Backend unit/service (210 tests) | §3.1 | ☐ | Must be 210/210 green |
| Backend type check | §3.2 | ☐ | Exit 0 |
| Customer app (55 tests) | §3.3 | ☐ | All passed |
| Rider app (15 tests) | §3.3 | ☐ | All passed |
| Kitchen / admin analyze | §3.3 | ☐ | No issues |
| Health checks | §5.1 | ☐ | Needs running stack |
| Migration status | §5.2 | ☐ | See known gap |
| Order→money e2e | §5.3 | ☐ | Needs DB |
| Auto-refund on reject | §5.4 | ☐ | Needs DB |
| bKash payment | §5.5 | ☐ | Needs credentials |
| SMS OTP | §5.6 | ☐ | Needs credentials |
| Push | §5.7 | ☐ | Needs credentials |
| Real-time reconnect | §5.8 | ☐ | Needs device |

---

## 7. Known gaps & deferred items (full disclosure)

These are tracked and intentionally **not** yet done — none block a cash-on-delivery soft
launch, but they should be understood:

1. **Formal migration** for `Message` + `RiderOrderRejection` (needs a shadow DB to generate;
   see §5.2). A fresh prod DB deploy must include this or those tables won't exist.
2. **Order-placement total** is proven at the unit level for its components (rounding,
   settlement, refund) but the full placement math is best verified by an **integration test
   against a seeded DB** (§5.3), not a mock.
3. **Customer-app socket room-rejoin** on reconnect is correct by inspection but not yet unit
   tested (would need a small socket-factory seam). The rider-app reconnection *policy* IS tested.
4. **Customer app production bundle ID** is still `com.demokitchen.*` — set the real ID before store submission.
5. **iOS `GoogleService-Info.plist`** is absent — iOS push is off until it's added.
6. **Scale items** (Redis Socket.IO adapter, metrics/structured logging) are for high volume,
   not a single-server soft launch.

---

## 8. Notes for an AI agent runner (e.g. Antigravity)

- Run **§3 first** — it is deterministic, needs no network/DB/credentials, and is the fastest
  signal. Report the exact test counts against the expected values in §3.1–§3.3.
- Do **NOT** run any `prisma migrate` / `db push` command against a production or shared
  database. Migration steps (§5.2, §7) require an explicitly disposable dev/shadow database.
- Treat §5 as environment-dependent: if no backend/DB/credentials are available, mark those
  rows "blocked (no environment)" rather than failed.
- When reporting, produce the §6 sign-off sheet filled in, and paste the raw output of any
  command that did not match its Expected result.
- Working directories matter: backend commands run in `<repo>/backend`; each Flutter command
  runs in that specific app's directory.
