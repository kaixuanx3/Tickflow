import Fastify, { type FastifyInstance } from 'fastify';
import type { FinnhubClient } from './infrastructure/finnhub-rest.js';
import { makeAuthGuard } from './routes/auth-guard.js';
import { registerAuthRoutes } from './routes/auth.js';
import { registerQuoteRoutes } from './routes/quotes.js';
import { registerSymbolRoutes } from './routes/symbols.js';
import { registerWatchlistRoutes } from './routes/watchlist.js';
import type { AuthService, GoogleTokenVerifier } from './services/auth-service.js';
import type { QuoteService } from './services/quote-service.js';
import type { WatchlistService } from './services/watchlist-service.js';

export interface AppDeps {
  authService: AuthService;
  googleVerifier: GoogleTokenVerifier | null;
  quoteService: QuoteService;
  watchlistService: WatchlistService;
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

  return app;
}
