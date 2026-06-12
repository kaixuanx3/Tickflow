import type { Redis } from 'ioredis';
import type { JsonCache } from '../services/symbol-directory.js';

/** Long TTL (7 days) backs the stale-fallback, like the quote/candle caches. */
export class RedisJsonCache implements JsonCache {
  constructor(
    private readonly redis: Redis,
    private readonly prefix: string,
    private readonly ttlSeconds = 7 * 24 * 3600,
  ) {}

  async get<T>(key: string): Promise<{ value: T; fetchedAt: number } | null> {
    const raw = await this.redis.get(`${this.prefix}:${key}`);
    return raw ? (JSON.parse(raw) as { value: T; fetchedAt: number }) : null;
  }

  async set<T>(key: string, value: { value: T; fetchedAt: number }): Promise<void> {
    await this.redis.setex(`${this.prefix}:${key}`, this.ttlSeconds, JSON.stringify(value));
  }
}
