import { describe, expect, it, vi } from 'vitest';
import {
  CandleService,
  CandlesUnavailableError,
  type Candle,
  type CandleCache,
} from './candle-service.js';

const candle = (t: number): Candle => ({ t, o: 1, h: 2, l: 0.5, c: 1.5, v: 100 });

class MemoryCache implements CandleCache {
  store = new Map<string, { candles: Candle[]; fetchedAt: number }>();
  async get(key: string) {
    return this.store.get(key) ?? null;
  }
  async set(key: string, value: { candles: Candle[]; fetchedAt: number }) {
    this.store.set(key, value);
  }
}

describe('CandleService', () => {
  it('fetches on miss, caches, and keys by symbol+range', async () => {
    const cache = new MemoryCache();
    const fetcher = { getCandles: vi.fn(async () => [candle(1), candle(2)]) };
    const service = new CandleService(cache, fetcher);

    const result = await service.getCandles('AAPL', '1D');

    expect(result).toMatchObject({ symbol: 'AAPL', range: '1D', stale: false });
    expect(result.candles).toHaveLength(2);
    expect(cache.store.has('AAPL:1D')).toBe(true);
    expect(fetcher.getCandles).toHaveBeenCalledWith('AAPL', '1D');
  });

  it('serves fresh cache without calling FMP (250/day budget)', async () => {
    const cache = new MemoryCache();
    const fetcher = { getCandles: vi.fn(async () => [candle(9)]) };
    const now = vi.fn(() => 30 * 60_000); // 30min later, 1D freshness is 1h
    const service = new CandleService(cache, fetcher, now);
    cache.store.set('AAPL:1D', { candles: [candle(1)], fetchedAt: 0 });

    const result = await service.getCandles('AAPL', '1D');

    expect(result.candles).toEqual([candle(1)]);
    expect(fetcher.getCandles).not.toHaveBeenCalled();
  });

  it('different ranges have different freshness windows', async () => {
    const cache = new MemoryCache();
    const fetcher = { getCandles: vi.fn(async () => [candle(9)]) };
    const now = vi.fn(() => 2 * 60 * 60_000); // 2h later
    const service = new CandleService(cache, fetcher, now);
    cache.store.set('AAPL:1D', { candles: [candle(1)], fetchedAt: 0 });
    cache.store.set('AAPL:1Y', { candles: [candle(2)], fetchedAt: 0 });

    await service.getCandles('AAPL', '1D'); // 1h window → expired → refetch
    expect(fetcher.getCandles).toHaveBeenCalledTimes(1);

    const yearly = await service.getCandles('AAPL', '1Y'); // 24h window → fresh
    expect(yearly.candles).toEqual([candle(2)]);
    expect(fetcher.getCandles).toHaveBeenCalledTimes(1);
  });

  it('serves expired cache with stale:true when FMP fails', async () => {
    const cache = new MemoryCache();
    const fetcher = {
      getCandles: vi.fn(async () => {
        throw new Error('budget exhausted');
      }),
    };
    const now = vi.fn(() => 48 * 60 * 60_000);
    const service = new CandleService(cache, fetcher, now);
    cache.store.set('AAPL:1Y', { candles: [candle(1)], fetchedAt: 0 });

    const result = await service.getCandles('AAPL', '1Y');

    expect(result).toMatchObject({ stale: true });
    expect(result.candles).toEqual([candle(1)]);
  });

  it('throws CandlesUnavailableError when FMP fails and nothing is cached', async () => {
    const fetcher = {
      getCandles: vi.fn(async () => {
        throw new Error('down');
      }),
    };
    const service = new CandleService(new MemoryCache(), fetcher);

    await expect(service.getCandles('AAPL', '1D')).rejects.toThrow(CandlesUnavailableError);
  });

  it('treats a broken cache as a miss', async () => {
    const cache: CandleCache = {
      get: vi.fn(async () => {
        throw new Error('redis down');
      }),
      set: vi.fn(async () => {
        throw new Error('redis down');
      }),
    };
    const fetcher = { getCandles: vi.fn(async () => [candle(1)]) };
    const service = new CandleService(cache, fetcher);

    const result = await service.getCandles('AAPL', '1D');

    expect(result.stale).toBe(false);
    expect(result.candles).toHaveLength(1);
  });
});
