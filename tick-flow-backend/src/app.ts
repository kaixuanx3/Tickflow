import cors from '@fastify/cors';
import Fastify, { type FastifyInstance } from 'fastify';
import type { FinnhubClient } from './infrastructure/finnhub-rest.js';
import { makeAuthGuard } from './routes/auth-guard.js';
import { registerAuthRoutes } from './routes/auth.js';
import { registerAlertRoutes } from './routes/alerts.js';
import { registerCandleRoutes } from './routes/candles.js';
import { registerNotificationRoutes } from './routes/notifications.js';
import { registerPortfolioRoutes } from './routes/portfolio.js';
import { registerQuoteRoutes } from './routes/quotes.js';
import { registerSymbolRoutes } from './routes/symbols.js';
import { registerWatchlistRoutes } from './routes/watchlist.js';
import type { AlertService } from './services/alert-service.js';
import type { AuthService, GoogleTokenVerifier } from './services/auth-service.js';
import type { CandleService } from './services/candle-service.js';
import type { NotificationService } from './services/notifications.js';
import type { PortfolioService } from './services/portfolio-service.js';
import type { QuoteService } from './services/quote-service.js';
import type { SymbolDirectoryService } from './services/symbol-directory.js';
import type { WatchlistService } from './services/watchlist-service.js';

export interface AppDeps {
  authService: AuthService;
  googleVerifier: GoogleTokenVerifier | null;
  quoteService: QuoteService;
  watchlistService: WatchlistService;
  portfolioService: PortfolioService;
  alertService: AlertService;
  notificationService: NotificationService;
  candleService: CandleService | null;
  symbolDirectory: SymbolDirectoryService;
  finnhub: FinnhubClient;
}

export function buildApp(deps: AppDeps): FastifyInstance {
  const app = Fastify({ logger: true });
  // Browser clients (Flutter web) need CORS; API is token-auth, no cookies, so allow-all is fine.
  // methods must be explicit: the plugin's default preflight only allows GET,HEAD,POST.
  app.register(cors, { origin: true, methods: ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE'] });
  const authGuard = makeAuthGuard(deps.authService);

  app.get('/health', async () => ({ status: 'ok' }));

  registerAuthRoutes(app, deps.authService, deps.googleVerifier, authGuard);
  registerQuoteRoutes(app, deps.quoteService);
  registerSymbolRoutes(app, deps.finnhub, deps.symbolDirectory);
  registerWatchlistRoutes(app, deps.watchlistService, authGuard);
  registerPortfolioRoutes(app, deps.portfolioService, authGuard);
  registerAlertRoutes(app, deps.alertService, authGuard);
  registerNotificationRoutes(app, deps.notificationService, authGuard);
  registerCandleRoutes(app, deps.candleService);

  return app;
}
