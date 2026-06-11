import Fastify, { type FastifyInstance } from 'fastify';
import type { FinnhubClient } from './infrastructure/finnhub-rest.js';
import { makeAuthGuard } from './routes/auth-guard.js';
import { registerAuthRoutes } from './routes/auth.js';
import { registerAlertRoutes } from './routes/alerts.js';
import { registerPortfolioRoutes } from './routes/portfolio.js';
import { registerQuoteRoutes } from './routes/quotes.js';
import { registerSymbolRoutes } from './routes/symbols.js';
import { registerWatchlistRoutes } from './routes/watchlist.js';
import type { AlertService } from './services/alert-service.js';
import type { AuthService, GoogleTokenVerifier } from './services/auth-service.js';
import type { PortfolioService } from './services/portfolio-service.js';
import type { QuoteService } from './services/quote-service.js';
import type { WatchlistService } from './services/watchlist-service.js';

export interface AppDeps {
  authService: AuthService;
  googleVerifier: GoogleTokenVerifier | null;
  quoteService: QuoteService;
  watchlistService: WatchlistService;
  portfolioService: PortfolioService;
  alertService: AlertService;
  finnhub: FinnhubClient;
}

export function buildApp(deps: AppDeps): FastifyInstance {
  const app = Fastify({ logger: true });
  const authGuard = makeAuthGuard(deps.authService);

  app.get('/health', async () => ({ status: 'ok' }));

  registerAuthRoutes(app, deps.authService, deps.googleVerifier);
  registerQuoteRoutes(app, deps.quoteService);
  registerSymbolRoutes(app, deps.finnhub);
  registerWatchlistRoutes(app, deps.watchlistService, authGuard);
  registerPortfolioRoutes(app, deps.portfolioService, authGuard);
  registerAlertRoutes(app, deps.alertService, authGuard);

  return app;
}
