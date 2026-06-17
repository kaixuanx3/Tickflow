import { summarize, type PortfolioSummary } from './portfolio-math.js';

export type AssetType = 'stock' | 'etf' | 'crypto';

export interface Holding {
  id: string;
  symbol: string;
  qty: number;
  buyPrice: number;
  assetType: AssetType;
  position: number;
  createdAt: Date;
}

export type HoldingInput = Pick<Holding, 'symbol' | 'qty' | 'buyPrice' | 'assetType'>;
// undefined values mean "leave unchanged" (Prisma skips them on update)
export type HoldingPatch = {
  [K in 'qty' | 'buyPrice' | 'assetType']?: Holding[K] | undefined;
};

export interface HoldingRepo {
  list(userId: string): Promise<Holding[]>;
  create(userId: string, data: HoldingInput): Promise<Holding>;
  /** null when the holding doesn't exist or belongs to another user */
  update(userId: string, id: string, patch: HoldingPatch): Promise<Holding | null>;
  /** false when the holding doesn't exist or belongs to another user */
  remove(userId: string, id: string): Promise<boolean>;
  /** Persists the user's manual order; ids not owned by the user are ignored. */
  reorder(userId: string, orderedIds: string[]): Promise<void>;
}

export interface QuotesPort {
  getQuotes(symbols: string[]): Promise<Array<{ symbol: string; price: number }>>;
}

export class PortfolioService {
  constructor(
    private readonly repo: HoldingRepo,
    private readonly quotes: QuotesPort,
  ) {}

  list(userId: string): Promise<Holding[]> {
    return this.repo.list(userId);
  }

  add(userId: string, data: HoldingInput): Promise<Holding> {
    return this.repo.create(userId, { ...data, symbol: data.symbol.toUpperCase() });
  }

  update(userId: string, id: string, patch: HoldingPatch): Promise<Holding | null> {
    return this.repo.update(userId, id, patch);
  }

  remove(userId: string, id: string): Promise<boolean> {
    return this.repo.remove(userId, id);
  }

  reorder(userId: string, orderedIds: string[]): Promise<void> {
    return this.repo.reorder(userId, orderedIds);
  }

  /** Unpriced symbols (quote unavailable) appear with null values; see portfolio-math. */
  async summary(userId: string): Promise<PortfolioSummary<Holding>> {
    const holdings = await this.repo.list(userId);
    const symbols = [...new Set(holdings.map((h) => h.symbol))];
    const quotes = symbols.length > 0 ? await this.quotes.getQuotes(symbols) : [];
    return summarize(holdings, new Map(quotes.map((q) => [q.symbol, q.price])));
  }
}
