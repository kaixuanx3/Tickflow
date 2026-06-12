import type { Redis } from 'ioredis';
import type { SubscriptionStore } from '../services/subscription-manager.js';

export class RedisSubscriptionStore implements SubscriptionStore {
  private readonly refsKey: string;
  private readonly touchedKey: string;

  constructor(
    private readonly redis: Redis,
    prefix = 'subs',
  ) {
    this.refsKey = `${prefix}:refs`;
    this.touchedKey = `${prefix}:touched`;
  }

  async reset(): Promise<void> {
    await this.redis.del(this.refsKey, this.touchedKey);
  }

  async incr(symbol: string): Promise<number> {
    return this.redis.hincrby(this.refsKey, symbol, 1);
  }

  async decr(symbol: string): Promise<number> {
    const refs = await this.redis.hincrby(this.refsKey, symbol, -1);
    if (refs > 0) return refs;
    await this.redis.hdel(this.refsKey, symbol);
    await this.redis.hdel(this.touchedKey, symbol);
    return 0;
  }

  async touch(symbol: string, ts: number): Promise<void> {
    await this.redis.hset(this.touchedKey, symbol, ts);
  }

  async snapshot(): Promise<Map<string, { refs: number; touched: number }>> {
    const [refs, touched] = await Promise.all([
      this.redis.hgetall(this.refsKey),
      this.redis.hgetall(this.touchedKey),
    ]);
    const result = new Map<string, { refs: number; touched: number }>();
    for (const [symbol, count] of Object.entries(refs)) {
      result.set(symbol, { refs: Number(count), touched: Number(touched[symbol] ?? 0) });
    }
    return result;
  }
}

/** In-memory twin for tests and anything that doesn't need cross-process state. */
export class MemorySubscriptionStore implements SubscriptionStore {
  private readonly entries = new Map<string, { refs: number; touched: number }>();

  async reset(): Promise<void> {
    this.entries.clear();
  }

  async incr(symbol: string): Promise<number> {
    const entry = this.entries.get(symbol) ?? { refs: 0, touched: 0 };
    entry.refs += 1;
    this.entries.set(symbol, entry);
    return entry.refs;
  }

  async decr(symbol: string): Promise<number> {
    const entry = this.entries.get(symbol);
    if (!entry) return 0;
    entry.refs -= 1;
    if (entry.refs <= 0) {
      this.entries.delete(symbol);
      return 0;
    }
    return entry.refs;
  }

  async touch(symbol: string, ts: number): Promise<void> {
    const entry = this.entries.get(symbol);
    if (entry) entry.touched = ts;
  }

  async snapshot(): Promise<Map<string, { refs: number; touched: number }>> {
    return new Map([...this.entries].map(([s, e]) => [s, { ...e }]));
  }
}
