export interface WatchlistItem {
  symbol: string;
  createdAt: Date;
}

export interface WatchlistRepo {
  list(userId: string): Promise<WatchlistItem[]>;
  upsert(userId: string, symbol: string): Promise<WatchlistItem>;
  remove(userId: string, symbol: string): Promise<void>;
}

/** Add and remove are idempotent — favouriting twice is not an error. */
export class WatchlistService {
  constructor(private readonly repo: WatchlistRepo) {}

  list(userId: string): Promise<WatchlistItem[]> {
    return this.repo.list(userId);
  }

  add(userId: string, symbol: string): Promise<WatchlistItem> {
    return this.repo.upsert(userId, symbol.toUpperCase());
  }

  remove(userId: string, symbol: string): Promise<void> {
    return this.repo.remove(userId, symbol.toUpperCase());
  }
}
