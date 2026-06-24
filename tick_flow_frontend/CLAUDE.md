# Tickflow App (tick_flow_frontend)

Flutter client for Tickflow, a stock tracker (system-design learning project, <5 users).
Deploy: Flutter **web first** (Vercel/Firebase Hosting), Android/Play Store later.
Timebox: the remaining share of a ~6-week project — always prefer the simplest option.

Monorepo sibling: `tick-flow-backend/` — complete, deployed, documented in its own CLAUDE.md.
The app talks ONLY to this backend (REST + WS). Never call Finnhub/FMP directly, never embed
vendor API keys in the app.

## Environments

| Env | REST | WebSocket |
|---|---|---|
| Local | `http://localhost:3000` (`docker compose up -d` + `npm run dev` in tick-flow-backend) | `ws://localhost:3000/ws` |
| Staging (Railway, `develop` branch, always on) | `https://tickflow-staging.up.railway.app` | `wss://tickflow-staging.up.railway.app/ws` |

- Staging runs `TICK_SOURCE=sim` (random-walk ticks), so the live feed works 24/7 — including
  Malaysian daytime when US markets are closed. Staging test account: `kai@tickflow.dev`
  (Kai has the password).
- Railway (trial plan) runs ONE environment only — this staging. There is no prod deployment
  and none should be created (3-volume cap + limited credit). `main` deploys nowhere; it is a
  milestone marker.
- The backend serves CORS allow-all (required for Flutter web).
- The API base URL comes from `--dart-define=API_URL=...`, read once in `core/env.dart`
  (WS URL is derived from it: `http→ws`, `https→wss`, path `/ws`). Never hardcode URLs.

## Backend contract (condensed — backend internals live in ../tick-flow-backend/CLAUDE.md)

