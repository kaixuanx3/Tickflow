export type CandleRange = '1D' | '1W' | '1M' | '1Y';

export interface Candle {
  t: number; // epoch ms
  o: number;
  h: number;
  l: number;
  c: number;
  v: number;
}

export interface CandleResult {
  symbol: string;
  range: CandleRange;
  candles: Candle[];
  stale: boolean; // upstream failed; serving an expired cached copy
}

interface CachedCandles {
  candles: Candle[];
  fetchedAt: number;
}

export interface CandleCache {
  get(key: string): Promise<CachedCandles | null>;
  set(key: string, value: CachedCandles): Promise<void>;
}

export interface CandleFetcher {
  getCandles(symbol: string, range: CandleRange): Promise<Candle[]>;
}

// 250 FMP calls/day is tiny → cache for hours, not seconds (CLAUDE.md).
// Intraday refreshes a bit faster so today's chart isn't a whole hour behind.
const FRESH_MS: Record<CandleRange, number> = {
  '1D': 60 * 60_000,
  '1W': 3 * 60 * 60_000,
  '1M': 12 * 60 * 60_000,
  '1Y': 24 * 60 * 60_000,
};

export class CandleService {
  constructor(
    private readonly cache: CandleCache,
    private readonly fetcher: CandleFetcher,
    private readonly now: () => number = Date.now,
  ) {}

  async getCandles(symbol: string, range: CandleRange): Promise<CandleResult> {
    const key = `${symbol}:${range}`;
    const cached = await this.cacheGet(key);
    if (cached && this.now() - cached.fetchedAt < FRESH_MS[range]) {
      return { symbol, range, candles: cached.candles, stale: false };
    }

    try {
      const candles = await this.fetcher.getCandles(symbol, range);
      await this.cacheSet(key, { candles, fetchedAt: this.now() });
      return { symbol, range, candles, stale: false };
    } catch (err) {
      // upstream down/rate-limited: yesterday's chart beats no chart
      console.error(`[candles] fetch ${key} failed:`, (err as Error).message);
      if (cached) return { symbol, range, candles: cached.candles, stale: true };
      throw new CandlesUnavailableError();
    }
  }

  private async cacheGet(key: string): Promise<CachedCandles | null> {
    try {
      return await this.cache.get(key);
    } catch {
      return null;
    }
  }

  private async cacheSet(key: string, value: CachedCandles): Promise<void> {
    try {
      await this.cache.set(key, value);
    } catch {
      // still serving the fetched candles
    }
  }
}

export class CandlesUnavailableError extends Error {
  constructor() {
    super('candles unavailable');
    this.name = 'CandlesUnavailableError';
  }
}
