# Tickflow Backend (tick-flow-backend)

Node.js + TypeScript backend for Tickflow, a stock tracker built as a system-design learning project. <5 users. Timebox ~6 weeks total. When realtime + caching + alerts work, STOP — no gold-plating.

Monorepo: this folder (`tick-flow-backend`) and the Flutter client (`tick_flow_frontend`) live together in the `Tickflow` repo. The app talks ONLY to this backend — never to data vendors directly.

## Stack

- Node.js + TypeScript (strict), Fastify
- Postgres + Prisma · Redis (cache + BullMQ queue)
- `ws` for the client-facing WebSocket · Firebase Admin SDK for FCM push
- Vitest for tests · Deploy: Railway/Render/Fly.io · CI: GitHub Actions

## Data sources — who provides what

| Data | Source | Why |
|---|---|---|
| Live streaming ticks (price updates as trades happen) | Finnhub **WebSocket** (free: US stocks, ~50 symbols max) | The realtime feed. This is what `TickSource` wraps. |
| Quote snapshot (current price, day change) | Finnhub REST `/quote` (60 calls/min) | On-demand + polling fallback |
| Symbol search / symbol list | Finnhub REST | Markets tab browse/search |
| Historical candles (charts) | **Financial Modeling Prep** (250 calls/day; free tier = EOD daily bars only via `/stable/historical-price-eod/full` — intraday intervals are 402/paid) | Finnhub candles are paid-tier; FMP covers charts. 1D range degrades to a 7-day daily view |
| Company profile / key stats | Finnhub free endpoints, FMP fallback | Detail view |

Cache candles aggressively (hours, not seconds) — 250 calls/day is tiny. All vendor code lives in `src/infrastructure/` so vendors can be swapped without touching services. Quotes are delayed on free tier — the API response includes a `delayed: true` flag for the app to display.

## TickSource (core abstraction)

A "tick" = one live price update for one symbol. `TickSource` is the interface over wherever ticks come from:

```ts
interface TickSource {
  subscribe(symbol: string): void;
  unsubscribe(symbol: string): void;
  onTick(cb: (tick: { symbol: string; price: number; ts: number }) => void): void;
}
```

Two implementations, selected by env var `TICK_SOURCE`:

- `FinnhubTickSource` (`TICK_SOURCE=finnhub`, PROD): ONE upstream WebSocket to Finnhub. Exponential backoff + jitter on reconnect; resubscribes all active symbols after reconnect.
- `SimulatedTickSource` (`TICK_SOURCE=sim`, DEV/UAT): generates fake ticks via random walk per symbol (configurable interval/volatility, seedable RNG for deterministic tests). Exists because US market hours are 9:30pm–4am MYT — without it the feed is dead during Malaysian daytime and nothing downstream can be developed or demoed.

Everything downstream (cache, fan-out, alerts) consumes `TickSource` and cannot tell which implementation is running.

## Environments

One codebase; behavior switched only by env vars at the composition root (no scattered `if (dev)`).

| | DEV/UAT | PROD (future) |
|---|---|---|
| `TICK_SOURCE` | `sim` | `finnhub` |
| DB/Redis | docker-compose local (or free UAT instance) | separate managed instances |
| Branch → deploy | `develop` → UAT | `main` → prod |
| Firebase project | tickflow-dev | tickflow-prod |

`.env*` gitignored; validate required env at boot with zod, fail fast.

## Architecture: layered

```
src/
  routes/          # Fastify routes: validate (zod), auth guard, call service. No Prisma here.
  services/        # business logic: portfolio math, alert evaluation, subscription manager
  repositories/    # Prisma/Redis access only
  infrastructure/  # FinnhubTickSource, SimulatedTickSource, FMP client, FCM, BullMQ workers
  ws/              # client-facing WebSocket server (auth, subscriptions, fan-out)
```

Services never import Fastify types; all business logic unit-testable without HTTP.

## System design requirements

### Quote cache
Latest quote per symbol in Redis, TTL 5–15s (fundamentals: minutes–hours; candles: hours). Client request → serve cache; miss/expired → ONE upstream fetch serves all users. This decouples client request rate from upstream quota.

