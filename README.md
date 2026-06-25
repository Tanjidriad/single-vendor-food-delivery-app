# Food Delivery Platform

Single-restaurant food delivery system with 3 Flutter apps (planned) and a NestJS backend.

## Backend (implemented — Phase 1 core)

Location: [`backend/`](backend/)

- NestJS 11 + PostgreSQL (Prisma) + JWT + Socket.IO
- Auth, menu, orders, delivery fee, dispatch, devices, notifications
- Swagger docs at `/api/docs` (development only)
- Full API reference: [`docs/api/API_DOCUMENTATION.md`](docs/api/API_DOCUMENTATION.md)

**Quick start:** see [`docs/SETUP.md`](docs/SETUP.md)

## Project layout

```
Food_delivery/
  backend/          # NestJS API
  infra/            # Docker Compose (PostgreSQL)
  docs/             # Setup, API samples
  apps/
    customer_app/   # Flutter customer app (clean architecture)
```

## Demo credentials (after seed)

| Role | Login | Password |
|------|-------|----------|
| Owner | owner@demokitchen.com | Password123! |
| Customer | customer@example.com | Password123! |
| Rider | +8801700000002 | Password123! |