### Auth
- `POST /auth/register` / `POST /auth/login` body `{email, password(≥8)}` → `201/200 {token, user:{id,email,name,pushEnabled,hasPassword}}`
- `POST /auth/google` `{idToken}` → 503 until GOOGLE_CLIENT_ID is configured server-side
  (it currently isn't) — v1 auth is email/password only.
- Protected routes: header `Authorization: Bearer <token>`. JWT expires in 7d — on 401, re-login.
- `GET/PATCH /auth/me` (Bearer) → user profile. `PATCH {name?, pushEnabled?}` is a true partial
  update (omit a field = leave untouched; empty `name` clears it). `hasPassword` is read-only
  (false for Google-only accounts).
- `POST /auth/change-password` (Bearer) `{currentPassword, newPassword(≥8)}` → verifies the
  current password (401 if wrong, 409 for Google-only accounts with no password).
- `DELETE /auth/me` (Bearer) → 204 — deletes the account and all its data (watchlist,
  portfolio, alerts, notifications). The Menu's "Delete account" uses it.
- Errors are always `{error: string}` with proper status codes (400/401/404/409/502/503).

### REST
Public (market data):
- `GET /symbols/search?q=` → `{results:[{symbol,displaySymbol,description,type}]}`
- `GET /symbols?page=` → `{symbols:[...], page, pageSize:50, total, stale}`
- `GET /symbols/:symbol/profile` → `{symbol,name,exchange,currency,country,marketCap,ipo,logo,website,industry,stale}` (404 unknown)
- `GET /quotes?symbols=AAPL,TSLA` (≤50) → `{quotes:[{symbol,price,change,changePercent,high,low,open,prevClose,ts,stale,delayed}]}` — unknown symbols simply absent
- `GET /symbols/:symbol/candles?range=1D|1W|1M|1Y` → `{symbol,range,stale,candles:[{t,o,h,l,c,v}]}`

Authed (Bearer):
- `GET/POST /watchlist` (`{symbol}`), `DELETE /watchlist/:symbol` — add/remove idempotent
- `GET/POST /portfolio/holdings` (`{symbol, qty, buyPrice, assetType?: stock|etf|crypto}`), `PUT/DELETE /portfolio/holdings/:id`
- `PUT /portfolio/holdings/reorder` (`{order:[id,…]}`) → 204 — saves the user's manual order (server-side `position`). New holdings sort to the bottom; `/summary` & `/holdings` return rows in this order.
- `GET /portfolio/summary` → holdings each with `{costBasis, price, marketValue, gainLoss, gainLossPercent}` (nulls when unpriced) + `{totalValue, totalCost, totalGainLoss, totalGainLossPercent, allocation:[{symbol,value,percent}], incomplete}`
- `GET/POST /alerts` (`{symbol, ruleType: price_above|price_below, threshold, kind?: one_shot|re_arm}`), `PUT /alerts/:id` (`{threshold?, kind?, status?: 'active'|'paused'}` — `active` re-arms/resumes, `paused` pauses; the engine owns `cooldown`/`done`), `DELETE /alerts/:id`
- `GET /notifications` → `{notifications:[{id,symbol,message,price,createdAt}]}` (triggered alerts, newest first)
- `POST /devices` `{token}` → 204 — send the FCM token after login (FCM phase only)

### WebSocket (live ticks)
1. Connect to `/ws`. Send `{"type":"auth","token":"<JWT>"}` as the FIRST message within 5s,
   or the server closes with code 4401. Never put the token in the URL.
2. On `{"type":"auth_ok"}` send `{"type":"subscribe","symbols":[...]}` (also `unsubscribe`).
   Server acks `{"type":"subscribed","symbols":[...]}` (full current set).
3. Receive `{"type":"tick","symbol","price","ts"}` only for subscribed symbols. Some symbols
   update every few seconds instead of live (server-side 50-symbol cap fallback) — same shape,
   just slower; the UI needs no special handling.

### Contract-driven UI rules
- `delayed: true` on quotes (free data tier) → show a small "delayed" badge near prices. Never hide it.
- `stale: true` anywhere → data is cached because the vendor is down; show subtly
  (e.g. greyed timestamp), don't error.
- Money to 2dp; `gainLossPercent` may be null (zero-cost lots) — render as "—".
- Candles: ALL ranges return DAILY bars (FMP free tier); `1D` = last ~7 days of daily bars.

## Stack

- Flutter + **Riverpod** (plain `Notifier`/`AsyncNotifier`, no codegen/build_runner) — MVVM
- **go_router** (auth redirect + `StatefulShellRoute` tabs) · **dio** (REST) · **web_socket_channel** (ticks)
- **fl_chart** ≥1.2 — CandlestickChart (detail), LineChart (sparklines), PieChart (allocation donut)
- **flutter_secure_storage** (JWT) · **shared_preferences** (theme, small prefs) · **intl** (money/date) · **google_fonts**
- **local_auth** — optional biometric app-lock (Menu → Security). Mobile only (needs
  `FlutterFragmentActivity` + `minSdk 23` on Android, `NSFaceIDUsageDescription` on iOS);
  auto-hidden on web.
- **cached_network_image** — company logos with an on-device disk cache + letter-avatar fallback
  (shared `core/widgets/symbol_logo.dart`); used by Markets/Favourites/Portfolio/Alerts rows.
- **flutter_localizations** + Flutter **gen-l10n** — full **English + 中文** localization. ARBs in
  `lib/l10n` (`app_en.arb`/`app_zh.arb`); the generated `AppLocalizations*.dart` are **committed**.
- Deferred, NOT in v1: **Drift** offline cache (needs sqlite3 WASM setup on web — add only after
  all tabs work online) · **firebase_messaging** (web push unreliable, Notifications tab is the
  reliable path; Firebase project: tickflow-dev)

## Architecture: MVVM with Riverpod

- **Model:** DTOs + repositories (`lib/data/`) — dio client, WS client. Repositories own all I/O.
- **ViewModel:** Riverpod `Notifier`/`AsyncNotifier` per feature (`lib/features/<f>/viewmodel/`) —
  ALL state & logic here, unit-testable with fake repositories (no widgets).
- **View:** widgets (`lib/features/<f>/view/`) only render state and forward events.
  No business logic, no API calls in widgets.

```
lib/
  core/            # env, theme, router, formatting, locale (i18n), biometric lock, widgets/
  data/            # api client, ws client, repositories, DTOs
  l10n/            # ARBs (app_en.arb / app_zh.arb) + generated AppLocalizations (committed)
  features/
    auth/          # login/register
    markets/       # view/ + viewmodel/ (same split in every feature)
    favourites/
    portfolio/
    notifications/
    menu/
    symbol_detail/ # pushed from any tab
```

## Navigation: 5 tabs + pushed screens

`[ Markets ] [ Favourites ] [ Portfolio ] [ Notifications ] [ Menu ]`

Unauthed users land on Login (email/password, register toggle). All tabs require auth.

### 1. Markets — a fintech dashboard (`moversProvider`)
- Inline **search bar** → the `/search` screen (backed by `/symbols/search`).
- **Overview carousel** of index/benchmark cards (price + day change + mini-sparkline).
- **Top gainers / losers / most active** tabs, ranked from a one-shot universe-quotes snapshot
  (`moversProvider`) that also primes the quote cache so tab switches render instantly.
- Row: company logo, symbol, name, price, day change % (green/red), star to favourite. Tap → Symbol Detail.
- The old paginated `/symbols` browse is parked (commented out), not deleted.

### 2. Favourites (watchlist)
- Starred symbols via `/watchlist`. Live price, day change %, sparkline (LineChart of 1M daily closes).
- Subscribes to all favourites while the tab is visible. Swipe to remove. Tap → Symbol Detail.

### 3. Portfolio
- Manual entry per holding: symbol, qty, **buy price** (cost basis — always user-entered),
  assetType `stock|etf|crypto`. All are live-priced by the backend.
- ALL valuation comes from `/portfolio/summary` — the app NEVER recomputes portfolio math.
- Donut (PieChart) of allocation, toggle by holding / by asset type. Totals + per-position
  gain/loss. USD only. Unpriced holdings → "—" + a subtle banner when `incomplete: true`.
- **Analytics** screen (`/analytics`, pushed): estimated value series (from daily closes), top
  contributors, asset mix — crypto/feed-uncovered ETFs are excluded from the series (a caveat banner).

### 4. Notifications
- **My Alerts**: card rows (company logo, status badge active/cooldown/done/paused, rule + live
  "now" price). A **pause/resume toggle** (`status: active ↔ paused`) and an **inline delete**
  (confirm dialog). Tap a card to edit; create → `POST /alerts`.
- **Triggered feed**: history from `/notifications`, newest first, pull-to-refresh
  (the reliable path on web; FCM push comes later, if at all).

### 5. Menu — sectioned settings (profile card + grouped cards)
- Profile card: avatar initials + display `name` (falls back to email when unset) + email.
- **Account**: **Account details** (`/account`) — edit display `name` via `PATCH /auth/me` ·
  **Subscriptions** (`/plans`, value "Free") — a display-only Free-vs-Pro "coming soon" preview,
  no purchase flow.
- **Preferences**: **Appearance** (System / Light / Dark) · **Language** (English / 中文, default
  English) — both persisted in shared_preferences.
- **Security** (section shown only when a row applies): **Change password** (`/change-password` →
  `POST /auth/change-password`; hidden when `hasPassword` is false — Google-only) · **Biometric
  unlock** toggle (mobile only, hidden on web) — a `local_auth` lock (`core/biometric_lock.dart`)
  on cold launch and after ~30s backgrounded.
- **Notifications**: **Push notifications** toggle (`pushEnabled` via `PATCH /auth/me`). When off,
  FCM push is muted but the in-app Notifications feed still receives entries.
- **Support**: **Help & Support** (`/help` — FAQs, contact `support@tickflow.my`, "live chat" is a
  disabled coming-soon) · **About** (dialog: version, "Market data via Finnhub/FMP — quotes delayed
  on the free tier", `showLicensePage`).
- Sign out (wipe token → login) · Delete account (`DELETE /auth/me`, behind a confirm dialog).
- Optional (debug builds only): current API_URL + WS connection status row.

### Symbol Detail (pushed, not a tab)
- Candlestick chart (fl_chart CandlestickChart) with 1D/1W/1M/1Y range selector — remember all
  ranges are daily bars, 1D ≈ last week.
- Live price header (WS tick), day change, company profile (`/profile`), key stats from the quote.
- Shortcuts: star, "create alert", "add to portfolio".

## Realtime client behavior

- ONE WS service app-wide. Desired-symbols set lives in a Riverpod provider; screens add/remove
  symbols, the service diffs and sends subscribe/unsubscribe.
- Reconnect with exponential backoff + jitter; after reconnect re-auth then resubscribe the full set.
- 4401 / auth failure mid-session → token expired → clear token, route to login.

## Future work (needs backend changes FIRST — do not build UI for these speculatively)

- "% move" alert rules (backend supports `price_above|price_below` only).
- Manual-valued assets (bonds/FDs where the user enters the CURRENT value because no feed
  prices them) — backend has no `manual` assetType and prices everything itself.
- Google sign-in (server returns 503 until GOOGLE_CLIENT_ID is set).
- Drift offline cache; FCM push via `/devices` (see Stack).

## Build order

1. ✅ Foundation: deps, env, theme, router, auth (login/register + token storage), 5-tab shell.
2. ✅ Markets: symbol list + search + visible-row quotes; Symbol Detail (profile + candles chart).
3. ✅ WS tick service + live prices on Markets/Detail; Favourites tab (watchlist + sparklines).
4. ✅ Portfolio (holdings CRUD + summary + donut).
5. ✅ Alerts + Notifications feed.
6. ✅ Polish (delayed/stale badges, empty/error states, REST 401 → login) + web deploy
   readiness (Firebase Hosting). Optional extras (FCM, Drift) remain, only if time allows.
7. ✅ Post-v1: full i18n (English + 中文); redesigns (Markets movers dashboard, sectioned Menu,
   card-style Alerts); pause/resume alerts (`paused` status); disk-cached company logos;
   Help & Support + Subscriptions (display-only coming-soon).

## Conventions

- One feature folder per tab; cross-feature imports only via `data/` or `core/`.
- ViewModels get unit tests (fake repositories). Portfolio/alerts widgets get widget tests if time allows.
- No business logic in widgets. Conventional commits. Prefer the simpler option — learning project.
- **i18n**: every user-facing string is localized — add new keys to BOTH `lib/l10n/app_en.arb` and
  `app_zh.arb`, then `flutter gen-l10n` (generated `AppLocalizations*.dart` are committed). Enums
  can't read `BuildContext`, so localize their labels via view-helper `switch` functions.
- One feature per commit AND push (Kai's rule — never bundle features). Features land on `develop`;
  at phase milestones merge `develop`→`main` via PR with a MERGE COMMIT (never squash — squashing
  collapses Kai's contribution history).

## Commands

```bash
flutter run -d chrome --dart-define=API_URL=https://tickflow-staging.up.railway.app  # against staging
flutter run -d chrome --dart-define=API_URL=http://localhost:3000                    # against local backend
flutter analyze && flutter test
flutter build web --release --dart-define=API_URL=<url>
firebase deploy --only hosting   # after build; config in firebase.json, project tickflow-dev
```
