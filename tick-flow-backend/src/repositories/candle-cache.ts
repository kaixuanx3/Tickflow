import type { Redis } from 'ioredis';
import type { CandleCache } from '../services/candle-service.js';

type Cached = { candles: import('../services/candle-service.js').Candle[]; fetchedAt: number };

/**
 * Redis TTL (7 days) far exceeds every freshness window — like the quote
 * cache, the long tail exists to serve stale charts when FMP is down or the
 * 250/day budget is exhausted.
 */
export class RedisCandleCache implements CandleCache {
  constructor(
    private readonly redis: Redis,
    private readonly ttlSeconds = 7 * 24 * 3600,
  ) {}

  async get(key: string): Promise<Cached | null> {
    const raw = await this.redis.get(`candles:${key}`);
    return raw ? (JSON.parse(raw) as Cached) : null;
  }

  async set(key: string, value: Cached): Promise<void> {
    await this.redis.setex(`candles:${key}`, this.ttlSeconds, JSON.stringify(value));
  }
}
