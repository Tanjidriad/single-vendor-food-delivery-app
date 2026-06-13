# Changes Applied — Critical Fixes (COD-First)

**Date:** 2026-05-31
**Scope:** Fix the COD-critical security & money bugs found in the audit. Online payment (bKash) deferred until the API is available.
**Build status:** ✅ `npm run build` passes clean. Entry compiles to `dist/main.js`.

> Companion docs: [AUDIT.md](AUDIT.md) is the findings checklist (✅ fixed / ⏸ deferred / 📋 backlog). This file describes *what changed* and *why*.

---

## New files

| File | Purpose |
|------|---------|
| [src/common/utils/money.util.ts](src/common/utils/money.util.ts) | `round2()` — snaps money math to 2 decimals (whole paisa) so floating-point drift can't accumulate. |
| [src/config/env.validation.ts](src/config/env.validation.ts) | Boot-time env validation. Fails fast on missing/short secrets and on insecure prod config. |
| [AUDIT.md](AUDIT.md) | Full audit findings checklist. |
| [CHANGES.md](CHANGES.md) | This file. |

---

## Fix 1 — Rider can no longer forge delivery; COD paid only at verified delivery
**File:** [src/modules/orders/orders.service.ts](src/modules/orders/orders.service.ts)

**Before:** `updateRiderStatus` allowed a rider to set `DELIVERED` directly (skipping `ON_THE_WAY` + OTP), and auto-marked the payment `PAID` regardless of method.

**After:**
- Riders can only set `PICKED_UP` and `ON_THE_WAY`, and must follow `VALID_TRANSITIONS` (no skipping states).
- `DELIVERED` is reachable **only** through `verifyDeliveryOtp()`, which now owns the transition: sets `DELIVERED` + `deliveredAt`, clears the OTP, writes status history, prints the receipt, and marks payment `PAID` **only when `paymentMethod === COD`**.
- `confirmDeliveryByCustomer()` (third-party courier path) likewise marks `PAID` **only for COD**.
- Online payments always stay `PENDING` — they'll be settled by the gateway later.

**Effect:** A delivery can't be closed as "paid" unless the customer's OTP was entered (cash collected) or the customer confirmed an external-courier delivery.

---

## Fix 2 — Add-on prices resolved server-side
**Files:** [src/modules/orders/orders.service.ts](src/modules/orders/orders.service.ts), [src/modules/orders/dto/place-order.dto.ts](src/modules/orders/dto/place-order.dto.ts)

**Before:** Add-on price came from the client request body; `addonId` was optional and never validated. A client could send `price: 0` and underpay.

**After:**
- DTO: `addonId` is now **required** (`@IsUUID()`). `name`/`price` are optional and ignored if sent.
- `placeOrder` fetches the add-ons from the DB via `MenuItemAddon`, validates each add-on is **linked to that menu item** and **active**, and uses the **DB price/name**. Unknown or unlinked add-ons are rejected with a 400.
- `reorder` updated to re-add add-ons by id only (price/name re-resolved from DB).

**Effect:** Order totals are fully server-computed. The client cannot influence any price.

---

## Fix 3 — Money rounded to 2 decimals
**Files:** [src/modules/orders/orders.service.ts](src/modules/orders/orders.service.ts), [src/common/utils/money.util.ts](src/common/utils/money.util.ts)

`round2()` is applied at every money step: `lineTotal`, `subtotal`, `discountAmount`, `taxAmount`, `packagingFee`, `grandTotal`, and the `Payment.amount` (which uses `grandTotal`).

**Effect:** No more fractional-paisa drift; `Payment.amount` always equals `grandTotal`. DB columns and API responses are unchanged (still numeric, e.g. `125.50`) — no Flutter change needed.

---

## Fix 4 — WebSocket room authorization
**File:** [src/gateways/realtime.gateway.ts](src/gateways/realtime.gateway.ts)

