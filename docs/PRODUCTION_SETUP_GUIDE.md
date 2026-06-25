# Production Setup Guide

Step-by-step checklist to take the Food Delivery system live.
Work through each section in order — later sections depend on earlier ones.

---

## Phase 1 — Secrets & Environment Variables

These must be set on your server before you deploy. The backend will throw on startup if any are missing.

### 1.1 Generate strong JWT secrets

Run this on any machine (or use a password manager):

```bash
# Run twice — one for access, one for refresh
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```

Copy the two outputs into your environment:

```env
JWT_ACCESS_SECRET=<64-char hex string>
JWT_REFRESH_SECRET=<different 64-char hex string>
```

### 1.2 Set all required production environment variables

Set these on your hosting platform (Railway / Render / AWS / DigitalOcean / VPS — wherever the backend runs):

```env
# ── Database ──────────────────────────────────────────────
DATABASE_URL=postgresql://USER:PASSWORD@HOST:5432/DB_NAME?schema=public

# ── Redis ─────────────────────────────────────────────────
REDIS_URL=redis://default:PASSWORD@HOST:6379

# ── Auth ──────────────────────────────────────────────────
JWT_ACCESS_SECRET=<generated above>
JWT_REFRESH_SECRET=<generated above>

# ── CORS — replace with your actual frontend/app domain ───
CORS_ORIGINS=https://yourdomain.com

# ── Trust proxy (number of LB hops in front of the API) ──
TRUST_PROXY=1

# ── Error monitoring ──────────────────────────────────────
SENTRY_DSN=https://xxx@oyyy.ingest.sentry.io/zzz

# ── Force-update gate (set after first Play Store upload) ─
MIN_APP_VERSION=1.0.0
ANDROID_UPDATE_URL=https://play.google.com/store/apps/details?id=com.yourpackage

# ── Push notifications ────────────────────────────────────
FCM_PROJECT_ID=your-firebase-project-id
FCM_CLIENT_EMAIL=firebase-adminsdk-xxx@your-project.iam.gserviceaccount.com
FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# ── Payments (bKash) ──────────────────────────────────────
BKASH_BASE_URL=https://tokenized.pay.bka.sh/v1.2.0-beta
BKASH_APP_KEY=...
BKASH_APP_SECRET=...
BKASH_USERNAME=...
BKASH_PASSWORD=...

# ── OTP (Twilio or Resend) ────────────────────────────────
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
TWILIO_FROM_NUMBER=+1...
# OR
RESEND_API_KEY=re_...

# ── Media (Cloudinary) ────────────────────────────────────
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...

# ── App ───────────────────────────────────────────────────
NODE_ENV=production
PORT=3000
```

> **How to set these:** Most platforms have a "Environment Variables" or "Secrets" section in their dashboard. Never put these in a `.env` file that gets committed.

---

## Phase 2 — Firebase Setup (Android)

### 2.1 Get google-services.json from Firebase Console

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Open your project → **Project Settings** (gear icon) → **General** tab
3. Scroll to "Your apps" → find the Android app
4. Click **Download google-services.json**
5. Place it here in the repo:
   ```
   apps/customer_app/android/app/google-services.json
   ```
   This file is gitignored — it will not be committed.

### 2.2 Verify Crashlytics is wired (it already is in code)

The build plugin is already added in `android/app/build.gradle.kts`. Once `google-services.json` is present, Crashlytics activates automatically in release builds.

To confirm after your first release build:
1. Firebase Console → your project → **Crashlytics**
2. Force a test crash: add `FirebaseCrashlytics.instance.crash()` temporarily, run a release build, check console within 5 minutes, then remove the line.

### 2.3 Rotate the Firebase Admin key (precautionary)

The `firebase-adminsdk` JSON at the repo root was never committed but may have been seen. Rotate it:

1. Google Cloud Console → **IAM & Admin** → **Service Accounts**
2. Find the firebase-adminsdk service account for your project
3. **Keys** tab → **Add Key** → JSON → download new key
4. Update `FCM_CLIENT_EMAIL` and `FCM_PRIVATE_KEY` env vars with values from the new key
5. Delete the old key from Google Cloud

---

## Phase 3 — Database

### 3.1 Enable automated backups

Do this in your Postgres provider's dashboard:

**Supabase:** Dashboard → Project → Settings → Database → **Backups** → enable daily backups + PITR  
**Neon:** Dashboard → project → **Backups** (Pro plan required for PITR)  
**RDS:** Console → DB instance → **Maintenance & backups** → set backup retention ≥ 7 days  
**Railway:** Dashboard → Postgres plugin → **Settings** → backups are automatic (check retention)  

