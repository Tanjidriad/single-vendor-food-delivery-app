# Plan 1: Backend security & blockers

> Priority: P0 — must be fixed before any deployment
> Estimated effort: 1-2 days

---

## Objective

Fix all deploy-blocking security issues and critical correctness bugs in the backend.

---

## Tasks

### 1.1 Fix `passwordHash` leak in API responses

**Problem:** `include: { user: true }` returns the full User record (including `passwordHash`) to any API caller viewing order details.

**Files to change:**
- `backend/src/modules/dispatch/dispatch.service.ts` — lines 197, 225, 406, 417
- `backend/src/modules/orders/orders.service.ts` — any `include: { user: true }` in findOne/findAll

**Action:** Replace every `include: { user: true }` with a `select` clause:
```typescript
include: {
  rider: {
    include: {
      user: {
        select: {
          id: true,
          name: true,
          phone: true,
          email: true,
          role: true,
          status: true,
          // NEVER include passwordHash
        }
      }
    }
  }
}
```

**Verify:** Call `GET /orders/:id` for an order with a rider assignment and confirm `passwordHash` is absent from the response.

---

### 1.2 Remove `.env` from git and rotate credentials

**Problem:** `.env` with real Pathao credentials (client_id, username, store_id), Cloudinary cloud name is committed to version control.

**Actions:**
1. Add `backend/.env` to `backend/.gitignore`
2. Remove from git tracking: `git rm --cached backend/.env`
3. Rotate all exposed credentials: Pathao client_secret, Cloudinary API key/secret, any JWT secrets that were in the file
4. Verify `.env.example` has only placeholder values

---

### 1.3 Add timeouts to ALL external `fetch()` calls

**Problem:** 14 `fetch()` calls across 4 files have no timeout. A hung upstream will block the Node.js event loop indefinitely.

**Files to change:**
- `backend/src/modules/delivery-fee/maps.service.ts` — lines 34, 59, 92, 114, 137, 161, 179, 198 (8 calls)
- `backend/src/modules/dispatch/pathao.service.ts` — lines 61, 138 (2 calls)
- `backend/src/modules/payments/gateways/bkash.provider.ts` — lines 179, 228 (2 calls)
- `backend/src/modules/notifications/sms.service.ts` — line 62 (1 call)

**Action:** Add `signal: AbortSignal.timeout(10_000)` to every `fetch()` options object. For payment calls (bKash), use 15s. For geocoding, use 8s.

**Pattern:**
```typescript
const res = await fetch(url, {
  ...existingOptions,
  signal: AbortSignal.timeout(10_000),
});
```

---

### 1.4 Add missing DB index on `RefreshToken.tokenHash`

**Problem:** Refresh token lookups filter on `userId + tokenHash + revokedAt + expiresAt` but `tokenHash` has no index.

**File:** `backend/prisma/schema.prisma`

**Action:** Add composite index:
```prisma
model RefreshToken {
  // ... existing fields
  @@index([userId, tokenHash])
}
```

Run `npx prisma migrate dev --name add-refresh-token-hash-index`.

---

### 1.5 Fix `SendOtpDto.purpose` runtime validation

**Problem:** `purpose` is `@IsString()` — any arbitrary string is accepted and stored in the DB.

**File:** `backend/src/modules/auth/dto/` (the SendOtp DTO)

**Action:**
```typescript
@IsIn(['LOGIN', 'RESET_PASSWORD', 'VERIFY_PHONE'])
purpose: 'LOGIN' | 'RESET_PASSWORD' | 'VERIFY_PHONE';
```

---

### 1.6 Add DTOs for inline request bodies

**Problem:** `accept()` and `reject()` in `OrdersController` use inline `{ body }` with no validation.

**File:** `backend/src/modules/orders/orders.controller.ts`

**Actions:**
- Create `AcceptOrderDto` with `@IsOptional() @IsInt() @Min(1) @Max(120) prepMinutes?: number`
- Create `RejectOrderDto` with `@IsOptional() @IsString() @MaxLength(500) note?: string`
- Add `@MaxLength(128)` to `idempotencyKey` in `PlaceOrderDto`

---

### 1.7 Scope admin user-listing to restaurant

**Problem:** `OWNER`/`MANAGER` can list ALL users platform-wide via `GET /admin/users`.

**Files:**
- `backend/src/modules/restaurant-admin/restaurant-admin.controller.ts`
- `backend/src/modules/restaurant-admin/restaurant-admin.service.ts` (or equivalent admin service)

**Action:** For `OWNER`/`MANAGER` roles, add `WHERE restaurantId = user.restaurantId` filter. Only `ADMIN` role should see all users.

---

### 1.8 Fix health endpoint HTTP status

**Problem:** Returns 200 even when DB is unreachable.

**File:** `backend/src/modules/health/health.controller.ts`

**Action:** Return HTTP 503 when `status === 'degraded'`:
```typescript
if (status === 'degraded') {
  throw new ServiceUnavailableException({ status: 'degraded', database: 'unreachable' });
}
```

---

## Verification checklist

- [ ] `GET /orders/:id` response does NOT contain `passwordHash`
- [ ] `git log --all -- backend/.env` shows removal commit
- [ ] All external fetch calls have timeout (grep for `fetch(` and verify `signal:`)
- [ ] `npx prisma migrate status` shows clean
- [ ] Sending `{ purpose: "INVALID" }` to OTP endpoint returns 400
- [ ] `accept()` with `prepMinutes: -5` returns 400
- [ ] `OWNER` calling `GET /admin/users` only sees their restaurant's users
- [ ] Health endpoint returns 503 when DB is stopped
