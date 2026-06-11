import { describe, expect, it, vi } from 'vitest';
import {
  QuoteService,
  type CachedQuote,
  type QuoteCache,
  type QuoteData,
  type QuoteFetcher,
} from './quote-service.js';

const quote = (symbol: string, price: number): QuoteData => ({
  symbol,
  price,
  change: 1,
  changePercent: 0.5,
  high: price + 1,
  low: price - 1,
  open: price,
  prevClose: price - 1,
  ts: 1_000_000,
});

class MemoryCache implements QuoteCache {
  store = new Map<string, CachedQuote>();
  async get(symbol: string): Promise<CachedQuote | null> {
    return this.store.get(symbol) ?? null;
  }
  async set(symbol: string, q: CachedQuote): Promise<void> {
    this.store.set(symbol, q);
  }
}

describe('QuoteService', () => {
  it('fetches upstream on cache miss and caches the result', async () => {
    const cache = new MemoryCache();
    const fetcher: QuoteFetcher = { getQuote: vi.fn(async (s) => quote(s, 150)) };
    const service = new QuoteService(cache, fetcher);

    const result = await service.getQuote('AAPL');

    expect(result).toMatchObject({ symbol: 'AAPL', price: 150, stale: false, delayed: true });
    expect(cache.store.get('AAPL')?.price).toBe(150);
    expect(fetcher.getQuote).toHaveBeenCalledTimes(1);
  });

  it('serves a fresh cache hit without calling upstream', async () => {
    const cache = new MemoryCache();
    const fetcher: QuoteFetcher = { getQuote: vi.fn(async (s) => quote(s, 999)) };
    const now = vi.fn(() => 5_000);
    const service = new QuoteService(cache, fetcher, 10_000, now);
    cache.store.set('AAPL', { ...quote('AAPL', 150), fetchedAt: 0 });

    const result = await service.getQuote('AAPL');

    expect(result?.price).toBe(150);
    expect(fetcher.getQuote).not.toHaveBeenCalled();
  });

  it('refetches once the cached entry is older than freshMs', async () => {
    const cache = new MemoryCache();
    const fetcher: QuoteFetcher = { getQuote: vi.fn(async (s) => quote(s, 160)) };
    const now = vi.fn(() => 20_000);
    const service = new QuoteService(cache, fetcher, 10_000, now);
    cache.store.set('AAPL', { ...quote('AAPL', 150), fetchedAt: 0 });

    const result = await service.getQuote('AAPL');

    expect(result).toMatchObject({ price: 160, stale: false });
    expect(fetcher.getQuote).toHaveBeenCalledTimes(1);
  });

  it('deduplicates concurrent requests into ONE upstream fetch', async () => {
    const cache = new MemoryCache();
    let resolve!: (q: QuoteData) => void;
    const fetcher: QuoteFetcher = {
      getQuote: vi.fn(() => new Promise<QuoteData>((r) => (resolve = r))),
    };
    const service = new QuoteService(cache, fetcher);

    const requests = Promise.all([
      service.getQuote('AAPL'),
      service.getQuote('AAPL'),
      service.getQuote('AAPL'),
    ]);
    // let the service get past its (async) cache check and call the fetcher
    await new Promise((r) => setTimeout(r, 0));
    resolve(quote('AAPL', 150));
    const results = await requests;

    expect(fetcher.getQuote).toHaveBeenCalledTimes(1);
    expect(results.map((r) => r?.price)).toEqual([150, 150, 150]);
  });

  it('serves expired cache with stale:true when upstream fails', async () => {
    const cache = new MemoryCache();
    const fetcher: QuoteFetcher = {
      getQuote: vi.fn(async () => {
        throw new Error('rate limited');
      }),
    };
    const now = vi.fn(() => 60_000);
    const service = new QuoteService(cache, fetcher, 10_000, now);
    cache.store.set('AAPL', { ...quote('AAPL', 150), fetchedAt: 0 });

    const result = await service.getQuote('AAPL');

    expect(result).toMatchObject({ price: 150, stale: true });
  });

  it('returns null (no throw) when upstream fails and nothing is cached', async () => {
    const fetcher: QuoteFetcher = {
      getQuote: vi.fn(async () => {
        throw new Error('down');
      }),
    };
    const service = new QuoteService(new MemoryCache(), fetcher);

    await expect(service.getQuote('AAPL')).resolves.toBeNull();
  });

  it('returns null for unknown symbols', async () => {
    const fetcher: QuoteFetcher = { getQuote: vi.fn(async () => null) };
    const service = new QuoteService(new MemoryCache(), fetcher);

    await expect(service.getQuote('NOPE')).resolves.toBeNull();
  });

  it('treats a broken cache as a miss and still serves from upstream', async () => {
    const cache: QuoteCache = {
      get: vi.fn(async () => {
        throw new Error('redis down');
      }),
      set: vi.fn(async () => {
        throw new Error('redis down');
      }),
    };
    const fetcher: QuoteFetcher = { getQuote: vi.fn(async (s) => quote(s, 150)) };
    const service = new QuoteService(cache, fetcher);

    const result = await service.getQuote('AAPL');

    expect(result).toMatchObject({ price: 150, stale: false });
  });

  it('getQuotes drops unavailable symbols and keeps the rest', async () => {
    const fetcher: QuoteFetcher = {
      getQuote: vi.fn(async (s) => (s === 'AAPL' ? quote(s, 150) : null)),
    };
    const service = new QuoteService(new MemoryCache(), fetcher);

    const results = await service.getQuotes(['AAPL', 'NOPE']);

    expect(results).toHaveLength(1);
    expect(results[0]?.symbol).toBe('AAPL');
  });
});
