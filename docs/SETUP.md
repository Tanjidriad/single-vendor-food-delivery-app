# Food Delivery — Backend Setup

## Prerequisites

- Node.js 20+
- Docker Desktop (PostgreSQL)
- Cloudinary account (image uploads)
- Google Maps API key (geocoding, distance, ETA)

## 1. Start database

```bash
cd infra
docker compose up -d
```

## 2. Configure environment

```bash
cd backend
cp .env.example .env
```

Set in `.env`:

- `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` (32+ characters)
- `GOOGLE_MAPS_API_KEY`
- `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`
- Optional: `FCM_PROJECT_ID`, `FCM_CLIENT_EMAIL`, `FCM_PRIVATE_KEY` for push notifications

## 3. Install, migrate, seed

```bash
npm install
npx prisma db push
npm run db:seed
```

## 4. Run API

```bash
npm run start:dev
```

- API: `http://localhost:3000/api/v1`
- Swagger: `http://localhost:3000/api/docs`
- The server binds to **`0.0.0.0`** (see `HOST` in `.env`) so phones on the same Wi‑Fi can connect.
- On startup, the API logs a **Physical device** URL and writes `apps/customer_app/assets/dev_api_host.txt` with your LAN address.
- Dev discovery: `GET http://localhost:3000/api/v1/dev/client-config` (returns `apiBaseUrl`, `socketBaseUrl`, and all LAN hosts).

### Flutter customer app (physical device)

1. Start the API first: `npm run start:dev` (updates `dev_api_host.txt` with your PC’s LAN IP).
2. Run the app: `cd apps/customer_app && flutter run` (no `launch.json` dart-defines needed).
3. Phone and PC must be on the **same Wi‑Fi**; allow port **3000** through Windows Firewall if requests fail.

The app probes `/health` and `/dev/client-config`, caches the working URL, and reuses it on the next launch.

## Demo accounts (after seed)

| Role | Login | Password |
|------|-------|----------|
| Owner | owner@demokitchen.com | Password123! |
| Kitchen | kitchen@demokitchen.com | Password123! |
| Rider | +8801700000002 | Password123! |
| Customer | customer@example.com | Password123! |

## OTP (development)

`POST /api/v1/auth/otp/send` — OTP is printed in the server console and returned as `devCode` when `NODE_ENV=development`.

## API modules

| Module | Endpoints |
|--------|-----------|
| Auth | register, login, refresh, logout, otp/send, otp/verify, forgot-password/reset |
| Uploads | POST uploads/image, uploads/image/banner (multipart) |
| Menu | public menu, search, banners; admin CRUD under `/admin/menu` |
| Restaurant admin | profile, settings, fees, hours, banners, coupons, zones |
| Orders | place, list, accept/reject/cancel/reorder, verify-delivery OTP, status updates |
| Delivery fee | quote (zone-aware), geocode, reverse-geocode |
| Dispatch | available riders, assign, auto-assign, rider accept/reject, auto-reassign on timeout |
| Complaints | customer create/list; staff list/update refunds |
| Users | GET/PATCH `me`, rider online toggle |
| Menu | filter endpoint `GET menu/restaurant/:id/filter` |
| Addresses | customer saved addresses CRUD |
| Favorites | add/remove/list |
| Reviews | post review, list by restaurant |
| Reports | sales, earnings, rider performance, rider earnings |
| Payments | online initiate/confirm, wallet stub |
| Print events | log kitchen/receipt print + socket `print:requested` |
| Coupons | validate |
| Notifications | list, mark read |
| Devices | register FCM token |

## Smoke test (all major REST endpoints)

With the API running and DB seeded:

```bash
cd backend
npm run smoke:test
```

Covers auth, menu, orders (full lifecycle), dispatch, complaints, admin, reports, etc. Does **not** cover multipart uploads or Socket.IO — test those manually.

## Socket.IO

- Namespace: `/realtime`
- Auth: JWT in `auth.token` or `Authorization` header
- Events: `order:created`, `order:status.changed`, `assignment:*`, `rider:location.updated`, `print:requested`
