import type { FastifyInstance } from 'fastify';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { buildApp } from '../app.js';
import type { FinnhubClient } from '../infrastructure/finnhub-rest.js';
import type { AlertService } from '../services/alert-service.js';
import { AuthService, type UserRecord, type UserRepo } from '../services/auth-service.js';
import type { NotificationService } from '../services/notifications.js';
import {
  PortfolioService,
  type Holding,
  type HoldingInput,
  type HoldingPatch,
  type HoldingRepo,
} from '../services/portfolio-service.js';
import type { QuoteService } from '../services/quote-service.js';
import type { SymbolDirectoryService } from '../services/symbol-directory.js';
import type { WatchlistService } from '../services/watchlist-service.js';

class MemoryUserRepo implements UserRepo {
  private users: UserRecord[] = [];
  private nextId = 1;
  async findByEmail(email: string): Promise<UserRecord | null> {
    return this.users.find((u) => u.email === email) ?? null;
  }
  async create(email: string, passwordHash: string | null): Promise<UserRecord> {
    const user = { id: `u${this.nextId++}`, email, passwordHash };
    this.users.push(user);
    return user;
  }
  async delete(userId: string): Promise<void> {
    this.users = this.users.filter((u) => u.id !== userId);
  }
}

class MemoryHoldingRepo implements HoldingRepo {
  holdings: Array<Holding & { userId: string }> = [];
  private nextId = 1;
  async list(userId: string): Promise<Holding[]> {
    return this.holdings.filter((h) => h.userId === userId);
  }
  async create(userId: string, data: HoldingInput): Promise<Holding> {
    const holding = { id: `h${this.nextId++}`, userId, createdAt: new Date(), ...data };
    this.holdings.push(holding);
    return holding;
  }
  async update(userId: string, id: string, patch: HoldingPatch): Promise<Holding | null> {
    const holding = this.holdings.find((h) => h.id === id && h.userId === userId);
    if (!holding) return null;
    Object.assign(holding, patch);
    return holding;
  }
  async remove(userId: string, id: string): Promise<boolean> {
    const before = this.holdings.length;
    this.holdings = this.holdings.filter((h) => !(h.id === id && h.userId === userId));
    return this.holdings.length < before;
  }
}

const fakeQuotes = {
  getQuotes: async (symbols: string[]) =>
    symbols.filter((s) => s !== 'UNPRICED').map((symbol) => ({ symbol, price: 200 })),
};

describe('portfolio routes', () => {
  let app: FastifyInstance;
  let authService: AuthService;

  beforeEach(() => {
    authService = new AuthService(new MemoryUserRepo(), 'test-secret');
    app = buildApp({
      authService,
      googleVerifier: null,
      portfolioService: new PortfolioService(new MemoryHoldingRepo(), fakeQuotes),
      quoteService: {} as QuoteService,
      watchlistService: {} as WatchlistService,
      alertService: {} as AlertService,
      notificationService: {} as NotificationService,
      candleService: null,
      symbolDirectory: {} as SymbolDirectoryService,
      finnhub: {} as FinnhubClient,
    });
  });

  afterEach(async () => {
    await app.close();
  });

  const authHeader = async (email = 'kai@example.com'): Promise<{ authorization: string }> => {
    const { token } = await authService.register(email, 'password123');
    return { authorization: `Bearer ${token}` };
  };

  it('rejects all portfolio routes without a token', async () => {
    for (const [method, url] of [
      ['GET', '/portfolio/holdings'],
      ['POST', '/portfolio/holdings'],
      ['PUT', '/portfolio/holdings/h1'],
      ['DELETE', '/portfolio/holdings/h1'],
      ['GET', '/portfolio/summary'],
    ] as const) {
      const res = await app.inject({ method, url });
      expect(res.statusCode, `${method} ${url}`).toBe(401);
    }
  });

  it('creates, lists, updates, and deletes holdings', async () => {
    const auth = await authHeader();

    const created = await app.inject({
      method: 'POST',
      url: '/portfolio/holdings',
      headers: auth,
      payload: { symbol: 'aapl', qty: 10, buyPrice: 150 },
    });
    expect(created.statusCode).toBe(201);
    const holding = created.json().holding;
    expect(holding.symbol).toBe('AAPL');
    expect(holding.assetType).toBe('stock'); // default

    const updated = await app.inject({
      method: 'PUT',
      url: `/portfolio/holdings/${holding.id}`,
      headers: auth,
      payload: { qty: 12 },
    });
    expect(updated.json().holding.qty).toBe(12);

    const del = await app.inject({
      method: 'DELETE',
      url: `/portfolio/holdings/${holding.id}`,
      headers: auth,
    });
    expect(del.statusCode).toBe(204);

    const list = await app.inject({ method: 'GET', url: '/portfolio/holdings', headers: auth });
    expect(list.json().holdings).toEqual([]);
  });

  it("cannot touch another user's holding (404)", async () => {
    const aliceAuth = await authHeader('alice@example.com');
    const bobAuth = await authHeader('bob@example.com');

    const created = await app.inject({
      method: 'POST',
      url: '/portfolio/holdings',
      headers: aliceAuth,
      payload: { symbol: 'AAPL', qty: 1, buyPrice: 100 },
    });
    const id = created.json().holding.id;

    const update = await app.inject({
      method: 'PUT',
      url: `/portfolio/holdings/${id}`,
      headers: bobAuth,
      payload: { qty: 999 },
    });
    expect(update.statusCode).toBe(404);

    const del = await app.inject({
      method: 'DELETE',
      url: `/portfolio/holdings/${id}`,
      headers: bobAuth,
    });
    expect(del.statusCode).toBe(404);
  });

  it('summary values holdings with quotes and flags unpriced ones', async () => {
    const auth = await authHeader();
    await app.inject({
      method: 'POST',
      url: '/portfolio/holdings',
      headers: auth,
      payload: { symbol: 'AAPL', qty: 10, buyPrice: 150 },
    });
    await app.inject({
      method: 'POST',
      url: '/portfolio/holdings',
      headers: auth,
      payload: { symbol: 'UNPRICED', qty: 5, buyPrice: 10 },
    });

    const res = await app.inject({ method: 'GET', url: '/portfolio/summary', headers: auth });
    const summary = res.json();

    // AAPL: 10 × $200 = 2000 value vs 1500 cost
    expect(summary.totalValue).toBe(2000);
    expect(summary.totalGainLoss).toBe(500);
    expect(summary.incomplete).toBe(true);
    expect(summary.allocation).toEqual([{ symbol: 'AAPL', value: 2000, percent: 100 }]);
    const unpriced = summary.holdings.find((h: { symbol: string }) => h.symbol === 'UNPRICED');
    expect(unpriced.marketValue).toBeNull();
  });

  it('rejects invalid bodies', async () => {
    const auth = await authHeader();

    const negativeQty = await app.inject({
      method: 'POST',
      url: '/portfolio/holdings',
      headers: auth,
      payload: { symbol: 'AAPL', qty: -1, buyPrice: 100 },
    });
    expect(negativeQty.statusCode).toBe(400);

    const emptyPatch = await app.inject({
      method: 'PUT',
      url: '/portfolio/holdings/h1',
      headers: auth,
      payload: {},
    });
    expect(emptyPatch.statusCode).toBe(400);
  });
});
