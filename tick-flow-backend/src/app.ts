import Fastify, { type FastifyInstance } from 'fastify';
import type { FinnhubClient } from './infrastructure/finnhub-rest.js';
import { registerAuthRoutes } from './routes/auth.js';
import { registerQuoteRoutes } from './routes/quotes.js';
import { registerSymbolRoutes } from './routes/symbols.js';
import type { AuthService } from './services/auth-service.js';
import type { QuoteService } from './services/quote-service.js';

export interface AppDeps {
  authService: AuthService;
  quoteService: QuoteService;
  finnhub: FinnhubClient;
}

export function buildApp(deps: AppDeps): FastifyInstance {
  const app = Fastify({ logger: true });

  app.get('/health', async () => ({ status: 'ok' }));

  registerAuthRoutes(app, deps.authService);
  registerQuoteRoutes(app, deps.quoteService);
  registerSymbolRoutes(app, deps.finnhub);

  return app;
}
