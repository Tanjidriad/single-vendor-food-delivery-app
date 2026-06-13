# 🔍 Production Readiness Audit — Food Delivery Platform

> **Date:** 2026-06-11  
> **Scope:** Full-stack audit — Backend (NestJS), Customer App (Flutter), Kitchen App, Rider App, Admin App, Merchant Dashboard (Next.js), Infrastructure  
> **Graph:** 8,633 nodes · 13,000 edges · 525 communities · 1,183 files

---

## Executive Summary

| Dimension | Grade | Verdict |
|-----------|-------|---------|
| **Architecture** | 🟢 A | Excellent — clean module separation, proper domain boundaries |
| **Backend Logic** | 🟢 A- | Solid — previous bugs fixed, order lifecycle is battle-tested |
| **Security** | 🟡 C+ | **Critical gaps** — exposed secrets, missing headers, weak rate limits |
| **UI/UX** | 🟢 B+ | Good design system, proper theming — but needs polish in edge cases |
| **Feature Completeness** | 🟡 B- | Core flows work — but missing several must-haves for production |
| **Testing** | 🔴 D | **Major gap** — 1 test file in customer app, 1 e2e in backend |
| **Infrastructure** | 🟡 C | Docker Compose for DB only — no CI/CD, no deployment config |

### **Bottom line: This is an impressive codebase, but NOT production-ready.** 
The architecture and code quality are ahead of most projects at this stage. But there are ~3 security blockers, ~5 missing features, and near-zero test coverage that must be addressed before any real user touches this.

---

## 🔴 CRITICAL: Security & Vulnerabilities

### 1. API Keys & Secrets Committed to `.env` (in repo)

