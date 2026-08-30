# Customer Web WASABI Menu Seed

Date: 2026-08-13 (revalidated 2026-08-14)

## Purpose

The customer web app currently defaults to the `wasabi` restaurant slug. The backend seed now creates repeat-safe WASABI storefront data so the web menu can be tested immediately from `http://localhost:3001/menu`.

## Changed File

- `backend/prisma/seed.ts`
- `customer-web/next.config.ts`

## Seeded Data

- Restaurant slug: `wasabi`
- Categories: `Regular Momo`, `Momocola`, `Premium Momo`, `Drinks`
- Menu items: 10
- Featured items: 5
- Banners: 3
- Add-ons: 6 sauce/topping add-ons, attached to momo items
- Storefront settings: tax, packaging fee, delivery fee config, and daily operating hours

## Test Command

```powershell
cd C:\Users\riads\Desktop\Food_delivery\backend
npm run db:seed
```

## Verified API Calls

```text
GET /api/v1/restaurant/slug/wasabi
GET /api/v1/menu/restaurant/:restaurantId
GET /api/v1/menu/restaurant/:restaurantId/featured
GET /api/v1/menu/restaurant/:restaurantId/banners
```

Expected result after seed:

- 4 active categories
- 10 available menu items
- 5 featured menu items
- 3 active banners

## Notes

- The existing `demo-kitchen` seed remains unchanged for the Flutter customer app path.
- WASABI seed IDs are stable and use `upsert`, so running the seed multiple times should not create duplicate WASABI categories, menu items, add-ons, or banners.
- Seeded food images currently use `images.unsplash.com`. That hostname is allowed in both the Next.js image optimizer `remotePatterns` and the Content Security Policy `img-src` list.
- Three original Unsplash photo identifiers returned HTTP 404 during live browser QA. They were replaced with HTTP-200-verified food photos and the repeat-safe seed was run again.
- When `next.config.ts` changes during local development, restart `npm run dev` if Next.js does not restart automatically.

## Image Error Fix

Resolved the menu crash:

```text
Invalid src prop ... hostname "images.unsplash.com" is not configured under images
```

The fix keeps `next/image` optimization enabled and explicitly allows only the required HTTPS Unsplash image hostname.

## 2026-08-14 Revalidation

- `npm run db:seed`: passed.
- WASABI seed result: 4 categories, 10 menu items, 5 featured items, and 3 banners.
- Live menu browser test: no unexpected image 4xx response remained.