Set retention to **at least 7 days**.

### 3.2 Test a restore (do this before launch, and quarterly after)

1. Create a scratch DB on your provider (or a local Postgres)
2. Restore the most recent backup into it
3. Run `npx prisma migrate status` against the scratch DB — confirm it's clean
4. Query a known table to confirm data is intact
5. Delete the scratch DB

An untested backup is not a backup.

### 3.3 Check for migration drift

Your project has two tables (`Message`, `RiderOrderRejection`) that were added via `db push` instead of a formal migration. Before deploying to production, run:

```bash
cd backend
npx prisma migrate status
```

If it shows **"drift detected"** or unapplied changes, resolve it:

```bash
# Option A: create a migration from the current schema (recommended)
npx prisma migrate dev --name add_message_riderorderrejection

# Then commit the generated migration file under prisma/migrations/
```

After this, `prisma migrate deploy` on container boot will work cleanly.

### 3.4 Set up connection pooling

Without pooling, each backend instance opens its own Prisma pool. Under autoscaling this exhausts Postgres `max_connections`.

**If using Supabase:** use the built-in connection pooler URL (Supavisor) — found in Project Settings → Database → **Connection Pooling**. Use the pooled URL for `DATABASE_URL` and the direct URL only for migrations:

```bash
# In your deploy script / CI, run migrations against direct URL:
DATABASE_URL=$DIRECT_DATABASE_URL npx prisma migrate deploy

# The app uses the pooled URL from DATABASE_URL env var
```

**If self-hosted:** install PgBouncer in transaction mode and point `DATABASE_URL` at it. Cap prisma:
```
DATABASE_URL=postgresql://...?connection_limit=10&pool_timeout=20
```

Rule: `(instances × connection_limit) + 5 < Postgres max_connections`

---

## Phase 4 — Deploy the Backend

### 4.1 Run database migrations on deploy

Your `Dockerfile` / deploy script should run migrations before starting the server:

```dockerfile
# Already in Dockerfile — confirm this line exists before CMD
RUN npx prisma generate
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/main.js"]
```

Or in your CI/CD pipeline:

```yaml
- run: npx prisma migrate deploy
- run: node dist/main.js
```

### 4.2 Verify health probes after deploy

Once deployed, hit these two endpoints:

```bash
# Should return 200 immediately (process-only check)
curl https://your-api.com/api/v1/health/live

# Should return 200 if DB + Redis are connected, 503 if not
curl https://your-api.com/api/v1/health/ready
```

If `/health/ready` returns 503, check:
- Is `DATABASE_URL` pointing to the correct DB?
- Is `REDIS_URL` reachable from the server?

### 4.3 Point your orchestrator/LB health probes

| Probe | URL | Expected |
|-------|-----|---------|
| Docker HEALTHCHECK (already set) | `/api/v1/health/live` | 200 |
| LB / k8s readiness probe | `/api/v1/health/ready` | 200 |
| LB / k8s liveness probe | `/api/v1/health/live` | 200 |

In docker-compose:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/api/v1/health/live"]
  interval: 30s
  timeout: 5s
  retries: 3
```

---

## Phase 5 — Build & Release the Android App

### 5.1 Create a keystore (one-time, keep it forever)

```bash
keytool -genkey -v \
  -keystore release.keystore \
  -alias food_delivery \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Store `release.keystore` somewhere safe (outside the repo). Back it up — losing it means you can never update the app on the Play Store.

### 5.2 Configure signing in the app

Create `apps/customer_app/android/key.properties` (already gitignored):

```properties
storePassword=<your keystore password>
keyPassword=<your key password>
keyAlias=food_delivery
storeFile=../../../release.keystore
```

Verify `apps/customer_app/android/app/build.gradle.kts` reads this file for release builds (it should already — check for `signingConfigs`).

### 5.3 Build the release APK / AAB

