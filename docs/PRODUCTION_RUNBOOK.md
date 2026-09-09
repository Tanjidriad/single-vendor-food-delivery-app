# Production Runbook

Operational checklist for taking the Food Delivery backend + customer app to production.
Code-level hardening is largely done (see the session changelog); the items here require your
cloud/CI environment and must be executed by an operator.

---

## 1. Database — backups, PITR, pooling (P1-4)

### Backups + point-in-time recovery
- Enable **automated daily backups** on the managed Postgres (RDS/Cloud SQL/Neon/Supabase).
- Enable **PITR / WAL archiving** with at least a 7-day window.
- **Test a restore quarterly** into a scratch instance — an untested backup is not a backup.
- Store one periodic logical dump off-provider: `pg_dump --no-owner --format=custom`.

### Connection pooling
- The app opens a Prisma pool per instance. Behind autoscaling this multiplies fast and can
  exhaust Postgres `max_connections`.
- Put **PgBouncer** (transaction mode) in front, or use the provider's pooler, and cap Prisma:
  `DATABASE_URL=...?connection_limit=10&pool_timeout=20`.
- Rule of thumb: `instances × connection_limit < max_connections` (leave headroom for migrations/admin).
- Run migrations against the **direct** (non-pooled) URL; serve traffic via the **pooled** URL.

### Migration drift
- Always ship schema changes as Prisma migrations (`prisma migrate deploy` runs on container boot).
- Reconcile any historical `db push`-only tables into a migration so `prisma migrate status` is clean.

---

## 2. Required production environment variables

| Var | Purpose |
|-----|---------|
| `DATABASE_URL` | Postgres (pooled for app) |
| `REDIS_URL` | Throttler + BullMQ + readiness (required in prod) |
| `SENTRY_DSN` | Error monitoring (required in prod) |
| `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` | ≥32 chars, unique |
| `CORS_ORIGINS` | Explicit allowlist (wildcard rejected in prod) |
| `TRUST_PROXY` | Hop count behind LB/CDN (default 1 in prod) — for correct client IP / rate limiting |
| `MIN_APP_VERSION`, `ANDROID_UPDATE_URL` | Force-update gate (`GET /app/config`) |
| `BKASH_*`, `FCM_*`, `TWILIO_*`/`RESEND_API_KEY`, `CLOUDINARY_*` | Payments, push, OTP, media |

Keep all secrets in a **secret manager** (not files). Rotate JWT secrets and the bKash/FCM
credentials on a schedule; document the rotation steps.

---

## 3. Health probes

- **Liveness** (orchestrator restart signal + Docker HEALTHCHECK): `GET /api/v1/health/live`
- **Readiness** (LB traffic gating): `GET /api/v1/health/ready` — returns 503 if Postgres/Redis down.
- Point your k8s/compose readiness probe at `/health/ready`.

---

## 4. Observability (P2)

- Sentry is wired (backend `instrument.ts`; app Crashlytics). Set `SENTRY_DSN` and align
  **release tags** across backend + app so crashes map to a build.
- Prometheus metrics are exposed (`@willsoto/nestjs-prometheus`). Add **Grafana dashboards** +
  **Alertmanager** rules: error rate, p95 latency, queue depth, DB connections, COD-settlement lag.
- App: add product analytics + performance traces (Firebase Performance or Sentry) on the
  checkout / order / tracking flows.

---

## 5. Queue reliability (P2)

- BullMQ is configured (dispatch, notifications). Add a **dead-letter queue** for jobs that
  exhaust retries and **alert** on DLQ depth, so a failed dispatch/notification is visible.
- Set sensible `attempts` + backoff on each queue; ensure idempotent job handlers.

---

## 6. Security follow-ups (P2)

- **Audit logging** for admin + money mutations (who changed what, when).
- **Certificate pinning** in the app for the API + payment hosts.
- Restrict the **Mapbox token** by Android package name / bundle id.
- **gitleaks** pre-commit + CI secret scan (the Firebase admin key is already gitignored — rotate it
  if it was ever shared, and keep service-account JSON out of the repo).

---

## 7. Pre-launch load test (P2)

- Load test the **order → dispatch → payment** path (k6 or Artillery) at expected peak ×3.
- Verify autoscaling, DB pool headroom, and rate-limit thresholds under load before any marketing push.
- Write incident runbooks (DB down, Redis down, payment gateway down) and set up on-call.

---

## 8. CI/CD

- `.github/workflows/backend-ci.yml` — Postgres service, `prisma migrate deploy`, build, unit + e2e tests.
- `.github/workflows/customer-app-ci.yml` — `flutter analyze` + `flutter test`.
- **TODO:** enable backend ESLint in CI after a one-time formatting pass — the repo currently has
  ~600 Prettier/CRLF lint errors. Run `npm run lint` (auto-fix) + add a `.gitattributes`
  (`* text=auto eol=lf`) to normalize line endings, then add a non-mutating lint step to CI.
- Add a **staging environment** mirroring prod; deploy there before promoting to production.
