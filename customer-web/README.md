# Wasabi customer web

Mobile-first Next.js storefront for customer acquisition before the Flutter customer app launch. It uses the existing NestJS API for menu, account, checkout, payment and order tracking.

The complete implementation change record, affected areas, verification evidence, and remaining production checks are documented in [`docs/CUSTOMER_WEB_COMPLETION_CHANGES.md`](docs/CUSTOMER_WEB_COMPLETION_CHANGES.md).

## Local development

1. Copy `.env.example` to `.env.local` and set `BACKEND_API_URL` to the Nest API including `/api/v1`.
2. Run `npm ci`.
3. Run `npm run dev` and open `http://localhost:3001`.

The browser talks only to the same-origin `/api/backend` proxy. Access and refresh tokens are stored as `HttpOnly`, `SameSite=Lax` cookies and are never persisted in browser JavaScript storage.

## Production environment

- `BACKEND_API_URL`: server-only API URL including `/api/v1`.
- `NEXT_PUBLIC_SITE_URL`: final HTTPS customer website origin.
- `NEXT_PUBLIC_SOCKET_URL`: public Socket.IO origin.
- `NEXT_PUBLIC_RESTAURANT_SLUG` or `NEXT_PUBLIC_RESTAURANT_ID`: storefront identity.
- `NEXT_PUBLIC_IMAGE_ORIGIN`: optional additional HTTPS image host.
- `NEXT_PUBLIC_GA_ID`: optional GA4 ID; analytics is disabled when omitted and respects browser Do Not Track.

Set backend `BKASH_CALLBACK_URL` to `${NEXT_PUBLIC_SITE_URL}/payment/callback`. Production callbacks must use HTTPS. Configure the exact customer origin in backend CORS settings as well.

## Verification

```bash
npm run lint
npm test
npm run build
npm audit --audit-level=high
npm run test:e2e
```

Playwright tests exercise mobile and desktop browsers through the real same-origin BFF with a deterministic mock backend and mock bKash page. A successful run does not replace a sandbox/production bKash transaction, SMS delivery test or deployment smoke test.

## Container

The included multi-stage `Dockerfile` builds the Next.js standalone server on port `3001` and exposes `/api/health` for platform health checks. Public `NEXT_PUBLIC_*` values must be provided at image build time; `BACKEND_API_URL` remains a runtime server secret.