**Before:** Any authenticated client could `order:join` for *any* orderId (streaming another customer's order + rider GPS). `rider:location` only checked the caller was *a* rider, not that they were assigned to the order. Gateway CORS was `*`.

**After:**
- `order:join` loads the order and allows the join only if the caller is its customer, the assigned rider, or staff of that restaurant (`canAccessOrder()`); otherwise returns `{ error: 'forbidden' }`.
- `rider:location` requires an **active assignment** (`ACCEPTED`/`NOTIFIED`) linking the rider to that order before persisting/broadcasting location.
- Gateway CORS now mirrors the configured `CORS_ORIGINS` allowlist.

**Effect:** Customers can only subscribe to their own orders; riders can only publish location for orders they're actually delivering.

---

## Fix 5 — Unsafe online-payment confirm disabled
**Files:** [src/modules/payments/payments.service.ts](src/modules/payments/payments.service.ts), [src/modules/payments/payments.controller.ts](src/modules/payments/payments.controller.ts)

**Before:** `confirmOnline()` marked a payment `PAID` from a client-supplied `transactionId` with no gateway verification and no ownership check — anyone could mark any order paid.

**After:** `confirmOnline()` now throws `501 Not Implemented`. The route is restricted to `CUSTOMER` and kept registered only so the client gets a clear 501 (not a 404). A `TODO(bKash)` block documents exactly what the real implementation must do (server-side verify, ownership, idempotency, status sync, signature check).

**Effect:** The free-order exploit is closed. Online orders simply can't be settled until bKash is wired in.

---

## Fix 6 — Config / secrets / OTP / CORS / Swagger hardening
**Files:** [src/config/configuration.ts](src/config/configuration.ts), [src/config/env.validation.ts](src/config/env.validation.ts), [src/app.module.ts](src/app.module.ts), [src/main.ts](src/main.ts), [src/modules/auth/auth.service.ts](src/modules/auth/auth.service.ts), [src/modules/auth/auth.controller.ts](src/modules/auth/auth.controller.ts), [src/common/utils/otp.util.ts](src/common/utils/otp.util.ts)

- **Env validation** wired into `ConfigModule.forRoot({ validate })`: app refuses to boot if `DATABASE_URL`/`JWT_ACCESS_SECRET`/`JWT_REFRESH_SECRET` are missing or `< 32` chars. In production it also rejects placeholder (`change-me`) secrets and wildcard CORS.
- **`NODE_ENV` now defaults to `production`** (was `development`). The OTP-leak gate, dev endpoints, and Swagger are all driven by this, so an *unset* env var now fails safe.
- **Crypto OTPs:** login OTP uses `crypto.randomInt(100000, 1000000)`; delivery OTP uses `crypto.randomInt(1000, 10000)` (were `Math.random()`).
- **Throttling:** added `@Throttle` to `POST /auth/otp/verify` (5/min) and `POST /auth/refresh` (10/min) — previously unprotected against brute force.
- **Swagger** only mounts when `NODE_ENV !== 'production'`.
- **CORS** refuses wildcard `*` in production (with a defensive check in `main.ts` on top of env validation).
- **Dev startup helpers** (LAN scan, Flutter asset write) only run outside production.

---

## Fix 7 — Coupon atomicity + discount clamp
**File:** [src/modules/orders/orders.service.ts](src/modules/orders/orders.service.ts)

- **Atomic usage limit:** the increment is now a conditional `updateMany` (`where: usedCount < maxUses`) inside the order transaction. If it affects 0 rows, the order rolls back with "Coupon usage limit reached". Two concurrent orders can no longer both pass a stale check.
- **Discount clamp:** `PERCENT` capped at 0–100; `FIXED` floored at 0; final discount capped at `subtotal` so `grandTotal` can never go negative.

---

## Bonus — Production build entry-point fix
**File:** [tsconfig.build.json](tsconfig.build.json)

`prisma/` and `scripts/` were being compiled with `src/`, which nested the entry at `dist/src/main.js` while `start:prod` runs `node dist/main` — production start would have crashed. Excluded them from the build; entry now correctly emits to `dist/main.js`.

---

## Files changed (summary)

```
NEW  src/common/utils/money.util.ts
NEW  src/config/env.validation.ts
NEW  AUDIT.md
NEW  CHANGES.md
EDIT src/modules/orders/orders.service.ts        (Fixes 1, 2, 3, 7)
EDIT src/modules/orders/dto/place-order.dto.ts   (Fix 2)
EDIT src/gateways/realtime.gateway.ts            (Fix 4)
EDIT src/modules/payments/payments.service.ts    (Fix 5)
EDIT src/modules/payments/payments.controller.ts (Fix 5)
EDIT src/config/configuration.ts                 (Fix 6)
EDIT src/app.module.ts                           (Fix 6)
EDIT src/main.ts                                 (Fix 6)
EDIT src/modules/auth/auth.service.ts            (Fix 6)
EDIT src/modules/auth/auth.controller.ts         (Fix 6)
EDIT src/common/utils/otp.util.ts                (Fix 6)
EDIT tsconfig.build.json                         (build entry fix)
```

---

## Action required from you (not code)

1. **Rotate exposed API keys.** The committed `.env` contained live-looking Cloudinary / Mapbox / Google Maps keys. Treat them as compromised and rotate.
2. **Production env vars.** `NODE_ENV=production` and an explicit `CORS_ORIGINS` (no `*`) are now **required** — the app won't boot otherwise. Your local `.env` already has `NODE_ENV=development`, so dev is unaffected.

---

## What's still open

### ⏸ Deferred — do when bKash API is available
- Real online-payment flow: server-side verification, ownership check, idempotency on transactionId, `Payment.status` + `Order.paymentStatus` sync, webhook signature verification. (Disabled stub is in place.)

### 📋 Backlog — not blocking COD launch, but real
| # | Issue | Where |
|---|-------|-------|
| H3 | Admin endpoints not scoped to caller's restaurant; a manager can read all tenants' PII and suspend any account | [admin.controller.ts](src/modules/admin/admin.controller.ts) |
| H4 | Dispatch accept-vs-expire race can double-assign an order | [dispatch.service.ts](src/modules/dispatch/dispatch.service.ts) |
| M1 | Delivery OTP stored in plaintext in notification payloads/logs | [orders.service.ts](src/modules/orders/orders.service.ts) |
| M2 | Fire-and-forget notifications lack `.catch` (unhandled rejection risk) | [orders.service.ts](src/modules/orders/orders.service.ts) |
| M3 | Public review listing leaks full customer profile PII | [reviews.service.ts](src/modules/reviews/reviews.service.ts) |
| M4 | No structured logging / request IDs / error tracking | app-wide |
| M5 | No helmet, compression, body-size/timeout limits, DB pool config | [main.ts](src/main.ts) |
| M7 | Coupon `usedCount` not refunded on cancel | [orders.service.ts](src/modules/orders/orders.service.ts) |
| — | No Dockerfile, no CI, no baseline Prisma migration, zero tests | repo |
| — | Per-user coupon limit (needs a `CouponRedemption` table) | schema |
| — | Account enumeration + login timing side-channel | [auth.service.ts](src/modules/auth/auth.service.ts) |

See [AUDIT.md](AUDIT.md) for the full detail on each.
