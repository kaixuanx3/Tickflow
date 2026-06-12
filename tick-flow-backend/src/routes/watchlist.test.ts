import type { FastifyInstance } from 'fastify';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { buildApp } from '../app.js';
import type { FinnhubClient } from '../infrastructure/finnhub-rest.js';
import type { AlertService } from '../services/alert-service.js';
import { AuthService, type UserRecord, type UserRepo } from '../services/auth-service.js';
import type { NotificationService } from '../services/notifications.js';
import type { PortfolioService } from '../services/portfolio-service.js';
import type { QuoteService } from '../services/quote-service.js';
import {
  WatchlistService,
  type WatchlistItem,
  type WatchlistRepo,
} from '../services/watchlist-service.js';

class MemoryUserRepo implements UserRepo {
  private users: UserRecord[] = [];
  private nextId = 1;
  async findByEmail(email: string): Promise<UserRecord | null> {
    return this.users.find((u) => u.email === email) ?? null;
  }
  async create(email: string, passwordHash: string): Promise<UserRecord> {
    const user = { id: `u${this.nextId++}`, email, passwordHash };
    this.users.push(user);
    return user;
  }
}

class MemoryWatchlistRepo implements WatchlistRepo {
  private items = new Map<string, WatchlistItem[]>();
  async list(userId: string): Promise<WatchlistItem[]> {
    return this.items.get(userId) ?? [];
  }
  async upsert(userId: string, symbol: string): Promise<WatchlistItem> {
    const list = this.items.get(userId) ?? [];
    const existing = list.find((i) => i.symbol === symbol);
    if (existing) return existing;
    const item = { symbol, createdAt: new Date() };
    this.items.set(userId, [...list, item]);
    return item;
  }
  async remove(userId: string, symbol: string): Promise<void> {
    const list = this.items.get(userId) ?? [];
    this.items.set(
      userId,
      list.filter((i) => i.symbol !== symbol),
    );
  }
}

describe('watchlist routes (with auth guard)', () => {
  let app: FastifyInstance;
  let authService: AuthService;

  beforeEach(() => {
    authService = new AuthService(new MemoryUserRepo(), 'test-secret');
    app = buildApp({
      authService,
      googleVerifier: null,
      watchlistService: new WatchlistService(new MemoryWatchlistRepo()),
      // routes other than watchlist are not exercised in this test
      quoteService: {} as QuoteService,
      portfolioService: {} as PortfolioService,
      alertService: {} as AlertService,
      notificationService: {} as NotificationService,
      candleService: null,
      finnhub: {} as FinnhubClient,
    });
  });

  afterEach(async () => {
    await app.close();
  });

  const registerAndGetToken = async (): Promise<string> => {
    const { token } = await authService.register('kai@example.com', 'password123');
    return token;
  };

  it('rejects requests without a token', async () => {
    const res = await app.inject({ method: 'GET', url: '/watchlist' });
    expect(res.statusCode).toBe(401);
  });

  it('rejects requests with an invalid token', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/watchlist',
      headers: { authorization: 'Bearer garbage' },
    });
    expect(res.statusCode).toBe(401);
  });

  it('adds, lists, and removes symbols for the authed user', async () => {
    const token = await registerAndGetToken();
    const auth = { authorization: `Bearer ${token}` };

    const add = await app.inject({
      method: 'POST',
      url: '/watchlist',
      headers: auth,
      payload: { symbol: 'aapl' },
    });
    expect(add.statusCode).toBe(201);
    expect(add.json().item.symbol).toBe('AAPL'); // normalized uppercase

    await app.inject({ method: 'POST', url: '/watchlist', headers: auth, payload: { symbol: 'TSLA' } });

    const list = await app.inject({ method: 'GET', url: '/watchlist', headers: auth });
    expect(list.json().items.map((i: WatchlistItem) => i.symbol).sort()).toEqual(['AAPL', 'TSLA']);

    const del = await app.inject({ method: 'DELETE', url: '/watchlist/AAPL', headers: auth });
    expect(del.statusCode).toBe(204);

    const after = await app.inject({ method: 'GET', url: '/watchlist', headers: auth });
    expect(after.json().items.map((i: WatchlistItem) => i.symbol)).toEqual(['TSLA']);
  });

  it('adding the same symbol twice is idempotent', async () => {
    const token = await registerAndGetToken();
    const auth = { authorization: `Bearer ${token}` };

    await app.inject({ method: 'POST', url: '/watchlist', headers: auth, payload: { symbol: 'AAPL' } });
    const again = await app.inject({
      method: 'POST',
      url: '/watchlist',
      headers: auth,
      payload: { symbol: 'AAPL' },
    });
    expect(again.statusCode).toBe(201);

    const list = await app.inject({ method: 'GET', url: '/watchlist', headers: auth });
    expect(list.json().items).toHaveLength(1);
  });

  it('rejects malformed symbols', async () => {
    const token = await registerAndGetToken();

    const res = await app.inject({
      method: 'POST',
      url: '/watchlist',
      headers: { authorization: `Bearer ${token}` },
      payload: { symbol: 'not a symbol!!' },
    });
    expect(res.statusCode).toBe(400);
  });
});
