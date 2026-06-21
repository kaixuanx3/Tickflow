import type { FastifyInstance } from 'fastify';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { buildApp } from '../app.js';
import type { FinnhubClient } from '../infrastructure/finnhub-rest.js';
import {
  AlertService,
  type Alert,
  type AlertInput,
  type AlertPatch,
  type AlertRepo,
} from '../services/alert-service.js';
import { AuthService, type UserRecord, type UserRepo } from '../services/auth-service.js';
import type { NotificationService } from '../services/notifications.js';
import type { PortfolioService } from '../services/portfolio-service.js';
import type { QuoteService } from '../services/quote-service.js';
import type { SymbolDirectoryService } from '../services/symbol-directory.js';
import type { WatchlistService } from '../services/watchlist-service.js';

class MemoryUserRepo implements UserRepo {
  private users: UserRecord[] = [];
  async findByEmail(email: string): Promise<UserRecord | null> {
    return this.users.find((u) => u.email === email) ?? null;
  }
  async findById(userId: string): Promise<UserRecord | null> {
    return this.users.find((u) => u.id === userId) ?? null;
  }
  async create(email: string, passwordHash: string | null): Promise<UserRecord> {
    const user = { id: `u${this.users.length + 1}`, email, name: null, passwordHash, pushEnabled: true };
    this.users.push(user);
    return user;
  }
  async updateProfile(userId: string, data: { name?: string | null }): Promise<UserRecord> {
    const user = this.users.find((u) => u.id === userId);
    if (!user) throw new Error('user not found');
    if (data.name !== undefined) user.name = data.name;
    return user;
  }
  async updatePasswordHash(userId: string, passwordHash: string): Promise<void> {
    const user = this.users.find((u) => u.id === userId);
    if (user) user.passwordHash = passwordHash;
  }
  async delete(userId: string): Promise<void> {
    this.users = this.users.filter((u) => u.id !== userId);
  }
}

export class MemoryAlertRepo implements AlertRepo {
  alerts: Alert[] = [];
  private nextId = 1;
  async list(userId: string): Promise<Alert[]> {
    return this.alerts.filter((a) => a.userId === userId);
  }
  async create(userId: string, data: AlertInput): Promise<Alert> {
    const alert: Alert = {
      id: `a${this.nextId++}`,
      userId,
      status: 'active',
      triggerCount: 0,
      lastTriggeredAt: null,
      createdAt: new Date(),
      ...data,
    };
    this.alerts.push(alert);
    return alert;
  }
  async update(userId: string, id: string, patch: AlertPatch): Promise<Alert | null> {
    const alert = this.alerts.find((a) => a.id === id && a.userId === userId);
    if (!alert) return null;
    for (const [k, v] of Object.entries(patch)) {
      if (v !== undefined) Object.assign(alert, { [k]: v });
    }
    return alert;
  }
  async remove(userId: string, id: string): Promise<Alert | null> {
    const alert = this.alerts.find((a) => a.id === id && a.userId === userId);
    if (!alert) return null;
    this.alerts = this.alerts.filter((a) => a !== alert);
    return alert;
  }
}

describe('alert routes', () => {
  let app: FastifyInstance;
  let authService: AuthService;
  let onSymbolTouched: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    authService = new AuthService(new MemoryUserRepo(), 'test-secret');
    onSymbolTouched = vi.fn();
    app = buildApp({
      authService,
      googleVerifier: null,
      alertService: new AlertService(new MemoryAlertRepo(), onSymbolTouched),
      quoteService: {} as QuoteService,
      watchlistService: {} as WatchlistService,
      portfolioService: {} as PortfolioService,
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

  it('requires auth on all alert routes', async () => {
    for (const [method, url] of [
      ['GET', '/alerts'],
      ['POST', '/alerts'],
      ['PUT', '/alerts/a1'],
      ['DELETE', '/alerts/a1'],
    ] as const) {
      const res = await app.inject({ method, url });
      expect(res.statusCode, `${method} ${url}`).toBe(401);
    }
  });

  it('creates an alert with defaults and notifies the engine hook', async () => {
    const auth = await authHeader();

    const res = await app.inject({
      method: 'POST',
      url: '/alerts',
      headers: auth,
      payload: { symbol: 'aapl', ruleType: 'price_above', threshold: 300 },
    });

    expect(res.statusCode).toBe(201);
    expect(res.json().alert).toMatchObject({
      symbol: 'AAPL',
      ruleType: 'price_above',
      threshold: 300,
      kind: 'one_shot',
      status: 'active',
      triggerCount: 0,
    });
    expect(onSymbolTouched).toHaveBeenCalledWith('AAPL');
  });

  it('updates threshold and re-arms a done alert, scoped to the owner', async () => {
    const auth = await authHeader();
    const created = await app.inject({
      method: 'POST',
      url: '/alerts',
      headers: auth,
      payload: { symbol: 'AAPL', ruleType: 'price_below', threshold: 250, kind: 're_arm' },
    });
    const id = created.json().alert.id;

    const updated = await app.inject({
      method: 'PUT',
      url: `/alerts/${id}`,
      headers: auth,
      payload: { threshold: 260, status: 'active' },
    });
    expect(updated.json().alert.threshold).toBe(260);

    const stranger = await authHeader('other@example.com');
    const foreign = await app.inject({
      method: 'PUT',
      url: `/alerts/${id}`,
      headers: stranger,
      payload: { threshold: 1 },
    });
    expect(foreign.statusCode).toBe(404);
  });

  it('rejects invalid payloads', async () => {
    const auth = await authHeader();

    const badRule = await app.inject({
      method: 'POST',
      url: '/alerts',
      headers: auth,
      payload: { symbol: 'AAPL', ruleType: 'volume_above', threshold: 10 },
    });
    expect(badRule.statusCode).toBe(400);

    const badStatus = await app.inject({
      method: 'PUT',
      url: '/alerts/a1',
      headers: auth,
      payload: { status: 'done' }, // engine-owned transition
    });
    expect(badStatus.statusCode).toBe(400);
  });

  it('deletes alerts and lists remaining ones', async () => {
    const auth = await authHeader();
    const created = await app.inject({
      method: 'POST',
      url: '/alerts',
      headers: auth,
      payload: { symbol: 'TSLA', ruleType: 'price_above', threshold: 400 },
    });
    const id = created.json().alert.id;

    const del = await app.inject({ method: 'DELETE', url: `/alerts/${id}`, headers: auth });
    expect(del.statusCode).toBe(204);
    expect(onSymbolTouched).toHaveBeenLastCalledWith('TSLA');

    const list = await app.inject({ method: 'GET', url: '/alerts', headers: auth });
    expect(list.json().alerts).toEqual([]);
  });
});
