export interface QuoteData {
  symbol: string;
  price: number;
  change: number;
  changePercent: number;
  high: number;
  low: number;
  open: number;
  prevClose: number;
  ts: number; // epoch ms, vendor quote time
}

export interface CachedQuote extends QuoteData {
  fetchedAt: number; // epoch ms, when WE fetched it — drives freshness
}

export interface QuoteResult extends QuoteData {
  stale: boolean; // upstream failed, serving an old cached value
  delayed: boolean; // free-tier quotes are delayed; app displays this
}

// Ports implemented by repositories/ (Redis) and infrastructure/ (Finnhub).
export interface QuoteCache {
  get(symbol: string): Promise<CachedQuote | null>;
  set(symbol: string, quote: CachedQuote): Promise<void>;
}

export interface QuoteFetcher {
  getQuote(symbol: string): Promise<QuoteData | null>;
}

/**
 * Cache-first quotes. A miss/expired entry triggers ONE upstream fetch no
 * matter how many concurrent requests want the symbol (in-flight dedup), so
 * client request rate is decoupled from the Finnhub 60/min quota.
 */
export class QuoteService {
  private readonly inFlight = new Map<string, Promise<QuoteResult | null>>();

  constructor(
    private readonly cache: QuoteCache,
    private readonly fetcher: QuoteFetcher,
    private readonly freshMs = 10_000, // CLAUDE.md: quote TTL 5–15s
    private readonly now: () => number = Date.now,
  ) {}

  async getQuotes(symbols: string[]): Promise<QuoteResult[]> {
    const results = await Promise.all(symbols.map((s) => this.getQuote(s)));
    return results.filter((q): q is QuoteResult => q !== null);
  }

  async getQuote(symbol: string): Promise<QuoteResult | null> {
    const cached = await this.cacheGet(symbol);
    if (cached && this.now() - cached.fetchedAt < this.freshMs) {
      return this.toResult(cached, false);
    }

    const existing = this.inFlight.get(symbol);
    if (existing) return existing;

    const fetch = this.fetchAndCache(symbol, cached).finally(() => {
      this.inFlight.delete(symbol);
    });
    this.inFlight.set(symbol, fetch);
    return fetch;
  }

  private async fetchAndCache(
    symbol: string,
    stale: CachedQuote | null,
  ): Promise<QuoteResult | null> {
    try {
      const fresh = await this.fetcher.getQuote(symbol);
      if (!fresh) return null; // unknown symbol
      const entry: CachedQuote = { ...fresh, fetchedAt: this.now() };
      await this.cacheSet(symbol, entry);
      return this.toResult(entry, false);
    } catch {
      // Upstream down/rate-limited: serve the expired cache entry, never crash
      return stale ? this.toResult(stale, true) : null;
    }
  }

  // Redis being down must not take the quote path down — treat as cache miss.
  private async cacheGet(symbol: string): Promise<CachedQuote | null> {
    try {
      return await this.cache.get(symbol);
    } catch {
      return null;
    }
  }

  private async cacheSet(symbol: string, entry: CachedQuote): Promise<void> {
    try {
      await this.cache.set(symbol, entry);
    } catch {
      // quote still served from the upstream response
    }
  }

  private toResult(cached: CachedQuote, stale: boolean): QuoteResult {
    const { fetchedAt: _fetchedAt, ...quote } = cached;
    return { ...quote, stale, delayed: true };
  }
}
