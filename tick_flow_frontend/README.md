# Tickflow (Flutter client)

Flutter client for Tickflow, a real-time US stock tracker built as a system-design
learning project. Talks only to the Tickflow backend (`../tick-flow-backend`) — never to
data vendors directly. See `CLAUDE.md` for the full backend contract and architecture notes.

Tabs: **Markets** (browse/search + live prices), **Favourites** (watchlist + sparklines),
**Portfolio** (holdings + allocation donut), **Notifications** (price alerts + triggered feed),
**Menu** (account, theme, about). Stock detail with a candlestick chart is pushed from any tab.

## Stack

Flutter · Riverpod (MVVM) · go_router · dio · web_socket_channel · fl_chart ·
flutter_secure_storage · intl · google_fonts.

## Run

The API base URL is passed at build time via `--dart-define=API_URL=...`
(the WebSocket URL is derived from it). Sign in with the staging test account
`kai@tickflow.dev`, or register a new one.

```bash
flutter pub get

# Against always-on staging (recommended — simulated ticks, works 24/7):
flutter run -d chrome --dart-define=API_URL=https://tickflow-staging.up.railway.app

# Against a local backend (needs docker compose + npm run dev in ../tick-flow-backend):
flutter run -d chrome --dart-define=API_URL=http://localhost:3000
```

## Test & analyze

```bash
flutter analyze
flutter test
```

## Deploy (Flutter web → Firebase Hosting)

Live at **https://tickflow-dev.web.app**. Hosting config lives in `firebase.json`; the default
project is `tickflow-dev` (`.firebaserc`). One-time: `npm i -g firebase-tools` and `firebase login`.

```bash
flutter build web --release --dart-define=API_URL=https://tickflow-staging.up.railway.app
firebase deploy --only hosting
```

The build output (`build/web`) is git-ignored and rebuilt on each deploy. All routes are
rewritten to `index.html` so deep links resolve. The backend allows all CORS origins, so the
hosted site can call staging without extra config.
