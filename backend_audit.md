# Backend Audit — Single Restaurant Food Delivery System

> **Stack:** NestJS • Prisma • PostgreSQL • Socket.IO • FCM  
> **Date:** 2026-05-21  
> **Scope:** Full codebase review — architecture, security, correctness, schema, performance

---

## Overall Verdict

**The backend is well-structured and production-capable.** Module separation is clean, auth is solid (JWT + refresh token rotation + OTP), order lifecycle is comprehensive, and the dispatch system handles re-assignment on timeout. That said, I found **3 real bugs**, several **security gaps**, and a handful of **unnecessary complexities** caused by the schema being designed for multi-vendor when this is a single-restaurant app.

---

## 🔴 Bugs — Must Fix

### 1. Coupon validation during order placement skips date/limit checks

**File:** [orders.service.ts](file:///c:/Users/riads/Desktop/Food_delivery/backend/src/modules/orders/orders.service.ts#L110-L125)

When placing an order with a coupon, the code only checks `isActive: true` — it does **not** check:
- `startsAt` / `endsAt` (expired coupons work)
- `maxUses` / `usedCount` (exhausted coupons still apply)
- `minOrderAmount` (small orders get a discount they shouldn't)

Meanwhile, `POST /coupons/validate` checks all of these correctly. So a user can skip the validate step and directly place an order with an expired coupon.

```diff
 // orders.service.ts — placeOrder()
 const coupon = await this.prisma.coupon.findFirst({
   where: {
     restaurantId: dto.restaurantId,
     code: dto.couponCode,
     isActive: true,
+    AND: [
+      { OR: [{ endsAt: null }, { endsAt: { gt: new Date() } }] },
+      { OR: [{ startsAt: null }, { startsAt: { lte: new Date() } }] },
+    ],
   },
 });
 if (!coupon) throw new BadRequestException('Invalid coupon');
+if (coupon.maxUses && coupon.usedCount >= coupon.maxUses) {
+  throw new BadRequestException('Coupon usage limit reached');
+}
+if (coupon.minOrderAmount && subtotal < coupon.minOrderAmount) {
+  throw new BadRequestException(`Minimum order ${coupon.minOrderAmount} required`);
+}
```

### 2. Payment status is always PENDING regardless of method

**File:** [orders.service.ts:L205-L208](file:///c:/Users/riads/Desktop/Food_delivery/backend/src/modules/orders/orders.service.ts#L205-L208)

```ts
status:
  dto.paymentMethod === 'COD'
    ? PaymentStatus.PENDING    // ← same
    : PaymentStatus.PENDING,   // ← same
```

This ternary does nothing — both branches return `PENDING`. For COD orders this is correct (it should remain PENDING until delivery), but this is clearly a copy-paste artifact that suggests the intent was different for ONLINE payments.

### 3. Rider `assertCanViewOrder` is overly permissive

**File:** [orders.service.ts:L468](file:///c:/Users/riads/Desktop/Food_delivery/backend/src/modules/orders/orders.service.ts#L468)

```ts
if (user.role === UserRole.RIDER) return; // ← any rider can view any order
```

Any rider can see any order in the system, not just their assigned ones. Should check `order.assignment.riderId === user.riderProfileId`.

---

## 🟡 Security Issues

### 4. Restaurant admin endpoints accept unvalidated `Record<string, unknown>`

**File:** [restaurant-admin.service.ts](file:///c:/Users/riads/Desktop/Food_delivery/backend/src/modules/restaurant-admin/restaurant-admin.service.ts)

All admin CRUD methods (`createBanner`, `createCoupon`, `updateSettings`, etc.) accept raw `Record<string, unknown>` and spread it directly into Prisma with `as never` casts:

```ts
createBanner(restaurantId: string, data: Record<string, unknown>) {
  return this.prisma.banner.create({
    data: { restaurantId, ...data } as never,  // ← bypasses type safety
  });
}
```

> [!WARNING]
> This allows any authenticated admin to inject arbitrary fields, including overriding `restaurantId`, `id`, or `createdAt`. Create proper DTOs with `class-validator` decorators for each admin operation.

### 5. OTP code logged in plaintext (dev mode)

**File:** [auth.service.ts:L251-L253](file:///c:/Users/riads/Desktop/Food_delivery/backend/src/modules/auth/auth.service.ts#L251-L253)

```ts
this.logger.log(`[OTP ${dto.purpose}] ${dto.phone ?? dto.email} => ${code}`);
```

The raw OTP is logged to stdout in **all environments**, not just dev. The `devCode` response field is correctly gated behind `nodeEnv === 'development'`, but the logger line runs unconditionally.

### 6. Throttler limit is very generous (200 req/min)

**File:** [app.module.ts:L38](file:///c:/Users/riads/Desktop/Food_delivery/backend/src/app.module.ts#L38)

```ts
ThrottlerModule.forRoot([{ ttl: 60000, limit: 200 }]),
```

200 requests per minute per IP is essentially no rate limiting for auth endpoints. Consider adding tighter per-route throttling on `POST /auth/login` and `POST /auth/otp/send` (e.g., 5/minute).

### 7. `@Public()` decorator overrides JWT globally

Correctly implemented, but worth flagging: any route marked `@Public()` skips JWT **and** role checks entirely. The menu, restaurant info, banners, and coupons endpoints are all public — which is correct. But the delivery-fee quote (`POST /delivery-fee/quote`) should probably require authentication to prevent abuse.

---

## 🟠 Schema Redundancies (Single-Vendor Simplification)

Since this is a **single restaurant** app, several schema entities add complexity without value:

| Entity | Issue | Recommendation |
|--------|-------|----------------|
| `Restaurant` | Every query requires `restaurantId` as a parameter, but there's only one restaurant | Consider hardcoding the restaurant ID as a config constant. Eliminates the need to pass it on every API call. |
| `Branch` | Schema supports branches, but no branch-aware logic exists | Remove unless you plan multi-branch expansion |
| `DeliveryZone` | Polygon-based zone checks add complexity | For a single restaurant, a simple max-radius check suffices |
| `StaffProfile` | Has `restaurantId` — redundant in single-vendor | Could be simplified to just user role + profile |

> [!NOTE]
> I'm **not** recommending you delete these tables — the schema is well-designed for future multi-vendor expansion. But if you're certain this stays single-vendor, simplifying would reduce bugs caused by mismatched `restaurantId` values.

---

## 🔵 Architecture — What's Working Well

| Area | Assessment |
|------|-----------|
| **Auth** | ✅ Excellent — bcrypt(12), JWT access+refresh rotation, SHA-256 hashed refresh tokens, OTP with expiry and single-use |
| **Order lifecycle** | ✅ State machine with `VALID_TRANSITIONS`, status history, timestamps per transition |
| **Dispatch** | ✅ Solid — timeout-based auto-reassignment via `setTimeout`, notifies riders via both WebSocket and FCM |
| **Exception filter** | ✅ Good — catches all errors, logs 5xx with stack traces, consistent response shape |
| **Validation** | ✅ `whitelist + forbidNonWhitelisted + transform` — rejects unknown properties |
| **Real-time** | ✅ Room-based Socket.IO with semantic events (`order:status.changed`, `assignment:created`) |
| **Delivery fee** | ✅ Configurable (base + per-km + peak-hour surcharge + free-delivery threshold + zone checks) |

---

## 🟡 Performance Considerations

### 8. Missing database indexes for common queries

The schema has good indexes on `Order` and `Category`, but these high-frequency queries lack them:

```
# Customer order history — filters by customerId + sorts by createdAt
# But the compound index is (restaurantId, status, createdAt)
# Missing: @@index([customerId, status])

# Coupon lookup during order placement
# Missing: @@index([restaurantId, code, isActive])
```

### 9. `setTimeout` for dispatch expiry is not crash-safe

**File:** [dispatch.service.ts:L215-L218](file:///c:/Users/riads/Desktop/Food_delivery/backend/src/modules/dispatch/dispatch.service.ts#L215-L218)

```ts
private scheduleExpiry(assignmentId: string, delayMs: number) {
  setTimeout(() => {
    void this.expireIfStillPending(assignmentId);
  }, delayMs);
}
```

If the server restarts, all pending `setTimeout` timers are lost. Assignments will never expire until the next manual intervention. For production, consider:
- A periodic cron job (e.g., every 30s) that queries `WHERE status = 'NOTIFIED' AND expiresAt < NOW()`
- Or a database-backed queue like BullMQ

### 10. N+1 queries in notification sending

**File:** [notifications.service.ts:L46](file:///c:/Users/riads/Desktop/Food_delivery/backend/src/modules/notifications/notifications.service.ts#L46)

FCM tokens are iterated one by one with individual `send()` calls and individual `notificationLog.create()` calls. For users with multiple devices this creates N+1 queries. Use `sendMulticast()` for FCM and `createMany()` for logs.

---

## 🔵 Minor Improvements

### 11. Refresh token expiry is hardcoded to 7 days

**File:** [auth.service.ts:L191-L192](file:///c:/Users/riads/Desktop/Food_delivery/backend/src/modules/auth/auth.service.ts#L191-L192)

```ts
const expiresAt = new Date();
expiresAt.setDate(expiresAt.getDate() + 7); // ← always 7 days
```

But `refreshExpiresIn` is configurable via env vars. The stored `expiresAt` should be derived from the config value, not hardcoded.

### 12. `listForUser` returns empty array silently for ADMIN role

**File:** [orders.service.ts:L280](file:///c:/Users/riads/Desktop/Food_delivery/backend/src/modules/orders/orders.service.ts#L280)

```ts
return []; // fallthrough for unhandled roles
```

If an ADMIN user tries to list orders, they silently get an empty list instead of a `ForbiddenException`. This should either handle ADMIN explicitly or throw.

### 13. Delivery OTP is sent via push but not SMS

The `generateDeliveryOtp` creates a 4-digit code, but it's only delivered via push notification. If the customer has notifications disabled, they can't receive the OTP to confirm delivery. Consider also sending it via SMS (same flow as auth OTP).

---

## Priority Summary

| # | Severity | Issue | Effort |
|---|----------|-------|--------|
| 1 | 🔴 Bug | Coupon validation bypassed during order placement | 30 min |
| 2 | 🔴 Bug | Payment status ternary is a no-op | 5 min |
| 3 | 🔴 Bug | Any rider can view any order | 10 min |
| 4 | 🟡 Security | Admin endpoints accept raw objects | 2-3 hours |
| 5 | 🟡 Security | OTP logged in plaintext | 5 min |
| 6 | 🟡 Security | Throttler too permissive | 30 min |
| 7 | 🟡 Info | `@Public()` on delivery-fee quote | 5 min |
| 8 | 🟡 Perf | Missing DB indexes | 15 min |
| 9 | 🟡 Reliability | setTimeout dispatch expiry not crash-safe | 1-2 hours |
| 10 | 🔵 Perf | N+1 in notification sending | 30 min |
| 11 | 🔵 Minor | Refresh token expiry hardcoded | 10 min |
| 12 | 🔵 Minor | ADMIN role returns empty orders | 5 min |
| 13 | 🔵 Minor | Delivery OTP only via push | 1 hour |

> [!TIP]
> Issues 1-3 are the critical ones — they're real bugs that affect correctness today. I can fix all three right now if you approve. Issues 4-6 should be addressed before any public launch.
