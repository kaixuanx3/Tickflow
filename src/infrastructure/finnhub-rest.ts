import type { QuoteData, QuoteFetcher } from '../services/quote-service.js';

export class UpstreamError extends Error {
  constructor(
    message: string,
    readonly status?: number,
  ) {
    super(message);
    this.name = 'UpstreamError';
  }
}

export interface SymbolSearchResult {
  symbol: string;
  displaySymbol: string;
  description: string;
  type: string;
}

interface FinnhubQuoteResponse {
  c: number; // current price
  d: number; // change
  dp: number; // change percent
  h: number;
  l: number;
  o: number;
  pc: number; // previous close
  t: number; // unix seconds
}

interface FinnhubSearchResponse {
  count: number;
  result: Array<{
    symbol: string;
    displaySymbol: string;
    description: string;
    type: string;
  }>;
}

export class FinnhubClient implements QuoteFetcher {
  constructor(
    private readonly apiKey: string,
    private readonly baseUrl = 'https://finnhub.io/api/v1',
  ) {}

  async getQuote(symbol: string): Promise<QuoteData | null> {
    const data = await this.request<FinnhubQuoteResponse>('/quote', { symbol });
    // Finnhub returns all-zeros for unknown symbols instead of an error
    if (data.c === 0 && data.t === 0) return null;
    return {
      symbol,
      price: data.c,
      change: data.d,
      changePercent: data.dp,
      high: data.h,
      low: data.l,
      open: data.o,
      prevClose: data.pc,
      ts: data.t * 1000,
    };
  }

  async searchSymbols(query: string): Promise<SymbolSearchResult[]> {
    const data = await this.request<FinnhubSearchResponse>('/search', { q: query });
    return data.result.map((r) => ({
      symbol: r.symbol,
      displaySymbol: r.displaySymbol,
      description: r.description,
      type: r.type,
    }));
  }

  private async request<T>(path: string, params: Record<string, string>): Promise<T> {
    const url = new URL(this.baseUrl + path);
    for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);
    let res: Response;
    try {
      res = await fetch(url, { headers: { 'X-Finnhub-Token': this.apiKey } });
    } catch (err) {
      throw new UpstreamError(`Finnhub unreachable: ${(err as Error).message}`);
    }
    if (!res.ok) {
      throw new UpstreamError(`Finnhub ${path} responded ${res.status}`, res.status);
    }
    return (await res.json()) as T;
  }
}
