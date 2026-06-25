# Tickflow

Realtime US stock tracker built as a system-design learning project. Monorepo:

| Folder | What |
|---|---|
| [`tick-flow-backend/`](tick-flow-backend/) | Node.js + TypeScript backend (Fastify, Postgres + Prisma, Redis, BullMQ, `ws`) |
| [`tick_flow_frontend/`](tick_flow_frontend/) | Flutter client (Riverpod MVVM) — talks only to the backend, never to data vendors |

## What the backend does

- **Live prices** over a client-facing WebSocket (`/ws`): JWT auth as the first message, then subscribe/unsubscribe per symbol. One upstream Finnhub WebSocket serves all clients; a subscription manager enforces Finnhub's ~50-symbol cap with refcounting, eviction, and REST-polling fallback — clients can't tell the difference.
- **Quote/candle/profile REST API**, aggressively cached in Redis so client request rate is decoupled from vendor quotas (Finnhub 60 calls/min, FMP 250 calls/day). Upstream down → cached data served with `stale: true`, never a crash.
- **Price alerts**: evaluated on every tick, atomic check-and-set triggering (no double-fires), one-shot or re-arming with hysteresis/cooldown, plus pause/resume (paused alerts drop out of evaluation), delivered via BullMQ → in-app feed + FCM push with idempotent job IDs.
- **Auth** (email/password + Google ID token → JWT), watchlist, portfolio with valuation math (cost basis, gain/loss, allocation), and account deletion (cascades all user data).

`TICK_SOURCE=sim` runs a seedable random-walk tick generator so everything works outside US market hours (9:30pm–4am MYT).

## What the frontend does

Flutter app (web-first), five tabs plus a pushed stock-detail screen:

- **Markets** — a movers dashboard: inline search, an index overview carousel, and Top gainers / losers / most active tabs (ranked from a cached universe-quotes snapshot); live ticks for on-screen rows only.
- **Favourites** — watchlist with live prices, day change, and sparklines.
- **Portfolio** — holdings CRUD (symbol, qty, buy price, asset type); total value, gain/loss, and an allocation donut — all valuation comes from the backend's `/portfolio/summary`, never recomputed client-side. A pushed Analytics screen adds an estimated value series, top contributors, and asset mix.
- **Notifications** — price alerts as cards (above/below, one-shot or re-arm) with a pause/resume toggle and inline delete, plus the triggered-alert feed.
- **Menu** — sectioned settings: account details, subscriptions (coming-soon Pro preview), appearance (system / light / dark) and language (English / 中文), change password, biometric unlock (mobile), a push-notification toggle, Help & Support, and delete account.
- **Stock detail** — candlestick chart (1D/1W/1M/1Y), company profile, live price.

Live prices stream over the backend WebSocket; `delayed`/`stale` hints surface the backend's data-quality flags. Auth is email/password → JWT in secure storage (expired token → re-login). State is Riverpod (MVVM); viewmodels are unit-tested. The whole app is localized in English and 中文 (Flutter gen-l10n), and company logos are disk-cached for instant reloads.

## Run locally

### Backend

```bash
cd tick-flow-backend
cp .env.example .env        # fill in keys (see comments in the file)
docker compose up -d        # Postgres 17 + Redis 7
npm ci
npx prisma migrate dev
npm run dev                 # http://localhost:3000, WS on /ws

npm test                    # vitest (114 tests)
npm run lint                # eslint (type-aware)
npm run typecheck           # tsc --noEmit, includes tests
```

### Frontend

```bash
cd tick_flow_frontend
flutter pub get
# Against always-on staging (simulated ticks, works 24/7):
flutter run -d chrome --dart-define=API_URL=https://tickflow-staging.up.railway.app
flutter analyze && flutter test   # 72 tests
```

The API base URL is passed at build time via `--dart-define=API_URL=...` (the WebSocket URL is derived from it). A staging test account `kai@tickflow.dev` exists, or register a new one.

## Environments, branches & deploy

- `develop` → **staging** on Railway (always on, `TICK_SOURCE=sim` so the live feed works 24/7). This is the only running environment on the current plan; `main` is a milestone/release branch and does **not** auto-deploy anywhere.
- GitHub Actions runs lint + typecheck + tests + build on every PR and push.
- **Backend deploy:** Railway, service root `tick-flow-backend/`.
- **Frontend deploy:** `flutter build web --release --dart-define=API_URL=<url>` then `firebase deploy --only hosting` (config in [`tick_flow_frontend/firebase.json`](tick_flow_frontend/firebase.json)).
