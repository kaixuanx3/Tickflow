import type { Candle, CandleFetcher, CandleRange } from '../services/candle-service.js';
import { UpstreamError } from './finnhub-rest.js';

interface EodRow {
  date: string; // "2026-06-11"
  open: number;
  high: number;
  low: number;
  close: number;
  volume: number;
}

const DAY_MS = 24 * 60 * 60 * 1000;

// FMP free tier is EOD-only (intraday endpoints are 402 Restricted), so every
// range serves daily candles; 1D degrades to a 7-day daily view.
const RANGE_DAYS: Record<CandleRange, number> = { '1D': 7, '1W': 7, '1M': 31, '1Y': 366 };

export class FmpClient implements CandleFetcher {
  constructor(
    private readonly apiKey: string,
    private readonly baseUrl = 'https://financialmodelingprep.com/stable',
  ) {}

  async getCandles(symbol: string, range: CandleRange): Promise<Candle[]> {
    const from = new Date(Date.now() - RANGE_DAYS[range] * DAY_MS).toISOString().slice(0, 10);
    const rows = await this.request<EodRow[]>('/historical-price-eod/full', { symbol, from });
    return rows
      .map((row) => ({
        t: Date.parse(`${row.date}T00:00:00Z`),
        o: row.open,
        h: row.high,
        l: row.low,
        c: row.close,
        v: row.volume,
      }))
      .sort((a, b) => a.t - b.t);
  }

  private async request<T>(path: string, params: Record<string, string>): Promise<T> {
    const url = new URL(this.baseUrl + path);
    for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);
    url.searchParams.set('apikey', this.apiKey);
    let res: Response;
    try {
      res = await fetch(url);
    } catch (err) {
      throw new UpstreamError(`FMP unreachable: ${(err as Error).message}`);
    }
    if (!res.ok) throw new UpstreamError(`FMP ${path} responded ${res.status}`, res.status);
    return (await res.json()) as T;
  }
}