### Client-facing WebSocket + auth
- Client must send `{"type":"auth","token":"<JWT>"}` as the FIRST message within 5s of connecting. Same JWT as REST. Invalid/timeout → close with code 4401. No subscriptions before auth.
- Then `{"type":"subscribe","symbols":[...]}` / `{"type":"unsubscribe","symbols":[...]}`.
- Server pushes `{"type":"tick","symbol","price","ts"}` only for symbols that client subscribed to (pub/sub routing).
- Never accept the token via URL query string (gets logged).

### Subscription manager — the 50-symbol cap
Finnhub free WS allows ~50 concurrently streamed symbols; the union of all connected clients' subscriptions can exceed that. This does NOT limit how many stocks users can view — it limits how many get push-streamed live at once.

- Redis refcount per symbol (`symbol → # of subscribed clients`) + last-touched timestamp.
- Refcount 0→1: subscribe upstream. 1→0: unsubscribe.
- At cap when a new symbol is needed: evict the lowest-refcount symbol (tie-break: least recently touched).
- Evicted/overflow symbols fall back to REST polling every 15–30s (within 60/min budget) and flow through the SAME cache → fan-out path. Clients see slower updates, identical message shape.
- Alerts on polled symbols are evaluated on polled quotes.

### Alert engine

```
ACTIVE ──condition met──► TRIGGERED ──► enqueue notification job (BullMQ) ──► FCM + in-app feed
  ▲                          │
  │ re-arm: after hysteresis ├─ one_shot → DONE (kept for history)
  │ (price retreats ≥0.5%    └─ re_arm  → COOLDOWN
  │  past threshold) or 15-min cooldown
  └──────────────────────────────┘
```

- Postgres row: `id, user_id, symbol, rule(type, threshold), kind(one_shot|re_arm), status, trigger_count, last_triggered_at`.
- Idempotency: BullMQ job ID = `alert-{id}-trigger-{trigger_count}` (BullMQ forbids `:` in job ids) — duplicate evaluation can't double-send.
- Status transition + enqueue atomic (transaction/check-and-set).
- Evaluation runs on every tick (streamed or polled).

### Resilience
Upstream down/rate-limited → keep serving cached data with `stale: true`, never crash. Backoff + jitter on reconnects.

## REST API surface (target)

```
POST /auth/register | /auth/login | /auth/google     → JWT
GET  /symbols/search?q=
GET  /symbols?page=                                   (US symbol list, paginated)
GET  /quotes?symbols=AAPL,TSLA                        (batched, cache-backed)
GET  /symbols/:symbol/candles?range=1D|1W|1M|1Y       (FMP-backed, heavily cached)
GET  /symbols/:symbol/profile
GET/POST/DELETE /watchlist                            (favourites)
GET/POST/PUT/DELETE /portfolio/holdings               (symbol, qty, buyPrice, assetType)
PUT  /portfolio/holdings/reorder                      ({order:[id,…]} — manual sort via Holding.position, new lots to bottom)
GET  /portfolio/summary                               (valuation, gain/loss, allocation)
GET/POST/PUT/DELETE /alerts
GET  /notifications                                   (triggered-alert feed)
WS   /ws                                              (auth → subscribe → ticks)
```

## Build order

1. Fastify skeleton + layered structure + docker-compose (Postgres+Redis) + Finnhub REST client + Redis quote cache + `SimulatedTickSource` + search/quote endpoints.
2. Auth (JWT, email + Google) + Prisma schema + watchlist/portfolio CRUD + portfolio math service (unit tests first).
3. Client WS server (auth, subscribe) + subscription manager (50-cap) + `FinnhubTickSource` + fan-out.
4. Alert engine + state machine + BullMQ + FCM + notifications feed endpoint.
5. Candles via FMP + caching + resilience polish (stale flags, backoff).
6. Test coverage, GitHub Actions (lint/test on PR; develop→UAT, main→prod deploy), README, deploy.

## Conventions

- TS strict; no `any` in services/repositories.
- Alert evaluation + portfolio math: tests required BEFORE marking done (Vitest).
- Conventional commits. Secrets via env only.
- Prefer the simpler option — learning project, not a product.

## Commands (once scaffolded)

```bash
docker compose up -d        # Postgres + Redis
npm run dev                 # TICK_SOURCE=sim
npm test                    # vitest
npx prisma migrate dev
```
