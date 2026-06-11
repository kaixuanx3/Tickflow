import Fastify, { type FastifyInstance } from 'fastify';
import type { FinnhubClient } from './infrastructure/finnhub-rest.js';
import { registerQuoteRoutes } from './routes/quotes.js';
import { registerSymbolRoutes } from './routes/symbols.js';
import type { QuoteService } from './services/quote-service.js';

export interface AppDeps {
  quoteService: QuoteService;
  finnhub: FinnhubClient;
}

export function buildApp(deps: AppDeps): FastifyInstance {
  const app = Fastify({ logger: true });

  app.get('/health', async () => ({ status: 'ok' }));

  registerQuoteRoutes(app, deps.quoteService);
  registerSymbolRoutes(app, deps.finnhub);

  return app;
}
