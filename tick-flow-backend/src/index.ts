// Composition root: the ONLY place env vars select behavior.
import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import { Redis } from 'ioredis';
import { buildApp } from './app.js';
import { loadEnv, type Env } from './config/env.js';
import { FinnhubClient } from './infrastructure/finnhub-rest.js';
import { FinnhubTickSource } from './infrastructure/finnhub-tick-source.js';
import { FmpClient } from './infrastructure/fmp-client.js';
import { GoogleAuthLibraryVerifier } from './infrastructure/google-verifier.js';
import { BullMqNotificationEnqueuer } from './infrastructure/notification-queue.js';
import { startNotificationWorker } from './infrastructure/notification-worker.js';
import { FcmPushSender, LogPushSender } from './infrastructure/push-sender.js';
import { SimulatedTickSource } from './infrastructure/simulated-tick-source.js';
import { RedisCandleCache } from './repositories/candle-cache.js';
import { RedisJsonCache } from './repositories/json-cache.js';
import { RedisQuoteCache } from './repositories/quote-cache.js';
import { PrismaHoldingRepo } from './repositories/holding-repo.js';
import { PrismaUserRepo } from './repositories/user-repo.js';
import { PrismaWatchlistRepo } from './repositories/watchlist-repo.js';
import { PrismaAlertRepo } from './repositories/alert-repo.js';
import { PrismaNotificationRepo, PrismaPushTokenRepo } from './repositories/notification-repo.js';
import { RedisSubscriptionStore } from './repositories/subscription-store.js';
import { AlertEngine } from './services/alert-engine.js';
import { AlertService } from './services/alert-service.js';
import { CandleService } from './services/candle-service.js';
import { NotificationDelivery, NotificationService } from './services/notifications.js';
import { SymbolDirectoryService } from './services/symbol-directory.js';
import { AuthService } from './services/auth-service.js';
import { PortfolioService } from './services/portfolio-service.js';
import { SubscriptionManager } from './services/subscription-manager.js';
import { QuoteService } from './services/quote-service.js';
import { WatchlistService } from './services/watchlist-service.js';
import type { TickSource } from './services/tick-source.js';
import { TickWsServer } from './ws/tick-ws-server.js';

function createTickSource(env: Env): TickSource {
  if (env.TICK_SOURCE === 'sim') return new SimulatedTickSource();
  return new FinnhubTickSource(env.FINNHUB_API_KEY);
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

// BullMQ needs its own connection (blocking commands; no fail-fast tweaks)
const bullRedis = new Redis(env.REDIS_URL, { maxRetriesPerRequest: null });
bullRedis.on('error', (err) => console.error('[bullmq-redis]', err.message));
const notificationEnqueuer = new BullMqNotificationEnqueuer(bullRedis);

const alertRepo = new PrismaAlertRepo(prisma);
const alertEngine = new AlertEngine(alertRepo, notificationEnqueuer, subscriptionManager);
const alertService = new AlertService(alertRepo, (symbol) => {
  void alertEngine.onSymbolTouched(symbol);
});
await alertEngine.start(subscriptionManager);

const notificationRepo = new PrismaNotificationRepo(prisma);
const pushTokenRepo = new PrismaPushTokenRepo(prisma);
const notificationService = new NotificationService(notificationRepo, pushTokenRepo);
// A malformed service-account credential should degrade to logging, not kill boot
let pushSender;
try {
  if (env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    pushSender = new FcmPushSender(JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_JSON) as object);
  } else if (env.FIREBASE_SERVICE_ACCOUNT_PATH) {
    pushSender = new FcmPushSender(env.FIREBASE_SERVICE_ACCOUNT_PATH);
  } else {
    pushSender = new LogPushSender();
  }
} catch (err) {
  console.warn('[push] FCM init failed, falling back to log sender:', (err as Error).message);
  pushSender = new LogPushSender();
}
console.log(`[push] sender: ${pushSender.constructor.name}`);
const workerRedis = new Redis(env.REDIS_URL, { maxRetriesPerRequest: null });
workerRedis.on('error', (err) => console.error('[worker-redis]', err.message));
const notificationWorker = startNotificationWorker(
  workerRedis,
  new NotificationDelivery(notificationRepo, pushTokenRepo, pushSender),
);

const app = buildApp({
  authService,
  googleVerifier,
  quoteService,
  watchlistService,
  portfolioService,
  alertService,
  notificationService,
  candleService: env.FMP_API_KEY
    ? new CandleService(new RedisCandleCache(redis), new FmpClient(env.FMP_API_KEY))
    : null,
  symbolDirectory: new SymbolDirectoryService(new RedisJsonCache(redis, 'dir'), finnhub),
  finnhub,
});

// the manager is both the subscription policy and the merged tick feed
// (streamed + polled symbols come out of the same onTick, same shape)
const wsServer = new TickWsServer(app.server, authService, subscriptionManager, subscriptionManager);

const shutdown = async (): Promise<void> => {
  wsServer.close();
  subscriptionManager.close();
  await app.close();
  await notificationWorker.close();
  await notificationEnqueuer.close();
  await prisma.$disconnect();
  workerRedis.disconnect();
  bullRedis.disconnect();
  redis.disconnect();
  process.exit(0);
};
process.on('SIGINT', () => void shutdown());
process.on('SIGTERM', () => void shutdown());

try {
  await app.listen({ port: env.PORT, host: '0.0.0.0' });
} catch (err) {
  app.log.error(err);
  process.exit(1);
}