```bash
cd apps/customer_app

# App Bundle (required for Play Store)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### 5.4 Set the force-update env vars on the backend

After your first Play Store upload, set:
```env
MIN_APP_VERSION=1.0.0
ANDROID_UPDATE_URL=https://play.google.com/store/apps/details?id=com.yourpackage.id
```

When you need to block an old version:
1. Set `MIN_APP_VERSION` to the new minimum (e.g., `1.1.0`)
2. Redeploy backend — old installs will see the force-update screen on next launch

---

## Phase 6 — Observability

### 6.1 Sentry (error monitoring)

1. Create a project at [sentry.io](https://sentry.io) → **NestJS**
2. Copy the DSN → set `SENTRY_DSN` env var on the backend
3. The backend already imports `instrument.ts` which initialises Sentry — no code change needed
4. To align release tracking, set `SENTRY_RELEASE` env var to your git SHA or version tag in CI:
   ```env
   SENTRY_RELEASE=v1.0.0
   ```

### 6.2 Verify Sentry is receiving errors

After setting `SENTRY_DSN`, hit an endpoint that throws:

```bash
curl https://your-api.com/api/v1/nonexistent-route
```

Check Sentry dashboard within 1 minute — you should see a 404 error event.

### 6.3 Prometheus + Grafana (metrics)

The backend exposes Prometheus metrics via `@willsoto/nestjs-prometheus`.

Default metrics endpoint: `GET /metrics`

Suggested Grafana dashboards to create:
- HTTP error rate (5xx/s)
- p95 response latency
- BullMQ queue depth (dispatch + notification queues)
- DB connection pool usage
- Active WebSocket connections

Set up Alertmanager rules for:
- Error rate > 1% for 5 minutes → page
- `/health/ready` returning 503 → page immediately
- Queue depth > 100 for 10 minutes → warning

---

## Phase 7 — Security Checklist

### 7.1 Restrict the Mapbox token

1. Go to [account.mapbox.com](https://account.mapbox.com) → **Tokens**
2. Edit your token → **Allowed URLs** or **Allowed scopes**
3. For Android: restrict to your app's package name
4. Create a separate token for dev if needed

### 7.2 Add gitleaks to prevent future secret commits

```bash
# Install (Windows)
winget install gitleaks

# Or download from: https://github.com/gitleaks/gitleaks/releases

# Test the repo
gitleaks detect --source . --verbose
```

Add to `.github/workflows/backend-ci.yml`:
```yaml
- name: Secret scan
  uses: gitleaks/gitleaks-action@v2
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 7.3 Fix the backend ESLint (CI quality gate)

The repo has ~600 pre-existing Prettier/line-ending errors that were excluded from CI to avoid noise.
Run this one-time cleanup before adding the lint step:

```bash
cd backend

# Auto-fix formatting
npm run lint -- --fix

# Normalize line endings
echo "* text=auto eol=lf" >> ../.gitattributes
git add --renormalize .
```

Then add to `.github/workflows/backend-ci.yml`:
```yaml
- run: npm run lint
```

---

## Phase 8 — Load Test Before Marketing Push

Run this before any significant traffic (launch, campaign, etc.):

### Install k6

```bash
winget install k6
# or: https://k6.io/docs/getting-started/installation/
```

### Basic order-flow load test

Create `load-test/order-flow.js`:

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 50 },   // ramp up
    { duration: '5m', target: 50 },   // hold
    { duration: '1m', target: 100 },  // spike
    { duration: '2m', target: 0 },    // ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% of requests under 500ms
    http_req_failed:   ['rate<0.01'],  // less than 1% errors
  },
};

export default function () {
  const res = http.get('https://your-api.com/api/v1/health/ready');
  check(res, { 'status 200': (r) => r.status === 200 });
  sleep(1);
}
```

```bash
k6 run load-test/order-flow.js
```

Watch `/health/ready`, Sentry error rate, and DB connection count during the test.

---

## Launch Day Sequence

Run these in order on the day you go live:

- [ ] All env vars set on the server
- [ ] `google-services.json` in `android/app/`
- [ ] Firebase admin key rotated
- [ ] `npx prisma migrate status` → clean
- [ ] DB backups enabled + restore tested
- [ ] Backend deployed → `/health/live` returns 200
- [ ] `/health/ready` returns 200
- [ ] Sentry receiving events
- [ ] Force-update env vars set (`MIN_APP_VERSION`, `ANDROID_UPDATE_URL`)
- [ ] Load test passed
- [ ] Release APK/AAB uploaded to Play Store
- [ ] First real order placed end-to-end (smoke test)

---

## After Launch — Ongoing Operations

| Task | Frequency |
|------|-----------|
| Test a DB restore | Quarterly |
| Rotate JWT secrets | Every 6 months |
| Rotate bKash / FCM credentials | Per provider recommendation |
| Review Sentry error trends | Weekly |
| Check BullMQ queue health | Weekly (set up an alert for DLQ depth) |
| Bump `MIN_APP_VERSION` when releasing a breaking app change | Per release |
| Run load test before campaigns | Before each major traffic event |