**Severity:** 🔴 CRITICAL  
**File:** [.env](file:///c:/Users/riads/Desktop/Food_delivery/backend/.env)

While `.env` is in `.gitignore`, the file **exists on disk with real production credentials**:

| Secret | Value Exposed | Risk |
|--------|--------------|------|
| `GOOGLE_MAPS_API_KEY` | `AIzaSyAOVYRI...` | Abuse charges, quota exhaustion |
| `MAPBOX_ACCESS_TOKEN` | `pk.eyJ1Ijoi...` | Map tile abuse, billing |
| `CLOUDINARY_API_SECRET` | `YWXiWacx0y5...` | Arbitrary file upload/deletion |
| `RESEND_API_KEY` | `re_UFsrkPbc...` | Email spoofing, spam |
| `JWT_ACCESS_SECRET` | `dev-access-secret-change-in-production-32chars` | **Token forgery if used in prod** |

> [!CAUTION]
> If this `.env` was EVER committed to git (even once, even if later gitignored), all these keys are compromised. Run `git log --all --follow -- backend/.env` to check. **Rotate every key immediately** if it was ever committed.

**Action:** 
- Rotate ALL keys listed above
- Use a secrets manager (AWS SSM, Vault, or at minimum `.env.local` with deploy-time injection)
- Add `*.env*` pattern validation to CI

---

### 2. No Security Headers (Helmet Missing)

**Severity:** 🔴 HIGH  
**File:** [main.ts](file:///c:/Users/riads/Desktop/Food_delivery/backend/src/main.ts)

The backend has **no HTTP security headers** at all. No `helmet()` middleware means:
- No `X-Content-Type-Options` → MIME sniffing attacks
- No `Strict-Transport-Security` → Downgrade attacks  
- No `X-Frame-Options` → Clickjacking
- No `Content-Security-Policy` → XSS via injected scripts

```diff
+ import helmet from 'helmet';
  
  async function bootstrap() {
    const app = await NestFactory.create(AppModule);
+   app.use(helmet());
```

**Effort:** 10 minutes

---

### 3. Rate Limiting on Auth is Essentially Disabled

**Severity:** 🟡 HIGH  
**File:** [app.module.ts](file:///c:/Users/riads/Desktop/Food_delivery/backend/src/app.module.ts#L46)

```typescript
ThrottlerModule.forRoot([{ ttl: 60000, limit: 200 }]),
```

200 requests/minute globally means an attacker can:
- Brute-force OTPs (6 digits = 1M combinations, 200/min = 83 hours to exhaust)
- Credential stuff login at 200 attempts/minute
- DDoS with low effort

**Fix:** Add per-route throttling:
```typescript
// On auth endpoints specifically:
@Throttle({ default: { ttl: 60000, limit: 5 } })  // 5 login attempts/min
@Throttle({ default: { ttl: 60000, limit: 3 } })  // 3 OTP sends/min
```

**Effort:** 30 minutes

---

### 4. OTP Still Logged in Plaintext in Non-Dev

**Severity:** 🟡 MEDIUM  
**File:** [auth.service.ts:L396-L405](file:///c:/Users/riads/Desktop/Food_delivery/backend/src/modules/auth/auth.service.ts#L396-L405)

The previous audit flagged this. It's now **partially fixed** — the OTP value is hidden in production logs. But in development mode, the raw OTP is still logged to stdout:

```typescript
if (nodeEnv === 'development') {
  this.logger.log(`[OTP ${dto.purpose}] ${dto.phone ?? dto.email} => ${code}`);
}
```

This is acceptable for dev, but make sure `NODE_ENV=development` is **never** set in production.

---

### 5. WebSocket CORS Reads Raw `process.env` at Import Time

**Severity:** 🟡 MEDIUM  
**File:** [realtime.gateway.ts:L31-L33](file:///c:/Users/riads/Desktop/Food_delivery/backend/src/gateways/realtime.gateway.ts#L31-L33)

```typescript
const corsOrigins = (process.env.CORS_ORIGINS ?? '*')
  .split(',')
  .map((o) => o.trim());
```

This reads raw environment at import time, bypassing NestJS ConfigModule validation. If `CORS_ORIGINS` is unset, the WebSocket gateway silently allows all origins even if the HTTP layer would reject them.

---

## 🟡 Previous Audit Bug Fixes — Status

| # | Bug | Status | Notes |
|---|-----|--------|-------|
| 1 | Coupon validation bypass | ✅ **Fixed** | Now checks `maxUses`, `minOrderAmount`, dates, + atomic `updateMany` to prevent race conditions |
| 2 | Payment status no-op ternary | ✅ **Fixed** | Now always creates as `PENDING`, COD marked `PAID` only on delivery OTP verification |
| 3 | Rider can view any order | ✅ **Fixed** | `assertCanViewOrder` now checks `assignment.riderId === user.riderProfileId` |
| 4 | Admin raw `Record<string, unknown>` | ✅ **Fixed** | All admin endpoints now use proper DTOs with class-validator: `CreateBannerDto`, `CreateCouponDto`, `UpdateSettingsDto`, etc. |
| 5 | OTP logged in plaintext | ✅ **Fixed** | Now gated behind `nodeEnv === 'development'` |
| 11 | Refresh token expiry hardcoded | ✅ **Fixed** | Now derives from config with `match(/^(\d+)([smhd])$/)`  |
| 12 | ADMIN gets empty orders | ✅ **Fixed** | Now throws `ForbiddenException('Role not permitted to list orders')` |

> [!TIP]
> All 7 issues from the May 2026 audit have been fixed. Good job. The codebase has clearly been actively maintained.

---

## 🟢 Backend — What's Excellent

| Area | Quality | Details |
|------|---------|---------|
| **Auth** | ⭐⭐⭐⭐⭐ | bcrypt(12), JWT access+refresh with rotation, SHA-256 hashed refresh tokens, OTP with hashed codes + single-use + expiry, env validation blocks weak secrets in prod |
| **Order Lifecycle** | ⭐⭐⭐⭐⭐ | Full state machine with `VALID_TRANSITIONS`, complete status history, atomic coupon updates with race-condition prevention, idempotency keys |
| **Dispatch** | ⭐⭐⭐⭐ | Auto-assignment, timeout expiry, re-assignment on reject, external courier support (Pathao/RedX), delivery OTP verification |
| **Validation** | ⭐⭐⭐⭐⭐ | Global `ValidationPipe` with `whitelist + forbidNonWhitelisted + transform` — rejects unknown fields |
| **Exception Handling** | ⭐⭐⭐⭐ | Global filter catches all errors, consistent response shape, request ID tracking |
| **Real-time** | ⭐⭐⭐⭐ | JWT-authenticated WebSocket with room-based access control, rate-limited events, assignment ownership validation |
| **CORS** | ⭐⭐⭐⭐ | Wildcard blocked in production with fail-fast validation |
| **Env Validation** | ⭐⭐⭐⭐ | Boot-time validation rejects missing/weak secrets, blocks wildcard CORS in prod |

---

## 🟡 UI/UX Assessment

### Customer App (Flutter)

**Architecture: Clean, well-structured**
- 14 features: auth, cart, checkout, favorites, home, menu, notifications, offers, onboarding, orders, profile, restaurant, splash, support
- Proper separation: `data/`, `domain/`, `presentation/` layers per feature
- Dedicated theme system with `AppColors`, `AppTokens`, `AppThemeExtension`, `AppSpacing`
- Accessibility: Has `A11yAnnouncer`, focus ring management

**What Needs Work:**

| Issue | Impact | Effort |
|-------|--------|--------|
| No loading/error states visible in many screens | Users see blank screens on slow connections | 2-3 days |
| Offline mode not implemented | App is unusable without internet | 3-5 days |
| No skeleton/shimmer loading for menu items | Feels unpolished vs production apps | 1 day |
| Cart doesn't persist across app restarts | Users lose their cart on crash/restart | 1 day |
| No deep linking for order tracking shared via notification | Users can't jump to order from push notification | 1-2 days |

### Kitchen App (Flutter)

- Only 2 features: `auth` + `kds` (Kitchen Display System)
- This is minimal but focused — exactly right for a kitchen screen

### Rider App (Flutter)

- 6 features: auth, earnings, onboarding, orders, profile, shift
- Good feature coverage for an MVP rider experience
- Has offline earnings cache (`EarningsCache`)

### Admin App (Flutter)

- 10 features: auth, banners, coupons, customers, dashboard, media, menu, orders, riders, zones
- Comprehensive admin panel

### Merchant Dashboard (Next.js)

- **Single page** app currently — all logic in one `page.tsx` (13KB)
- Uses shadcn/ui components properly
- Has KDS integration, order history, settings

> [!WARNING]
> The merchant dashboard is a single-page app with everything in one file. For production, this needs to be broken into proper routes (`/orders`, `/menu`, `/settings`, `/reports`).

---

## 🔴 Missing Must-Have Features

### Tier 1 — Blockers for Production

| Feature | Why It's a Blocker | Effort |
|---------|-------------------|--------|
| **Online Payment Integration** | Payment controller returns 501 for `confirm` — bKash/SSLCommerz not integrated. COD-only limits addressable market. | 3-5 days |
| **SMS OTP Delivery** | OTPs only sent via email (Resend) and push. No SMS provider connected. Most BD users expect SMS OTP. | 1-2 days |
| **Crash-Safe Dispatch Expiry** | Still uses `setTimeout` — server restart loses all pending assignments. Need a cron job or BullMQ. | 1-2 days |
| **Email/Phone Verification Flow** | Users can register with any email/phone without verifying ownership. | 1 day |
| **Error Monitoring** | No Sentry, no error tracking. Production crashes will be invisible. | 2-3 hours |

### Tier 2 — Expected by Users

| Feature | Why It Matters | Effort |
|---------|---------------|--------|
| **Search Functionality** | Customer app has no menu search — users must scroll through categories | 1 day |
| **Order Tracking Map** | Customer sees status text but no live map with rider position (WebSocket events exist but UI may not consume them fully) | 2-3 days |
| **Multi-Language Support** | BD market expects Bangla support | 2-3 days |
| **Push Notification Setup** | FCM config is empty (`FCM_PROJECT_ID=`, `FCM_CLIENT_EMAIL=`, `FCM_PRIVATE_KEY=`) — push notifications are silently broken | 1 day |
| **Receipt/Invoice Download** | No PDF receipt generation for completed orders | 1-2 days |

### Tier 3 — Nice to Have

| Feature | Status |
|---------|--------|
| Loyalty/rewards points | Not implemented |
| Scheduled/pre-orders | Not implemented |
| Refer-a-friend | Not implemented |
| Multi-restaurant support | Schema supports it but app is single-vendor |
| Rider live-chat with customer | Not implemented |

---

## 🔴 Test Coverage — Critical Gap

| Component | Test Files | Coverage | Verdict |
|-----------|-----------|----------|---------|
| **Backend** | 1 e2e test (scaffold only) | ~0% | 🔴 No unit tests, no integration tests |
| **Customer App** | 1 test file | ~0% | 🔴 Flutter widget tests absent |
| **Kitchen App** | 0 | 0% | 🔴 |
| **Rider App** | 0 | 0% | 🔴 |
| **Admin App** | Some property tests (breakpoints) | <5% | 🟡 Has test helpers/harness framework but minimal tests |
| **Merchant Dashboard** | 0 | 0% | 🔴 |

> [!CAUTION]
> This is the single biggest risk for production. The order placement, coupon logic, dispatch assignment, and delivery OTP verification are complex state machines that need thorough testing. One regression here = money lost.

**Minimum viable test suite needed:**
1. Order placement (with/without coupon, with/without delivery fee)
2. Order status transitions (all valid, all invalid)
3. Auth flow (register, login, refresh, OTP)
4. Dispatch assignment (assign, timeout, re-assign, reject)
5. Delivery OTP verification
6. RBAC — ensure customers can't hit admin endpoints

---

## 🟡 Infrastructure Readiness

| Item | Status | Notes |
|------|--------|-------|
| **Database** | ✅ PostgreSQL 16 via Docker | Healthy, with proper migrations |
| **Backend Dockerfile** | ❌ Missing | No way to containerize the NestJS API |
| **CI/CD Pipeline** | ❌ Missing | No GitHub Actions / GitLab CI |
| **Environment Management** | ❌ Weak | Single `.env` file, no staging/production configs |
| **Monitoring/Logging** | ❌ Missing | No structured logging (Pino), no APM, no health dashboards |
| **Backup Strategy** | ❌ Missing | No pg_dump schedule, no point-in-time recovery |
| **SSL/TLS** | ❌ Not configured | API listens on plain HTTP |
| **CDN** | ✅ Cloudinary | Image uploads handled |
| **WebSocket Scale** | ⚠️ Single-server | Socket.IO with no Redis adapter — won't work with multiple instances |

---

## 📊 Prioritized Action Plan

### Phase 1 — Security (Do Before Any Launch) — ~2 days

| # | Action | Effort | File |
|---|--------|--------|------|
| 1 | Rotate ALL exposed API keys | 1 hour | `.env` |
| 2 | Install `helmet` middleware | 10 min | `main.ts` |
| 3 | Add per-route rate limiting on auth | 30 min | `auth.controller.ts` |
| 4 | Integrate SMS OTP provider (Twilio/Vonage) | 1 day | `auth.service.ts` |
| 5 | Configure FCM credentials | 1 hour | `.env` |

### Phase 2 — Critical Features (Week 1) — ~5 days

| # | Action | Effort |
|---|--------|--------|
| 6 | Integrate bKash/SSLCommerz for online payments | 3-5 days |
| 7 | Replace `setTimeout` dispatch with cron-based expiry | 1 day |
| 8 | Add email/phone verification before first order | 1 day |

### Phase 3 — Testing (Week 2) — ~5 days

| # | Action | Effort |
|---|--------|--------|
| 9 | Backend unit tests for order/dispatch/auth | 3 days |
| 10 | Backend integration/e2e tests | 2 days |
| 11 | Flutter widget tests for critical screens | 2 days |

### Phase 4 — Infrastructure (Week 3) — ~3 days

| # | Action | Effort |
|---|--------|--------|
| 12 | Create Backend Dockerfile + docker-compose for full stack | 1 day |
| 13 | Set up CI/CD (GitHub Actions) | 1 day |
| 14 | Add Sentry error tracking | 2 hours |
| 15 | Add structured logging (Pino) | 4 hours |
| 16 | Socket.IO Redis adapter for horizontal scaling | 4 hours |

### Phase 5 — Polish (Week 4)

| # | Action | Effort |
|---|--------|--------|
| 17 | Menu search in customer app | 1 day |
| 18 | Skeleton/shimmer loading states | 1 day |
| 19 | Cart persistence (local storage) | 1 day |
| 20 | Bangla language support | 2 days |

---

## Final Honest Assessment

**What this project gets RIGHT (and most don't):**
- 🏗️ Architecture is genuinely impressive — clean feature-based structure across 4 Flutter apps + 1 NestJS API + 1 Next.js dashboard
- 🔐 Auth is properly done — not just "JWT in a cookie" but full rotation, hashing, OTP with expiry
- 📊 The Prisma schema is production-grade — proper indexes, enums, audit trails, idempotency
- 🔄 Real-time system with proper access control (rooms, ownership checks, rate limiting)
- 🛡️ Previous audit bugs were ALL fixed properly — shows active maintenance

**What WILL break in production:**
- 🔑 Leaked API keys (if ever committed to git)
- 💰 No online payments (COD only = limited market)
- 📱 No SMS OTP (email-only in a market that expects SMS)
- 🧪 Zero test coverage = first hotfix will break something else
- 🔄 `setTimeout` dispatch = assignments lost on any restart
- 🚨 No error monitoring = you won't know things are broken

> **Estimate to production-ready: 3-4 focused weeks**, following the phase plan above. The foundation is excellent — it's the operational hardening that's missing.
