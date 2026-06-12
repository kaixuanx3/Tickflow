import { describe, expect, it, vi } from 'vitest';
import type { CompanyProfile, SymbolSearchResult } from '../infrastructure/finnhub-rest.js';
import {
  DirectoryUnavailableError,
  SYMBOL_PAGE_SIZE,
  SymbolDirectoryService,
  type JsonCache,
} from './symbol-directory.js';

const row = (symbol: string): SymbolSearchResult => ({
  symbol,
  displaySymbol: symbol,
  description: `${symbol} Inc`,
  type: 'Common Stock',
});

const profile = (symbol: string): CompanyProfile => ({
  symbol,
  name: `${symbol} Inc`,
  exchange: 'NASDAQ',
  currency: 'USD',
  country: 'US',
  marketCap: 1000,
  ipo: '1990-01-01',
  logo: null,
  website: null,
  industry: 'Technology',
});

class MemoryJsonCache implements JsonCache {
  store = new Map<string, { value: unknown; fetchedAt: number }>();
  async get<T>(key: string) {
    return (this.store.get(key) as { value: T; fetchedAt: number } | undefined) ?? null;
  }
  async set<T>(key: string, value: { value: T; fetchedAt: number }) {
    this.store.set(key, value);
  }
}

const symbols = Array.from({ length: 120 }, (_, i) => row(`S${i}`));

describe('SymbolDirectoryService', () => {
  it('paginates the cached symbol list and reports the total', async () => {
    const fetcher = { listSymbols: vi.fn(async () => symbols), getProfile: vi.fn() };
    const service = new SymbolDirectoryService(new MemoryJsonCache(), fetcher);

    const page1 = await service.listPage(1);
    const page3 = await service.listPage(3);

    expect(page1.symbols).toHaveLength(SYMBOL_PAGE_SIZE);
    expect(page1.total).toBe(120);
    expect(page3.symbols).toHaveLength(20); // 120 - 2*50
    expect(fetcher.listSymbols).toHaveBeenCalledTimes(1); // second page hit the cache
  });

  it('serves a stale list when Finnhub fails after the cache expired', async () => {
    const cache = new MemoryJsonCache();
    cache.store.set('symbols:US', { value: [row('OLD')], fetchedAt: 0 });
    const fetcher = {
      listSymbols: vi.fn(async () => {
        throw new Error('rate limited');
      }),
      getProfile: vi.fn(),
    };
    const now = vi.fn(() => 48 * 60 * 60_000); // way past 24h freshness
    const service = new SymbolDirectoryService(cache, fetcher, now);

    const page = await service.listPage(1);

    expect(page.stale).toBe(true);
    expect(page.symbols[0]!.symbol).toBe('OLD');
  });

  it('throws DirectoryUnavailableError with no cache and no upstream', async () => {
    const fetcher = {
      listSymbols: vi.fn(async () => {
        throw new Error('down');
      }),
      getProfile: vi.fn(),
    };
    const service = new SymbolDirectoryService(new MemoryJsonCache(), fetcher);

    await expect(service.listPage(1)).rejects.toThrow(DirectoryUnavailableError);
  });

  it('caches profiles per symbol and returns null for unknowns', async () => {
    const fetcher = {
      listSymbols: vi.fn(),
      getProfile: vi.fn(async (s: string) => (s === 'AAPL' ? profile('AAPL') : null)),
    };
    const service = new SymbolDirectoryService(new MemoryJsonCache(), fetcher);

    const first = await service.profile('AAPL');
    const second = await service.profile('AAPL');
    const unknown = await service.profile('NOPE');

    expect(first).toMatchObject({ symbol: 'AAPL', stale: false });
    expect(second?.name).toBe('AAPL Inc');
    expect(fetcher.getProfile).toHaveBeenCalledTimes(2); // AAPL once + NOPE once
    expect(unknown).toBeNull();
  });
});
