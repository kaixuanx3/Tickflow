import type { CompanyProfile, SymbolSearchResult } from '../infrastructure/finnhub-rest.js';

// Generic cache-aside entry; reference data changes daily at most.
interface CachedValue<T> {
  value: T;
  fetchedAt: number;
}

export interface JsonCache {
  get<T>(key: string): Promise<CachedValue<T> | null>;
  set<T>(key: string, value: CachedValue<T>): Promise<void>;
}

export interface DirectoryFetcher {
  listSymbols(): Promise<SymbolSearchResult[]>;
  getProfile(symbol: string): Promise<CompanyProfile | null>;
}

export interface SymbolPage {
  symbols: SymbolSearchResult[];
  page: number;
  pageSize: number;
  total: number;
  stale: boolean;
}

const FRESH_MS = 24 * 60 * 60_000;
export const SYMBOL_PAGE_SIZE = 50;

export class DirectoryUnavailableError extends Error {
  constructor() {
    super('symbol directory unavailable');
    this.name = 'DirectoryUnavailableError';
  }
}

/** US symbol list + company profiles: Finnhub-backed, cached for a day. */
export class SymbolDirectoryService {
  constructor(
    private readonly cache: JsonCache,
    private readonly fetcher: DirectoryFetcher,
    private readonly now: () => number = Date.now,
  ) {}

  async listPage(page: number): Promise<SymbolPage> {
    const { value: all, stale } = await this.cached('symbols:US', () =>
      this.fetcher.listSymbols(),
    );
    const start = (page - 1) * SYMBOL_PAGE_SIZE;
    return {
      symbols: all.slice(start, start + SYMBOL_PAGE_SIZE),
      page,
      pageSize: SYMBOL_PAGE_SIZE,
      total: all.length,
      stale,
    };
  }

  async profile(symbol: string): Promise<(CompanyProfile & { stale: boolean }) | null> {
    const { value, stale } = await this.cached(`profile:${symbol}`, () =>
      this.fetcher.getProfile(symbol),
    );
    return value === null ? null : { ...value, stale };
  }

  private async cached<T>(key: string, fetch: () => Promise<T>): Promise<{ value: T; stale: boolean }> {
    const hit = await this.cacheGet<T>(key);
    if (hit && this.now() - hit.fetchedAt < FRESH_MS) return { value: hit.value, stale: false };
    try {
      const value = await fetch();
      await this.cacheSet(key, { value, fetchedAt: this.now() });
      return { value, stale: false };
    } catch (err) {
      console.error(`[directory] fetch ${key} failed:`, (err as Error).message);
      if (hit) return { value: hit.value, stale: true };
      throw new DirectoryUnavailableError();
    }
  }

  private async cacheGet<T>(key: string): Promise<CachedValue<T> | null> {
    try {
      return await this.cache.get<T>(key);
    } catch {
      return null;
    }
  }

  private async cacheSet<T>(key: string, value: CachedValue<T>): Promise<void> {
    try {
      await this.cache.set(key, value);
    } catch {
      // serving the fetched value regardless
    }
  }
}
