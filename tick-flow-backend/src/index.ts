// Composition root: the ONLY place env vars select behavior.
import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import { Redis } from 'ioredis';
import { buildApp } from './app.js';
import { loadEnv, type Env } from './config/env.js';
import { FinnhubClient } from './infrastructure/finnhub-rest.js';
import { GoogleAuthLibraryVerifier } from './infrastructure/google-verifier.js';
import { SimulatedTickSource } from './infrastructure/simulated-tick-source.js';
import { RedisQuoteCache } from './repositories/quote-cache.js';
import { PrismaHoldingRepo } from './repositories/holding-repo.js';
import { PrismaUserRepo } from './repositories/user-repo.js';
import { PrismaWatchlistRepo } from './repositories/watchlist-repo.js';
import { AuthService } from './services/auth-service.js';
import { PortfolioService } from './services/portfolio-service.js';
import { QuoteService } from './services/quote-service.js';
import { WatchlistService } from './services/watchlist-service.js';
import type { TickSource } from './services/tick-source.js';

function createTickSource(env: Env): TickSource {
  if (env.TICK_SOURCE === 'sim') return new SimulatedTickSource();
  throw new Error('FinnhubTickSource is not implemented yet (week 3) — use TICK_SOURCE=sim');
}

const env = loadEnv();

const redis = new Redis(env.REDIS_URL, {
  // Fail fast when Redis is down so the quote path falls through to upstream
  // instead of hanging; QuoteService treats cache errors as misses.
  maxRetriesPerRequest: 1,
  enableOfflineQueue: false,
});
redis.on('error', (err) => console.error('[redis]', err.message));

const prisma = new PrismaClient();
const finnhub = new FinnhubClient(env.FINNHUB_API_KEY);
const quoteService = new QuoteService(new RedisQuoteCache(redis), finnhub);
const authService = new AuthService(new PrismaUserRepo(prisma), env.JWT_SECRET);
const watchlistService = new WatchlistService(new PrismaWatchlistRepo(prisma));
const googleVerifier = env.GOOGLE_CLIENT_ID
  ? new GoogleAuthLibraryVerifier(env.GOOGLE_CLIENT_ID)
  : null;
const portfolioService = new PortfolioService(new PrismaHoldingRepo(prisma), quoteService);

// No consumers yet — the WS fan-out (week 3) and alert engine (week 4) will
// subscribe through this same instance.
export const tickSource = createTickSource(env);

const app = buildApp({
  authService,
  googleVerifier,
  quoteService,
  watchlistService,
  portfolioService,
  finnhub,
});

const shutdown = async (): Promise<void> => {
  await app.close();
  await prisma.$disconnect();
  redis.disconnect();
  process.exit(0);
};
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

try {
  await app.listen({ port: env.PORT, host: '0.0.0.0' });
} catch (err) {
  app.log.error(err);
  process.exit(1);
}
