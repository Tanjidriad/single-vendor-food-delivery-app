# Plan 2: Backend reliability & infrastructure

> Priority: P1 — required before handling real traffic
> Estimated effort: 3-4 days

---

## Objective

Make the backend resilient to multi-instance deployment, external service failures, data growth, and operational blindness.

---

## Tasks

### 2.1 Switch rate-limit store to Redis

**Problem:** In-memory throttle store resets on restart and is per-instance — trivially bypassable in multi-pod deployment.

**Files:**
- `backend/src/app.module.ts`
- `backend/package.json` (new dep)

**Actions:**
1. Install `@nestjs/throttler-storage-redis` and `ioredis`
2. Add `REDIS_URL` to `.env.example` and `env.validation.ts` (required in production)
3. Update `ThrottlerModule.forRoot()`:
```typescript
ThrottlerModule.forRoot({
  throttlers: [{ ttl: 60000, limit: 200 }],
  storage: new ThrottlerStorageRedisService(new Redis(configService.get('REDIS_URL'))),
}),
```
4. Update WebSocket `allowAction()` map to use Redis instead of in-memory `Map`

---

### 2.2 Add persistent job queue with BullMQ

**Problem:** Dispatch, notifications, and refunds are fire-and-forget `void promise.catch()`. Crash = lost jobs.

**Actions:**
1. Install `@nestjs/bullmq` and `bullmq`
2. Create queues:
   - `dispatch` — rider assignment, retry on rejection, expired assignment sweep
   - `notifications` — SMS, FCM push, email
   - `refunds` — bKash refund execution with automatic retry
3. Replace all `void someAsyncCall().catch(...)` patterns with `queue.add(jobName, data)`
4. Add `BullModule.forRoot({ connection: { url: REDIS_URL } })` to `AppModule`
5. Create processor classes for each queue

**Key files to change:**
- `backend/src/modules/dispatch/dispatch.service.ts` — move dispatch cycle to a job
- `backend/src/modules/notifications/sms.service.ts` — move SMS send to a job
- `backend/src/modules/payments/refunds.service.ts` — move refund execution to a job

---

### 2.3 Fix cron job double-firing in multi-instance

**Problem:** `@Cron` runs in-process on every instance simultaneously.

**Actions:**
- Option A (simple): Move cron-triggered work to BullMQ repeatable jobs (from 2.2) — BullMQ guarantees single execution across instances
- Option B (if not using BullMQ): Add a Redis-based distributed lock before each cron job body

**Files:**
- `backend/src/modules/dispatch/dispatch.service.ts` — assignment expiry sweep
- Any other `@Cron` or `@Interval` decorated methods

---

### 2.4 Add `RiderLocation` cleanup job

**Problem:** `RiderLocation` table grows unboundedly — every WebSocket position update inserts a row.

**Action:** Add a daily BullMQ repeatable job (or `@Cron` with lock from 2.3):
```typescript
// Delete locations older than 7 days
await this.prisma.riderLocation.deleteMany({
  where: { recordedAt: { lt: subDays(new Date(), 7) } },
});
```

**File:** Create `backend/src/modules/rider/rider-location-cleanup.processor.ts` or add to an existing cron service.

---

### 2.5 Add structured JSON logging

**Problem:** NestJS default logger outputs plain text — unusable by log aggregators (CloudWatch, Datadog, ELK).

**Actions:**
1. Install `nestjs-pino` and `pino-pretty` (dev only)
2. Replace `Logger` with `LoggerModule.forRoot()` in `AppModule`:
```typescript
LoggerModule.forRoot({
  pinoHttp: {
    level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
    transport: process.env.NODE_ENV !== 'production' ? { target: 'pino-pretty' } : undefined,
  },
}),
```
3. Replace `console.log` in `main.ts` with the Pino logger
4. Ensure request-id middleware feeds the request ID into pino's `reqId`

---

### 2.6 Add Prometheus metrics endpoint

**Problem:** No request latency, throughput, or error rate tracking beyond Sentry.

**Actions:**
1. Install `@willsoto/nestjs-prometheus`
2. Register `PrometheusModule` in `AppModule`
3. Expose `GET /metrics` (protected by an internal API key or IP whitelist)
4. Default metrics include HTTP request duration histogram, active connections, Node.js memory/CPU

---

### 2.7 Slim down Docker production image

**Problem:** Production image includes all devDependencies.

**File:** `backend/Dockerfile`

**Action:** Add a prune step in the runner stage:
```dockerfile
# In builder stage, after build:
RUN npm prune --omit=dev

# In runner stage:
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
```

Also add explicit error handling for migration failure:
```dockerfile
CMD ["sh", "-c", "npx prisma migrate deploy || exit 1 && node dist/main.js"]
```

---

### 2.8 Make Sentry required in production

**Problem:** `SENTRY_DSN` is optional — Sentry silently disabled without it.

**File:** `backend/src/config/env.validation.ts`

**Action:** In the production validation block, require `SENTRY_DSN`:
```typescript
if (isProduction && !config.SENTRY_DSN) {
  errors.push('SENTRY_DSN is required in production');
}
```

---

### 2.9 Add retry logic for critical external calls

**Problem:** A single transient failure on bKash/Pathao throws immediately to the user.

**Action:** Create a shared `retryFetch` utility:
```typescript
async function retryFetch(url: string, options: RequestInit, maxRetries = 2): Promise<Response> {
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fetch(url, { ...options, signal: AbortSignal.timeout(10_000) });
    } catch (err) {
      if (attempt === maxRetries) throw err;
      await new Promise(r => setTimeout(r, 1000 * (attempt + 1)));
    }
  }
}
```

Apply to: bKash token grant, bKash execute, Pathao create-order, SMS send. Do NOT retry Pathao token (it has its own caching).

---

## Verification checklist

- [ ] Throttle works across two backend instances (start two, exhaust limit from one, verify blocked on other)
- [ ] Kill a backend instance mid-dispatch — verify the job is picked up by the surviving instance
- [ ] `RiderLocation` rows older than 7 days are deleted by the cleanup job
- [ ] `docker image inspect` shows production image < 300MB (no devDeps)
- [ ] `GET /metrics` returns Prometheus-format counters
- [ ] Logs output JSON in production mode
- [ ] Backend refuses to start without `SENTRY_DSN` in production
- [ ] Simulated bKash timeout is retried automatically
