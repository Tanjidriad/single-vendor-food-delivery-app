# Food Delivery Platform — Full Workflow & Implementation Audit

**Project:** Food Delivery Platform (Bangladesh Market)
**Date:** 2026-06-18
**Author:** Riad
**Status:** MVP Complete — Kitchen App Pilot-Ready

---

## Table of Contents

1. [Platform Overview](#1-platform-overview)
2. [System Architecture](#2-system-architecture)
3. [Backend — NestJS API](#3-backend--nestjs-api)
4. [Customer App](#4-customer-app-flutter)
5. [Rider App](#5-rider-app-flutter)
6. [Kitchen App (KDS)](#6-kitchen-app-kds--flutter)
7. [Admin App](#7-admin-app-flutter)
8. [Web Dashboards](#8-web-dashboards-nextjs)
9. [Real-Time System](#9-real-time-system)
10. [Payment System](#10-payment-system)
11. [Delivery & Dispatch System](#11-delivery--dispatch-system)
12. [Push Notifications](#12-push-notifications)
13. [Third-Party Integrations](#13-third-party-integrations)
14. [Database Schema Summary](#14-database-schema-summary)
15. [Security & Auth](#15-security--auth)
16. [Deployment & Configuration](#16-deployment--configuration)
17. [Implementation Progress](#17-implementation-progress)
18. [Known Gaps & Next Steps](#18-known-gaps--next-steps)

---

## 1. Platform Overview

A full-stack food delivery platform targeting the Bangladesh market. It covers the complete delivery lifecycle — from a customer placing an order, to kitchen staff preparing it, to a rider picking it up and delivering it — with real-time tracking and communication at every step.

### Apps in the Platform

| App | Type | Target User |
|-----|------|-------------|
| Customer App | Flutter (iOS/Android) | End customers |
| Rider App | Flutter (iOS/Android) | Delivery riders |
| Kitchen App (KDS) | Flutter (Android tablet) | Kitchen & restaurant staff |
| Admin App | Flutter (iOS/Android) | Restaurant owner/manager |
| Admin Dashboard | Next.js (Web) | System administrator |
| Restaurant Dashboard | Next.js (Web) | Kitchen staff (web KDS) |
| Backend API | NestJS (Node.js) | All apps via REST + WebSocket |

---

## 2. System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                             │
│                                                                 │
│  Flutter Customer App   Flutter Rider App   Flutter Kitchen App │
│  Flutter Admin App      Next.js Admin Web   Next.js KDS Web    │
└───────────────────────────┬─────────────────────────────────────┘
                            │  REST API + WebSocket (Socket.IO)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     BACKEND (NestJS 11)                         │
│                                                                 │
│   Auth │ Orders │ Dispatch │ Riders │ Menu │ Payments │ Reports  │
│   Messages │ Notifications │ Delivery Fee │ Media │ Admin       │
└──────────┬──────────────────────────┬──────────────────────────┘
           │                          │
    ┌──────▼──────┐           ┌───────▼───────┐
    │ PostgreSQL   │           │     Redis      │
    │ (Prisma ORM) │           │ (BullMQ Queue) │
    └─────────────┘           └───────────────┘
           │
    ┌──────▼──────────────────────────────────────┐
    │           External Services                  │
    │  bKash │ Pathao │ Mapbox │ FCM │ Cloudinary  │
    └─────────────────────────────────────────────┘
```

### Tech Stack Summary

| Layer | Technology |
|-------|-----------|
| Mobile Apps | Flutter 3.11+ / Dart |
| State Management | Riverpod |
| Navigation | GoRouter |
| HTTP Client | Dio |
| Web Dashboards | Next.js 16.2 / React 19 / TypeScript |
| UI Components (Web) | shadcn/ui + Tailwind CSS |
| Backend | NestJS 11 / Node.js |
| Database | PostgreSQL (via Prisma ORM) |
| Queue/Cache | Redis (BullMQ) |
| Real-Time | Socket.IO |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| Image Storage | Cloudinary |
| Payments | bKash (Bangladesh) |
| External Delivery | Pathao Parcel |
| Maps | Mapbox (primary) / Google Maps (fallback) |
| Error Tracking | Sentry |
| Metrics | Prometheus |
| Logging | Pino (JSON structured) |

---

## 3. Backend — NestJS API

**Location:** `backend/`
**Base URL:** `http://<host>:3000/api/v1`
**API Docs:** `http://<host>:3000/api/docs` (Swagger)

### 3.1 Modules (27 total)

| Module | Responsibility |
|--------|---------------|
| `auth` | Registration, login, OTP, JWT, password reset |
| `users` | User profile, rider online toggle |
| `addresses` | Customer delivery address CRUD |
| `admin` | System-wide admin operations |
| `restaurant` | Public restaurant info, operating hours |
| `restaurant-admin` | Private settings, fees, zones, banners, coupons |
| `menu` | Public menu API, search, filter; admin CRUD |
| `orders` | Order lifecycle (place → accept → prepare → deliver) |
| `dispatch` | Rider assignment, auto-assign, timeout handling |
| `rider` | Onboarding, document approval, earnings, performance |
| `delivery-fee` | Dynamic fee calculation, geocoding, distance matrix |
| `payments` | bKash gateway integration, refund workflow |
| `notifications` | FCM push notification dispatch |
| `devices` | FCM token registration and lifecycle |
| `messages` | In-order chat between customer and rider |
| `media` | Image uploads to Cloudinary |
| `uploads` | Multipart file handling |
| `coupons` | Discount code validation |
| `favorites` | Customer saved menu items |
| `reviews` | Post-delivery ratings and comments |
| `complaints` | Issue tracking and resolution |
| `print-events` | Kitchen printer logging and socket emission |
| `earnings` | Rider earnings reports and ledger entries |
| `reports` | Sales, rider performance, analytics |
| `health` | Readiness/liveness probes |
| `dev` | Dev-only endpoints (client config, seed data) |

### 3.2 Key API Endpoints

#### Authentication
```
POST /auth/register              — Customer registration
POST /auth/register/rider        — Rider onboarding
POST /auth/login                 — Email/phone + password login
POST /auth/otp/send              — Send OTP (SMS/email)
POST /auth/otp/verify            — Verify OTP
POST /auth/forgot-password/reset — Password reset
POST /auth/refresh               — Refresh JWT tokens
POST /auth/logout                — Invalidate refresh token
```

#### Orders
```
POST   /orders                          — Place new order
GET    /orders                          — List (scoped by role)
GET    /orders/:id                      — Order detail
GET    /orders/kitchen/history          — Kitchen history view
POST   /orders/:id/accept               — Kitchen accepts order
POST   /orders/:id/reject               — Kitchen rejects order
POST   /orders/:id/cancel               — Cancel order
POST   /orders/:id/reorder              — Reorder (clone previous)
POST   /orders/:id/delivery-exception   — Report delivery failure
POST   /orders/:id/resolve-exception    — Mark exception resolved
POST   /orders/:id/food-disposition     — Approve/discard food
POST   /orders/:id/verify-delivery      — OTP delivery confirmation
POST   /orders/:id/dispatch-external    — Hand off to Pathao courier
POST   /orders/:id/confirm-delivery     — Final delivery confirmation
PATCH  /orders/:id/status               — Admin direct status override
```

#### Dispatch
```
GET  /dispatch/riders        — List available riders
POST /dispatch/assign        — Manual rider assignment
POST /dispatch/auto-assign   — Trigger automatic assignment
POST /dispatch/accept        — Rider accepts assignment
POST /dispatch/reject        — Rider rejects assignment
```

#### Menu
```
GET    /menu                              — Full public menu
GET    /menu/restaurant/:id/filter        — Filtered/searchable menu
POST   /menu/search                       — Search menu items
GET    /banners                           — Active promotional banners
POST   /admin/menu/categories             — Create category
PATCH  /admin/menu/categories/:id         — Update category
DELETE /admin/menu/categories/:id         — Delete category
POST   /admin/menu/items                  — Create menu item
PATCH  /admin/menu/items/:id              — Update menu item
DELETE /admin/menu/items/:id              — Delete menu item
```

#### Delivery Fee
```
POST /delivery-fee/quote            — Calculate fee for customer quote
POST /delivery-fee/geocode          — Forward geocoding (address → coords)
POST /delivery-fee/reverse-geocode  — Reverse geocoding (coords → address)
```

#### Payments
```
POST /payments/online/initiate   — Create bKash payment
POST /payments/online/confirm    — Confirm bKash transaction
POST /refunds/request            — Submit refund request
POST /refunds/:id/approve        — Approve refund
POST /refunds/:id/execute        — Execute payout
```

#### Riders
```
GET    /users/me                  — Current rider profile
POST   /users/rider/online        — Toggle online/offline status
POST   /rider/documents           — Upload approval documents
GET    /rider/earnings            — Earnings summary
GET    /rider/performance         — Performance metrics (rating, stats)
GET    /rider/location            — Current location
```

#### Reports (Admin)
```
GET /reports/sales              — Sales data (date-range, branch)
GET /reports/rider-earnings     — Rider earnings breakdown
GET /reports/rider-performance  — Acceptance rate, avg delivery time
```

### 3.3 Background Jobs (BullMQ + Redis)

| Queue | Job | Description |
|-------|-----|-------------|
| `dispatch` | `ASSIGN_RIDER` | Find and notify the next available rider |
| `dispatch` | `EXPIRE_ASSIGNMENT` | Expire assignment after timeout, trigger reassignment |
| `dispatch` | `AUTO_ASSIGN_RETRY` | Retry if no rider accepted initial offer |
| `notifications` | `SEND_PUSH` | Batch FCM push delivery |
| `print` | `PRINT_KOT` | Retry failed kitchen printer jobs |

**Scheduled Crons:**
- **SLA Timer Policy** — Tracks order stage durations; escalates overdue orders
- **Rider Document Expiry** — Flags expired licenses/NDI
- **Payout Batch** — Periodic rider payout aggregation

---

## 4. Customer App (Flutter)

**Location:** `apps/customer_app/`

### 4.1 Features

| Feature | Description | Status |
|---------|-------------|--------|
| Phone/email login | OTP-based auth, remember me | ✓ Done |
| Registration | Name, phone, email, password | ✓ Done |
| Forgot password | OTP reset flow | ✓ Done |
| Home screen | Banners, categories, featured items | ✓ Done |
| Menu browsing | Category filter, search, item cards | ✓ Done |
| Item detail | Description, add-ons, quantity picker | ✓ Done |
| Cart | Add/remove items, add-on selection, quantity | ✓ Done |
| Coupon code | Apply discount at checkout | ✓ Done |
| Delivery address | Map picker, saved addresses (Home/Office/Other) | ✓ Done |
| Payment method | COD or bKash online payment | ✓ Done |
| Checkout | Order summary, fee breakdown, place order | ✓ Done |
| bKash payment | WebView flow, confirmation, fallback | ✓ Done |
| Order tracking | Real-time status + live rider map | ✓ Done |
| Rider chat | In-app Socket.IO chat during delivery | ✓ Done |
| OTP delivery | Confirm delivery with 4-digit OTP | ✓ Done |
| Order history | Past orders, reorder shortcut | ✓ Done |
| Favorites | Save/unsave menu items | ✓ Done |
| Notifications | FCM push + in-app notification list | ✓ Done |
| Review & rating | Post-delivery 1–5 star rating + comment | ✓ Done |
| Complaint filing | Report issue per order | ✓ Done |
| User profile | Edit name, phone, email, avatar | ✓ Done |
| Wallet | Stub — backend ready, UI pending | ⚠ Partial |

### 4.2 App Architecture

```
lib/
├── app.dart                  — App root, theme, router init
├── core/
│   ├── config/               — API host resolver (dev auto-discovery)
│   ├── constants/            — API endpoint constants
│   ├── network/              — Dio HTTP client, JWT interceptor
│   ├── realtime/             — Socket.IO client wrapper
│   ├── router/               — GoRouter with auth guards
│   ├── theme/                — App colors, typography, Material 3 theme
│   ├── utils/                — Popups, loaders, helpers
│   └── widgets/              — Shared UI components
│       ├── commerce/         — FloatingCartBar, MenuItemCard
│       ├── map/              — AppMapView (Mapbox)
│       ├── media/            — AppFoodImage (Cloudinary + cache)
│       ├── navigation/       — AppBottomNavBar, AppShell
│       └── shapes/           — Decorative containers, headers
└── features/
    ├── auth/                 — Login, register, forgot password
    ├── home/                 — Home screen, banners, filters
    ├── menu/                 — Menu listing, item detail
    ├── cart/                 — Cart state, cart screen
    ├── checkout/             — Checkout flow, address picker
    ├── orders/               — Order tracking, history
    ├── messages/             — Rider chat
    ├── favorites/            — Saved items
    ├── notifications/        — Notification list
    ├── profile/              — User profile
    └── support/              — Complaints, refunds
```

### 4.3 Order Tracking Flow (Customer)

```
Place Order
    ↓
Order Confirmed (WebSocket: order:updated)
    ↓
Kitchen Accepted (order status → ACCEPTED)
    ↓
Preparing... (status → PREPARING)
    ↓
Rider Assigned (order:assigned event — show rider on map)
    ↓
Rider On The Way (status → ON_THE_WAY — live GPS updates)
    ↓
Rider Arrived (notification)
    ↓
OTP Verification (customer shows OTP to rider)
    ↓
Delivered (status → DELIVERED)
    ↓
Review Prompt
```

---

## 5. Rider App (Flutter)

**Location:** `apps/rider_app/`

### 5.1 Features

| Feature | Description | Status |
|---------|-------------|--------|
| Phone login | OTP-based login | ✓ Done |
| Multi-step onboarding | Personal info, documents upload | ✓ Done |
| Document upload | NID, driving license, vehicle registration, insurance | ✓ Done |
| Approval status | Track document review status | ✓ Done |
| Online/offline toggle | Start/stop receiving orders | ✓ Done |
| Available orders | List + map of nearby orders | ✓ Done |
| Accept/reject | Accept or reject order assignment | ✓ Done |
| Active delivery map | Turn-by-turn directions overlay | ✓ Done |
| Real-time GPS broadcast | Location sent to server every 800ms | ✓ Done |
| Customer chat | In-app Socket.IO chat | ✓ Done |
| OTP confirmation | Verify delivery with customer OTP | ✓ Done |
| Delivery exception | Report unreachable customer, wrong address, etc. | ✓ Done |
| Earnings dashboard | Daily/weekly/monthly earnings summary | ✓ Done |
| Ledger history | Transaction-level earning breakdown | ✓ Done |
| Performance metrics | Acceptance rate, avg delivery time, rating | ✓ Done |
| Shift management | Start/end shift, hours tracking | ✓ Done |
| Profile management | Edit details, view document statuses | ✓ Done |
| Push notifications | FCM for new assignments, updates | ✓ Done |

### 5.2 Rider Dispatch Flow

```
Rider goes Online
    ↓
New order placed by customer
    ↓
Dispatch service selects nearest available rider
    ↓
Push notification sent to rider (FCM)
    ↓
Rider receives assignment in app (WebSocket: order:assigned)
    ↓
Rider accepts (within timeout window)  ← or rejects → next rider offered
    ↓
GPS tracking begins (800ms intervals)
    ↓
Rider arrives at restaurant
    ↓
Rider picks up order
    ↓
Rider navigates to customer
    ↓
OTP verification at door
    ↓
Delivery confirmed → Earnings recorded
```

### 5.3 Delivery Exception Handling

When a delivery cannot be completed, the rider can report:
- Customer unreachable
- Wrong address
- Customer refused delivery
- Accident
- App crash / technical failure

Staff resolves the exception (approve food disposition, arrange redelivery, or refund).

---

## 6. Kitchen App (KDS) — Flutter

**Location:** `apps/kitchen_app/`
**Target Device:** Android tablet (landscape)
**Current Phase:** Phase 5 — Complete ✓

### 6.1 Features

| Feature | Description | Status |
|---------|-------------|--------|
| Staff login | Kitchen/manager/cashier OTP login | ✓ Done |
| Restaurant identity | Dynamic name from JWT | ✓ Done |
| Kanban board | 3-column layout (New / Preparing / Ready) | ✓ Done |
| Order card (tile) | Compact Foodpanda-style card with timer | ✓ Done |
| Order detail sheet | Expandable sheet with full item list, add-ons, notes | ✓ Done |
| Live order timer | Elapsed time per stage (animated) | ✓ Done |
| Accept order | Move from New → Preparing | ✓ Done |
| Mark ready | Move from Preparing → Ready | ✓ Done |
| Hand off | Mark order handed to rider | ✓ Done |
| Print KOT | Auto-print on accept (Sunmi printer), retry banner on fail | ✓ Done |
| Print failure UI | Non-blocking retry/skip banner | ✓ Done |
| Test order toggle | Filter test orders from live view | ✓ Done |
| Restaurant online toggle | Enable/disable order acceptance | ✓ Done |
| Order history | Past orders with filter and stats | ✓ Done |
| Daily stats | Order count, revenue, avg prep time | ✓ Done |
| Dark theme | For open kitchen lighting | ✓ Done |
| Compact density | Compact / normal / spacious toggle | ✓ Done |
| Settings panel | Sound, vibration, theme, density | ✓ Done |
| Audio alert | Sound on new order arrival | ✓ Done |
| Haptic feedback | Vibration on key actions | ✓ Done |
| Accessibility | Screen reader labels, contrast | ✓ Done |
| Responsive layout | 1-col (phone) → 2-col (tablet portrait) → 3-col (tablet landscape) | ✓ Done |
| Per-column empty states | Friendly message when column is empty | ✓ Done |
| Push notifications | FCM for new orders (when app is background) | ✓ Done |

### 6.2 KDS Development Phases

| Phase | What Was Done | Commit |
|-------|--------------|--------|
| Phase 0 | Test order toggle fix, workflow verification | `da3e28d` |
| Phase 1 | Kitchen login UX, restaurant identity, print failure banner | — |
| Phase 2 | Foodpanda kanban layout, responsive tablet shell | `761f425` |
| Phase 3 | Foodpanda order tile + detail sheet + per-column empty states | `8ef1a3a` |
| Phase 4 | Dark theme + compact density toggle | `84340a4` |
| Phase 5 | Accessibility, performance, settings cleanup, haptics | `59bd1fe` |

### 6.3 KDS Component Tree

```
KDS Screen
├── KdsHeaderWidget
│   ├── Restaurant name (from JWT)
│   ├── Online/offline toggle
│   └── Settings button
├── KdsKanbanBoard
│   ├── Column: New Orders
│   │   ├── OrderStageTimer
│   │   ├── PremiumOrderCard (tile)
│   │   └── EmptyStateWidget
│   ├── Column: Preparing
│   │   └── (same as above)
│   └── Column: Ready
│       └── (same as above)
├── OrderDetailSheet (expandable bottom sheet)
│   ├── Full item list with add-ons
│   ├── Special notes
│   ├── Customer details
│   └── Action buttons (Accept / Mark Ready / Hand Off)
├── DailyStatsView
│   ├── Total orders
│   ├── Revenue
│   └── Avg prep time
└── SettingsPanel
    ├── Theme toggle (dark/light)
    ├── Density selector
    ├── Sound toggle
    └── Vibration toggle
```

### 6.4 Real-Time Events (Kitchen)

| Event (received) | Trigger |
|-----------------|---------|
| `order:updated` | Any order status change |
| `order:assigned` | Rider assigned to order |
| `order:rejected` | Rider rejected assignment |
| `print:requested` | Server requests KOT print |

---

## 7. Admin App (Flutter)

**Location:** `apps/admin_app/`

### 7.1 Features

| Feature | Status |
|---------|--------|
| Owner/manager login | ✓ Done |
| Dashboard overview (orders, revenue) | ✓ Done |
| Order management (list, filter, detail) | ✓ Done |
| Accept / reject / cancel orders | ✓ Done |
| Menu management (categories + items) | ✓ Done |
| Rider management (approve, suspend, view documents) | ✓ Done |
| Customer management (list, complaints, refunds) | ✓ Done |
| Banner management (create, edit, schedule) | ✓ Done |
| Coupon management (create, manage codes) | ✓ Done |
| Delivery zone management (polygon GIS) | ✓ Done |

---

## 8. Web Dashboards (Next.js)

### 8.1 Admin Dashboard

**Location:** `admin-dashboard/`
**Stack:** Next.js 16.2, React 19, TypeScript, Tailwind CSS, shadcn/ui

**Purpose:** System-wide administration — users, restaurants, complaints, refunds, analytics.

**Status:** UI framework complete (100+ components), backend API integration in progress.

### 8.2 Restaurant Merchant Dashboard (Web KDS)

**Location:** `restaurant-merchant-dashboard/`
**Stack:** Next.js 16.2, React 19, TypeScript, Tailwind CSS 4, shadcn/ui

**Purpose:** Web-based Kitchen Display System — mirrors the kitchen app for browser-based use.

**Key Components:**

| Component | Description | Status |
|-----------|-------------|--------|
| KDS Kanban | 3-column order board | ✓ UI Done |
| Order card | Compact tile with order #, items, timing | ✓ UI Done |
| Detail sheet | Expandable full order detail | ✓ UI Done |
| Daily stats | Revenue, order count, prep time | ✓ UI Done |
| Order history | Filterable past orders | ✓ UI Done |
| Settings | Theme, density, print preferences | ✓ UI Done |
| Sidebar | Navigation, menu reference | ✓ UI Done |
| Header | Restaurant name, online toggle, notifications | ✓ UI Done |

**Status:** All UI built, WebSocket + API integration pending.

---

## 9. Real-Time System

**Technology:** Socket.IO
**Namespace:** `/realtime`
**Auth:** JWT required on connection handshake

### 9.1 Room Architecture

Every connected client is automatically subscribed to relevant rooms based on role:

| Room | Who Joins | Events Received |
|------|-----------|----------------|
| `user:{userId}` | Everyone | Personal notifications |
| `restaurant:{restaurantId}` | Staff, kitchen, admin | All order events |
| `rider:{userId}` | Rider | New assignments |
| `order:{orderId}` | Customer, kitchen, assigned rider | Order lifecycle events |

### 9.2 Events

| Event | Direction | Description |
|-------|-----------|-------------|
| `order:updated` | Server → Client | Order status changed |
| `order:assigned` | Server → Client | Rider matched to order |
| `order:accepted` | Server → Client | Kitchen or rider accepted |
| `order:ready` | Server → Client | Order ready for pickup |
| `order:rejected` | Server → Client | Rider rejected assignment |
| `rider:location` | Server → Client | GPS position update (800ms) |
| `message:new` | Server → Client | New chat message |
| `print:requested` | Server → Kitchen | KOT print request |
| `rider:location` | Rider → Server | GPS broadcast |
| `order:join` | Client → Server | Subscribe to order updates |

### 9.3 Rate Limiting

- Rider GPS broadcast: debounced at **800ms** minimum interval
- Global API: **200 requests/minute** per IP (Redis-backed)

---

## 10. Payment System

### 10.1 bKash Integration (Bangladesh Mobile Payment)

**Flow:**

```
Customer selects "bKash" at checkout
    ↓
App calls POST /payments/online/initiate
    ↓
Backend obtains bKash OAuth token (cached)
    ↓
Backend creates payment → returns bKashURL
    ↓
App opens WebView with bKashURL
    ↓
Customer completes payment in bKash app/web
    ↓
App calls POST /payments/online/confirm with paymentID
    ↓
Backend verifies and records transaction
    ↓
Order proceeds (status updated)
```

**Fallback:** Customer can switch to COD if bKash fails.

### 10.2 Cash on Delivery (COD)

- Rider collects cash from customer
- COD settlement tracked via `CodSettlement` model
- Reconciliation between rider and restaurant

### 10.3 Refund Workflow

```
Customer files complaint / refund request
    ↓
Admin reviews RefundRequest
    ↓
Admin approves → execute payout
    ↓
Refund issued (bKash reversal or wallet credit)
```

### 10.4 Rider Earnings

- Every completed delivery records a `RiderLedgerEntry`
- Entry types: `DELIVERY_EARNED`, `PAYOUT`, `ADJUSTMENT`
- Payout batches generated on configurable schedule
- Rider can view daily/weekly/monthly breakdowns in app

---

## 11. Delivery & Dispatch System

### 11.1 Delivery Fee Calculation

```
Customer enters delivery address
    ↓
App calls POST /delivery-fee/quote
    ↓
Backend checks:
  1. Is address in a delivery zone? (polygon check)
  2. Calculate distance (Mapbox Distance Matrix → Google fallback → Haversine)
  3. Apply fee config:
     - Base fee
     - Per-km fee × distance
     - Peak hour surcharge (if applicable)
     - Free delivery if order ≥ threshold
    ↓
Returns: fee, estimated time, zone name
```

### 11.2 Rider Assignment (Dispatch)

```
Order placed
    ↓
DispatchService triggered
    ↓
Query available riders in zone (online, no active delivery)
    ↓
Sort by: proximity, acceptance rate, exception count
    ↓
Top rider notified (FCM push + WebSocket)
    ↓
Assignment created (status: NOTIFIED)
    ↓
If rider accepts within timeout window:
    → Assignment: ACCEPTED
    → Order: ON_THE_WAY
    → Real-time update to customer
    ↓
If rider rejects or timeout expires:
    → RiderOrderRejection recorded (prevents re-offer during cooldown)
    → Next rider in queue is offered
    → Repeat
    ↓
If no riders available:
    → Admin notified
    → Option to dispatch via Pathao external courier
```

### 11.3 Delivery Exception Flow

```
Rider cannot complete delivery
    ↓
Rider reports exception type (unreachable, wrong address, etc.)
    ↓
Optional: upload photo evidence
    ↓
Admin/staff reviews exception
    ↓
Decision:
  A. Attempt redelivery → create new RiderAssignment
  B. Approve food disposition (discard) → trigger refund
  C. Mark as failed delivery
```

### 11.4 Pathao External Courier Integration

For orders that cannot be fulfilled by in-house riders:

```
Admin clicks "Dispatch External"
    ↓
Backend obtains Pathao OAuth token
    ↓
Creates Pathao order with merchant order ID
    ↓
Pathao assigns their rider
    ↓
Status tracked via Pathao webhook / polling
```

---

## 12. Push Notifications

**Service:** Firebase Cloud Messaging (FCM)
**Conditional Init:** Only activates if `FCM_PROJECT_ID`, `FCM_CLIENT_EMAIL`, `FCM_PRIVATE_KEY` are set in env.

### 12.1 Notification Triggers

| Event | Recipient | Channel |
|-------|-----------|---------|
| New order placed | Kitchen staff | FCM push |
| Order accepted (kitchen) | Customer | FCM push |
| Rider assigned | Customer | FCM push |
| Rider on the way | Customer | FCM push |
| Rider arrived | Customer | FCM push |
| Order delivered | Customer | FCM push |
| Order rejected | Customer | FCM push |
| New assignment | Rider | FCM push |
| Assignment expired | Rider | FCM push |
| Delivery exception | Admin/staff | FCM push |
| Refund approved | Customer | FCM push |

### 12.2 Device Token Management

- All 3 apps register FCM tokens via `POST /devices`
- Tokens stored in `DeviceToken` table (ANDROID / IOS / WEB)
- Stale tokens purged on delivery failure response
- Multi-device support per user

### 12.3 In-App Notifications

- All push events also create a `Notification` record in DB
- Customer app displays notification list with read/unread state
- `PATCH /notifications/:id/read` marks individual notifications read

---

## 13. Third-Party Integrations

| Service | Integration Method | What It Does |
|---------|-------------------|-------------|
| **bKash** | REST API + OAuth token | Mobile payment (Bangladesh) |
| **Pathao Parcel** | REST API + OAuth | External courier dispatch |
| **Mapbox** | SDK + REST API | Maps, geocoding, directions, distance matrix |
| **Google Maps** | REST API | Fallback geocoding + distance matrix |
| **Firebase FCM** | Admin SDK | Push notifications to all platforms |
| **Cloudinary** | SDK + REST API | Image CDN (menu, banners, documents) |
| **Sunmi Printer** | Native Android SDK | Kitchen receipt/KOT printing |
| **Sentry** | SDK | Error tracking (backend + apps) |
| **Prometheus** | HTTP metrics endpoint | System health monitoring |
| **Redis** | Native client | BullMQ queues, rate limiting, token cache |

---

## 14. Database Schema Summary

**ORM:** Prisma
**DB:** PostgreSQL
**Total Models:** 40+

### Core Tables

| Table | Purpose |
|-------|---------|
| `User` | All users (multi-role: CUSTOMER, RIDER, KITCHEN, OWNER, MANAGER, CASHIER, ADMIN) |
| `CustomerProfile` | Customer-specific data |
| `StaffProfile` | Kitchen/restaurant staff data |
| `RiderProfile` | Rider data, approval status, ratings, exception count |
| `Restaurant` | Restaurant entity |
| `Branch` | Multiple branches per restaurant |
| `Order` | Full order record with SLA timestamps |
| `OrderItem` | Line items per order |
| `OrderItemAddon` | Add-ons per line item |
| `OrderStatusHistory` | Audit trail of all status changes |
| `OrderPlacementIdempotency` | Prevent duplicate order submissions |
| `Category` | Menu categories |
| `MenuItem` | Menu items with availability, tags, featured flag |
| `Addon` | Item add-ons |
| `RiderAssignment` | Order-to-rider matching record |
| `RiderLocation` | GPS coordinates, heading, speed |
| `RiderDocument` | Documents for approval (NID, license, etc.) |
| `RiderOrderRejection` | Rejection record with cooldown enforcement |
| `RiderLedgerEntry` | Financial transactions (earnings, payouts) |
| `RiderPayout` | Payout batch records |
| `DeliveryZone` | GIS polygon delivery areas |
| `DeliveryFeeConfig` | Base fee, per-km, peak surcharge, free threshold |
| `DeliveryException` | Delivery failure records |
| `Payment` | Transaction per order (COD/ONLINE/WALLET) |
| `RefundRequest` | Refund workflow with status |
| `CodSettlement` | Cash reconciliation rider ↔ restaurant |
| `Message` | Chat messages (customer ↔ rider) |
| `Notification` | In-app notification log |
| `NotificationLog` | FCM delivery audit |
| `DeviceToken` | FCM push tokens per device |
| `RefreshToken` | JWT refresh token with revocation |
| `OtpCode` | One-time passwords (phone/email) |
| `AuditLog` | Admin action audit trail |
| `Review` | Customer ratings per order |
| `Complaint` | Issue reports |
| `Favorite` | Saved menu items per customer |
| `Address` | Customer delivery addresses |
| `Coupon` | Discount codes with usage tracking |
| `Banner` | Promotional banners with scheduling |
| `Media` | Uploaded image records (Cloudinary) |
| `PrintLog` | Kitchen printer event log |

### Order Status Lifecycle

```
PLACED → ACCEPTED → PREPARING → READY_FOR_PICKUP → ON_THE_WAY → DELIVERED
                                                                     ↑
                                        CANCELLED ←────────────── (any point)
                                        REJECTED  ←────────────── (PLACED)
```

---

## 15. Security & Auth

### JWT Strategy

| Token | Lifetime | Storage |
|-------|---------|---------|
| Access token | Short (15–60 min) | httpOnly cookie + Authorization header |
| Refresh token | Long (30 days) | DB-tracked with revocation |

### Security Layers

| Layer | Implementation |
|-------|---------------|
| Password hashing | bcryptjs |
| Role-based access | `@Roles()` guard on every protected endpoint |
| Rate limiting | 200 req/min per IP (Redis-backed ThrottlerModule) |
| Security headers | Helmet middleware |
| CORS | Configurable whitelist per environment |
| Request tracking | `X-Request-ID` header on all responses |
| OTP expiry | Time-limited one-time codes |
| Token revocation | Refresh tokens tracked in DB; logout invalidates |
| Error reporting | Sentry captures all unhandled exceptions |

---

## 16. Deployment & Configuration

### Environment Variables

```env
# Database
DATABASE_URL=postgresql://user:pass@host:5432/db

# Auth
JWT_ACCESS_SECRET=...
JWT_REFRESH_SECRET=...

# Maps
MAPBOX_ACCESS_TOKEN=...
GOOGLE_MAPS_API_KEY=...

# Payments
BKASH_APP_KEY=...
BKASH_APP_SECRET=...
BKASH_USERNAME=...
BKASH_PASSWORD=...

# External Courier
PATHAO_CLIENT_ID=...
PATHAO_CLIENT_SECRET=...
PATHAO_USERNAME=...
PATHAO_PASSWORD=...

# Firebase (optional — push disabled if absent)
FCM_PROJECT_ID=...
FCM_CLIENT_EMAIL=...
FCM_PRIVATE_KEY=...

# Media
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...

# Queue
REDIS_URL=redis://localhost:6379

# Runtime
NODE_ENV=production
```

### Docker Compose

- **PostgreSQL** — Primary database
- **Redis** — Queue storage, rate-limit counters, bKash token cache

### Dev Auto-Discovery

Mobile apps (customer/rider) auto-detect the backend host on LAN:
- `GET /api/v1/dev/client-config` returns `{ apiBaseUrl, socketUrl }`
- Server logs the LAN IP on startup for easy device testing
- App caches the last working URL in secure storage

---

## 17. Implementation Progress

### Backend
| Area | Progress |
|------|---------|
| Auth & sessions | ✅ Complete |
| User & profile management | ✅ Complete |
| Restaurant & branch management | ✅ Complete |
| Menu (categories, items, add-ons) | ✅ Complete |
| Order lifecycle | ✅ Complete |
| Dispatch & rider assignment | ✅ Complete |
| Delivery fee calculation | ✅ Complete |
| Delivery zones & geocoding | ✅ Complete |
| bKash payment integration | ✅ Complete |
| Pathao external courier | ✅ Complete |
| Rider earnings & ledger | ✅ Complete |
| COD settlement | ✅ Complete |
| Refund workflow | ✅ Complete |
| In-app chat (messages) | ✅ Complete |
| Push notifications (FCM) | ✅ Complete |
| Delivery exception handling | ✅ Complete |
| Reports & analytics | ✅ Complete |
| Image uploads (Cloudinary) | ✅ Complete |
| Kitchen print events | ✅ Complete |
| Real-time (Socket.IO) | ✅ Complete |
| Monitoring (Sentry, Prometheus) | ✅ Complete |
| Wallet payment method | ⚠️ Backend ready, not wired to apps |

### Mobile Apps
| App | Progress |
|-----|---------|
| Customer App | ✅ MVP Feature-Complete |
| Rider App | ✅ MVP Feature-Complete |
| Kitchen App (KDS) | ✅ Pilot-Ready (Phase 5 Complete) |
| Admin App | ✅ Core Features Complete |

### Web Dashboards
| Dashboard | Progress |
|-----------|---------|
| Admin Dashboard UI | ✅ Framework + 100+ components |
| Admin Dashboard API Integration | ⚠️ In Progress |
| Restaurant KDS Web UI | ✅ Framework + all components |
| Restaurant KDS Web API Integration | ⚠️ Pending |

---

## 18. Known Gaps & Next Steps

### Pending Work

| Item | Area | Priority |
|------|------|---------|
| Message + RiderOrderRejection formal DB migration | Backend | High |
| Google Maps migration (Mapbox → Google) | All apps + backend | Medium |
| Wallet payment flows in apps | Customer App | Medium |
| Admin Dashboard API integration | Web | Medium |
| Restaurant KDS Web API integration | Web | Medium |
| Background geolocation optimization | Rider App | Medium |
| Station filtering for KDS | Kitchen App | Low (post-pilot) |
| User IP logging | Backend | Low |
| Sensitive data masking in logs | Backend | Low |

### Deferred Features (Post-Pilot)

- KDS station filtering (prep station vs. packaging)
- Web KDS full parity with Flutter KDS
- Multi-restaurant support (currently single restaurant, multi-branch)
- Analytics dashboard for merchants
- Customer loyalty / points system

---

*Document prepared for internal review. All features listed as "Done" are implemented and tested in development. MVP is ready for pilot deployment.*
