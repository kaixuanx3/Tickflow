import { createServer, type Server } from 'node:http';
import { WebSocket } from 'ws';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { SimulatedTickSource } from '../infrastructure/simulated-tick-source.js';
import { AuthService, type UserRecord, type UserRepo } from '../services/auth-service.js';
import type { TickSource } from '../services/tick-source.js';
import { TickWsServer, type SymbolSubscriptions } from './tick-ws-server.js';

// minimal refcounting subscriptions for hub tests (prod uses SubscriptionManager)
class LocalSubscriptions implements SymbolSubscriptions {
  private readonly refs = new Map<string, number>();
  constructor(private readonly tickSource: TickSource) {}
  async add(symbol: string): Promise<void> {
    const refs = (this.refs.get(symbol) ?? 0) + 1;
    this.refs.set(symbol, refs);
    if (refs === 1) this.tickSource.subscribe(symbol);
  }
  async remove(symbol: string): Promise<void> {
    const refs = (this.refs.get(symbol) ?? 0) - 1;
    if (refs > 0) {
      this.refs.set(symbol, refs);
      return;
    }
    this.refs.delete(symbol);
    this.tickSource.unsubscribe(symbol);
  }
}

class MemoryUserRepo implements UserRepo {
  private users: UserRecord[] = [];
  async findByEmail(email: string): Promise<UserRecord | null> {
    return this.users.find((u) => u.email === email) ?? null;
  }
  async create(email: string, passwordHash: string | null): Promise<UserRecord> {
    const user = { id: `u${this.users.length + 1}`, email, passwordHash };
    this.users.push(user);
    return user;
  }
}

const waitFor = <T>(check: () => T | undefined, timeoutMs = 2000): Promise<T> =>
  new Promise((resolve, reject) => {
    const started = Date.now();
    const poll = setInterval(() => {
      const value = check();
      if (value !== undefined) {
        clearInterval(poll);
        resolve(value);
      } else if (Date.now() - started > timeoutMs) {
        clearInterval(poll);
        reject(new Error('waitFor timed out'));
      }
    }, 5);
  });

interface TestClient {
  ws: WebSocket;
  messages: Array<Record<string, unknown>>;
  closed: Promise<number>;
}

describe('TickWsServer', () => {
  let server: Server;
  let wsServer: TickWsServer;
  let authService: AuthService;
  let port: number;
  let token: string;

  beforeEach(async () => {
    authService = new AuthService(new MemoryUserRepo(), 'test-secret');
    token = (await authService.register('kai@example.com', 'password123')).token;

    const tickSource = new SimulatedTickSource({ intervalMs: 20, seed: 1 });
    server = createServer();
    wsServer = new TickWsServer(
      server,
      authService,
      new LocalSubscriptions(tickSource),
      tickSource,
      150, // short auth timeout for tests
    );
    await new Promise<void>((resolve) => server.listen(0, resolve));
    const address = server.address();
    if (typeof address === 'string' || !address) throw new Error('no port');
    port = address.port;
  });

  afterEach(async () => {
    wsServer.close();
    await new Promise<void>((resolve) => server.close(() => resolve()));
  });

  const connect = (): Promise<TestClient> =>
    new Promise((resolve, reject) => {
      const ws = new WebSocket(`ws://127.0.0.1:${port}/ws`);
      const messages: Array<Record<string, unknown>> = [];
      ws.on('message', (raw) => messages.push(JSON.parse(raw.toString())));
      const closed = new Promise<number>((res) => ws.on('close', (code) => res(code)));
      ws.on('open', () => resolve({ ws, messages, closed }));
      ws.on('error', reject);
    });

  const authed = async (): Promise<TestClient> => {
    const client = await connect();
    client.ws.send(JSON.stringify({ type: 'auth', token }));
    await waitFor(() => client.messages.find((m) => m.type === 'auth_ok'));
    return client;
  };

  it('closes 4401 when no auth arrives within the timeout', async () => {
    const client = await connect();
    expect(await client.closed).toBe(4401);
  });

  it('closes 4401 when the first message is not auth', async () => {
    const client = await connect();
    client.ws.send(JSON.stringify({ type: 'subscribe', symbols: ['AAPL'] }));
    expect(await client.closed).toBe(4401);
  });

  it('closes 4401 on an invalid token', async () => {
    const client = await connect();
    client.ws.send(JSON.stringify({ type: 'auth', token: 'garbage' }));
    expect(await client.closed).toBe(4401);
  });

  it('streams ticks only for subscribed symbols', async () => {
    const client = await authed();
    client.ws.send(JSON.stringify({ type: 'subscribe', symbols: ['aapl'] }));

    const tick = await waitFor(() => client.messages.find((m) => m.type === 'tick'));
    expect(tick).toMatchObject({ type: 'tick', symbol: 'AAPL' });
    expect(typeof tick.price).toBe('number');
    expect(typeof tick.ts).toBe('number');

    const ticks = client.messages.filter((m) => m.type === 'tick');
    expect(ticks.every((t) => t.symbol === 'AAPL')).toBe(true);
  });

  it('stops streaming after unsubscribe', async () => {
    const client = await authed();
    client.ws.send(JSON.stringify({ type: 'subscribe', symbols: ['AAPL'] }));
    await waitFor(() => client.messages.find((m) => m.type === 'tick'));

    client.ws.send(JSON.stringify({ type: 'unsubscribe', symbols: ['AAPL'] }));
    await waitFor(() =>
      client.messages.find((m) => m.type === 'subscribed' && (m.symbols as string[]).length === 0),
    );

    const countAtUnsub = client.messages.filter((m) => m.type === 'tick').length;
    await new Promise((r) => setTimeout(r, 100));
    // allow one in-flight tick that raced the unsubscribe
    expect(client.messages.filter((m) => m.type === 'tick').length).toBeLessThanOrEqual(
      countAtUnsub + 1,
    );
  });

  it('keeps clients isolated: each receives only its own symbols', async () => {
    const a = await authed();
    const b = await authed();
    a.ws.send(JSON.stringify({ type: 'subscribe', symbols: ['AAPL'] }));
    b.ws.send(JSON.stringify({ type: 'subscribe', symbols: ['TSLA'] }));

    await waitFor(() => a.messages.find((m) => m.type === 'tick'));
    await waitFor(() => b.messages.find((m) => m.type === 'tick'));

    expect(a.messages.filter((m) => m.type === 'tick').every((m) => m.symbol === 'AAPL')).toBe(true);
    expect(b.messages.filter((m) => m.type === 'tick').every((m) => m.symbol === 'TSLA')).toBe(true);
  });

  it('ignores tokens in the query string', async () => {
    const ws = new WebSocket(`ws://127.0.0.1:${port}/ws?token=${token}`);
    const closed = new Promise<number>((res) => ws.on('close', (code) => res(code)));
    expect(await closed).toBe(4401); // still must auth via message
  });
});
