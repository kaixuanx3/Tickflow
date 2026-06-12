# Tickflow App (tick_flow_frontend)

Flutter client for Tickflow, a stock tracker (system-design learning project, <5 users).
Monorepo sibling: `tick-flow-backend/` — the app talks ONLY to this backend, never to data
vendors. The backend is COMPLETE and deployed; do not change it from this project.

## Backends

| Env | REST | WebSocket |
|---|---|---|
| Local | `http://localhost:3000` (run `npm run dev` in tick-flow-backend; needs `docker compose up -d`) | `ws://localhost:3000/ws` |
| Staging (Railway, develop branch, always on) | `https://tickflow-staging.up.railway.app` | `wss://tickflow-staging.up.railway.app/ws` |

Staging uses `TICK_SOURCE=sim` (simulated random-walk ticks), so the live feed works 24/7 —
including Malaysian daytime when US markets are closed. A test account `kai@tickflow.dev`
exists on staging (Kai has the password).

## Auth

- `POST /auth/register` / `POST /auth/login` body `{email, password(≥8)}` → `201/200 {token, user:{id,email}}`
- `POST /auth/google` body `{idToken}` (from google_sign_in) → same shape; 503 until GOOGLE_CLIENT_ID configured server-side
- All protected routes: header `Authorization: Bearer <token>`. JWT expires in 7d — on 401, re-login.
- Errors are always `{error: string}` with proper status codes (400/401/404/409/502/503).

## REST endpoints

Public (market data):
- `GET /symbols/search?q=` → `{results:[{symbol,displaySymbol,description,type}]}`
- `GET /symbols?page=` → `{symbols:[...], page, pageSize:50, total, stale}`
- `GET /symbols/:symbol/profile` → `{symbol,name,exchange,currency,country,marketCap,ipo,logo,website,industry,stale}` (404 unknown)
- `GET /quotes?symbols=AAPL,TSLA` (≤50) → `{quotes:[{symbol,price,change,changePercent,high,low,open,prevClose,ts,stale,delayed}]}` — unknown symbols simply absent
- `GET /symbols/:symbol/candles?range=1D|1W|1M|1Y` → `{symbol,range,stale,candles:[{t,o,h,l,c,v}]}` — ALL ranges are DAILY bars (FMP free tier); 1D = last 7 days

Authed (Bearer):
- `GET/POST /watchlist` (`{symbol}`), `DELETE /watchlist/:symbol` — add/remove idempotent
- `GET/POST /portfolio/holdings` (`{symbol, qty, buyPrice, assetType?: stock|etf|crypto}`), `PUT/DELETE /portfolio/holdings/:id`
- `GET /portfolio/summary` → holdings each with `{costBasis, price, marketValue, gainLoss, gainLossPercent}` (nulls when unpriced) + `{totalValue, totalCost, totalGainLoss, totalGainLossPercent, allocation:[{symbol,value,percent}], incomplete}`
- `GET/POST /alerts` (`{symbol, ruleType: price_above|price_below, threshold, kind?: one_shot|re_arm}`), `PUT /alerts/:id` (`{threshold?, kind?, status?: 'active'}` re-arm only), `DELETE /alerts/:id`
- `GET /notifications` → `{notifications:[{id,symbol,message,price,createdAt}]}` (triggered alerts, newest first)
- `POST /devices` `{token}` → 204 — send the FCM token from firebase_messaging after login

## WebSocket protocol (live ticks)

1. Connect to `/ws`. Send `{"type":"auth","token":"<JWT>"}` as the FIRST message within 5s,
   or the server closes with code 4401. Never put the token in the URL.
2. On `{"type":"auth_ok"}` send `{"type":"subscribe","symbols":["AAPL","TSLA"]}` (also `unsubscribe`).
   Server acks with `{"type":"subscribed","symbols":[...]}` (full current set).
3. Receive `{"type":"tick","symbol","price","ts"}` only for subscribed symbols. Some symbols
   update every few seconds instead of live (server-side 50-symbol cap fallback) — same shape,
   just slower; the UI needs no special handling.
4. Reconnect with backoff on close; re-auth + re-subscribe after reconnect.

## UI requirements from the backend contract

- `delayed: true` on quotes (free data tier) — show a "delayed" hint on price displays.
- `stale: true` anywhere — data is from cache because the vendor is down; show subtly (e.g. greyed timestamp), don't error.
- Money to 2dp; gainLossPercent may be null (zero-cost lots) — render as "—".

## Conventions

- Timebox: this is the remaining share of a ~6-week project — prefer the simplest option.
- Current state: bare `flutter create` scaffold (counter app) — everything is to be built.
- Target tabs per the original plan: Watchlist (favourites + live prices), Markets (browse/search),
  Portfolio (holdings + summary), Alerts (+ notifications feed), stock detail with candle chart.
- Firebase project for FCM: tickflow-dev (Kai owns it).
