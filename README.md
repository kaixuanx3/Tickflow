# Tickflow

Realtime stock tracker built as a system-design learning project. Monorepo:

| Folder | What |
|---|---|
| [`tick-flow-backend/`](tick-flow-backend/) | Node.js + TypeScript backend (Fastify, Postgres + Prisma, Redis, BullMQ, `ws`) |
| [`tick_flow_frontend/`](tick_flow_frontend/) | Flutter client (talks only to the backend, never to data vendors) |

## What the backend does

- **Live prices** over a client-facing WebSocket (`/ws`): JWT auth as the first message, then subscribe/unsubscribe per symbol. One upstream Finnhub WebSocket serves all clients; a subscription manager enforces Finnhub's ~50-symbol cap with refcounting, eviction, and REST-polling fallback — clients can't tell the difference.
- **Quote/candle/profile REST API**, aggressively cached in Redis so client request rate is decoupled from vendor quotas (Finnhub 60 calls/min, FMP 250 calls/day). Upstream down → cached data served with `stale: true`, never a crash.
- **Price alerts**: evaluated on every tick, atomic check-and-set triggering (no double-fires), one-shot or re-arming with hysteresis/cooldown, delivered via BullMQ → in-app feed + FCM push with idempotent job IDs.
- **Auth** (email/password + Google ID token → JWT), watchlist, portfolio with valuation math (cost basis, gain/loss, allocation).

`TICK_SOURCE=sim` runs a seedable random-walk tick generator so everything works outside US market hours (9:30pm–4am MYT).

## Run locally

```bash
cd tick-flow-backend
cp .env.example .env        # fill in keys (see comments in the file)
docker compose up -d        # Postgres 17 + Redis 7
npm ci
npx prisma migrate dev
npm run dev                 # http://localhost:3000, WS on /ws
```

```bash
npm test                    # vitest (94 tests)
npm run lint                # eslint (type-aware)
npm run typecheck           # tsc --noEmit, includes tests
```

## Branches & CI

- `develop` → UAT/staging, `main` → production.
- GitHub Actions runs lint + typecheck + tests + build on every PR and push.
- Deploys on Railway track the connected branch per environment; the service root is `tick-flow-backend/`.
