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
import { RedisSubscriptionStore } from './repositories/subscription-store.js';
import { AuthService } from './services/auth-service.js';
import { PortfolioService } from './services/portfolio-service.js';
import { SubscriptionManager } from './services/subscription-manager.js';
import { QuoteService } from './services/quote-service.js';
import { WatchlistService } from './services/watchlist-service.js';
import type { TickSource } from './services/tick-source.js';
import { TickWsServer } from './ws/tick-ws-server.js';

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

const tickSource = createTickSource(env);

const app = buildApp({
  authService,
  googleVerifier,
  quoteService,
  watchlistService,
  portfolioService,
  finnhub,
});

const subscriptionStore = new RedisSubscriptionStore(redis);
// A crashed previous run must not leak refcounts. enableOfflineQueue is off,
// so wait (briefly) for the connection; if Redis is down, still boot.
try {
  await new Promise<void>((resolve, reject) => {
    if (redis.status === 'ready') return resolve();
    const timeout = setTimeout(() => reject(new Error('redis not ready')), 3000);
    redis.once('ready', () => {
      clearTimeout(timeout);
      resolve();
    });
  });
  await subscriptionStore.reset();
} catch (err) {
  console.warn('[subs] skipping refcount reset at boot:', (err as Error).message);
}
const subscriptionManager = new SubscriptionManager(tickSource, quoteService, subscriptionStore);
// the manager is both the subscription policy and the merged tick feed
// (streamed + polled symbols come out of the same onTick, same shape)
const wsServer = new TickWsServer(app.server, authService, subscriptionManager, subscriptionManager);

const shutdown = async (): Promise<void> => {
  wsServer.close();
  subscriptionManager.close();
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
