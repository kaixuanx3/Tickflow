import type { Redis } from 'ioredis';
import type { CachedQuote, QuoteCache } from '../services/quote-service.js';

/**
 * Redis TTL is deliberately long (1h): freshness (5–15s) is decided by
 * QuoteService via fetchedAt, while the long TTL keeps an expired-but-recent
 * value around to serve with stale:true when upstream is down.
 */
export class RedisQuoteCache implements QuoteCache {
  constructor(
    private readonly redis: Redis,
    private readonly ttlSeconds = 3600,
  ) {}

  async get(symbol: string): Promise<CachedQuote | null> {
    const raw = await this.redis.get(this.key(symbol));
    return raw ? (JSON.parse(raw) as CachedQuote) : null;
  }

  async set(symbol: string, quote: CachedQuote): Promise<void> {
    await this.redis.setex(this.key(symbol), this.ttlSeconds, JSON.stringify(quote));
  }

  private key(symbol: string): string {
    return `quote:${symbol}`;
  }
}
