# Food Delivery — Admin Panel

A production-grade restaurant operations console built with **Next.js 16, React 19, TypeScript, Tailwind CSS 4, and shadcn/ui**. It replaces the previous `admin-dashboard/` (Next.js) and `apps/admin_app/` (Flutter) panels.

Scoped for a **single restaurant** today (owner/manager back office) and architected to grow into multi-branch and platform-wide super-admin views without a rewrite.

## Features

- **Dashboard** — KPI cards, 7-day revenue chart, recent orders, top-selling items, live-updating via sockets.
- **Orders** — searchable/filterable table, order detail drawer, accept/reject/cancel, status transitions, rider dispatch.
- **Live Operations** — exception queues (in transit / failed / returned) with live refresh.
- **Menu** — categories, items, and add-ons with image upload and optimistic availability/featured toggles.
- **Customers & Riders** — user management with suspend/activate; rider roster and pending-approval workflow.
- **Promotions** — banners and discount coupons.
- **Settings** — restaurant profile, business settings, delivery pricing, operating hours, delivery zones.
- **Finance** — sales/earnings reports, complaint resolution, COD settlements.
- Light + dark themes, responsive (desktop → tablet), full loading/empty/error states, toasts on every mutation.

## Getting started

```bash
npm install
npm run dev      # http://localhost:8000
```

The panel expects the NestJS backend (in `../backend`) running on port 3000.

### Environment

`.env.local`:

```
NEXT_PUBLIC_API_URL=http://localhost:3000/api/v1
NEXT_PUBLIC_SOCKET_URL=http://localhost:3000
```

Sign in with a staff account (`OWNER`, `MANAGER`, `ADMIN`, `CASHIER`, or `KITCHEN`). Customer and rider accounts are rejected at login.

## Architecture

- `app/(auth)/` — login. `app/(dashboard)/` — authenticated shell + feature pages.
- `components/ui/` — shadcn primitives. `components/<feature>/` — feature components. `components/layout/` — sidebar, topbar, branch switcher.
- `lib/api/client.ts` — fetch wrapper with transparent 401→refresh. `lib/api/endpoints.ts` — typed route map. `lib/api/queries/` — TanStack Query hooks per feature.
- `lib/realtime/` — socket.io client + query invalidation. `store/auth-store.ts` — Zustand auth (persisted).
- `lib/auth/roles.ts` — role gates; nav is data-driven (`components/layout/nav-config.ts`) so the future super-admin view is additive.

## Scripts

```bash
npm run dev      # dev server (port 8000)
npm run build    # production build
npm run start    # serve production build
npm run lint     # eslint
```
